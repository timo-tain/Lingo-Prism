# Lingo Prism

[English](README.en.md) · [繁體中文](README.md) · [简体中文](README.zh-Hans.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)

[下載最新版本](https://github.com/timo-tain/Lingo-Prism/releases/latest)

> **Lingo Prism 是一款原生 macOS 螢幕翻譯工具：框選任何畫面上的文字，便以本機 OCR 擷取並將譯文無縫覆蓋回原位置。**

Lingo Prism 專為閱讀外語介面、圖片、影片字幕與文件而設計。它保留原畫面的視覺脈絡，讓翻譯看起來就像原本顯示在畫面上一樣，而不是把你帶離正在使用的 App。

## 主要特色

- **螢幕覆蓋翻譯**：譯文直接重繪在原文字位置，保留附近圖片、版面與介面。
- **流暢框選體驗**：使用全域快捷鍵或選單列按鈕，拖曳選取範圍；辨識和翻譯期間保留選取框與載入狀態。
- **本機 Vision OCR**：文字辨識在 Mac 上完成，支援自動偵測、繁中、簡中、英文、日文、韓文、西文、法文、德文與俄文。
- **可選翻譯來源**：預設 Google，也支援 Bing、Yandex、DeepL、macOS 翻譯、Ollama，以及 OpenAI 相容的自架端點。
- **自架模型支援**：內建 Ollama、LM Studio、LocalAI、vLLM、llama.cpp、Jan 與自訂 OpenAI 相容端點的預設設定。
- **可複製、可切換原文**：翻譯結果能反白選取與複製，也可快速查看原文、重新框選或關閉結果。
- **純選單列 App**：不顯示於 Dock；可調整全域快捷鍵、設定登入時啟動與開啟時顯示設定視窗。
- **多國語言介面**：支援英文、繁中、簡中、日文、韓文、西文、法文、德文與俄文，首次啟動會依 macOS 系統語言自動選擇。

## 使用方式

1. 從選單列開啟 **Lingo Prism**。
2. 點選「開始螢幕翻譯」或按下你設定的全域快捷鍵。
3. 拖曳框選欲翻譯的內容；右鍵或 `Esc` 可取消。
4. 等待本機 OCR 與翻譯完成，譯文便會覆蓋在原畫面上。

在設定中可以改為浮動視窗顯示結果、調整來源／目標語言、翻譯引擎、快捷鍵與框線效果。

Lingo Prism 使用 Sparkle 從 GitHub Releases 檢查並安裝更新。既有 v0.3.0 使用者需要手動安裝第一個含更新器的版本一次；之後可在 App 內更新。發佈步驟與簽章說明請見[更新流程](docs/updates.md)。

## 隱私與資料流向

- 螢幕截取僅用於本機 Vision OCR，**不會將截圖上傳至翻譯服務**。
- 選取範圍中的 OCR 文字會傳給你選擇的翻譯引擎；Lingo Prism 不會在未告知的情況下改用其他供應商。
- 選擇 Ollama 或自架端點時，資料可留在你的本機／自有網路；macOS 翻譯則依 macOS 與 Apple 的服務設定處理。
- 公開翻譯端點可能有使用限制、速率限制或服務變動；正式使用前請確認各供應商的條款與隱私政策。

## 系統需求與權限

- macOS 14 或更新版本
- Xcode 16+（從原始碼建置時）
- **螢幕錄製**權限：擷取選取區域供 OCR 使用
- **輔助使用**權限：讓全域快捷鍵可在其他 App 前景時運作

macOS 內建翻譯可用的語言與 Vision OCR 語言模型均由系統管理；可在 Lingo Prism 設定頁查看可用狀態並前往系統設定下載。

## 從原始碼建置

```bash
git clone https://github.com/<your-account>/lingo-prism.git
cd lingo-prism
swift test
./Scripts/make-app.sh
open './dist/Lingo Prism.app'
```

`make-app.sh` 會產生本機 ad-hoc 簽署的 App，適合開發與測試。對外發行前，請改用正式 Bundle ID、Developer ID 或 App Store 憑證簽署，並完成 notarization。

## 翻譯引擎

| 類型 | 選項 |
| --- | --- |
| 公開網路服務 | Google、Bing、Yandex、DeepL |
| 系統服務 | macOS 翻譯 |
| 本機／自架模型 | Ollama、LM Studio、LocalAI、vLLM、llama.cpp、Jan、自訂 OpenAI 相容端點 |

Google 為預設引擎，不需在 App 內填寫 API 金鑰或服務網址。其他引擎的設定與服務注意事項請見[翻譯引擎說明](docs/translation-engines.md)。

## 驗證

```bash
swift test

# 選用：以固定範例檢查公開翻譯服務連線
LINGOPRISM_LIVE_TESTS=1 swift test --filter LiveTranslatorTests
```

