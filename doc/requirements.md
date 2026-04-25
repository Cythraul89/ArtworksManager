# App Requirements

## Overview

A personal artwork catalogue app for a private collector. The app gives the owner a clear overview of their collection and lets them record, browse, and manage up to 1000 artworks from their Android device.

## Target Users

A single private individual who owns a personal art collection of up to 1000 artworks and wants a simple, organised way to catalogue and review it.

## Core Features

- **Add artwork** — record a new artwork with the following details:
  - Title
  - Artist name
  - Year of creation
  - Medium / technique (e.g. oil on canvas, watercolour, sculpture)
  - Dimensions (height × width × depth where applicable)
  - Photo (taken with camera or selected from gallery)
  - Description / notes
  - Location (where the artwork is stored or displayed)
  - Acquisition date and purchase price
- **Edit artwork** — update any detail of an existing artwork
- **Delete artwork** — remove an artwork from the catalogue
- **Browse collection** — scrollable list/grid of all artworks with thumbnail, title, and artist
- **Artwork detail view** — full-screen view of all recorded details and the photo
- **Search** — find artworks by title or artist name
- **Filter & sort** — filter by medium or year; sort by title, artist, or acquisition date
- **Dashboard / overview** — summary statistics:
  - Total number of artworks
  - Breakdown by medium
  - Breakdown by artist

## Nice to Have

- Multiple photos per artwork
- Tags / custom categories
- Export collection as PDF or CSV
- Estimated current value field separate from purchase price
- Provenance / ownership history notes
- Condition field (excellent, good, fair, poor)

## Out of Scope

- Multi-user access or sharing with others
- Cloud sync or online backup (all data stored locally on device)
- Public marketplace or valuation services
- Collections larger than 1000 artworks

## Screens / User Flows

1. **Dashboard** — entry point; shows total artwork count, quick stats by medium and artist, and a shortcut to add a new artwork
2. **Collection list** — grid or list of all artworks; supports search, filter, and sort; tapping an item opens the detail view
3. **Artwork detail** — displays the photo and all recorded fields; action buttons to edit or delete
4. **Add / Edit artwork** — form with all fields, photo picker/camera, and a save button
5. **Search results** — filtered view of the collection list based on a search query

## Non-Functional Requirements

- **Min Android version:** Android 7.0 (API 24)
- **Target devices:** Android smartphones (portrait-first, tablet-friendly)
- **Offline support:** Full offline — all data stored locally using a local database (no internet required)
- **Storage:** Photos stored on-device; collection data in a local SQLite/Room database
- **Performance:** Collection list should load and scroll smoothly for up to 1000 artworks
- **Languages / localisation:** English (single language for initial version)
- **Accessibility:** Adequate contrast and content descriptions on images
