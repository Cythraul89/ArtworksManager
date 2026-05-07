# Screen: Artwork Detail

## Purpose
Display all recorded information, the cover photo, and additional photos for a single artwork. Entry point for editing or deleting.

## Wireframe

```
┌─────────────────────────────────┐
│  ←                    ✏  🗑    │  ← Top app bar (back, edit, delete)
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────────┐│
│  │                             ││
│  │                             ││
│  │       [ Cover Photo ]       ││  ← Full-width image, 280dp tall, centerCrop
│  │                             ││
│  │                             ││
│  └─────────────────────────────┘│
│                                 │
│  ┌──────┐ ┌──────┐ ┌──────┐    │  ← Additional photos strip (hidden when empty)
│  │  🖼  │ │  🖼  │ │  🖼  │    │    Horizontal scroll, 88×88dp thumbnails
│  └──────┘ └──────┘ └──────┘    │
│                                 │
│  Sunflowers                     │  ← Title (Headline Small)
│  Vincent van Gogh  ·  1888      │  ← Artist · Year (Label, Medium Grey)
│                                 │
│  ─────────────────────────────  │
│                                 │
│  Type                           │  ← Field label (hidden when empty)
│  Painting                       │  ← Field value
│                                 │
│  Medium                         │
│  Oil on canvas                  │
│                                 │
│  Dimensions                     │
│  92.1 × 73 cm                   │
│                                 │
│  Location                       │
│  Living room, north wall        │
│                                 │
│  Acquired                       │
│  12 March 2019  ·  €4,200       │  ← Date · Price (currency per-artwork or global pref)
│                                 │
│  Description                    │
│  One of Van Gogh's most famous  │
│  series, depicting sunflowers   │
│  in a vase...                   │
│                                 │
│  ─────────────────────────────  │
└─────────────────────────────────┘
```

## Behaviour

- **Cover photo** — shown at full width when set; hidden (`GONE`) when no photo exists
- **Additional photos strip** — shown as a horizontal scrollable row of thumbnails immediately below the cover photo; hidden when the artwork has no additional photos; read-only (no remove button)
- **Edit icon (✏)** — navigates to Add / Edit Form pre-filled with this artwork's data
- **Delete icon (🗑)** — shows a confirmation dialog:
  ```
  ┌──────────────────────────────┐
  │  Delete artwork?             │
  │                              │
  │  This will permanently       │
  │  remove "Sunflowers" and     │
  │  cannot be undone.           │
  │                              │
  │  [Cancel]        [Delete]    │
  └──────────────────────────────┘
  ```
  On confirm: artwork and all its photos are deleted (cascade), navigate back to Collection List with snackbar "Artwork deleted"
- **Back arrow** — returns to Collection List preserving scroll position
- **Price currency** — uses the artwork's own `currency` field if set; falls back to the global preference
- Fields with no value entered are hidden (not shown as empty rows)
