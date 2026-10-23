import CoreGraphics
import Foundation
import Vision

struct RecognizedLine: Sendable {
    let text: String
    let boundingBox: NormalizedRect
}

enum TextRecognitionService {
    static func recognize(_ image: CGImage, sourceLanguage: AppLanguage) async throws -> [RecognizedLine] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let request = VNRecognizeTextRequest()
                    request.recognitionLevel = .accurate
                    request.usesLanguageCorrection = true
                    request.minimumTextHeight = 0.012
                    if let code = sourceLanguage.visionCode {
                        request.recognitionLanguages = [code]
                    } else {
                        request.automaticallyDetectsLanguage = true
                    }

                    let handler = VNImageRequestHandler(cgImage: image, options: [:])
                    try handler.perform([request])
                    let lines = (request.results ?? [])
                        .compactMap { observation -> RecognizedLine? in
                            guard let candidate = observation.topCandidates(1).first,
                                  !candidate.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                                return nil
                            }
                            let box = observation.boundingBox
                            return RecognizedLine(
                                text: candidate.string,
                                boundingBox: NormalizedRect(
                                    x: box.minX,
                                    y: box.minY,
                                    width: box.width,
                                    height: box.height
                                )
                            )
                        }
                        .sorted {
                            let yDifference = abs($0.boundingBox.y - $1.boundingBox.y)
                            if yDifference > 0.035 { return $0.boundingBox.y > $1.boundingBox.y }
                            return $0.boundingBox.x < $1.boundingBox.x
                        }
                    continuation.resume(returning: lines)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
