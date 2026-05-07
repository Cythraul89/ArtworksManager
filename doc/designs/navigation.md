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
| Settings     | `settings`    | Export PDF, backup export/import, Nextcloud backup, about |

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


┌──────────────────┐
│     Settings     │
│──────────────────│
│ Export PDF       │──▶ system share sheet
│ Export backup    │──▶ SAF "Create Document" picker → writes zip
│ Import backup    │──▶ SAF "Open Document" picker → confirm dialog → restore
│ Nextcloud backup │──▶ NextcloudFragment (full-screen, back arrow)
└──────────────────┘
         │
         ▼
┌──────────────────────┐
│  Nextcloud Settings  │
│──────────────────────│
│ Server URL           │
│ Username             │
│ App password         │──▶ test credentials (OCS API) → save → schedule worker
│ [Connect]            │
│ [Disconnect]         │──▶ clear credentials → cancel WorkManager job
│ [Back up now]        │──▶ enqueue OneTimeWorkRequest
└──────────────────────┘
```

---

## Navigation Behaviour

- **Back stack:** each tab maintains its own back stack; switching tabs preserves scroll position
- **Add / Edit Form:** opened as a full-screen destination (no bottom nav visible)
- **Artwork Detail:** opened as a full-screen destination (no bottom nav visible)
- **Delete:** triggered from Artwork Detail via a confirmation dialog; on confirm, pops back to Collection List
- **Search:** inline in the Collection List toolbar (expands the search bar, no separate screen)
- **Filter / Sort:** bottom sheet opened from Collection List toolbar
- **Nextcloud Settings:** full-screen destination pushed from Settings; `findNavController().popBackStack()` on back arrow; bottom nav hidden
