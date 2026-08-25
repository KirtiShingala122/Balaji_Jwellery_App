Place your square app icon PNG here using this filename:

assets/icon/app_icon.png

Requirements:
- Square image, recommended 1024x1024 px
- Format: PNG
- Transparent or solid background

If you want, I can write the provided PNG into this path for you. If you want me to do that, reply "Please add the attached PNG" and I'll write it into `assets/icon/app_icon.png` now.

After adding `assets/icon/app_icon.png` run these commands from the `frontend` folder:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
flutter clean
flutter run
```

Notes:
- Uninstall any previously installed app from device/emulator before testing
- If you prefer different background color for splash, edit `flutter_native_splash.color` in `pubspec.yaml`
