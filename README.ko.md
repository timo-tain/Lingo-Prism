# Lingo Prism

[English](README.en.md) · [繁體中文](README.md) · [简体中文](README.zh-Hans.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)

[최신 릴리스 다운로드](https://github.com/timo-tain/Lingo-Prism/releases/latest)

> **Lingo Prism은 화면에서 선택한 텍스트를 로컬 OCR로 인식하고 원래 위치에 번역을 겹쳐 표시하는 네이티브 macOS 화면 번역 앱입니다.**

현재 사용 중인 앱을 벗어나지 않고 외국어 인터페이스, 이미지, 동영상 자막, 문서를 읽을 수 있도록 설계되었습니다.

## 주요 기능

- **화면 오버레이 번역**: 원문 위치에 번역문을 다시 그리면서 주변 레이아웃을 유지합니다.
- **부드러운 영역 선택**: 전역 단축키나 메뉴 막대에서 시작하고, OCR 및 번역 중에도 선택 영역을 표시합니다.
- **기기 내 Vision OCR**: Mac에서 인식하며 자동 감지, 번체 중국어, 간체 중국어, 영어, 일본어, 한국어, 스페인어, 프랑스어, 독일어, 러시아어를 지원합니다.
- **다양한 번역 소스**: 기본 Google을 비롯해 Bing, Yandex, DeepL, macOS 번역, Ollama, OpenAI 호환 자체 호스팅 엔드포인트를 사용할 수 있습니다.
- **자체 호스팅 모델 프리셋**: Ollama, LM Studio, LocalAI, vLLM, llama.cpp, Jan 및 사용자 지정 OpenAI 호환 서버를 지원합니다.
- **결과 선택 및 복사**: 번역문을 선택해 복사하고, 원문으로 전환하거나 다시 선택하고 결과를 닫을 수 있습니다.
- **메뉴 막대 전용 앱**: Dock에는 표시하지 않으며 전역 단축키, 로그인 시 실행, 실행 시 설정 표시를 지정할 수 있습니다.
- **다국어 UI**: 영어, 번체 중국어, 간체 중국어, 일본어, 한국어, 스페인어, 프랑스어, 독일어, 러시아어를 지원합니다.

## 사용 방법

1. 메뉴 막대에서 **Lingo Prism**을 엽니다.
2. 「화면 번역 시작」을 누르거나 설정한 전역 단축키를 누릅니다.
3. 번역할 텍스트를 드래그해 선택합니다. 오른쪽 클릭 또는 `Esc`로 취소할 수 있습니다.
4. OCR과 번역이 완료되면 번역문이 원래 화면 위에 표시됩니다.

설정에서 플로팅 창 표시, 언어, 번역 엔진, 단축키, 테두리 모양을 변경할 수 있습니다.

## 개인정보 및 데이터 흐름

- 스크린샷은 로컬 Vision OCR에만 사용하며 **번역 서비스로 업로드하지 않습니다**.
- 번역 엔진으로 보내는 것은 OCR로 추출한 텍스트뿐이며, Lingo Prism이 다른 공급자로 몰래 전환하지 않습니다.
- Ollama 또는 자체 호스팅 엔드포인트를 사용하면 데이터를 Mac 또는 사설 네트워크 안에 보관할 수 있습니다. macOS 번역은 macOS와 Apple의 서비스 설정을 따릅니다.
- 공개 번역 엔드포인트에는 제한이나 변경이 있을 수 있으므로 실제 사용 전에 각 서비스의 약관과 개인정보 처리방침을 확인하세요.

## 요구 사항 및 권한

- macOS 14 이상
- 소스에서 빌드하려면 Xcode 16 이상
- **화면 기록** 권한: 선택 영역을 OCR에 사용
- **손쉬운 사용** 권한: 다른 앱이 앞에 있을 때 전역 단축키 사용

사용 가능한 macOS 번역 언어와 Vision OCR 모델은 macOS가 관리합니다. Lingo Prism 설정에서 상태를 확인하고 시스템 설정으로 이동해 다운로드할 수 있습니다.

## 소스에서 빌드

```bash
git clone https://github.com/<your-account>/lingo-prism.git
cd lingo-prism
swift test
./Scripts/make-app.sh
open './dist/Lingo Prism.app'
```

`make-app.sh`는 개발용 로컬 ad-hoc 서명 앱을 생성합니다. 배포할 때는 정식 Bundle ID, Developer ID 또는 App Store 서명과 notarization을 사용하세요.

## 번역 엔진

| 유형 | 옵션 |
| --- | --- |
| 공개 웹 서비스 | Google, Bing, Yandex, DeepL |
| 시스템 서비스 | macOS 번역 |
| 로컬／자체 호스팅 | Ollama, LM Studio, LocalAI, vLLM, llama.cpp, Jan, 사용자 지정 OpenAI 호환 엔드포인트 |

Google이 기본 엔진이며 앱에서 API 키나 서비스 주소를 입력할 필요가 없습니다. 자세한 내용은 [번역 엔진 안내](docs/translation-engines.md)를 참고하세요.

## 테스트

```bash
swift test

# 선택 사항: 고정 샘플로 공개 번역 서비스 확인
LINGOPRISM_LIVE_TESTS=1 swift test --filter LiveTranslatorTests
```

