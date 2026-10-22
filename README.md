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

Google sign-in identifies the account. Grocery items and orders are saved in
per-account Hive boxes on the device. User profiles and device details continue
to use Firestore; the app no longer reads or writes order documents there.
Existing Firestore orders are not imported, changed, or deleted, so orders that
exist only in Firestore will not appear in local list history.
