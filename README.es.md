# Lingo Prism

[English](README.en.md) · [繁體中文](README.md) · [简体中文](README.zh-Hans.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)

[Descargar la última versión](https://github.com/timo-tain/Lingo-Prism/releases/latest)

> **Lingo Prism es un traductor de pantalla nativo para macOS que reconoce con OCR local el área seleccionada y superpone la traducción en la posición original.**

Está pensado para leer interfaces, imágenes, subtítulos y documentos en otros idiomas sin salir de la aplicación que estás usando.

## Funciones principales

- **Traducción superpuesta**: redibuja el texto traducido en su posición original y conserva el diseño alrededor.
- **Selección fluida**: inicia con un atajo global o desde la barra de menús; la selección permanece visible mientras se ejecutan el OCR y la traducción.
- **Vision OCR local**: el reconocimiento se realiza en el Mac y admite detección automática, chino tradicional, chino simplificado, inglés, japonés, coreano, español, francés, alemán y ruso.
- **Varias fuentes de traducción**: Google por defecto, además de Bing, Yandex, DeepL, traducción de macOS, Ollama y endpoints autoalojados compatibles con OpenAI.
- **Modelos autoalojados**: incluye ajustes para Ollama, LM Studio, LocalAI, vLLM, llama.cpp, Jan y servidores OpenAI compatibles personalizados.
- **Resultados seleccionables**: selecciona y copia el texto, vuelve al original, crea otra selección o cierra el resultado.
- **Solo barra de menús**: no aparece en el Dock; configura el atajo global, el inicio de sesión y la apertura de Ajustes al iniciar.
- **Interfaz localizada**: inglés, chino tradicional, chino simplificado, japonés, coreano, español, francés, alemán y ruso.

## Uso

1. Abre **Lingo Prism** desde la barra de menús.
2. Elige «Iniciar traducción de pantalla» o pulsa el atajo global configurado.
3. Arrastra para seleccionar el texto; haz clic derecho o pulsa `Esc` para cancelar.
4. Cuando terminen el OCR y la traducción, el resultado aparecerá sobre la pantalla original.

Desde Ajustes puedes usar una ventana flotante y configurar idiomas, motores, atajos y el aspecto del borde.

## Privacidad y flujo de datos

- Las capturas se usan únicamente para el Vision OCR local; **no se suben capturas a los servicios de traducción**.
- Solo se envía el texto reconocido al motor que eliges. Lingo Prism no cambia de proveedor silenciosamente.
- Ollama y los endpoints autoalojados pueden mantener los datos en tu Mac o red privada. La traducción de macOS sigue la configuración de macOS y Apple.
- Los endpoints públicos pueden tener límites o cambiar; revisa las condiciones y la política de privacidad de cada proveedor antes de usarlo en producción.

## Requisitos y permisos

- macOS 14 o posterior
- Xcode 16+ para compilar desde el código fuente
- Permiso de **Grabación de pantalla** para capturar el área seleccionada
- Permiso de **Accesibilidad** para usar el atajo global cuando otra app está en primer plano

macOS gestiona los idiomas disponibles para Traducción y los modelos de Vision OCR. Lingo Prism muestra su estado y enlaza con Ajustes del Sistema para descargarlos.

## Compilar desde el código fuente

```bash
git clone https://github.com/<your-account>/lingo-prism.git
cd lingo-prism
swift test
./Scripts/make-app.sh
open './dist/Lingo Prism.app'
```

`make-app.sh` crea una app firmada localmente con ad-hoc para desarrollo. Para distribuirla, usa un Bundle ID propio, firma Developer ID o App Store y completa la notarización.

## Motores de traducción

| Tipo | Opciones |
| --- | --- |
| Servicios web públicos | Google, Bing, Yandex, DeepL |
| Servicio del sistema | Traducción de macOS |
| Local / autoalojado | Ollama, LM Studio, LocalAI, vLLM, llama.cpp, Jan y endpoints OpenAI compatibles personalizados |

Google es el motor predeterminado y no requiere introducir una clave API ni una URL de servicio en la app. Consulta las [notas sobre motores](docs/translation-engines.md) para más información.

## Verificación

```bash
swift test

# Opcional: comprobar servicios públicos con una muestra fija
LINGOPRISM_LIVE_TESTS=1 swift test --filter LiveTranslatorTests
```

