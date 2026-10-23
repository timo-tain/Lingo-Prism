import Foundation

#if canImport(Translation)
@preconcurrency import Translation
#endif

enum SystemTranslationAvailability: Sendable {
    case installed
    case downloadable
    case unsupported
    case unavailable
}

struct SystemTranslationLanguageStatus: Identifiable, Sendable {
    let language: AppLanguage
    let availability: SystemTranslationAvailability

    var id: AppLanguage { language }
}

struct SystemTranslationDownloadRequest: Equatable {
    let id = UUID()
    let source: AppLanguage
    let target: AppLanguage
}

/// A small adapter over Apple's Translation framework. Availability is a
/// property of a language *pair*, so the Settings UI lists source languages
/// against the currently selected target language rather than implying that a
/// language is installed independently of every possible pairing.
enum SystemTranslationCatalog {
    static func statuses(forTarget target: AppLanguage) async -> [SystemTranslationLanguageStatus] {
        guard target != .auto, target.translationCode != nil else {
            return AppLanguage.allCases.filter { $0 != .auto }.map {
                .init(language: $0, availability: .unsupported)
            }
        }

        #if canImport(Translation)
        if #available(macOS 15.0, *) {
            return await statusesUsingSystemFramework(forTarget: target)
        }
        #endif

        return AppLanguage.allCases.filter { $0 != .auto }.map {
            .init(language: $0, availability: .unavailable)
        }
    }

    static func isDownloadablePair(source: AppLanguage, target: AppLanguage) async -> Bool {
        guard source != .auto, target != .auto else { return false }
        return await statuses(forTarget: target).first(where: { $0.language == source })?.availability == .downloadable
    }

    #if canImport(Translation)
    @available(macOS 15.0, *)
    private static func statusesUsingSystemFramework(forTarget target: AppLanguage) async -> [SystemTranslationLanguageStatus] {
        guard let targetCode = target.translationCode else { return [] }
        let availability = LanguageAvailability()
        let targetLanguage = Locale.Language(identifier: targetCode)
        var output: [SystemTranslationLanguageStatus] = []

        for language in AppLanguage.allCases where language != .auto {
            guard let sourceCode = language.translationCode else { continue }
            let systemStatus = await availability.status(
                from: Locale.Language(identifier: sourceCode),
                to: targetLanguage
            )
            let status: SystemTranslationAvailability
            switch systemStatus {
            case .installed: status = .installed
            case .supported: status = .downloadable
            case .unsupported: status = .unsupported
            @unknown default: status = .unsupported
            }
            output.append(.init(language: language, availability: status))
        }
        return output
    }
    #endif
}

enum SystemTranslationService {
    static func translate(
        texts: [String],
        source: AppLanguage,
        target: AppLanguage
    ) async throws -> [String] {
        guard source != .auto else { throw TranslationError.systemTranslationSourceRequired }
        guard target != .auto else { throw TranslationError.targetLanguageRequired }

        #if canImport(Translation)
        if #available(macOS 26.0, *) {
            return try await translateInstalled(texts: texts, source: source, target: target)
        }
        #endif

        throw TranslationError.systemTranslationRequiresMacOS26
    }

    #if canImport(Translation)
    @available(macOS 26.0, *)
    private static func translateInstalled(
        texts: [String],
        source: AppLanguage,
        target: AppLanguage
    ) async throws -> [String] {
        guard let sourceCode = source.translationCode, let targetCode = target.translationCode else {
            throw TranslationError.systemTranslationSourceRequired
        }
        let session = TranslationSession(
            installedSource: Locale.Language(identifier: sourceCode),
            target: Locale.Language(identifier: targetCode)
        )
        var output: [String] = []
        for text in texts {
            try Task.checkCancellation()
            let response = try await session.translate(text)
            let translation = response.targetText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !translation.isEmpty else { throw TranslationError.invalidResponse }
            output.append(translation)
        }
        return output
    }
    #endif
}

enum OpenAICompatibleCatalog {
    private struct Response: Decodable {
        struct Model: Decodable { let id: String }
        let data: [Model]
    }

    static func models(at baseURL: String, session: URLSession = .shared) async throws -> [String] {
        let endpoint = try OpenAICompatibleTranslator.endpoint(baseURL)
        var request = URLRequest(url: endpoint.appendingPathComponent("models"))
        request.timeoutInterval = 15
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw TranslationError.selfHostedUnavailable(baseURL)
        }
        return try JSONDecoder().decode(Response.self, from: data).data.map(\.id)
    }
}

enum OpenAICompatibleTranslator {
    private struct RequestBody: Encodable {
        struct Message: Encodable { let role: String; let content: String }
        let model: String
        let messages: [Message]
        let temperature: Double
        let stream: Bool
    }

    static func translate(
        texts: [String],
        baseURL: String,
        model: String,
        source: AppLanguage,
        target: AppLanguage,
        session: URLSession = .shared
    ) async throws -> [String] {
        let endpoint = try endpoint(baseURL)
        let cleanModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanModel.isEmpty else { throw TranslationError.selfHostedConfigurationInvalid }
        let url = endpoint.appendingPathComponent("chat/completions")
        let prompt = "You are a translation engine. Translate from \(source.promptName) to \(target.promptName). Preserve punctuation and line intent. Return only the translation, without explanations, labels, quotation marks, or Markdown."
        var output: [String] = []

        for text in texts {
            try Task.checkCancellation()
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 90
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpBody = try JSONEncoder().encode(RequestBody(
                model: cleanModel,
                messages: [.init(role: "system", content: prompt), .init(role: "user", content: text)],
                temperature: 0.1,
                stream: false
            ))

            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else { throw TranslationError.invalidResponse }
                guard (200..<300).contains(http.statusCode) else {
                    throw TranslationError.selfHostedService(statusCode: http.statusCode, detail: errorMessage(from: data))
                }
                guard let translation = responseText(from: data), !translation.isEmpty else {
                    throw TranslationError.invalidResponse
                }
                output.append(translation)
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as TranslationError {
                throw error
            } catch {
                throw TranslationError.selfHostedUnavailable(baseURL)
            }
        }
        return output
    }

    static func endpoint(_ input: String) throws -> URL {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: value),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              components.host?.isEmpty == false,
              components.user == nil, components.password == nil,
              components.query == nil, components.fragment == nil else {
            throw TranslationError.selfHostedConfigurationInvalid
        }
        let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = path.hasSuffix("v1") ? "/" + path : "/" + [path, "v1"].filter { !$0.isEmpty }.joined(separator: "/")
        guard let url = components.url else { throw TranslationError.selfHostedConfigurationInvalid }
        return url
    }

    private static func responseText(from data: Data) -> String? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = root["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any] else { return nil }
        if let text = message["content"] as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let parts = message["content"] as? [[String: Any]] {
            let text = parts.compactMap { $0["text"] as? String }.joined()
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }

    private static func errorMessage(from data: Data) -> String? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let error = root["error"] as? [String: Any] { return error["message"] as? String }
        return root["error"] as? String
    }
}
