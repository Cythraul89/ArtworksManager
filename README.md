# ArtworksManager

A personal artwork catalogue app for Android. Record, browse, and manage a private art collection of up to 1,000 artworks — fully offline, no account required.

## Features

- **Add / Edit / Delete** artworks with title, artist, year, type, medium, dimensions, location, acquisition date, purchase price, photos, and notes
- **Per-artwork currency** — each artwork stores its own currency (EUR, USD, NOK, ZAR); falls back to the global preference when not set
- **Multiple photos** — attach a cover photo plus any number of additional photos to each artwork
- **Browse** the collection in grid or list view with real-time search, filter by medium, and sort by title, artist, or date
- **Dashboard** with total count, breakdown by medium and artist, recently-added strip, and a **Collection Value card** showing per-currency subtotals and a live grand total converted via the Frankfurter API (offline fallback: per-currency subtotals only)
- **Export PDF** — one A4 page per artwork, photos orientation-corrected via EXIF
- **Export backup** — saves a zip containing `artworks.json` (human-readable, including additional photos) and all artwork photos to any location via the Android Storage Access Framework
- **Import backup** — restores a collection (artworks + additional photos) from a previously exported zip
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
│   ├── data/
│   │   ├── Artwork.kt                 Main artwork entity
│   │   ├── ArtworkPhoto.kt            Additional photos entity (one-to-many)
│   │   ├── ArtworkDao.kt              Room DAO
│   │   ├── ArtworkDatabase.kt         Room database (v3)
│   │   ├── ArtworkRepository.kt       Single source of truth
│   │   ├── AppPreferences.kt          SharedPreferences wrapper + reactive currencyFlow
│   │   └── Currency.kt                Enum: EUR / USD / NOK / ZAR
│   ├── ui/
│   │   ├── MainActivity.kt            Single-activity host, Navigation Component
│   │   ├── addedit/
│   │   │   ├── AddEditFragment.kt     Add / Edit form + photo management
│   │   │   ├── AddEditViewModel.kt    Save logic + additional-photo diff
│   │   │   └── AdditionalPhotoAdapter.kt  Horizontal photo strip adapter
│   │   ├── collection/                Collection list, search, filter/sort
│   │   ├── dashboard/                 Stats overview + collection value card
│   │   ├── detail/                    Artwork detail view + photo strip
│   │   └── settings/                  PDF export, backup export/import, about
│   └── util/
│       ├── BackupExporter.kt          Zip backup creation (artworks + photos)
│       ├── BackupImporter.kt          Zip backup restoration → BackupData
│       ├── ExchangeRateService.kt     Live currency rates via Frankfurter API
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
├── class-diagram.md                   Mermaid class diagram of all classes
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
