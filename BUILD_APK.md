# Build Gu Cultivation APK

## Prerequisites

1. **Flutter SDK** (3.16+ recommended)  
   https://docs.flutter.dev/get-started/install

2. **Android Studio** (or Android SDK + command-line tools)  
   - SDK Platform 34  
   - Build-Tools 34.x  
   - Accept licenses: `flutter doctor --android-licenses`

3. Confirm setup:
   ```bash
   flutter doctor
   ```

## Build steps

```bash
# 1. Unzip / open the project
cd gu_cultivation

# 2. If android/ looks incomplete, regenerate platform files:
flutter create . --project-name gu_cultivation --org com.gucultivation --platforms=android

# 3. Get dependencies
flutter pub get

# 4. Build release APK
flutter build apk --release
```

## Output

APK path:

```
build/app/outputs/flutter-apk/app-release.apk
```

Copy that file to your phone and install it (enable “Install from unknown sources” if needed).

## Optional: split APKs / App Bundle

```bash
# Smaller per-ABI APKs
flutter build apk --split-per-abi --release

# Play Store bundle
flutter build appbundle --release
```

## Notes

- Release build is signed with the **debug** keystore so you can install it immediately.  
  For a store release, create your own keystore and configure `signingConfigs` in `android/app/build.gradle.kts`.
- First build downloads Gradle and dependencies; it can take several minutes.
- Data (Gu list, materials) is bundled in `assets/data/`.
