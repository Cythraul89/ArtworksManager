# Screen: Settings

## Purpose
Access app-level preferences (currency), export the collection as PDF, export and import a full zip backup, configure Nextcloud automatic backup, and view app information.

## Wireframe

```
┌─────────────────────────────────┐
│  Settings                       │  ← Top app bar (no back arrow — top-level)
├─────────────────────────────────┤
│                                 │
│  PREFERENCES                    │  ← Section header
│ ┌─────────────────────────────┐ │
│ │ 💱  Currency      Euro (€) ▸│ │  ← Tapping opens single-choice dialog
│ │     Used for purchase prices│ │
│ └─────────────────────────────┘ │
│                                 │
│  EXPORT                         │  ← Section header
│ ┌─────────────────────────────┐ │
│ │ 📄  Export collection       │ │  ← Generates PDF immediately; opens share sheet
│ │     Generate a PDF of all   │ │    Progress spinner replaces icon while generating
│ │     artworks                │ │
│ └─────────────────────────────┘ │
│                                 │
│  BACKUP                         │  ← Section header
│ ┌─────────────────────────────┐ │
│ │ 💾  Export backup           │ │  ← Opens SAF "Create document" file picker
│ │     Save database and       │ │    Default filename: artworks_backup_YYYYMMDD_HHmmss.zip
│ │     photos as a zip file    │ │    Progress spinner while writing
│ ├─────────────────────────────┤ │
│ │ ⬇   Import backup           │ │  ← Opens SAF "Open document" file picker (zip only)
│ │     Restore collection      │ │    Progress spinner while reading
│ │     from a zip backup       │ │
│ ├─────────────────────────────┤ │
│ │ ☁   Nextcloud backup      ›│ │  ← Navigates to Nextcloud sub-screen
│ │     Not connected           │ │    Status: "Connected" or "Not connected"
│ └─────────────────────────────┘ │
│                                 │
│  ABOUT                          │  ← Section header
│ ┌─────────────────────────────┐ │
│ │  Version              0.0.3 │ │
│ ├─────────────────────────────┤ │
│ │  License   GNU General      │ │
│ │            Public License   │ │
│ │            v3.0 (GPL-3.0)   │ │
│ └─────────────────────────────┘ │
│                                 │
├──────────────┬──────────┬───────┤
│  Dashboard   │Collection│Settings│
└──────────────┴──────────┴───────┘
```

## Currency Selection Behaviour

Tapping **Currency** opens a single-choice dialog listing all supported currencies:

```
┌──────────────────────────────────┐
│  Select currency                 │
│                                  │
│  ● Euro (€)                      │
│  ○ US Dollar ($)                 │
│  ○ Norwegian Krone (kr)          │
│  ○ South African Rand (R)        │
│                                  │
└──────────────────────────────────┘
```

The selection is saved to SharedPreferences immediately and reflected in:
- The currency row label in Settings
- The default currency dropdown in Add / Edit Artwork (for new artworks)
- The price display in Artwork Detail (when no per-artwork currency is set)
- The price field in PDF exports
- The grand total currency in the Dashboard Collection Value card

Adding a new currency requires only a new entry in the `Currency` enum — no other code changes.

Note: individual artworks can store their own currency override; the global preference is the default.

## Export PDF Behaviour

Tapping **Export collection** immediately starts generating the PDF (no options sheet):
- Each artwork renders on its own A4 page: photo (EXIF orientation-corrected), title, artist/year, then all non-empty fields; price is shown with the artwork's own currency symbol (or the global preference when not set)
- A progress spinner is shown in the row while generating
- On completion the system share sheet opens (save to Files, print, share via email, etc.)
- If the collection is empty a toast "No artworks to export" is shown instead

## Export Backup Behaviour

Tapping **Export backup** opens the Android Storage Access Framework *Create Document* picker with the suggested filename `artworks_backup_YYYYMMDD_HHmmss.zip`. After the user selects a save location the zip is written containing:

```
artworks.json       ← all artwork records as pretty-printed JSON
photos/             ← every artwork photo (cover + additional)
  <filename>.jpg
  ...
```

