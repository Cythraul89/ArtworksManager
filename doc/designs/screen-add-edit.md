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
│  │     Tap to add photo        ││  ← Photo picker (full-width, dashed border)
│  │     📷  or  🖼              ││     Icons: Camera | Gallery
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
│  │ Medium / Technique    ▾     ││  ← Dropdown (Oil, Watercolour, Sculpture,
│  └─────────────────────────────┘│     Print, Drawing, Digital, Other)
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
│  ┌─────────────────────────────┐│
│  │ Purchase price (€)          ││
│  └─────────────────────────────┘│
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

- **Photo picker area**
  - Tapping shows a bottom sheet: "Take photo" / "Choose from gallery"
  - Once a photo is selected it fills the area with a preview; a small ✕ in the corner removes it
- **Title** — required; form cannot be saved without it; shows inline error "Title is required" on empty submit
- **Medium dropdown** — predefined list with "Other" as fallback (free-text field appears when "Other" is selected)
- **Acquisition date** — opens the Material date picker dialog
- **Purchase price** — numeric keyboard; currency symbol (€) shown as prefix
- **SAVE ARTWORK**
  - Validates required fields; scrolls to first error if invalid
  - On success: saves to local database, navigates to Artwork Detail of the saved artwork, shows snackbar "Artwork saved"
- **Back / discard** — if any field has been changed, shows a confirmation dialog:
  ```
  ┌──────────────────────────────┐
  │  Discard changes?            │
  │                              │
  │  [Keep editing]  [Discard]   │
  └──────────────────────────────┘
  ```
