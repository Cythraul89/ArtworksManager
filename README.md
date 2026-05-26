# ArtworksManager (AWoMa)

A cross-platform personal artwork catalogue — Android, iOS, macOS, Linux, and Windows. Record, browse, and manage a private art collection fully offline; no account required.

## Features

- **Add / Edit / Delete** artworks with title, artist, year, type, medium, dimensions, location, acquisition date, purchase price, photos, and notes
- **Multiple photos** — cover photo plus any number of additional photos; tap any photo to open a full-screen viewer with pinch-to-zoom and swipe between photos
- **Browse** the collection in grid or list view with real-time search, filter by medium / condition, and sort by title, artist, date, or price
- **Dashboard** with total count, breakdown by medium and artist, recently-added strip, and a **Collection Value** card showing per-currency subtotals converted to a single total via the [Frankfurter API](https://www.frankfurter.app) (offline fallback: per-currency subtotals only)
- **Default currency** — 21 supported currencies (EUR, USD, GBP, JPY, CHF, CAD, AUD, BRL, CZK, DKK, HKD, HUF, INR, KRW, MXN, NOK, NZD, PLN, SEK, SGD, ZAR)
- **Export PDF** — one A4 page per artwork, photos EXIF-corrected, rendered with Noto Sans for cross-platform consistency
- **Local backup** — saves a ZIP containing `artworks.json` and all photos; restore from any previously saved ZIP
- **Nextcloud backup** — connect via app password; supports custom self-signed certificates via SHA-256 fingerprint pinning; configurable auto-sync interval; startup prompt when a newer remote backup is detected
- **Theme** — system, light, or dark
- **App logs** — viewable and exportable diagnostic log (Settings → App logs)

## Requirements

| Concern | Requirement |
|---------|-------------|
| Flutter SDK | stable channel (≥ 3.44) |
| Dart SDK | ≥ 3.3 |
| Android | JDK 17, Android SDK API 33+ |
| iOS / macOS | Xcode (latest stable) |
| Linux | `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libsecret-1-dev libjsoncpp-dev` |
| Windows | Visual Studio 2022 with the *Desktop development with C++* workload |

## Getting Started

```bash
git clone https://github.com/Cythraul89/ArtworksManager.git
cd ArtworksManager/flutter_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Building

```bash
flutter build apk --release          # Android
flutter build ios --no-codesign      # iOS (simulator / ad-hoc)
flutter build macos --release        # macOS
flutter build linux --release        # Linux
flutter build windows --release      # Windows
```

## Testing

```bash
flutter test                         # unit & widget tests
flutter analyze --no-fatal-infos     # static analysis (local SDK)
```

> **Note:** Five analyzer hints for `RadioGroup` and `DropdownButtonFormField.initialValue` appear with the local Flutter 3.32.x SDK but are valid on CI (Flutter 3.44+). Do not suppress them.

## CI / Release

GitHub Actions workflows live in `.github/workflows/`:

| Workflow | Trigger | Jobs |
|----------|---------|------|
| `flutter_ci.yml` | Push to `main`, `develop`, `feature/**`; PR to `main` | Analyze & Test → build all platforms + SBOM |
| `flutter_release.yml` | Push tag `v*.*.*` | Build all platforms + SBOM → GitHub Release with all artifacts attached |

A **CycloneDX SBOM** (`awoma-sbom.cdx.json`) is generated on every CI run and attached to every release.

To publish a release:
```bash
git tag v1.0.0 && git push origin v1.0.0
```

## Documentation

| Document | Description |
|----------|-------------|
| [`doc/flutter-architecture.md`](doc/flutter-architecture.md) | Tech stack, data flow, provider conventions, navigation |
| [`doc/flutter-class-diagram.md`](doc/flutter-class-diagram.md) | Mermaid class diagram of database, DAOs, and services |
| [`doc/requirements.md`](doc/requirements.md) | Functional and non-functional requirements |
| [`doc/designs/design-system.md`](doc/designs/design-system.md) | Colour palette (light + dark), typography |
| [`doc/designs/navigation.md`](doc/designs/navigation.md) | Navigation structure and screen map |
| [`doc/designs/screen-dashboard.md`](doc/designs/screen-dashboard.md) | Dashboard wireframe |
| [`doc/designs/screen-collection-list.md`](doc/designs/screen-collection-list.md) | Collection list wireframe |
| [`doc/designs/screen-add-edit.md`](doc/designs/screen-add-edit.md) | Add / Edit form wireframe |
| [`doc/designs/screen-artwork-detail.md`](doc/designs/screen-artwork-detail.md) | Artwork detail wireframe |
| [`doc/designs/screen-settings.md`](doc/designs/screen-settings.md) | Settings wireframe |

## License

Copyright (C) 2026 Cythraul89

This program is free software: you can redistribute it and/or modify it under the terms of the **GNU General Public License** as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but **without any warranty**; without even the implied warranty of merchantability or fitness for a particular purpose. See the [GNU General Public License](https://www.gnu.org/licenses/gpl-3.0.html) for more details.
