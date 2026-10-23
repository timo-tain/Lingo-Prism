# Lingo Prism

[English](README.en.md) · [繁體中文](README.md) · [简体中文](README.zh-Hans.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)

[下载最新版本](https://github.com/timo-tain/Lingo-Prism/releases/latest)

> **Lingo Prism 是一款原生 macOS 屏幕翻译工具：框选画面上的文字，通过本地 OCR 识别，并将译文无缝覆盖回原文字位置。**

Lingo Prism 适合阅读外语界面、图片、视频字幕和文档，不需要离开当前正在使用的 App。

## 主要功能

- **屏幕覆盖翻译**：在原文字位置重绘译文，同时保留周围的画面布局。
- **流畅框选流程**：使用全局快捷键或菜单栏按钮开始框选；OCR 和翻译期间选区会保持显示。
- **本机 Vision OCR**：在 Mac 本机完成识别，支持自动检测、繁体中文、简体中文、英语、日语、韩语、西班牙语、法语、德语和俄语。
- **多种翻译来源**：默认使用 Google，也支持 Bing、Yandex、DeepL、macOS 翻译、Ollama 和 OpenAI 兼容的自建端点。
- **自建模型预设**：支持 Ollama、LM Studio、LocalAI、vLLM、llama.cpp、Jan 和自定义 OpenAI 兼容服务。
- **可选择结果文字**：可以反白复制译文、切换回原文、重新框选或关闭结果。
- **纯菜单栏 App**：不显示在 Dock；可以设置全局快捷键、登录时启动，以及启动时是否显示设置。
- **多语言界面**：支持英语、繁体中文、简体中文、日语、韩语、西班牙语、法语、德语和俄语。

## 使用方法

1. 从菜单栏打开 **Lingo Prism**。
2. 点击「开始屏幕翻译」或按下设置的全局快捷键。
3. 拖曳框选需要翻译的文字；右键或按 `Esc` 取消。
4. 等待 OCR 和翻译完成，译文会覆盖在原画面上。

设置中可以切换为浮动窗口，并调整语言、翻译引擎、快捷键和边框效果。

## 隐私与数据流向

- 截图只用于本机 Vision OCR，**不会将截图上传到翻译服务**。
- 只有 OCR 文字会发送到你选择的翻译引擎，Lingo Prism 不会静默切换供应商。
- 使用 Ollama 或自建端点时，数据可以保留在本机或私有网络；macOS 翻译遵循 macOS 与 Apple 的服务设置。
- 公共翻译端点可能存在速率限制或服务变化，正式使用前请查看各供应商的条款和隐私政策。

## 系统要求与权限

- macOS 14 或更高版本
- 从源码构建需要 Xcode 16+
- **屏幕录制**权限：截取选区供 OCR 使用
- **辅助功能**权限：让其他 App 位于前台时仍能使用全局快捷键

macOS 负责管理可用的翻译语言和 Vision OCR 语言模型。Lingo Prism 设置页会显示状态，并提供前往系统设置下载的入口。

## 从源码构建

```bash
git clone https://github.com/<your-account>/lingo-prism.git
cd lingo-prism
swift test
./Scripts/make-app.sh
open './dist/Lingo Prism.app'
```

`make-app.sh` 会生成用于开发的本机 ad-hoc 签名 App。对外发布时，请使用正式 Bundle ID、Developer ID 或 App Store 签名，并完成 notarization。

## 翻译引擎

| 类型 | 选项 |
| --- | --- |
| 公共网络服务 | Google、Bing、Yandex、DeepL |
| 系统服务 | macOS 翻译 |
| 本机／自建模型 | Ollama、LM Studio、LocalAI、vLLM、llama.cpp、Jan、自定义 OpenAI 兼容端点 |

Google 是默认引擎，App 内不需要填写 API 密钥或服务地址。详细说明请参阅[翻译引擎说明](docs/translation-engines.md)。

## 验证

```bash
swift test

# 可选：使用固定样例检查公共翻译服务
LINGOPRISM_LIVE_TESTS=1 swift test --filter LiveTranslatorTests
```

