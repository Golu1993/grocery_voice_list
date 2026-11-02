# grocery_voice_list

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Data storage

Google sign-in identifies the account. Grocery lists are stored in Firestore's
`lists` collection and their items in `list_items`, scoped by the signed-in
profile UUID. New accounts start with an empty Firestore list; existing Hive
grocery data is not imported. Hive stores the saved login and local profile
and device UUIDs through `HiveService`. Firestore rules in `firestore.rules`
must be deployed before the new collections can be used.

After sign-in setup completes, the profile UUID is saved locally for that
Firebase account. Later launches open Home and load the active Firestore list
without uploading profile details again. Signing out clears the saved
login; the next sign-in runs profile and device setup again.

All profile, device, list, and item queries are handled by `FirestoreQuery`.
Each signed-in session shares an instance scoped to its profile UUID.
