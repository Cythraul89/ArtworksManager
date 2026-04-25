# Screen: Settings

## Purpose
Access app-level actions: exporting the collection as PDF and configuring optional Nextcloud backup.

## Wireframe

```
┌─────────────────────────────────┐
│  Settings                       │  ← Top app bar (no back arrow — top-level)
├─────────────────────────────────┤
│                                 │
│  EXPORT                         │  ← Section header
│ ┌─────────────────────────────┐ │
│ │ 📄  Export collection       │ │  ← Tapping opens export options sheet
│ │     Generate a PDF of all   │ │
│ │     artworks                │ │
│ └─────────────────────────────┘ │
│                                 │
│  BACKUP                         │
│ ┌─────────────────────────────┐ │
│ │ ☁  Nextcloud backup   OFF ▸│ │  ← Toggle row; navigates to Nextcloud config
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ ↑  Back up now              │ │  ← Enabled only when Nextcloud is configured
│ │    Last backup: never       │ │
│ └─────────────────────────────┘ │
│                                 │
│  ABOUT                          │
│ ┌─────────────────────────────┐ │
│ │     App version: 1.0.0      │ │
│ └─────────────────────────────┘ │
│                                 │
├──────────────┬──────────┬───────┤
│  Dashboard   │Collection│Settings│
└──────────────┴──────────┴───────┘
```

## Export Options Bottom Sheet

```
┌─────────────────────────────────┐
│  Export as PDF             ✕    │
│─────────────────────────────────│
│  Include                        │
│  ☑ All artworks                 │
│  ☑ Artwork photos               │
│  ☑ Prices                       │
│                                 │
│  Layout                         │
│  ● One artwork per page         │
│  ○ Compact list                 │
│                                 │
│  ┌─────────────────────────────┐│
│  │      GENERATE PDF           ││
│  └─────────────────────────────┘│
└─────────────────────────────────┘
```
After generation: system share sheet (save to files, print, share via email, etc.)

## Nextcloud Configuration Screen

```
┌─────────────────────────────────┐
│  ←   Nextcloud Backup           │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────────┐│
│  │ Server URL                  ││  e.g. https://cloud.example.com
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ Username                    ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ App password          👁    ││  ← Use a Nextcloud app password, not account password
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │      TEST CONNECTION        ││  ← Secondary button
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │         SAVE                ││  ← Enabled after successful connection test
│  └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```
