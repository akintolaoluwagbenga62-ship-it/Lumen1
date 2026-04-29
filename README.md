# Lumen

A Flutter study app for Nigerian JAMB candidates. Includes CBT practice, study groups & chat, flashcards, leaderboards, a paywall, and an admin panel.

> **Default admin login:** `admin@lumen.ng` (register with that email and you become admin automatically).

---

## What changed in this revision

### Bug fixes
- **`models.dart`** — `LumenUser.calcLevel` now uses `dart:math.sqrt` instead of a slow custom integer-square-root extension on `double`. Faster, correct, and no extension namespace pollution. Added `nextLevelXp` helper.
- **`paywall_screen.dart`** — removed the duplicate `AdminScreen` and `NotificationsScreen` that were jammed into this file. They now live in `admin_screen.dart` and `notifications_screen.dart` respectively. The original duplicate broke `import` resolution and made the paywall file 3× larger than it needed to be.
- **`notifications_screen.dart`** — created as its own file (was missing entirely; `main_shell.dart` was importing a non-existent file). `markAllNotifsRead()` now runs once in `initState` instead of being scheduled on every build.
- **`group_chat_screen.dart`** — `_scrollToBottom()` was called unconditionally inside `build()`, causing wasted work on every Provider notification. Now only scrolls when the message list grows. Also marks the chat as read once on open via `initState` (previously messages were never marked read on open).
- **`flashcards_screen.dart`** — removed unused `_cardIndex` and `_flipped` fields from `_DeckDetailScreenState` (they were write-only and shadowed by `_StudyMode`).
- **`app_state.dart`** — `login()` and `register()` are now properly `async` (they return `Future<String?>` and persist to disk before resolving). `auth_screen.dart` awaits them. Removed the sentinel-empty `LumenUser` pattern; we now use real `null` everywhere. Added `markGroupRead(gid)` and `unreadCount(gid)` so chats can show real unread badges. Added centralised `SharedPreferences` keys, safe JSON decode with `debugPrint` on failure, and a 100-item cap on stored notifications so storage stays bounded.

### Android modernization
- **JDK 17** (was JDK 8 / 1.8) — required by AGP 8.x.
- **AGP 8.1.4 + Kotlin 1.9.22 + Gradle 8.3** (was AGP 8.0 + Kotlin 1.9.0 + Gradle 8.0).
- **Modern declarative plugin DSL** in `settings.gradle` (no more `buildscript { classpath … }` blocks).
- **`compileSdk 34`, `targetSdk 34`, `minSdk 21`** — current Play Store requirements.
- **Manifest `<queries>` block** — required by Android 11+ for `url_launcher` to actually find browser/email/dial intents.
- **`READ_MEDIA_IMAGES`** for Android 13+ image picker; legacy `READ_EXTERNAL_STORAGE` capped at SDK 32.
- **R8 / ProGuard rules** — minify + shrink resources for release builds, with rules for Flutter, OkHttp, and `android.util.Log` stripping.
- **Optional release signing config** — drop a `key.properties` next to `android/build.gradle` and release builds are signed automatically. Without it, builds fall back to the debug keystore so `flutter build apk` always works.

---

## Building the APK

You have three options. The first one is the easiest by far.

### Option 1 — GitHub Actions (recommended, free)

The repo ships with `.github/workflows/build-apk.yml`. Every push to `main` (or `master`) builds release APKs in CI and uploads them as workflow artifacts.

1. Push this folder to a new GitHub repo.
2. Open the **Actions** tab → click the latest **Build Android APK** run.
3. Scroll to **Artifacts** at the bottom and download:
   - `lumen-apk-universal` → one APK that runs on every device (~25 MB).
   - `lumen-apks-split` → smaller per-architecture APKs (`arm64-v8a`, `armeabi-v7a`, `x86_64`).
4. Transfer the APK to your Android phone and install it. You will need to enable **Install unknown apps** for your file manager / browser the first time.

No keystore or local Android SDK needed.

### Option 2 — Local build

Requires:
- Flutter 3.16+ (`flutter --version`)
- Android SDK with build-tools 34
- JDK 17

```bash
cd lumen_app
cp android/local.properties.example android/local.properties
# Edit local.properties with your SDK + Flutter paths.

flutter pub get
flutter build apk --release --split-per-abi
# APKs land in build/app/outputs/flutter-apk/
```

For a single universal APK: `flutter build apk --release`.

### Option 3 — Codemagic / Bitrise / Appcircle

Any cloud Flutter CI accepts this project as-is. Point it at the repo and use the default **Build APK** workflow.

---

## Signing for the Play Store

```bash
keytool -genkey -v -keystore ~/lumen-release-key.jks \
        -keyalg RSA -keysize 2048 -validity 10000 -alias lumen
```

Then copy `android/key.properties.example` → `android/key.properties` and fill in the four values. The next `flutter build apk --release` (or `flutter build appbundle`) will be signed.

For GitHub Actions signed builds, store `key.properties` and the `.jks` file as base64 secrets and add a step that decodes them before `flutter build` — happy to wire that up if you want.

---

## Project layout

```
lib/
├── main.dart                         # App entrypoint + ChangeNotifierProvider wiring
├── models/
│   ├── constants.dart                # Subjects, banks, plans, admin email, etc.
│   └── models.dart                   # LumenUser, StudyGroup, ChatMessage, FlashDeck, ...
├── providers/
│   └── app_state.dart                # Single ChangeNotifier; persists to SharedPreferences
├── screens/
│   ├── auth_screen.dart              # Login / register
│   ├── main_shell.dart               # Bottom nav: Groups · CBT · Cards · Alerts · Profile
│   ├── groups_screen.dart            # Group list + create
│   ├── group_chat_screen.dart        # Per-group chat with replies, pin, mod tools
│   ├── cbt_screen.dart               # CBT practice / timed test
│   ├── flashcards_screen.dart        # Decks + study mode
│   ├── notifications_screen.dart     # Per-user alerts feed
│   ├── paywall_screen.dart           # Plans + bank-transfer + reference submission
│   ├── profile_screen.dart           # XP / level, settings, logout
│   └── admin_screen.dart             # Pending payments + user list (admin only)
└── utils/
    └── theme.dart                    # Light/dark Material 3 themes + BuildContext extensions
```

---

## Tech stack

- **Flutter 3.16+ / Dart 3+**
- **provider** — lightweight ChangeNotifier state management
- **shared_preferences** — local-only persistence (no backend yet)
- **uuid, intl, url_launcher, image_picker, cached_network_image, flutter_svg**

Storage is fully local: there is no server, no Firebase, no auth provider. All users, groups, messages, decks, and notifications live in `SharedPreferences` on the device.

---

## Known limitations

- **Local-only storage** — uninstalling the app wipes everything. A real deployment will want Firebase/Supabase or a custom backend; the `AppState` API is structured to make that swap straightforward.
- **No password hashing** — passwords are stored in plaintext in SharedPreferences. Acceptable for a local prototype only. Move to a real backend before publishing.
- **Image picker / camera permissions** — wired in the manifest but not yet requested at runtime via `permission_handler`. Add that before shipping.
- **CBT question bank** is small — easy to extend in `models/constants.dart`.
