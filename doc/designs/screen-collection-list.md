# Screen: Collection List

## Purpose
Browse the full catalogue. Supports switching between grid and list view, inline search, and a filter/sort bottom sheet.

## Wireframe — Grid View (default)

```
┌─────────────────────────────────┐
│  🔍 Search artworks...    ☰ ⊞  │  ← Search bar + filter + view toggle
├─────────────────────────────────┤
│ [Oil ×] [Monet ×]               │  ← Active filter chips (visible when filters applied)
├────────────────┬────────────────┤
│                │                │
│    [  🖼  ]    │    [  🖼  ]    │
│  Sunflowers    │  Water Lilies  │  ← Grid cards (2 columns)
│  Van Gogh      │  Monet         │
│                │                │
├────────────────┼────────────────┤
│                │                │
│    [  🖼  ]    │    [  🖼  ]    │
│  The Scream    │  Starry Night  │
│  Munch         │  Van Gogh      │
│                │                │
├────────────────┴────────────────┤
│           (scroll...)           │
│                        ╋        │  ← FAB icon-only (Warm Gold)
├──────────────┬──────────┬───────┤
│  Dashboard   │Collection│Settings│
└──────────────┴──────────┴───────┘
```

## Wireframe — List View

```
┌─────────────────────────────────┐
│  🔍 Search artworks...    ☰ ☰  │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ [🖼] Sunflowers          › │ │
│ │      Van Gogh · 1888        │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ [🖼] Water Lilies        › │ │
│ │      Monet · 1906           │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ [🖼] The Scream           › │ │
│ │      Munch · 1893           │ │
│ └─────────────────────────────┘ │
│           (scroll...)           │
│                        ╋        │
├──────────────┬──────────┬───────┤
│  Dashboard   │Collection│Settings│
└──────────────┴──────────┴───────┘
```

## Filter / Sort Bottom Sheet

```
┌─────────────────────────────────┐
│  Filter & Sort            ✕     │
│─────────────────────────────────│
│  Sort by                        │
│  ○ Title (A–Z)   ● Artist  ○ Date│
│                                 │
│  Medium                         │
│  ☑ Oil   ☑ Watercolour          │
│  ☐ Sculpture  ☐ Print  ☐ Other  │
│                                 │
│  Year range                     │
│  [1800] ──────────────── [2024] │
│                                 │
│  ┌──────────┐  ┌──────────────┐ │
│  │  Reset   │  │  Apply       │ │
│  └──────────┘  └──────────────┘ │
└─────────────────────────────────┘
```

## Behaviour

- **Search bar** — filters list in real time as the user types (searches title and artist)
- **Filter icon (☰)** — opens the Filter / Sort bottom sheet
- **View toggle (⊞ / ☰)** — switches between 2-column grid and single-column list; preference persisted
- **Active filter chips** — shown below the search bar when filters are active; tapping the × removes that filter
- **Empty state** — when no artworks match, show an illustration and "No artworks found. Try adjusting your filters."
- **FAB** — navigates to Add / Edit Form