`artworks.json` structure:
```json
{
  "exportedAt": "2026-04-26T14:30:00",
  "count": 2,
  "artworks": [
    {
      "id": 1,
      "title": "Sunflowers",
      "artist": "Van Gogh",
      "year": 1888,
      "type": "Painting",
      "medium": "Oil",
      "heightCm": 92.1,
      "widthCm": 73.0,
      "location": "Living room",
      "acquisitionDate": "2024-03-15",
      "currency": "EUR",
      "purchasePrice": 1500.0,
      "description": "Replica",
      "photo": "1714123456789.jpg",
      "createdAt": "2026-01-10T09:00:00",
      "additionalPhotos": [
        { "photo": "1714123500000.jpg", "sortOrder": 0 },
        { "photo": "1714123560000.jpg", "sortOrder": 1 }
      ]
    }
  ]
}
```

A success toast is shown on completion; an error toast on failure.

## Import Backup Behaviour

Tapping **Import backup** opens the SAF *Open Document* picker filtered to `application/zip`. After the user selects a file a confirmation dialog is shown:

```
┌──────────────────────────────────┐
│  Replace collection?             │
│                                  │
│  This will permanently replace   │
│  all current artworks and photos │
│  with the contents of the        │
│  backup. This cannot be undone.  │
│                                  │
│  [Cancel]           [Replace]    │
└──────────────────────────────────┘
```

On **Replace**:
1. Photos are extracted from `photos/` in the zip to the app's internal storage
2. `artworks.json` is parsed; artworks and their additional photos are reconstructed with correct local photo paths
3. The entire current collection (artworks + photos) is atomically replaced in one Room transaction
4. A toast shows `"Imported N artworks"` on success, or an error toast on failure

## Nextcloud Row Behaviour

The Nextcloud row in the BACKUP section shows:
- **Not connected** — when no credentials are saved
- **Connected** — when all three credential fields (server URL, username, app password) are saved

Tapping the row always navigates to the Nextcloud settings sub-screen. The status label is refreshed in `onResume` so it reflects changes made on the sub-screen when the user navigates back.

## Nextcloud Sub-Screen

```
┌─────────────────────────────────┐
│  ←   Nextcloud backup           │  ← Toolbar with back arrow
├─────────────────────────────────┤
│                                 │
│  ☁  Nextcloud backup            │  ← Header
│     Daily automatic backup to   │
│     ArtworksManager/artworks_   │
│     backup.zip                  │
│                                 │
│  ┌─────────────────────────────┐│
│  │ Server URL                  ││  ← e.g. https://cloud.example.com
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ Username                    ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ App password            👁  ││  ← Password toggle
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ ℹ  Use an app-specific      ││  ← Info card
│  │    password, not your        ││
│  │    account password...       ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│  ← Status card (hidden when Idle)
│  │ ✓  Connected as alice       ││    Green icon + primary text when Connected
│  │    https://cloud.example.com││    Red icon + red text on Error
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │         CONNECT             ││  ← Filled button (hidden when Connected)
│  └─────────────────────────────┘│    Spinner overlay while Testing
│                                 │
│  ┌─────────────────────────────┐│
│  │         DISCONNECT          ││  ← Outlined button (hidden when not Connected)
│  └─────────────────────────────┘│
│                                 │
│  ─────────────────────────────  │  ← Divider (hidden when not Connected)
│                                 │
│  ┌─────────────────────────────┐│
│  │       BACK UP NOW           ││  ← Tonal button (hidden when not Connected)
│  └─────────────────────────────┘│
│                                 │
│  Last backup: 06 May 2026,      │  ← Caption (hidden when not Connected)
│  14:32                          │    "Never backed up" before first upload
│                                 │
└─────────────────────────────────┘
```

### Connect behaviour
1. User fills in server URL, username, and app password
2. Tapping **Connect** calls `NextcloudClient.testConnection()` on a background thread (OCS API GET `/ocs/v2.php/cloud/user` with Basic auth)
3. A spinner is shown over the Connect button while testing
4. On HTTP 200: credentials saved to `NextcloudPreferences`; a daily `PeriodicWorkRequest` is registered in WorkManager; screen transitions to Connected state
5. On failure: error message shown in the status card (e.g. "Invalid username or app password", "Connection timed out")

### Disconnect behaviour
Credentials are cleared from `NextcloudPreferences` and the scheduled WorkManager job is cancelled.

### Back up now behaviour
Enqueues a `OneTimeWorkRequest` for `NextcloudBackupWorker`. The worker runs as soon as a network connection is available. A snackbar "Backup queued" is shown immediately. The "Last backup" label updates to the new timestamp the next time the fragment is visible (the worker stores the result in `NextcloudPreferences.lastBackupTime`).
