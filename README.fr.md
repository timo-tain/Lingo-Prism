# Lingo Prism

[English](README.en.md) · [繁體中文](README.md) · [简体中文](README.zh-Hans.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)

[Télécharger la dernière version](https://github.com/timo-tain/Lingo-Prism/releases/latest)

> **Lingo Prism est un traducteur d’écran natif pour macOS : il reconnaît en OCR local la zone sélectionnée et superpose la traduction à la position du texte original.**

Il est conçu pour lire des interfaces, images, sous-titres vidéo et documents dans une autre langue sans quitter l’application utilisée.

## Fonctionnalités

- **Traduction en surimpression** : redessine le texte traduit à son emplacement d’origine tout en conservant la mise en page alentour.
- **Sélection fluide** : démarrez avec un raccourci global ou depuis la barre des menus ; la sélection reste visible pendant l’OCR et la traduction.
- **Vision OCR local** : la reconnaissance s’effectue sur le Mac et prend en charge la détection automatique, le chinois traditionnel, le chinois simplifié, l’anglais, le japonais, le coréen, l’espagnol, le français, l’allemand et le russe.
- **Plusieurs sources de traduction** : Google par défaut, ainsi que Bing, Yandex, DeepL, la traduction macOS, Ollama et les endpoints auto-hébergés compatibles OpenAI.
- **Modèles auto-hébergés** : préréglages pour Ollama, LM Studio, LocalAI, vLLM, llama.cpp, Jan et les serveurs OpenAI compatibles personnalisés.
- **Résultats sélectionnables** : sélectionnez et copiez le texte, revenez à l’original, refaites une sélection ou fermez le résultat.
- **Application dans la barre des menus** : aucune icône dans le Dock ; configurez le raccourci global, le lancement à la connexion et l’ouverture des réglages au démarrage.
- **Interface localisée** : anglais, chinois traditionnel, chinois simplifié, japonais, coréen, espagnol, français, allemand et russe.

## Utilisation

1. Ouvrez **Lingo Prism** depuis la barre des menus.
2. Choisissez « Démarrer la traduction d’écran » ou utilisez le raccourci global configuré.
3. Faites glisser le curseur sur le texte à traduire ; clic droit ou `Esc` pour annuler.
4. Une fois l’OCR et la traduction terminés, le résultat apparaît sur l’écran original.

Les réglages permettent d’utiliser une fenêtre flottante et de configurer les langues, les moteurs, les raccourcis et l’apparence de la bordure.

## Confidentialité et flux des données

- Les captures servent uniquement à l’OCR Vision local ; **aucune capture n’est envoyée aux services de traduction**.
- Seul le texte extrait par OCR est envoyé au moteur choisi. Lingo Prism ne change pas de fournisseur en silence.
- Ollama et les endpoints auto-hébergés peuvent conserver les données sur votre Mac ou votre réseau privé. La traduction macOS suit les services configurés par macOS et Apple.
- Les endpoints publics peuvent imposer des limites ou évoluer ; consultez les conditions et la politique de confidentialité de chaque fournisseur avant un usage en production.

## Configuration requise et autorisations

- macOS 14 ou version ultérieure
- Xcode 16+ pour compiler depuis les sources
- Autorisation **Enregistrement de l’écran** pour capturer la zone sélectionnée
- Autorisation **Accessibilité** pour utiliser le raccourci global lorsqu’une autre app est au premier plan

macOS gère les langues disponibles pour Traduction et les modèles de langue Vision OCR. Lingo Prism affiche leur état et permet d’ouvrir les Réglages Système pour les télécharger.

## Compiler depuis les sources

```bash
git clone https://github.com/<your-account>/lingo-prism.git
cd lingo-prism
swift test
./Scripts/make-app.sh
open './dist/Lingo Prism.app'
```

`make-app.sh` crée une app signée localement en ad-hoc pour le développement. Pour la distribuer, utilisez votre Bundle ID, une signature Developer ID ou App Store et la notarisation.

## Moteurs de traduction

| Type | Options |
| --- | --- |
| Services Web publics | Google, Bing, Yandex, DeepL |
| Service système | Traduction macOS |
| Local / auto-hébergé | Ollama, LM Studio, LocalAI, vLLM, llama.cpp, Jan et endpoints OpenAI compatibles personnalisés |

Google est le moteur par défaut et ne nécessite ni clé API ni URL de service dans l’app. Consultez les [notes sur les moteurs](docs/translation-engines.md) pour plus de détails.

## Vérification

```bash
swift test

# Facultatif : vérifier les services publics avec un exemple fixe
LINGOPRISM_LIVE_TESTS=1 swift test --filter LiveTranslatorTests
```

