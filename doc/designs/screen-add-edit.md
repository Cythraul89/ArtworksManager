# Screen: Add / Edit Artwork

## Purpose
Form for creating a new artwork record or editing an existing one. Opened from the FAB (add) or the edit icon on the Artwork Detail screen (edit).

## Wireframe

```
┌─────────────────────────────────┐
│  ←   Add Artwork                │  ← "Edit Artwork" when editing
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────────┐│
│  │                             ││
│  │     Tap to add photo        ││  ← Cover photo picker (full-width card)
│  │         📷                  ││     Tap → "Take photo" / "Gallery or cloud storage"
│  │                             ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ Title *                     ││  ← Required field
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ Artist name                 ││
│  └─────────────────────────────┘│
│                                 │
│  ┌───────────────┐              │
│  │ Year          │              │  ← Numeric input
│  └───────────────┘              │
│                                 │
│  ┌─────────────────────────────┐│
│  │ Type                  ▾     ││  ← Dropdown (Painting, Drawing, Photography,
│  └─────────────────────────────┘│     Sculpture, Print, Book, Textile, Ceramics, Other)
│                                 │
│  ┌─────────────────────────────┐│
│  │ Medium / Technique    ▾     ││  ← Dropdown (Oil, Watercolour, Acrylic, …, Book, Other)
│  └─────────────────────────────┘│
│                                 │
│  Dimensions                     │  ← Section label
│  ┌──────────┐ ┌──────────┐      │
│  │ Height   │ │ Width    │  cm  │
│  └──────────┘ └──────────┘      │
│  ┌──────────┐                   │
│  │ Depth    │  (optional)       │
│  └──────────┘                   │
│                                 │
│  ┌─────────────────────────────┐│
│  │ Location                    ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ Acquisition date      📅   ││  ← Date picker
│  └─────────────────────────────┘│
│                                 │
│  ┌──────────┐ ┌────────────────┐│
│  │Currency ▾│ │ Purchase price ││  ← Currency dropdown + price field side by side
│  │  EUR     │ │  € 1,200.00   ││     Prefix symbol updates on currency change
│  └──────────┘ └────────────────┘│
│                                 │
│  Additional Photos              │  ← Section label
│  ┌──────┐ ┌──────┐ ┌──────┐    │
│  │ 🖼 ×│ │ 🖼 ×│ │ 🖼 ×│   │  ← Horizontal strip; × badge removes photo
│  └──────┘ └──────┘ └──────┘    │
│  [ + Add more photos ]          │  ← Outlined button
│                                 │
│  Certificate                    │  ← Section label
│  [ Attach certificate (PDF) ]   │  ← Outlined button; hidden once a cert is attached
│                                 │
│  cert_1714123456789.pdf  Remove │  ← Filename + text button; hidden when no cert
│                                 │
│  ┌─────────────────────────────┐│
│  │ Description / Notes         ││
│  │                             ││  ← Multi-line, 4 rows min
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │         SAVE ARTWORK        ││  ← Primary button (Deep Indigo)
│  └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

## Behaviour

- **Cover photo picker**
  - Tapping shows a dialog: "Take photo" / "Gallery or cloud storage"
  - "Gallery or cloud storage" opens the Android Storage Access Framework document picker (`GetContent("image/*")`), which includes the device gallery and all installed cloud document providers (Google Drive, Dropbox, OneDrive, Nextcloud app, etc.) — no extra configuration needed
  - Once a photo is selected it fills the card with a preview
  - Camera photos are saved directly to `filesDir/artworks/`; picked images are copied there from their source URI
- **Type dropdown** — selects from the predefined list; stored as a string on the artwork record
- **Medium dropdown** — predefined list; includes Book among other media
- **Currency dropdown** — shows all supported currencies (EUR, USD, NOK, ZAR); defaults to the global preference on new artwork; updates the price field prefix symbol immediately; stored per-artwork
- **Additional photos**
  - Tapping "Add more photos" opens the same "Take photo" / "Gallery or cloud storage" dialog as the cover
  - Each photo appears as an 88×88dp thumbnail with a × badge in the horizontal strip
  - Tapping × queues the photo for deletion; it is removed from the database on save
  - When editing, existing DB photos are pre-loaded into the strip; only newly added ones are inserted on save
- **Certificate**
  - Tapping "Attach certificate (PDF)" opens the SAF document picker filtered to `application/pdf`, giving access to local files and all installed cloud document providers
  - The selected PDF is copied to `filesDir/artworks/cert_<timestamp>.pdf`; the filename is shown with a "Remove" button
  - Tapping "Remove" clears the certificate without deleting the copied file
  - When editing an artwork that already has a certificate, the filename is restored and the attach button is hidden
  - The certificate path is saved with the artwork record on SAVE ARTWORK
- **Title** — required; shows inline error "Title is required" on empty submit; form scrolls to top
- **Acquisition date** — opens the Material date picker dialog
- **SAVE ARTWORK**
  - Validates required fields; scrolls to the first error if invalid
  - On success: saves artwork, applies photo diff (deletes removed, inserts new), navigates to Artwork Detail, shows snackbar "Artwork saved"
- **Back / discard** — if title or artist has been entered, shows a confirmation dialog:
  ```
  ┌──────────────────────────────┐
  │  Discard changes?            │
  │                              │
  │  [Keep editing]  [Discard]   │
  └──────────────────────────────┘
  ```
