import Foundation
import Testing
@testable import LingoPrism

@Suite(.serialized)
struct WebTranslatorTests {
    private func session(_ handler: @escaping @Sendable (URLRequest) throws -> (Int, String)) -> URLSession {
        FixtureProtocol.handler = handler
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FixtureProtocol.self]
        return URLSession(configuration: configuration)
    }

    @Test func googleNeedsNoKeyAndPreservesOCRLineGeometry() async throws {
        let session = session { request in
            #expect(request.url?.host == "translate.googleapis.com")
            let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!
            #expect(!query.contains { $0.name == "key" })
            #expect(query.first { $0.name == "sl" }?.value == "auto")
            #expect(query.first { $0.name == "tl" }?.value == "zh-TW")
            let text = query.first { $0.name == "q" }?.value
            if text == "Hello & good morning + 你好?" {
                return (200, #"[[["您好，","Hello"],["早安。","good morning"]],null,"en"]"#)
            }
            #expect(text == "Second line")
            return (200, #"[[["第二行","Second line"]]]"#)
        }
        defer { session.invalidateAndCancel() }
        let result = try await TranslationService.translate(
            lines: [
                RecognizedLine(text: "Hello & good morning + 你好?", boundingBox: .init(x: 0.1, y: 0.8, width: 0.7, height: 0.1)),
                RecognizedLine(text: "Second line", boundingBox: .init(x: 0.2, y: 0.6, width: 0.5, height: 0.1))
            ],
            engine: .google, sourceLanguage: .auto, targetLanguage: .traditionalChinese,
            ollamaURL: "", ollamaModel: "", session: session
        )
        #expect(result.lines.map(\.translatedText) == ["您好，早安。", "第二行"])
        #expect(result.lines[1].sourceText == "Second line")
        #expect(result.lines[1].boundingBox.y == 0.6)
    }

    @Test func bingUsesEphemeralTokenAndBatchesWithoutSourceWhenAuto() async throws {
        let session = session { request in
            if request.url?.path == "/translate/auth" { return (200, "test-token") }
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
            let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!
            #expect(!query.contains { $0.name == "from" })
            #expect(query.first { $0.name == "to" }?.value == "zh-Hant")
            let input = try JSONSerialization.jsonObject(with: request.bodyData()) as! [[String: String]]
            #expect(input == [["Text": "First"], ["Text": "Second"]])
            return (200, #"[{"translations":[{"text":"第一"}]},{"translations":[{"text":"第二"}]}]"#)
        }
        defer { session.invalidateAndCancel() }
        let output = try await WebTranslationClient(session: session).translate(texts: ["First", "Second"], engine: .bing, source: .auto, target: .traditionalChinese)
        #expect(output == ["第一", "第二"])
    }

    @Test func bingHandlesRetiredEdgeAuthWithBingWebSession() async throws {
        let session = session { request in
            switch request.url!.path {
            case "/translate/auth": return (404, "")
            case "/translator":
                return (200, #"<script>var params_AbusePreventionHelper = [123456,"fixture-token",3600000]; var x={IG:"fixture-ig"};</script><div data-iid="translator.5023"></div>"#)
            default:
                #expect(request.url?.path == "/ttranslatev3")
                let body = String(data: try request.bodyData(), encoding: .utf8)!
                #expect(body.contains("fromLang=auto-detect"))
                #expect(body.contains("to=zh-Hant"))
                #expect(body.contains("token=fixture-token"))
                return (200, #"[{"translations":[{"text":"您好"}]}]"#)
            }
        }
        defer { session.invalidateAndCancel() }
        let output = try await WebTranslationClient(session: session).translate(texts: ["Hello"], engine: .bing, source: .auto, target: .traditionalChinese)
        #expect(output == ["您好"])
    }

    @Test func yandexEncodesFormAndConvertsChineseScript() async throws {
        let session = session { request in
            let body = String(data: try request.bodyData(), encoding: .utf8)!
            #expect(body.contains("text=A%26B%20%2B%20%E4%BD%A0%E5%A5%BD"))
            #expect(body.contains("target_lang=zh"))
            return (200, #"{"code":200,"text":["这是屏幕翻译"]}"#)
        }
        defer { session.invalidateAndCancel() }
        let output = try await WebTranslationClient(session: session).translate(texts: ["A&B + 你好"], engine: .yandex, source: .auto, target: .traditionalChinese)
        #expect(output == ["這是屏幕翻譯"])
    }

    @Test func deepLUsesReplacementEndpointAndTraditionalChinese() async throws {
        let session = session { request in
            #expect(request.url?.host == "oneshot-free.www.deepl.com")
            let body = try JSONSerialization.jsonObject(with: request.bodyData()) as! [String: Any]
            #expect(body["target_lang"] as? String == "zh-Hant")
            #expect(body["text"] as? [String] == ["Hello", "World"])
            // Both response formats used by the website are accepted.
            return (200, #"{"translations":[{"text":"您好"},"世界"]}"#)
        }
        defer { session.invalidateAndCancel() }
        let output = try await WebTranslationClient(session: session).translate(texts: ["Hello", "World"], engine: .deepl, source: .auto, target: .traditionalChinese)
        #expect(output == ["您好", "世界"])
    }

    @Test func deepLFallsBackToLegacyOnlyWhenNewEndpointRetired() async throws {
        let session = session { request in
            if request.url?.host == "oneshot-free.www.deepl.com" { return (404, "") }
            #expect(request.url?.host == "www2.deepl.com")
            let body = try JSONSerialization.jsonObject(with: request.bodyData()) as! [String: Any]
            #expect(body["method"] as? String == "LMT_handle_texts")
            return (200, #"{"result":{"texts":[{"text":"屏幕翻译"}]}}"#)
        }
        defer { session.invalidateAndCancel() }
        let output = try await WebTranslationClient(session: session).translate(texts: ["Screen translation"], engine: .deepl, source: .english, target: .traditionalChinese)
        #expect(output == ["屏幕翻譯"])
    }

    @Test func rateLimitIsReportedWithoutChangingProvider() async throws {
        let session = session { request in
            #expect(request.url?.host == "translate.googleapis.com")
            return (429, "limited")
        }
        defer { session.invalidateAndCancel() }
        do {
            _ = try await WebTranslationClient(session: session).translate(texts: ["Hello"], engine: .google, source: .auto, target: .traditionalChinese)
            Issue.record("Expected rate-limit error")
        } catch TranslationError.webHTTP(let engine, let status) {
            #expect(engine == .google)
            #expect(status == 429)
        }
    }

    @Test func openAICompatibleEndpointUsesStandardChatCompletionsAndPreservesLines() async throws {
        let session = session { request in
            #expect(request.url?.host == "127.0.0.1")
            #expect(request.url?.port == 1234)
            #expect(request.url?.path == "/v1/chat/completions")
            #expect(request.httpMethod == "POST")
            let body = try JSONSerialization.jsonObject(with: request.bodyData()) as! [String: Any]
            #expect(body["model"] as? String == "local-model")
            let messages = body["messages"] as! [[String: String]]
            #expect(messages.last?["content"] == "Hello")
            return (200, #"{"choices":[{"message":{"content":"您好"}}]}"#)
        }
        defer { session.invalidateAndCancel() }

        let result = try await TranslationService.translate(
            lines: [RecognizedLine(text: "Hello", boundingBox: .init(x: 0, y: 0, width: 1, height: 1))],
            engine: .openAICompatible,
            sourceLanguage: .english,
            targetLanguage: .traditionalChinese,
            ollamaURL: "",
            ollamaModel: "",
            selfHostedURL: "http://127.0.0.1:1234/v1",
            selfHostedModel: "local-model",
            session: session
        )
        #expect(result.translatedText == "您好")
    }

    @Test func openAICompatibleCatalogListsModelsAndNormalizesBaseURL() async throws {
        let session = session { request in
            #expect(request.url?.path == "/v1/models")
            #expect(request.httpMethod == "GET")
            return (200, #"{"data":[{"id":"qwen"},{"id":"llama"}]}"#)
        }
        defer { session.invalidateAndCancel() }

        let models = try await OpenAICompatibleCatalog.models(at: "http://127.0.0.1:8080", session: session)
        #expect(models == ["qwen", "llama"])
    }

}

private final class FixtureProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) throws -> (Int, String))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            let (status, content) = try Self.handler!(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(content.utf8))
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() { }
}

private extension URLRequest {
    func bodyData() throws -> Data {
        if let httpBody { return httpBody }
        guard let stream = httpBodyStream else { return Data() }
        stream.open()
        defer { stream.close() }
        var output = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count < 0 { throw stream.streamError ?? URLError(.cannotDecodeRawData) }
            if count == 0 { break }
            output.append(contentsOf: buffer.prefix(count))
        }
        return output
    }
}

struct LiveTranslatorTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["LINGOPRISM_LIVE_TESTS"] == "1"))
    func googleReturnsRealTranslationWithoutKey() async throws {
        let output = try await WebTranslationClient().translate(
            texts: ["Hello, welcome to Lingo Prism.", "Select an area of your screen."],
            engine: .google, source: .english, target: .traditionalChinese
        )
        #expect(output.count == 2)
        #expect(output[0] != "Hello, welcome to Lingo Prism.")
        print("LIVE Google: \(output)")
    }

    // This is an availability probe, not a claim that every public endpoint works.
    // It prints failures distinctly and never forwards test text to a different engine.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["LINGOPRISM_LIVE_TESTS"] == "1"), arguments: [TranslationEngine.bing, .yandex, .deepl])
    func probeOptionalPublicEndpoint(engine: TranslationEngine) async {
        do {
            let output = try await WebTranslationClient().translate(texts: ["Hello, welcome to Lingo Prism."], engine: engine, source: .english, target: .traditionalChinese)
            print("LIVE \(engine.shortTitle) OK: \(output)")
        } catch { print("LIVE \(engine.shortTitle) UNAVAILABLE: \(error.localizedDescription)") }
    }
}
