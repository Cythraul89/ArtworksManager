# Screen: Artwork Detail

## Purpose
Display all recorded information and the photo for a single artwork. Entry point for editing or deleting.

## Wireframe

```
┌─────────────────────────────────┐
│  ←                    ✏  🗑    │  ← Top app bar (back, edit, delete)
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────────┐│
│  │                             ││
│  │                             ││
│  │          [ Photo ]          ││  ← Full-width image (16:9), tap to full-screen
│  │                             ││
│  │                             ││
│  └─────────────────────────────┘│
│                                 │
│  Sunflowers                     │  ← Title (Headline Small)
│  Vincent van Gogh  ·  1888      │  ← Artist · Year (Label, Medium Grey)
│                                 │
│  ─────────────────────────────  │
│                                 │
│  Medium                         │  ← Field label
│  Oil on canvas                  │  ← Field value
│                                 │
│  Dimensions                     │
│  92.1 × 73 cm                   │
│                                 │
│  Location                       │
│  Living room, north wall         │
│                                 │
│  Acquired                       │
│  12 March 2019  ·  €4,200       │  ← Date · Price
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

- **Photo** — tapping opens a full-screen image viewer with pinch-to-zoom; swipe down to dismiss
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
  On confirm: delete artwork + photo, navigate back to Collection List with a snackbar "Artwork deleted"
- **Back arrow** — returns to Collection List preserving scroll position
- Fields with no value entered are hidden (not shown as empty rows)
