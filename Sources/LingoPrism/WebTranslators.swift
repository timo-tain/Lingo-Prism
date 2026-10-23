import Foundation

/// Native Swift implementations of the public protocols also used by Pot.
/// No page scraping, browser cookies, persistent tokens, or automatic provider fallback.
struct WebTranslationClient: Sendable {
    var session: URLSession = .shared

    func translate(
        texts: [String],
        engine: TranslationEngine,
        source: AppLanguage,
        target: AppLanguage,
        googleURL: String = "https://translate.googleapis.com"
    ) async throws -> [String] {
        let output: [String]
        switch engine {
        case .google:
            output = try await google(texts, source: source, target: target, baseURL: googleURL)
        case .bing:
            output = try await bing(texts, source: source, target: target)
        case .yandex:
            output = try await yandex(texts, source: source, target: target)
        case .deepl:
            output = try await deepl(texts, source: source, target: target)
        default:
            throw TranslationError.invalidResponse
        }
        guard output.count == texts.count,
              output.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw TranslationError.webResponse(engine)
        }
        // Yandex exposes a single Chinese language code. Keep the user's
        // selected script instead of silently treating Traditional Chinese as Simplified.
        if engine == .yandex {
            return output.map { Self.convertChineseScript($0, target: target) }
        }
        return output
    }

    private func google(_ texts: [String], source: AppLanguage, target: AppLanguage, baseURL: String) async throws -> [String] {
        let base = try Self.validatedBaseURL(baseURL, engine: .google)
        var output: [String] = []
        for text in texts {
            try Task.checkCancellation()
            // Keep an individual OCR line mapped to exactly one output item, even if
            // the service splits that line into several sentences in its JSON response.
            var translation = ""
            for chunk in Self.chunks(text, maximumCharacters: 1_000) {
                let url = try Self.url(base.appendingPathComponent("translate_a/single"), query: [
                    "client": "gtx", "sl": source.googleCode ?? "auto",
                    "tl": target.googleCode ?? "zh-TW", "dt": "t", "q": chunk,
                    "ie": "UTF-8", "oe": "UTF-8"
                ])
                let data = try await send(URLRequest(url: url), engine: .google)
                guard let root = try? JSONSerialization.jsonObject(with: data) as? [Any],
                      let segments = root.first as? [[Any]] else {
                    throw TranslationError.webResponse(.google)
                }
                let result = segments.compactMap { $0.first as? String }.joined()
                guard !result.isEmpty else { throw TranslationError.webResponse(.google) }
                translation += result
            }
            output.append(translation.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return output
    }

    private func bing(_ texts: [String], source: AppLanguage, target: AppLanguage) async throws -> [String] {
        let authURL = URL(string: "https://edge.microsoft.com/translate/auth")!
        let authData: Data
        do {
            authData = try await send(URLRequest(url: authURL), engine: .bing)
        } catch TranslationError.webHTTP(_, let status) where status == 404 || status == 410 {
            return try await bingWeb(texts, source: source, target: target)
        }
        guard let token = String(data: authData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !token.isEmpty, !token.contains("\n"), !token.hasPrefix("<") else {
            throw TranslationError.webResponse(.bing)
        }
        var output: [String] = []
        for batch in Self.batches(texts) {
            try Task.checkCancellation()
            var query = ["api-version": "3.0", "to": Self.bingLanguage(target)]
            if source != .auto { query["from"] = Self.bingLanguage(source) }
            let url = try Self.url(URL(string: "https://api-edge.cognitive.microsofttranslator.com/translate")!, query: query)
            var request = try Self.post(url, json: batch.map { ["Text": $0] })
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let data = try await send(request, engine: .bing)
            let response = try decode([BingItem].self, data: data, engine: .bing)
            guard response.count == batch.count else { throw TranslationError.webResponse(.bing) }
            for item in response {
                guard let text = item.translations.first?.text else { throw TranslationError.webResponse(.bing) }
                output.append(text)
            }
        }
        return output
    }

    private func bingWeb(_ texts: [String], source: AppLanguage, target: AppLanguage) async throws -> [String] {
        let page = try await send(URLRequest(url: URL(string: "https://www.bing.com/translator")!), engine: .bing)
        guard let html = String(data: page, encoding: .utf8),
              let parameters = Self.capture(#"params_AbusePreventionHelper\s*=\s*(\[[^\]]+\])"#, in: html),
              let bytes = parameters.data(using: .utf8),
              let values = try? JSONSerialization.jsonObject(with: bytes) as? [Any],
              values.count >= 2, let key = values[0] as? NSNumber, let token = values[1] as? String,
              let ig = Self.capture(#"IG:\s*"([^"]+)""#, in: html),
              let iid = Self.capture(#"data-iid="(translator\.[^"]+)""#, in: html) else {
            throw TranslationError.webResponse(.bing)
        }
        var output: [String] = []
        for (index, text) in texts.enumerated() {
            try Task.checkCancellation()
            let url = try Self.url(URL(string: "https://www.bing.com/ttranslatev3")!, query: [
                "isVertical": "1", "IG": ig, "IID": iid + ".\(index + 1)"
            ])
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = Data(Self.formEncoded([
                "fromLang": source == .auto ? "auto-detect" : Self.bingLanguage(source),
                "to": Self.bingLanguage(target), "text": text,
                "key": key.stringValue, "token": token
            ]).utf8)
            let data = try await send(request, engine: .bing)
            let items = try decode([BingItem].self, data: data, engine: .bing)
            guard let translation = items.first?.translations.first?.text else { throw TranslationError.webResponse(.bing) }
            output.append(translation)
        }
        return output
    }

    private func yandex(_ texts: [String], source: AppLanguage, target: AppLanguage) async throws -> [String] {
        var output: [String] = []
        for text in texts {
            try Task.checkCancellation()
            let url = try Self.url(URL(string: "https://translate.yandex.net/api/v1/tr.json/translate")!, query: [
                "id": UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased() + "-0-0",
                "srv": "android"
            ])
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let fields = [
                "source_lang": source == .auto ? "" : Self.genericLanguage(source),
                "target_lang": Self.genericLanguage(target), "text": text
            ]
            request.httpBody = Data(Self.formEncoded(fields).utf8)
            let data = try await send(request, engine: .yandex)
            let response = try decode(YandexResponse.self, data: data, engine: .yandex)
            guard response.code == nil || response.code == 200,
                  let result = response.text.first else { throw TranslationError.webResponse(.yandex) }
            output.append(result)
        }
        return output
    }

    private func deepl(_ texts: [String], source: AppLanguage, target: AppLanguage) async throws -> [String] {
        var output: [String] = []
        for batch in Self.batches(texts) {
            try Task.checkCancellation()
            // Pot PR #1290 documents the replacement for its retired JSON-RPC endpoint.
            let request = try Self.post(URL(string: "https://oneshot-free.www.deepl.com/v1/storefront/translate")!, json: [
                "text": batch, "source_lang": Self.deepLLanguage(source),
                "target_lang": Self.deepLLanguage(target),
                "language_model": "next-gen", "usage_type": "Translate"
            ])
            do {
                let data = try await send(request, engine: .deepl)
                let response = try decode(DeepLResponse.self, data: data, engine: .deepl)
                guard response.translations.count == batch.count else { throw TranslationError.webResponse(.deepl) }
                output.append(contentsOf: response.translations.map(\.text))
            } catch TranslationError.webHTTP(_, let status) where status == 404 || status == 410 {
                output.append(contentsOf: try await deepLLegacy(batch, source: source, target: target))
            }
        }
        return output
    }

    private func deepLLegacy(_ texts: [String], source: AppLanguage, target: AppLanguage) async throws -> [String] {
        let identifier = Int.random(in: 100_000...199_999) * 1_000
        let period = Int64(texts.joined().filter { $0 == "i" }.count + 1)
        let now = Int64(Date().timeIntervalSince1970 * 1_000)
        let timestamp = period > 1 ? now - now % period + period : now
        var request = try Self.post(URL(string: "https://www2.deepl.com/jsonrpc")!, json: [
            "jsonrpc": "2.0", "method": "LMT_handle_texts", "id": identifier,
            "params": [
                "splitting": "newlines", "timestamp": timestamp,
                "lang": [
                    "source_lang_user_selected": source == .auto ? "auto" : Self.genericLanguage(source).uppercased(),
                    "target_lang": Self.genericLanguage(target).uppercased()
                ],
                "texts": texts.map { ["text": $0, "requestAlternatives": 0] }
            ]
        ])
        if let data = request.httpBody, let json = String(data: data, encoding: .utf8) {
            let key = (identifier + 5) % 29 == 0 || (identifier + 3) % 13 == 0 ? "\"method\" : \"" : "\"method\": \""
            request.httpBody = Data(json.replacingOccurrences(of: "\"method\":\"", with: key).utf8)
        }
        let data = try await send(request, engine: .deepl)
        let result = try decode(DeepLLegacyResponse.self, data: data, engine: .deepl)
        guard result.result.texts.count == texts.count else { throw TranslationError.webResponse(.deepl) }
        return result.result.texts.map { Self.convertChineseScript($0.text, target: target) }
    }

    private func send(_ input: URLRequest, engine: TranslationEngine) async throws -> Data {
        var request = input
        request.timeoutInterval = 25
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json, text/plain;q=0.9", forHTTPHeaderField: "Accept")
        request.setValue("LingoPrism/0.3 (macOS)", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw TranslationError.webResponse(engine) }
            guard (200..<300).contains(http.statusCode) else {
                // Never log response bodies or bearer tokens. 429/403 get actionable UI.
                throw TranslationError.webHTTP(engine, http.statusCode)
            }
            return data
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as TranslationError {
            throw error
        } catch let error as URLError where [
            .secureConnectionFailed, .serverCertificateHasBadDate, .serverCertificateUntrusted,
            .serverCertificateHasUnknownRoot, .serverCertificateNotYetValid
        ].contains(error.code) {
            throw TranslationError.webCertificate(engine)
        } catch {
            throw TranslationError.webNetwork(engine)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, data: Data, engine: TranslationEngine) throws -> T {
        do { return try JSONDecoder().decode(type, from: data) }
        catch { throw TranslationError.webResponse(engine) }
    }

    private static func post(_ url: URL, json: Any) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys, .withoutEscapingSlashes])
        return request
    }

    private static func capture(_ pattern: String, in input: String) -> String? {
        guard let expression = try? NSRegularExpression(pattern: pattern),
              let match = expression.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
              let range = Range(match.range(at: 1), in: input) else { return nil }
        return String(input[range])
    }

    private static func url(_ base: URL, query: [String: String]) throws -> URL {
        var parts = URLComponents(url: base, resolvingAgainstBaseURL: false)
        parts?.queryItems = query.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = parts?.url else { throw TranslationError.invalidResponse }
        return url
    }

    static func validatedBaseURL(_ value: String, engine: TranslationEngine) throws -> URL {
        let input = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: input),
              let scheme = components.scheme?.lowercased(), ["https", "http"].contains(scheme),
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil,
              components.query == nil, components.fragment == nil,
              let url = components.url else { throw TranslationError.webConfiguration(engine) }
        return url
    }

    private static func batches(_ texts: [String]) -> [[String]] {
        var result: [[String]] = []
        var current: [String] = []
        var characters = 0
        for text in texts {
            if !current.isEmpty && (current.count >= 20 || characters + text.count > 4_000) {
                result.append(current)
                current = []
                characters = 0
            }
            current.append(text)
            characters += text.count
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    private static func chunks(_ text: String, maximumCharacters: Int) -> [String] {
        var result: [String] = []
        var start = text.startIndex
        while start < text.endIndex {
            let end = text.index(start, offsetBy: maximumCharacters, limitedBy: text.endIndex) ?? text.endIndex
            result.append(String(text[start..<end]))
            start = end
        }
        return result
    }

    private static func formEncoded(_ fields: [String: String]) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        return fields.sorted { $0.key < $1.key }.map {
            "\($0.key.addingPercentEncoding(withAllowedCharacters: allowed) ?? "")=\($0.value.addingPercentEncoding(withAllowedCharacters: allowed) ?? "")"
        }.joined(separator: "&")
    }

    private static func bingLanguage(_ language: AppLanguage) -> String {
        switch language {
        case .traditionalChinese: "zh-Hant"
        case .simplifiedChinese: "zh-Hans"
        default: language.googleCode ?? ""
        }
    }

    private static func genericLanguage(_ language: AppLanguage) -> String {
        switch language {
        case .traditionalChinese, .simplifiedChinese: "zh"
        default: language.googleCode ?? "auto"
        }
    }

    private static func deepLLanguage(_ language: AppLanguage) -> String {
        switch language {
        case .traditionalChinese: "zh-Hant"
        case .simplifiedChinese: "zh-Hans"
        default: language.googleCode ?? "auto"
        }
    }

    static func convertChineseScript(_ text: String, target: AppLanguage) -> String {
        let transform: StringTransform
        switch target {
        case .traditionalChinese: transform = StringTransform("Simplified-Traditional")
        case .simplifiedChinese: transform = StringTransform("Traditional-Simplified")
        default: return text
        }
        return text.applyingTransform(transform, reverse: false) ?? text
    }

    private struct BingItem: Decodable {
        struct Translation: Decodable { let text: String }
        let translations: [Translation]
    }
    private struct YandexResponse: Decodable { let code: Int?; let text: [String] }
    private struct DeepLResponse: Decodable {
        struct Translation: Decodable {
            let text: String
            private enum CodingKeys: String, CodingKey { case text }
            init(from decoder: any Decoder) throws {
                if let value = try? decoder.singleValueContainer().decode(String.self) {
                    text = value
                } else {
                    text = try decoder.container(keyedBy: CodingKeys.self).decode(String.self, forKey: .text)
                }
            }
        }
        let translations: [Translation]
    }
    private struct DeepLLegacyResponse: Decodable {
        struct Result: Decodable {
            struct Text: Decodable { let text: String }
            let texts: [Text]
        }
        let result: Result
    }
}
