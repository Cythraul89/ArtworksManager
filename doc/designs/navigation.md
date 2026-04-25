# Navigation Flow

## Structure

The app uses a **bottom navigation bar** with three top-level destinations:

```
┌─────────────────────────────────────┐
│                                     │
│           Screen Content            │
│                                     │
├──────────────┬──────────┬───────────┤
│  Dashboard   │Collection│  Settings │
└──────────────┴──────────┴───────────┘
```

| Tab          | Icon          | Description                        |
|--------------|---------------|------------------------------------|
| Dashboard    | `dashboard`   | Stats overview + quick add         |
| Collection   | `collections` | Browse, search, filter artworks    |
| Settings     | `settings`    | Export PDF, Nextcloud backup, prefs|

---

## Screen Map

```
                    ┌─────────────┐
                    │  Dashboard  │
                    └──────┬──────┘
                           │ tap FAB "+ Add Artwork"
                           ▼
┌─────────────┐     ┌─────────────────┐
│  Collection │────▶│ Add / Edit Form │
│    List     │     └─────────────────┘
└──────┬──────┘           ▲
       │ tap artwork       │ tap Edit
       ▼                   │
┌─────────────────┐        │
│ Artwork Detail  │────────┘
└─────────────────┘
       │ tap Delete
       ▼
  Confirm dialog → back to Collection List


┌─────────────┐
│  Settings   │
│─────────────│
│ Export PDF  │──▶ system share / save dialog
│ Nextcloud   │──▶ Nextcloud config screen
└─────────────┘
```

---

## Navigation Behaviour

- **Back stack:** each tab maintains its own back stack; switching tabs preserves scroll position
- **Add / Edit Form:** opened as a full-screen destination (no bottom nav visible)
- **Artwork Detail:** opened as a full-screen destination (no bottom nav visible)
- **Delete:** triggered from Artwork Detail via a confirmation dialog; on confirm, pops back to Collection List
- **Search:** inline in the Collection List toolbar (expands the search bar, no separate screen)
- **Filter / Sort:** bottom sheet opened from Collection List toolbar
