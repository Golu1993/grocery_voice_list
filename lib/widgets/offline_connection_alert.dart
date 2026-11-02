import 'dart:async';

import 'package:flutter/material.dart';

import '../services/firestore_query_guard.dart';

/// Shows one app-wide alert when a Firestore operation detects no internet.
class OfflineConnectionAlert extends StatefulWidget {
  const OfflineConnectionAlert({super.key, required this.child});

  final Widget child;

  @override
  State<OfflineConnectionAlert> createState() => _OfflineConnectionAlertState();
}

class _OfflineConnectionAlertState extends State<OfflineConnectionAlert> {
  late final StreamSubscription<FirestoreQueryFailure> _subscription;
  bool _alertVisible = false;

  @override
  void initState() {
    super.initState();
    _subscription = FirestoreQueryGuard.offlineFailures.listen((_) {
      if (_alertVisible) return;
      _alertVisible = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        try {
          await showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('No internet connection'),
              content: const Text(
                'Connect to the internet, then try your action again.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } finally {
          _alertVisible = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
