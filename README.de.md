# Lingo Prism

[English](README.en.md) · [繁體中文](README.md) · [简体中文](README.zh-Hans.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)

[Neueste Version herunterladen](https://github.com/timo-tain/Lingo-Prism/releases/latest)

> **Lingo Prism ist ein nativer macOS-Bildschirmübersetzer, der den ausgewählten Bereich per lokaler OCR erkennt und die Übersetzung an der ursprünglichen Textposition einblendet.**

Die App ist für fremdsprachige Benutzeroberflächen, Bilder, Videountertitel und Dokumente gedacht, ohne die aktuell verwendete App verlassen zu müssen.

## Funktionen

- **Bildschirm-Overlay-Übersetzung**: Zeichnet die Übersetzung an der ursprünglichen Position und erhält das umliegende Layout.
- **Flüssige Auswahl**: Start über einen globalen Shortcut oder die Menüleiste; der Auswahlrahmen bleibt während OCR und Übersetzung sichtbar.
- **Lokale Vision OCR**: Die Erkennung erfolgt auf dem Mac und unterstützt automatische Erkennung, traditionelles und vereinfachtes Chinesisch, Englisch, Japanisch, Koreanisch, Spanisch, Französisch, Deutsch und Russisch.
- **Mehrere Übersetzungsquellen**: Standardmäßig Google sowie Bing, Yandex, DeepL, macOS-Übersetzung, Ollama und OpenAI-kompatible selbst gehostete Endpunkte.
- **Presets für eigene Modelle**: Ollama, LM Studio, LocalAI, vLLM, llama.cpp, Jan und benutzerdefinierte OpenAI-kompatible Server.
- **Auswählbare Ergebnisse**: Übersetzung auswählen und kopieren, zum Original wechseln, erneut auswählen oder Ergebnis schließen.
- **Nur Menüleiste**: Kein Dock-Symbol; globalen Shortcut, Start bei Anmeldung und Anzeige der Einstellungen beim Start konfigurieren.
- **Lokalisierte Oberfläche**: Englisch, traditionelles und vereinfachtes Chinesisch, Japanisch, Koreanisch, Spanisch, Französisch, Deutsch und Russisch.

## Verwendung

1. **Lingo Prism** über die Menüleiste öffnen.
2. „Bildschirmübersetzung starten“ wählen oder den konfigurierten globalen Shortcut drücken.
3. Den zu übersetzenden Text mit der Maus markieren; Rechtsklick oder `Esc` bricht ab.
4. Nach OCR und Übersetzung erscheint das Ergebnis über dem ursprünglichen Bildschirmbereich.

In den Einstellungen können ein schwebendes Ergebnisfenster, Sprachen, Übersetzungs-Engines, Shortcuts und das Rahmen-Design geändert werden.

## Datenschutz und Datenfluss

- Screenshots werden nur für lokale Vision OCR verwendet; **Screenshots werden nicht an Übersetzungsdienste hochgeladen**.
- An die ausgewählte Engine wird nur der erkannte OCR-Text gesendet. Lingo Prism wechselt nicht stillschweigend den Anbieter.
- Ollama und selbst gehostete Endpunkte können Daten auf dem Mac oder im privaten Netzwerk halten. Die macOS-Übersetzung folgt den von macOS und Apple konfigurierten Diensten.
- Öffentliche Übersetzungs-Endpunkte können Limits haben oder sich ändern. Vor dem produktiven Einsatz die Bedingungen und Datenschutzrichtlinien der Anbieter prüfen.

## Voraussetzungen und Berechtigungen

- macOS 14 oder neuer
- Xcode 16+ für den Build aus dem Quellcode
- **Bildschirmaufnahme** zum Erfassen des ausgewählten Bereichs für OCR
- **Bedienungshilfen** für den globalen Shortcut bei einer anderen aktiven App

macOS verwaltet die verfügbaren Übersetzungssprachen und Vision-OCR-Modelle. Lingo Prism zeigt deren Status und verlinkt zu den Systemeinstellungen für Downloads.

## Aus dem Quellcode bauen

```bash
git clone https://github.com/<your-account>/lingo-prism.git
cd lingo-prism
swift test
./Scripts/make-app.sh
open './dist/Lingo Prism.app'
```

`make-app.sh` erstellt eine lokal ad-hoc-signierte App für die Entwicklung. Für die Veröffentlichung eine eigene Bundle ID, Developer-ID- oder App-Store-Signatur sowie Notarisierung verwenden.

## Übersetzungs-Engines

| Typ | Optionen |
| --- | --- |
| Öffentliche Webdienste | Google, Bing, Yandex, DeepL |
| Systemdienst | macOS-Übersetzung |
| Lokal / selbst gehostet | Ollama, LM Studio, LocalAI, vLLM, llama.cpp, Jan und benutzerdefinierte OpenAI-kompatible Endpunkte |

Google ist die Standard-Engine; in der App müssen weder API-Schlüssel noch eine Service-URL eingetragen werden. Weitere Informationen stehen in den [Hinweisen zu Übersetzungs-Engines](docs/translation-engines.md).

## Prüfung

```bash
swift test

# Optional: öffentliche Übersetzungsdienste mit einem festen Beispiel prüfen
LINGOPRISM_LIVE_TESTS=1 swift test --filter LiveTranslatorTests
```
