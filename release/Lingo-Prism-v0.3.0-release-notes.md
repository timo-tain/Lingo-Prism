# Lingo Prism v0.3.0

Lingo Prism is a native macOS screen translator. Select an area on screen and receive a translation overlaid at the original text position.

## Highlights

- Screen overlay translation with a selectable floating-window option.
- Local Vision OCR with language availability shown in Settings.
- Google as the default public translation source, plus Bing, Yandex, DeepL, macOS Translation, Ollama, and OpenAI-compatible self-hosted endpoints.
- Presets for Ollama, LM Studio, LocalAI, vLLM, llama.cpp, and Jan.
- Menu-bar-only workflow with configurable global shortcuts.
- Selectable translation results, original-text toggle, copy, and reselect actions.
- Localized interface: English, Traditional Chinese, Simplified Chinese, Japanese, Korean, Spanish, French, German, and Russian.

## Install

1. Download `Lingo-Prism-v0.3.0-macOS.dmg`.
2. Open the DMG and drag **Lingo Prism.app** to the **Applications** shortcut.
3. Open the app from the menu bar.
4. Grant **Screen Recording** permission when prompted. Grant **Accessibility** permission if you want to use the global shortcut from other apps.

The ZIP archive is also available for users who prefer a portable archive or need to inspect the app bundle directly.

## Notes

- The release is an ad-hoc signed macOS build for local testing.
- Google and other public web endpoints may apply rate limits or change availability.
- OCR sends recognized text to the translation engine selected by the user; screenshots are not uploaded to translation services.
