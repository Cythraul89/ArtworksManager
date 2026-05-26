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
│ │ 💾  Export backup           │ │  ← Opens native save dialog (FilePicker.saveFile)
│ │     Save database and       │ │    Default filename: artworks_YYYYMMDD_HHmmss.zip
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
│ │  Version            0.2.0+1 │ │
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
│  Default currency                │
│                                  │
│  ✓ Euro (€)                      │
│    US Dollar ($)                 │
│    Pound Sterling (£)            │
│    Japanese Yen (¥)              │
│    Swiss Franc (CHF)             │
│    … (21 currencies total)       │
│                                  │
└──────────────────────────────────┘
```

All 21 currencies: EUR, USD, GBP, JPY, CHF, CAD, AUD, BRL, CZK, DKK, HKD, HUF, INR, KRW, MXN, NOK, NZD, PLN, SEK, SGD, ZAR.

The selection is saved to the app database (Settings table) immediately and reflected in:
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

Tapping **Export backup** opens the native save dialog (`FilePicker.saveFile`) with the suggested filename `artworks_YYYYMMDD_HHmmss.zip`. After the user selects a save location the zip is written containing:

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

Tapping **Import backup** opens the native file picker filtered to ZIP files. After the user selects a file a confirmation dialog is shown:

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
3. The entire current collection (artworks + photos) is atomically replaced in one Drift transaction
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
│     Automatic backup to         │
│     AWoMa/ on your Nextcloud    │
│     server via WebDAV           │
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
│  ┌─────────────────────────────┐│
│  │ SHA-256 fingerprint (opt.)  ││  ← Leave empty for system-trusted CAs;
│  └─────────────────────────────┘│    paste fingerprint to pin a specific cert
│                                 │
│  ┌─────────────────────────────┐│  ← Status card (hidden when Idle)
│  │ ✓  Connected as alice       ││    Green icon + primary text when Connected
│  │    https://cloud.example.com││    Red icon + red text on Error
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │     TEST CONNECTION         ││  ← Fetches cert info; shows trust dialog
│  └─────────────────────────────┘│    if cert is untrusted; runs verifyCredentials()
│                                 │
│  ┌─────────────────────────────┐│
│  │     CONFIRM & CONNECT       ││  ← Enabled only after successful test;
│  └─────────────────────────────┘│    saves settings; checks for remote backup;
│                                 │    shows sync-choice dialog; closes screen
│  ┌─────────────────────────────┐│
│  │    BACKUP TO NEXTCLOUD NOW  ││  ← Immediate upload; available when configured
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │    RESTORE FROM CLOUD       ││  ← Download latest backup from server
│  └─────────────────────────────┘│
│                                 │
│  Last backup: 06 May 2026,      │  ← Shown when lastSyncAt is set
│  14:32                          │
│                                 │
└─────────────────────────────────┘
```

### Test connection behaviour
1. User fills in server URL, username, app password, and optionally a SHA-256 fingerprint for cert pinning
2. Tapping **Test connection** calls `NextcloudService.fetchCertificateInfo()` to inspect the server cert
3. If the cert is not OS-trusted and no fingerprint is set, a dialog shows subject / issuer / valid-until / fingerprint with **Trust & pin** / **Reject** options
4. After cert handling, `NextcloudService.verifyCredentials()` is called (WebDAV PROPFIND with Basic auth)
5. On success: `_connectionVerified = true`; the **Confirm & connect** button becomes active
6. On failure: error message shown beneath the button

### Confirm & connect behaviour
1. Saves server URL, username, remote path, cert fingerprint, and auto-sync settings to the Drift Settings table; password to `flutter_secure_storage`
2. Calls `NextcloudService.findLatestBackup()` to check for an existing remote backup
3. If a backup is found: shows a sync-choice dialog ("Restore from server" / "Upload current" / "Later")
4. Executes the chosen action, then closes the screen

### Back up now behaviour
Immediately exports a ZIP via `BackupService.exportToZip()`, uploads via `NextcloudService.uploadBackup()`, prunes old files via `listFiles()` / `deleteFile()`, and saves `lastSyncAt` on success or `lastSyncError` on failure to the Settings table. A progress indicator is shown while the operation runs.

### Restore from cloud behaviour
Downloads the latest backup via `NextcloudService.downloadFile()`, then calls `BackupService.importFromBytes()` and `ArtworksDao.replaceAll()` in a Drift transaction. Saves `lastSyncAt` on success.
