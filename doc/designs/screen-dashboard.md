# Screen: Dashboard

## Purpose
Entry point of the app. Gives the user an at-a-glance summary of their collection and a quick way to add a new artwork.

## Wireframe

```
┌─────────────────────────────────┐
│  ≡   My Collection        🔔    │  ← Top app bar
├─────────────────────────────────┤
│                                 │
│  Good morning               │
│  You have 142 artworks          │  ← Headline
│                                 │
│ ┌─────────────────────────────┐ │
│ │  TOTAL ARTWORKS             │ │
│ │                             │ │
│ │           142               │ │  ← Summary card
│ │                             │ │
│ └─────────────────────────────┘ │
│                                 │
│  By Medium                      │  ← Section header
│ ┌──────────┐ ┌──────────┐       │
│ │   Oil    │ │Watercolou│       │
│ │    58    │ │    34    │  ...  │  ← Horizontal scroll chips
│ └──────────┘ └──────────┘       │
│                                 │
│  By Artist                      │  ← Section header
│ ┌─────────────────────────────┐ │
│ │ 🖼  Monet              12  │ │
│ │ 🖼  Picasso             8  │ │  ← Top 5 artists list
│ │ 🖼  Unknown             6  │ │
│ │           See all →        │ │
│ └─────────────────────────────┘ │
│                                 │
│  Recently Added                 │  ← Section header
│ ┌──────┐ ┌──────┐ ┌──────┐      │
│ │  🖼  │ │  🖼  │ │  🖼  │      │  ← Horizontal thumbnail strip
│ │Title │ │Title │ │Title │      │
│ └──────┘ └──────┘ └──────┘      │
│                                 │
│                   ┌───────────┐ │
│                   │+ Add Art  │ │  ← Extended FAB (Warm Gold)
│                   └───────────┘ │
├──────────┬──────────┬───────────┤
│ Dashboard│Collection│ Settings  │  ← Bottom nav
└──────────┴──────────┴───────────┘
```

## Behaviour

- **Total artworks card** — tapping navigates to the Collection List
- **By Medium chips** — tapping a chip navigates to Collection List pre-filtered by that medium
- **By Artist list** — tapping an artist row navigates to Collection List pre-filtered by that artist; "See all" opens a full artist breakdown sheet
- **Recently Added strip** — tapping a thumbnail opens the Artwork Detail
- **FAB "+ Add Artwork"** — navigates to the Add / Edit Form
