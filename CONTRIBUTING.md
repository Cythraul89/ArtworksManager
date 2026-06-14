# Contributing to AWoMa

## Branch conventions

| Branch | Purpose |
|--------|---------|
| `main` | Stable, released code |
| `develop` | Integration branch; features are merged here first |
| `feature/<short-name>` | One feature or fix per branch, branched from `develop` |

Always open pull requests **against `develop`** (not `main`). Direct pushes to `main` are reserved for release merges.

## Setting up

Follow the platform-specific prerequisites in [`doc/SETUP.md`](doc/SETUP.md), then:

```bash
git clone https://github.com/Cythraul89/ArtworksManager.git
cd ArtworksManager/flutter_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run          # pick a connected device or simulator
```

## Code generation requirement

**Any change to `app_database.dart`, a DAO, or any class annotated with `@DriftDatabase` / `@DriftAccessor` requires re-running:**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated `*.g.dart` files are committed to the repository so CI does not need `build_runner` for the test or analyze steps (it regenerates them explicitly anyway).

## Before opening a PR

```bash
flutter analyze --no-fatal-infos   # must be clean (see note below)
flutter test                        # all tests must pass
```

> **Analyzer note:** Five `info`-level hints for `RadioGroup` and `DropdownButtonFormField.initialValue` appear with the local Flutter 3.32.x SDK. They are valid API on CI (Flutter 3.44+). Do **not** suppress them with `// ignore` comments.

## Commit messages

Use the imperative mood and keep the first line under 72 characters:

```
Add certificate-pinning flow to Nextcloud screen
Fix UTC offset bug in backup filename generation
Refactor _pruneOldBackups to filter by regex
```

Reference GitHub issues where relevant: `Fixes #42`.

## Adding a database column

Follow the four-step rule documented in `CLAUDE.md` under **Schema Migration Rules**:

1. Declare the column in `app_database.dart`
2. Bump `schemaVersion`
3. Add `m.addColumn(...)` in the correct `if (from < N)` migration block
4. Update the fallback `Setting(...)` literal in `SettingsDao.watch()`
5. Run `build_runner`

## Pull request checklist

- [ ] `flutter analyze --no-fatal-infos` passes locally
- [ ] `flutter test` passes locally
- [ ] `build_runner` re-run if any Drift file changed
- [ ] New behaviour covered by a unit test (or explain why it cannot be)
- [ ] No secrets, keystore files, or `.env` files committed
- [ ] PR description explains **why** the change is needed, not just what changed
