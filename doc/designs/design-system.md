# Design System

## Colour Palette

| Role                  | Name            | Hex       |
|-----------------------|-----------------|-----------|
| Primary               | Deep Indigo     | `#3D3B8E` |
| Primary variant       | Dark Indigo     | `#2B2A6B` |
| Secondary / accent    | Warm Gold       | `#C9A84C` |
| Background            | Off White       | `#F8F6F2` |
| Surface               | White           | `#FFFFFF` |
| Error                 | Brick Red       | `#B00020` |
| On Primary            | White           | `#FFFFFF` |
| On Background / text  | Charcoal        | `#1C1C1E` |
| Secondary text        | Medium Grey     | `#6E6E73` |
| Divider / border      | Light Grey      | `#E0DED9` |

> Rationale: neutral off-white background keeps the focus on artwork photos; indigo and gold give a gallery/museum feel without being garish.

## Dark Mode Palette

The app follows the device system dark/light setting (`MODE_NIGHT_FOLLOW_SYSTEM`). When dark mode is active the following overrides replace the light palette:

| Role                  | Name               | Hex       |
|-----------------------|--------------------|-----------|
| Primary               | Lighter Indigo     | `#7B78D9` |
| Primary variant       | Mid Indigo         | `#5A57B0` |
| Secondary / accent    | Bright Gold        | `#D4A855` |
| Background            | Near Black         | `#121218` |
| Surface               | Dark Surface       | `#1E1E28` |
| Error                 | Soft Red           | `#CF6679` |
| On Primary            | White              | `#FFFFFF` |
| On Background / text  | Near White         | `#E8E8EF` |
| Secondary text        | Muted Grey         | `#9090A0` |
| Divider / border      | Dark Divider       | `#3A3A4A` |

> The primary colour is lightened in dark mode to maintain contrast against the dark background while preserving the indigo/gold brand identity.

---

## Typography

| Style          | Typeface          | Size  | Weight   | Usage                          |
|----------------|-------------------|-------|----------|--------------------------------|
| Headline Large | Playfair Display  | 32sp  | Bold     | Dashboard title                |
| Headline Small | Playfair Display  | 22sp  | SemiBold | Screen titles, artwork title   |
| Title          | Inter             | 18sp  | Medium   | Card titles, section headers   |
| Body           | Inter             | 16sp  | Regular  | Detail fields, descriptions    |
| Label          | Inter             | 14sp  | Regular  | Captions, metadata, form hints |
| Button         | Inter             | 14sp  | Medium   | All buttons (ALL CAPS)         |

---

## Spacing & Layout

- Base grid unit: **8dp**
- Screen horizontal padding: **16dp**
- Card internal padding: **16dp**
- Between cards: **12dp**
- Between form fields: **16dp**
- FAB bottom margin: **24dp**

---

## Elevation & Shape

- Cards: 2dp elevation, 12dp corner radius
- Bottom nav bar: 8dp elevation
- FAB: 6dp elevation, fully rounded (56dp)
- Dialogs: 4dp elevation, 16dp corner radius
- Input fields: outlined style, 8dp corner radius

---

## Iconography

- Icon set: **Material Symbols** (outlined style)
- Size: 24dp standard, 20dp inside dense lists
- Colour: matches text role (Charcoal for active, Medium Grey for inactive)

Key icons used:

| Action            | Icon                   |
|-------------------|------------------------|
| Add artwork       | `add`                  |
| Edit              | `edit`                 |
| Delete            | `delete`               |
| Search            | `search`               |
| Filter            | `tune`                 |
| Sort              | `sort`                 |
| Photo / camera    | `photo_camera`         |
| Gallery           | `photo_library`        |
| Export PDF        | `picture_as_pdf`       |
| Nextcloud backup  | `cloud_upload`         |
| Dashboard         | `dashboard`            |
| Collection        | `collections`          |
| Settings          | `settings`             |

---

## Components

### Artwork Card (grid)
- Aspect ratio: 1:1 thumbnail (cropped, centred)
- Below image: title (Title style, 1 line, ellipsis), artist (Label style, Medium Grey)
- Tap → Artwork Detail

### Artwork Card (list)
- 72dp tall row
- Leading: 56×56dp thumbnail, 4dp corner radius
- Content: title (Title), artist + year (Label, Medium Grey)
- Trailing: chevron icon

### Form Field
- Outlined `TextInputLayout` with floating label
- Error state: border + label turn Brick Red with inline message

### Primary Button
- Background: Deep Indigo, text: White, fully rounded
- Disabled: 38% opacity

### Destructive Button
- Text-only, Brick Red, used for Delete actions

### FAB (Floating Action Button)
- Extended on Dashboard ("+ Add Artwork"), icon-only on list screens
- Background: Warm Gold, icon: White
