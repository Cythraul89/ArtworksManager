# Hello World Android App

A basic Android application built with Kotlin.

## Prerequisites

- [Android Studio](https://developer.android.com/studio) (Hedgehog or newer)
- JDK 8 or higher (bundled with Android Studio)
- Android SDK 24+ (installed via Android Studio's SDK Manager)

## Opening the Project

1. Clone the repository:
   ```bash
   git clone https://github.com/Cythraul89/ArtworksManager.git
   cd ArtworksManager
   ```
2. Open Android Studio and select **File → Open**
3. Navigate to the cloned folder and click **OK**
4. Wait for Gradle to sync (bottom status bar will show progress)

## Modifying the App

### Changing the displayed text
Edit `app/src/main/res/values/strings.xml` and update the `hello_world` value:
```xml
<string name="hello_world">Your new text here</string>
```

### Changing the layout
Edit `app/src/main/res/layout/activity_main.xml` to adjust the UI. The main `TextView` can be restyled (font size, colour, position) directly in this file or via Android Studio's visual layout editor.

### Adding new screens
1. Right-click the `com.example.helloworld` package in Android Studio → **New → Activity → Empty Views Activity**
2. Android Studio will generate the Activity class and layout file automatically
3. Link to the new screen from `MainActivity.kt` using an `Intent`:
   ```kotlin
   startActivity(Intent(this, YourNewActivity::class.java))
   ```

### Changing the app name or package
- **App name:** update `app_name` in `app/src/main/res/values/strings.xml`
- **Package:** use Android Studio's refactor tool — right-click the package → **Refactor → Rename**

## Building the App

### From Android Studio
- **Run on a device/emulator:** click the green **Run ▶** button (or `Shift+F10`)
- **Build a debug APK:** **Build → Build Bundle(s) / APK(s) → Build APK(s)**
  - Output: `app/build/outputs/apk/debug/app-debug.apk`
- **Build a release APK:** **Build → Generate Signed Bundle / APK**, follow the signing wizard

### From the command line
```bash
# Debug APK
./gradlew assembleDebug

# Release APK (requires a signing keystore configured in app/build.gradle)
./gradlew assembleRelease

# Install directly on a connected device
./gradlew installDebug
```

### Running on a physical device
1. Enable **Developer Options** on your Android device (tap *Build number* 7 times in Settings → About phone)
2. Enable **USB Debugging** in Developer Options
3. Connect via USB and accept the prompt on the device
4. Select the device in Android Studio's toolbar and click **Run ▶**

## Project Structure

```
app/src/main/
├── java/com/example/helloworld/
│   └── MainActivity.kt          # Main screen logic
└── res/
    ├── layout/
    │   └── activity_main.xml    # Main screen layout
    └── values/
        ├── strings.xml          # Text strings
        ├── colors.xml           # Colour palette
        └── themes.xml           # App theme
```
