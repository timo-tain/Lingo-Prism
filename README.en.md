# Lingo Prism

[English](README.en.md) · [繁體中文](README.md) · [简体中文](README.zh-Hans.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)

[Download latest release](https://github.com/timo-tain/Lingo-Prism/releases/latest)

> **Lingo Prism is a native macOS screen translator that uses local OCR to capture a selected area and seamlessly overlays the translation at the original text position.**

Lingo Prism is made for reading foreign-language interfaces, images, video subtitles, and documents without leaving the app you are using.

## Highlights

- **Screen overlay translation**: redraws translated text over the original location while preserving the surrounding layout.
- **Smooth selection flow**: start with a global shortcut or the menu bar, then drag to select; the selection stays visible while OCR and translation are running.
- **On-device Vision OCR**: recognition runs on your Mac and supports automatic detection, Traditional Chinese, Simplified Chinese, English, Japanese, Korean, Spanish, French, German, and Russian.
- **Multiple translation sources**: Google by default, plus Bing, Yandex, DeepL, macOS Translation, Ollama, and OpenAI-compatible self-hosted endpoints.
- **Self-hosted model presets**: Ollama, LM Studio, LocalAI, vLLM, llama.cpp, Jan, and custom OpenAI-compatible servers.
- **Selectable results**: select and copy translated text, switch back to the original, reselect an area, or close the result.
- **Menu bar only**: no Dock icon; configure the global shortcut, launch at login, and whether Settings opens at launch.
- **Localized UI**: English, Traditional Chinese, Simplified Chinese, Japanese, Korean, Spanish, French, German, and Russian.

## Usage

1. Open **Lingo Prism** from the menu bar.
2. Choose **Start Screen Translation** or press your configured global shortcut.
3. Drag over the text to translate; right-click or press `Esc` to cancel.
4. Wait for OCR and translation. The result appears over the original screen content.

Settings can switch to a floating result window and configure languages, engines, shortcuts, and border appearance.

## Privacy and data flow

- Screenshots are used for local Vision OCR; **screenshots are not uploaded to translation services**.
- Only OCR text is sent to the translation engine you choose. Lingo Prism does not silently switch providers.
- Ollama and self-hosted endpoints can keep data on your local machine or private network. macOS Translation follows the services configured by macOS and Apple.
- Public translation endpoints may impose limits or change over time. Review each provider's terms and privacy policy before production use.

## Requirements and permissions

- macOS 14 or later
- Xcode 16+ to build from source
- **Screen Recording** permission to capture the selected area for OCR
- **Accessibility** permission for the global shortcut while another app is frontmost

macOS manages the available Translation languages and Vision OCR language models. Lingo Prism Settings shows their status and links to System Settings for downloads.

## Build from source

```bash
git clone https://github.com/<your-account>/lingo-prism.git
cd lingo-prism
swift test
./Scripts/make-app.sh
open './dist/Lingo Prism.app'
```

`make-app.sh` creates a locally ad-hoc-signed app for development. For distribution, use your own Bundle ID, Developer ID or App Store signing, and notarize the app.

## Translation engines

| Type | Options |
| --- | --- |
| Public web services | Google, Bing, Yandex, DeepL |
| System service | macOS Translation |
| Local / self-hosted | Ollama, LM Studio, LocalAI, vLLM, llama.cpp, Jan, custom OpenAI-compatible endpoints |

Google is the default and does not require an API key or service URL in the app. See [translation engine notes](docs/translation-engines.md) for provider details.

## Validation

```bash
swift test

# Optional: check public translation services with a fixed sample
LINGOPRISM_LIVE_TESTS=1 swift test --filter LiveTranslatorTests
```

