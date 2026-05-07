# Screen: Dashboard

## Purpose
Entry point of the app. Gives the user an at-a-glance summary of their collection and a quick way to add a new artwork.

## Wireframe

```
┌─────────────────────────────────┐
│  ≡   My Collection        🔔    │  ← Top app bar
├─────────────────────────────────┤
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
│  Collection Value               │  ← Section header
│ ┌─────────────────────────────┐ │
│ │  Oil (EUR)      € 12,400   │ │
│ │  USD            $ 3,200    │ │  ← Per-currency subtotals (one row each)
│ │  ─────────────────────────  │ │
│ │  Total (EUR)   € 16,180   │ │  ← Converted grand total (live rates badge)
│ │                  live rates │ │    Or: "Offline – conversion unavailable"
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
- **Collection Value card**
  - Always shows one row per distinct currency found in artwork purchase prices (only artworks that have a purchase price are counted)
  - When an internet connection is available: fetches live ECB exchange rates from the Frankfurter API and shows a grand total converted to the user's preferred currency, labelled "live rates"
  - While fetching: a loading spinner is shown
  - When offline or rate fetch fails: shows "Offline – conversion unavailable" instead of the grand total; per-currency subtotals are still shown
  - Re-fetches automatically when the user changes the preferred currency in Settings
- **Recently Added strip** — tapping a thumbnail opens the Artwork Detail
- **FAB "+ Add Artwork"** — navigates to the Add / Edit Form
