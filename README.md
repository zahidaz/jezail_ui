# Jezail UI

Web interface for the **Jezail Android penetration testing toolkit**. This Flutter web app provides browser-based device control and is automatically bundled into the main Jezail Android application at build time.

## Integration

This UI is automatically downloaded and embedded into the Jezail Android app using Gradle:

```kotlin
val jezailUiDownloadUrl = "https://github.com/zahidaz/jezail_ui/releases/latest/download/web-assets.zip"
```

The web assets are fetched from GitHub releases and bundled as static assets during the Android build process.

**Part of**: [Jezail Android Pentesting Toolkit](https://github.com/zahidaz/jezail)
