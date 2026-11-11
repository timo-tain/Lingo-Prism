import SwiftUI

/// Preview of Sparkle's update prompt for the simulated update state.
/// Choosing Update Now only closes this preview; it never downloads or installs.
struct SimulatedUpdatePromptView: View {
    let language: AppInterfaceLanguage
    let version: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 30))
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 3) {
                    Text(text(.updateAvailableTitle))
                        .font(.headline)
                    Text("Lingo Prism")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(String(format: text(.updateAvailableMessage), version))
                    .font(.body)
                Text(text(.releaseNotesTitle))
                    .font(.subheadline.weight(.semibold))
                Text(text(.simulatedReleaseNote))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button(text(.later)) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(text(.installUpdate)) { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minHeight: 260)
        .frame(width: 430)
    }

    private func text(_ key: AppLocalizer.DebugKey) -> String {
        AppLocalizer.debug(key, language: language)
    }
}
