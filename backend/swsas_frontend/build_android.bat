@echo off
echo Installing Flutter Dependencies...
flutter pub get

echo Building Android APK...
flutter build apk --release

echo Build complete! You can find the APK at build\app\outputs\flutter-apk\app-release.apk
