import Foundation

enum TranslationService {
    static func translate(
        lines: [RecognizedLine],
        engine: TranslationEngine,
        sourceLanguage: AppLanguage,
        targetLanguage: AppLanguage,
        ollamaURL: String,
        ollamaModel: String,
        selfHostedURL: String = "",
        selfHostedModel: String = "",
        googleWebURL: String = "https://translate.googleapis.com",
        session: URLSession = .shared
    ) async throws -> TranslationResult {
        guard !lines.isEmpty else { throw TranslationError.noText }
        guard targetLanguage != .auto else { throw TranslationError.targetLanguageRequired }

        let original = lines.map(\.text)
        let translated: [String]
        switch engine {
        case .google, .bing, .yandex, .deepl:
            translated = try await WebTranslationClient(session: session).translate(
                texts: original, engine: engine, source: sourceLanguage, target: targetLanguage,
                googleURL: googleWebURL
            )
        case .ollama:
            translated = try await OllamaTranslator.translate(
                texts: original,
                baseURL: ollamaURL,
                model: ollamaModel,
                source: sourceLanguage,
                target: targetLanguage
            )
        case .openAICompatible:
            translated = try await OpenAICompatibleTranslator.translate(
                texts: original,
                baseURL: selfHostedURL,
                model: selfHostedModel,
                source: sourceLanguage,
                target: targetLanguage,
                session: session
            )
        case .macOS:
            translated = try await SystemTranslationService.translate(
                texts: original,
                source: sourceLanguage,
                target: targetLanguage
            )
        }

        guard translated.count == lines.count else { throw TranslationError.invalidResponse }
        let resultLines = zip(lines, translated).map { line, translatedText in
            TranslatedLine(
                id: UUID(),
                sourceText: line.text,
                translatedText: translatedText,
                boundingBox: line.boundingBox
            )
        }
        return TranslationResult(
            lines: resultLines,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            engine: engine
        )
    }
}

enum OllamaCatalog {
    private struct Response: Decodable {
        struct Model: Decodable { let name: String }
        let models: [Model]
    }

    static func models(at baseURL: String) async throws -> [String] {
        let base = baseURL.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: base + "/api/tags") else { throw TranslationError.ollamaConfigurationInvalid }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw TranslationError.ollamaUnavailable(baseURL)
        }
        return try JSONDecoder().decode(Response.self, from: data).models.map(\.name)
    }
}

private enum OllamaTranslator {
    private struct RequestBody: Encodable {
        struct Message: Encodable { let role: String; let content: String }
        let model: String
        let messages: [Message]
        let stream = false
        let options = Options()
        struct Options: Encodable { let temperature = 0.1 }
    }

    private struct ResponseBody: Decodable {
        struct Message: Decodable { let content: String }
        let message: Message
    }

    static func translate(
        texts: [String],
        baseURL: String,
        model: String,
        source: AppLanguage,
        target: AppLanguage
    ) async throws -> [String] {
        let cleanedBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: cleanedBaseURL + "/api/chat"), !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranslationError.ollamaConfigurationInvalid
        }

        // One request per visual line preserves its geometry for the screen overlay.
        // A local model may be slower than Google for many lines, but it avoids brittle JSON parsing.
        var output: [String] = []
        for text in texts {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 90
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let systemPrompt = "You are a translation engine. Translate from \(source.promptName) to \(target.promptName). Preserve punctuation and line intent. Return only the translation, without explanations, labels, quotation marks, or Markdown."
            request.httpBody = try JSONEncoder().encode(RequestBody(
                model: model,
                messages: [
                    .init(role: "system", content: systemPrompt),
                    .init(role: "user", content: text)
                ]
            ))

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else { throw TranslationError.invalidResponse }
                guard (200..<300).contains(http.statusCode) else {
                    throw TranslationError.ollamaService(statusCode: http.statusCode, detail: serviceMessage(from: data))
                }
                let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
                let translation = decoded.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !translation.isEmpty else { throw TranslationError.invalidResponse }
                output.append(translation)
            } catch let error as TranslationError {
                throw error
            } catch {
                throw TranslationError.ollamaUnavailable(baseURL)
            }
        }
        return output
    }
}

private func serviceMessage(from data: Data) -> String? {
    guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
    if let error = object["error"] as? [String: Any], let message = error["message"] as? String { return message }
    return object["error"] as? String
}

enum TranslationError: LocalizedError {
    case noText
    case targetLanguageRequired
    case ollamaConfigurationInvalid
    case ollamaUnavailable(String)
    case ollamaService(statusCode: Int, detail: String?)
    case selfHostedConfigurationInvalid
    case selfHostedUnavailable(String)
    case selfHostedService(statusCode: Int, detail: String?)
    case systemTranslationRequiresMacOS26
    case systemTranslationSourceRequired
    case invalidResponse
    case webHTTP(TranslationEngine, Int)
    case webNetwork(TranslationEngine)
    case webResponse(TranslationEngine)
    case webConfiguration(TranslationEngine)
    case webCertificate(TranslationEngine)

    var errorDescription: String? {
        switch self {
        case .noText: AppLocalizer.text(.errorNoText)
        case .targetLanguageRequired: AppLocalizer.text(.errorTargetLanguageRequired)
        case .ollamaConfigurationInvalid: AppLocalizer.text(.errorOllamaInvalid)
        case .ollamaUnavailable(let url): AppLocalizer.format(.errorOllamaUnavailableFormat, url)
        case .ollamaService(let statusCode, let detail):
            AppLocalizer.format(.errorOllamaServiceFormat, statusCode, detail ?? AppLocalizer.text(.errorOllamaDetail))
        case .selfHostedConfigurationInvalid:
            "Enter a valid OpenAI-compatible server address and model name."
        case .selfHostedUnavailable(let url):
            "Unable to connect to the local OpenAI-compatible server (\(url)). Check that it is running and that its address is correct."
        case .selfHostedService(let statusCode, let detail):
            "The local OpenAI-compatible server returned an error (\(statusCode)). \(detail ?? "Check the model name and server log.")"
        case .systemTranslationRequiresMacOS26:
            AppLocalizer.selfHosted(.requiresMacOS26)
        case .systemTranslationSourceRequired:
            AppLocalizer.selfHosted(.chooseSourceLanguage)
        case .invalidResponse: AppLocalizer.text(.errorInvalidResponse)
        case .webHTTP(let engine, let code):
            code == 429
                ? AppLocalizer.format(.errorRateLimitedFormat, engine.shortTitle)
                : AppLocalizer.format(.errorWebHTTPFormat, engine.shortTitle, code)
        case .webNetwork(let engine): AppLocalizer.format(.errorWebNetworkFormat, engine.shortTitle)
        case .webResponse(let engine): AppLocalizer.format(.errorWebResponseFormat, engine.shortTitle)
        case .webConfiguration(let engine): AppLocalizer.format(.errorWebConfigurationFormat, engine.shortTitle)
        case .webCertificate(let engine): AppLocalizer.format(.errorWebCertificateFormat, engine.shortTitle)
        }
    }
}
