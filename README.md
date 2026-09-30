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
per-account Hive boxes on the device. Order UUIDs and device details remain
available in their models, but the app does not save user, device, or order
documents to Firestore. Existing Firestore documents are not changed or deleted.
