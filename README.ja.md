# Lingo Prism

[English](README.en.md) · [繁體中文](README.md) · [简体中文](README.zh-Hans.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)

[最新リリースをダウンロード](https://github.com/timo-tain/Lingo-Prism/releases/latest)

> **Lingo Prism は、画面上で選択した文字をローカル OCR で認識し、元の位置に翻訳を重ねて表示するネイティブ macOS スクリーン翻訳アプリです。**

外国語のアプリ画面、画像、動画字幕、ドキュメントを、今使っているアプリから離れずに読むために作られています。

## 主な機能

- **画面オーバーレイ翻訳**：元の位置に翻訳を描画し、周囲のレイアウトを保ちます。
- **スムーズな範囲選択**：グローバルショートカットまたはメニューバーから開始し、OCR と翻訳中も選択枠を表示します。
- **オンデバイス Vision OCR**：Mac 上で認識を行い、自動検出、繁体字中国語、簡体字中国語、英語、日本語、韓国語、スペイン語、フランス語、ドイツ語、ロシア語に対応します。
- **複数の翻訳ソース**：デフォルトの Google に加え、Bing、Yandex、DeepL、macOS 翻訳、Ollama、OpenAI 互換の自前エンドポイントに対応します。
- **自前モデルのプリセット**：Ollama、LM Studio、LocalAI、vLLM、llama.cpp、Jan、カスタム OpenAI 互換サーバーを設定できます。
- **結果の選択とコピー**：翻訳文の選択・コピー、原文への切り替え、再選択、結果の終了ができます。
- **メニューバー常駐**：Dock には表示せず、ショートカット、ログイン時の起動、起動時の設定表示を設定できます。
- **多言語 UI**：英語、繁体字中国語、簡体字中国語、日本語、韓国語、スペイン語、フランス語、ドイツ語、ロシア語に対応します。

## 使い方

1. メニューバーから **Lingo Prism** を開きます。
2. 「画面翻訳を開始」を選ぶか、設定したショートカットを押します。
3. 翻訳したい文字をドラッグで選択します。右クリックまたは `Esc` でキャンセルできます。
4. OCR と翻訳が完了すると、翻訳文が元の画面上に表示されます。

設定からフローティングウィンドウ表示、言語、翻訳エンジン、ショートカット、枠線の外観を変更できます。

## プライバシーとデータの流れ

- スクリーンショットはローカル Vision OCR にのみ使用し、**翻訳サービスへ画像をアップロードしません**。
- 翻訳エンジンへ送信するのは OCR で抽出した文字だけです。選択していないプロバイダーへ自動送信することはありません。
- Ollama や自前エンドポイントを使う場合、データを Mac またはプライベートネットワーク内に保持できます。macOS 翻訳は macOS と Apple の設定に従います。
- 公開翻訳エンドポイントには制限や仕様変更があるため、本番利用前に各サービスの規約とプライバシーポリシーを確認してください。

## 動作環境と権限

- macOS 14 以降
- ソースからのビルドには Xcode 16 以降
- **画面収録**権限：選択範囲を OCR に渡すために必要です
- **アクセシビリティ**権限：別のアプリが前面にあるときもショートカットを使うために必要です

使用できる macOS 翻訳言語と Vision OCR モデルは macOS が管理します。Lingo Prism の設定画面から状態を確認し、システム設定でダウンロードできます。

## ソースからビルド

```bash
git clone https://github.com/<your-account>/lingo-prism.git
cd lingo-prism
swift test
./Scripts/make-app.sh
open './dist/Lingo Prism.app'
```

`make-app.sh` は開発用の ad-hoc 署名アプリを作成します。配布時は正式な Bundle ID、Developer ID または App Store の署名と notarization を使用してください。

## 翻訳エンジン

| 種類 | オプション |
| --- | --- |
| 公開 Web サービス | Google、Bing、Yandex、DeepL |
| システムサービス | macOS 翻訳 |
| ローカル／自前モデル | Ollama、LM Studio、LocalAI、vLLM、llama.cpp、Jan、カスタム OpenAI 互換エンドポイント |

Google がデフォルトで、アプリ内に API キーやサービス URL を入力する必要はありません。詳細は[翻訳エンジンの説明](docs/translation-engines.md)をご覧ください。

## テスト

```bash
swift test

# 任意：固定サンプルで公開翻訳サービスを確認
LINGOPRISM_LIVE_TESTS=1 swift test --filter LiveTranslatorTests
```

