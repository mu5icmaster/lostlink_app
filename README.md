# LostLink

Flutter/Firebase campus lost-and-found application.

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Enable Email/Password Authentication, Firestore, Storage, Cloud Messaging, and
App Check in Firebase project `lostlink-4ac08`. Register the App Check debug
token printed by debug builds; use Play Integrity for release builds.

Deploy backend policy after reviewing it for the target campus:

```sh
firebase deploy --only firestore:rules,firestore:indexes,storage
```

Cloud Messaging tokens are registered by the app. Sending background push
notifications requires a trusted server or Cloud Function that reads those
tokens; never place Firebase Admin credentials in this client repository.

## Android release

The current Firebase Android registration uses `com.example.lost_link`.
Before publishing, create a permanent application ID, register that Android
app in Firebase, and rerun `flutterfire configure`.

Create an upload keystore, copy `android/key.properties.example` to
`android/key.properties`, and fill in the real values. Keystores and signing
credentials are excluded from source control.
