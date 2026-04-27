# ArtworksManager

A personal artwork catalogue app for Android. Record, browse, and manage a private art collection of up to 1,000 artworks — fully offline, no account required.

## Features

- **Add / Edit / Delete** artworks with title, artist, year, medium, dimensions, location, acquisition date, purchase price, photo, and notes
- **Browse** the collection in grid or list view with real-time search, filter by medium, and sort by title, artist, or date
- **Dashboard** with total count, breakdown by medium and artist, and a recently-added strip
- **Export PDF** — one A4 page per artwork, photos orientation-corrected via EXIF
- **Export backup** — saves a zip containing `artworks.json` (human-readable) and all artwork photos to any location via the Android Storage Access Framework
- **Import backup** — restores a collection from a previously exported zip
- **Dark mode** — follows the system light/dark setting

## Requirements

| Tool | Version |
|------|---------|
| Android Studio | Ladybug or newer |
| JDK | 11 (bundled with Android Studio) |
| Android SDK (min) | API 33 (Android 13) |
| Android SDK (target) | API 35 (Android 15) |
| Gradle | 8.13 |
| Android Gradle Plugin | 8.13.2 |

## Getting Started

```bash
git clone https://github.com/Cythraul89/ArtworksManager.git
cd ArtworksManager
```

1. Open **Android Studio** → **File → Open** → select the cloned folder
2. Wait for Gradle to sync
3. Click **Run ▶** (or `Shift+F10`) to launch on a connected device or emulator

### Physical device

1. Enable **Developer Options** (tap *Build number* 7 times in **Settings → About phone**)
2. Enable **USB Debugging**
3. Connect via USB, accept the prompt, then select the device in Android Studio and click **Run ▶**

## Building

```bash
# Debug APK
./gradlew assembleDebug
# Output: app/build/outputs/apk/debug/app-debug.apk

# Release APK (requires a signing keystore configured in app/build.gradle)
./gradlew assembleRelease

# Install directly on a connected device
./gradlew installDebug
```

A signed release APK can also be generated from Android Studio via **Build → Generate Signed Bundle / APK**.

## Project Structure

```
app/src/main/
├── java/com/example/artworksmanager/
│   ├── ArtworksManagerApp.kt          Application class (DB + repository singletons)
│   ├── data/                          Room database, DAO, entity, repository
│   ├── ui/
│   │   ├── MainActivity.kt            Single-activity host, Navigation Component
│   │   ├── addedit/                   Add / Edit artwork screen
│   │   ├── collection/                Collection list, search, filter/sort
│   │   ├── dashboard/                 Stats overview + recently added
│   │   ├── detail/                    Artwork detail view
│   │   └── settings/                  PDF export, backup export/import, about
│   └── util/
│       ├── BackupExporter.kt          Zip backup creation
│       ├── BackupImporter.kt          Zip backup restoration
│       └── PdfExporter.kt             PDF generation
└── res/
    ├── layout/                        XML layouts for all screens
    ├── navigation/                    Nav graph (Safe Args)
    ├── values/                        Strings, colours (light), themes
    ├── values-night/                  Dark mode colour overrides
    └── xml/
        └── file_paths.xml             FileProvider path configuration
doc/
├── architecture.md                    Architecture overview and design decisions
├── requirements.md                    Functional and non-functional requirements
└── designs/                           Per-screen wireframes and design system
```

See [`doc/architecture.md`](doc/architecture.md) for a detailed description of the MVVM architecture, data flow, and key design decisions.

## Documentation

| Document | Description |
|----------|-------------|
| [`doc/architecture.md`](doc/architecture.md) | Architecture, tech stack, data flow, design decisions |
| [`doc/class-diagram.md`](doc/class-diagram.md) | Mermaid class diagram of all classes and relationships |
| [`doc/requirements.md`](doc/requirements.md) | Functional and non-functional requirements |
| [`doc/designs/design-system.md`](doc/designs/design-system.md) | Colour palette (light + dark), typography, components |
| [`doc/designs/screen-settings.md`](doc/designs/screen-settings.md) | Settings screen wireframe and backup behaviour |

## License

Copyright (C) 2026 Cythraul89

This program is free software: you can redistribute it and/or modify it under the terms of the **GNU General Public License** as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but **without any warranty**; without even the implied warranty of merchantability or fitness for a particular purpose. See the [GNU General Public License](https://www.gnu.org/licenses/gpl-3.0.html) for more details.
