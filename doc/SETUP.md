# Development Environment Setup

All development targets Flutter stable channel (≥ 3.44). Install Flutter first:
<https://docs.flutter.dev/get-started/install>

After installing Flutter, verify:

```bash
flutter doctor -v
```

All required components for your target platform must show a green tick.

---

## Android

### Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| JDK | 17 | Temurin build recommended |
| Android SDK | API 33+ | Install via Android Studio SDK Manager |
| Android Studio | Latest stable | Optional but easiest way to manage SDKs and emulators |

### Environment variables

```bash
# Adjust paths to match your installation
export JAVA_HOME=/usr/lib/jvm/temurin-17           # Linux
export JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home  # macOS
export ANDROID_SDK_ROOT=$HOME/Android/Sdk           # Linux
export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk   # macOS
export PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools
```

### Emulator (optional)

Create an AVD via Android Studio → Device Manager → Create Virtual Device.
Choose API 33+ (Tiramisu or later) to exercise background-sync scheduling.

### Debug signing

Debug builds use Flutter's auto-generated debug keystore — no setup required.
See [`doc/RELEASE.md`](RELEASE.md) for release signing.

---

## iOS

### Prerequisites

- macOS machine
- Xcode (latest stable) — install from the Mac App Store
- Command Line Tools: `xcode-select --install`

### Running on Simulator

```bash
open -a Simulator
flutter run
```

### Running on device

An Apple Developer account (free tier works for personal devices) and a provisioning profile are required. Follow Flutter's official guide:
<https://docs.flutter.dev/deployment/ios>

### Code signing in CI

CI uses `--no-codesign` for the debug/test build. Distribution signing is not configured; ad-hoc or App Store distribution needs a certificate and provisioning profile added to GitHub secrets.

---

## macOS

### Prerequisites

- macOS machine
- Xcode + Command Line Tools (same as iOS)
- Enable the macOS Flutter target: `flutter config --enable-macos-desktop`

### Sandbox note

AWoMa's `macos/Runner/DebugProfile.entitlements` includes the app-sandbox. If you add new platform capabilities (microphone, calendar, etc.) you must add the corresponding entitlement keys. CI strips the sandbox for unsigned builds.

---

## Linux

### Prerequisites

Install the required system libraries:

```bash
sudo apt-get update -y
sudo apt-get install -y \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev \
  libsecret-1-dev libjsoncpp-dev
```

`libsecret-1-dev` is required by `flutter_secure_storage` for Keyring access.
`libjsoncpp-dev` / `libjsoncpp25` is pulled in transitively by a Flutter engine dependency.

Enable the Linux target:

```bash
flutter config --enable-linux-desktop
```

---

## Windows

### Prerequisites

- Windows 10 or 11 (64-bit)
- **Visual Studio 2022** with the workload:
  *Desktop development with C++* (includes MSVC, CMake, Windows SDK)

Enable the Windows target:

```powershell
flutter config --enable-windows-desktop
```

### Building

```powershell
flutter build windows --release
```

The output bundle is in `build/windows/x64/runner/Release/`. Distribute the entire folder (executable + DLLs + `data/`).

---

## All platforms — first build

After cloning and installing prerequisites:

```bash
cd ArtworksManager/flutter_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

`build_runner` must be re-run whenever `app_database.dart` or any DAO file changes.

---

## Replacing the app icon

### 1. Prepare your source image

A **1024×1024 px PNG** with a transparent background. Square, no rounded corners — each platform applies its own shape mask.

### 2. Add `flutter_launcher_icons` to `pubspec.yaml`

```yaml
# flutter_app/pubspec.yaml

dev_dependencies:
  flutter_launcher_icons: ^0.14.2

flutter_launcher_icons:
  android: true
  ios: true
  macos: true
  windows: true
  image_path: "assets/icon/icon.png"
```

Place your image at `flutter_app/assets/icon/icon.png` (create the folder).

### 3. Run the generator

```bash
cd flutter_app
dart run flutter_launcher_icons
```

This overwrites all platform icon files automatically:

| Platform | Files updated |
|----------|--------------|
| Android | `android/app/src/main/res/mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png` |
| iOS | All 16 sizes in `ios/Runner/Assets.xcassets/AppIcon.appiconset/` |
| macOS | 7 sizes in `macos/Runner/Assets.xcassets/AppIcon.appiconset/` |
| Windows | `windows/runner/resources/app_icon.ico` |

### 4. Update the Linux `.deb` icon (CI)

The CI packaging step currently copies the macOS 256×256 asset for the Linux `.deb`. After replacing the icon, update both workflow files so they use your source image instead:

```yaml
# .github/workflows/flutter_ci.yml  and  flutter_release.yml
# inside the "Package as .deb" step — replace:
cp macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png \
  ${PKG}/usr/share/icons/hicolor/256x256/apps/awoma.png
# with:
cp assets/icon/icon.png \
  ${PKG}/usr/share/icons/hicolor/256x256/apps/awoma.png
```

### 5. Commit

```bash
git add android/app/src/main/res/ \
        ios/Runner/Assets.xcassets/ \
        macos/Runner/Assets.xcassets/ \
        windows/runner/resources/ \
        assets/icon/icon.png \
        pubspec.yaml
git commit -m "Replace app icon with custom logo"
```

### Manual alternative (no package)

Overwrite each PNG at the exact pixel sizes already in the repository. For the Windows `.ico`, use ImageMagick to embed all required resolutions:

```bash
magick icon.png -define icon:auto-resize=256,48,32,16 \
  windows/runner/resources/app_icon.ico
```
