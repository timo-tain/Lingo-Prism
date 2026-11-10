import SwiftUI

/// A safe preview of the update dialogs and progress state. It never calls
/// Sparkle or accesses the network, so it cannot install an update.
struct UpdateFlowSimulationView: View {
    let language: AppInterfaceLanguage

    @Environment(\.dismiss) private var dismiss
    @State private var isDownloading = false
    @State private var isComplete = false
    @State private var progress = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(isComplete ? .green : .accentColor)
                VStack(alignment: .leading, spacing: 3) {
                    Text(isComplete ? text(.downloadComplete) : isDownloading ? text(.downloading) : text(.updateAvailableTitle))
                        .font(.headline)
                    Text("Lingo Prism")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if isComplete {
                Text(text(.restartMessage))
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else if isDownloading {
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: progress)
                    Text("\(Int(progress * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(text(.updateAvailableMessage))
                        .font(.body)
                    Text(text(.releaseNotesTitle))
                        .font(.subheadline.weight(.semibold))
                    Text("• \(text(.simulatedReleaseNote))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            HStack {
                Spacer()
                if isComplete {
                    Button(text(.finish)) { dismiss() }
                        .keyboardShortcut(.defaultAction)
                } else if isDownloading {
                    Button(text(.later)) { dismiss() }
                } else {
                    Button(text(.later)) { dismiss() }
                        .keyboardShortcut(.cancelAction)
                    Button(text(.simulateDownload)) {
                        isDownloading = true
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(24)
        .frame(minHeight: 260)
        .frame(width: 430)
        .task(id: isDownloading) {
            guard isDownloading else { return }
            while progress < 1 {
                do {
                    try await Task.sleep(for: .milliseconds(90))
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
                progress = min(1, progress + 0.035)
            }
            isDownloading = false
            isComplete = true
        }
    }

    private func text(_ key: AppLocalizer.DebugKey) -> String {
        AppLocalizer.debug(key, language: language)
    }
}
