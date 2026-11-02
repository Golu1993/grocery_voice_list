import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'providers/grocery_provider.dart';
import 'providers/order_provider.dart';
import 'providers/voice_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/firestore_query.dart';
import 'services/firestore_query_guard.dart';
import 'services/hive_service.dart';
import 'utils/app_theme.dart';
import 'utils/utility.dart';
import 'widgets/offline_connection_alert.dart';

class GroceryVoiceApp extends StatelessWidget {
  const GroceryVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Vocart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: const OfflineConnectionAlert(child: _AuthGate()),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late Future<void> _firebaseStartup;
  Stream<User?>? _authStream;
  Timer? _startupWatchdog;
  bool _startupTimedOut = false;

  @override
  void initState() {
    super.initState();
    _startFirebase();
  }

  void _startFirebase() {
    _startupWatchdog?.cancel();
    _startupTimedOut = false;
    _authStream = null;
    final startup = AuthService.initialize();
    _firebaseStartup = startup;
    final watchdog = Timer(const Duration(seconds: 25), () {
      if (mounted) setState(() => _startupTimedOut = true);
    });
    _startupWatchdog = watchdog;
    startup.then(
      (_) => watchdog.cancel(),
      onError: (Object _) => watchdog.cancel(),
    );
  }

  void _retryFirebase() {
    setState(_startFirebase);
  }

  void _retrySession() {
    setState(() {
      _authStream = AuthService.authStateChanges();
    });
  }

  @override
  void dispose() {
    _startupWatchdog?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _firebaseStartup,
      builder: (context, startup) {
        if (startup.hasError ||
            (_startupTimedOut &&
                startup.connectionState != ConnectionState.done)) {
          return _StatusScreen(
            message: startup.hasError
                ? AuthService.errorMessage(startup.error!)
                : 'Firebase did not respond. Check your connection and retry.',
            onRetry: _retryFirebase,
          );
        }
        if (startup.connectionState != ConnectionState.done) {
          return const _StatusScreen(message: 'Starting Vocart…');
        }

        _authStream ??= AuthService.authStateChanges();
        return StreamBuilder<User?>(
          stream: _authStream,
          initialData: AuthService.currentUser,
          builder: (context, session) {
            if (session.hasError) {
              return _StatusScreen(
                message: AuthService.errorMessage(session.error!),
                onRetry: _retrySession,
              );
            }
            if (session.connectionState == ConnectionState.waiting &&
                !session.hasData) {
              return const _StatusScreen(message: 'Checking your session…');
            }
            final user = session.data;
            if (user == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).popUntil((route) => route.isFirst);
                }
              });
            }
            return user == null
                ? const LoginScreen()
                : _UserSession(key: ValueKey(user.uid), user: user);
          },
        );
      },
    );
  }
}

class _UserSession extends StatefulWidget {
  const _UserSession({super.key, required this.user});

  final User user;

  @override
  State<_UserSession> createState() => _UserSessionState();
}

class _UserSessionState extends State<_UserSession>
    with WidgetsBindingObserver {
  late Future<_SessionData> _openSession;
  _SessionData? _restoredSession;
  late FirestoreQuery _firestoreQuery;
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription<String>? _fcmTokenSubscription;
  Future<void> _fcmTokenSync = Future<void>.value();
  bool _deviceRegistered = false;
  String? _latestFcmToken;
  String? _savedFcmToken;
  String? _profileUuid;
  String _sessionStatus = 'Opening your account…';

  @override
  void initState() {
    super.initState();
    final savedProfileUuid = HiveService.readProfileUuid(
      authUid: widget.user.uid,
    );
    _firestoreQuery = FirestoreQuery(ownerId: savedProfileUuid);
    WidgetsBinding.instance.addObserver(this);
    _fcmTokenSubscription = _firebaseService.onTokenRefresh.listen(
      _onTokenRefresh,
      onError: (Object error) =>
          debugPrint('Could not refresh the FCM token: $error'),
    );
    if (savedProfileUuid == null) {
      _openSession = _openUserSession();
    } else {
      // The local login is valid until sign-out. Open Home without repeating
      // the Firestore profile or device setup.
      _profileUuid = savedProfileUuid;
      _deviceRegistered = true;
      final data = _SessionData(firestoreQuery: _firestoreQuery);
      _restoredSession = data;
      _openSession = Future.value(data);
      unawaited(_refreshFcmToken());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final subscription = _fcmTokenSubscription;
    if (subscription != null) unawaited(subscription.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _deviceRegistered) {
      unawaited(_refreshFcmToken());
    }
  }

  void _onTokenRefresh(String token) {
    if (token.isEmpty) return;
    _latestFcmToken = token;
    if (_deviceRegistered && token != _savedFcmToken) {
      _queueFcmTokenSync(token);
    }
  }

  Future<void> _refreshFcmToken() async {
    try {
      final token = await _firebaseService.getFcmToken();
      if (mounted && token != null) _onTokenRefresh(token);
    } catch (error) {
      debugPrint('Could not get the FCM token: $error');
    }
  }

  void _queueFcmTokenSync(String token) {
    _fcmTokenSync = _fcmTokenSync.then((_) => _syncFcmToken(token));
  }

  Future<void> _syncFcmToken(String token) async {
    try {
      if (!mounted || AuthService.currentUser?.uid != widget.user.uid) return;
      final deviceUuid = await HiveService.getOrCreateDeviceUuid();
      if (!mounted || AuthService.currentUser?.uid != widget.user.uid) return;
      await _firestoreQuery.saveFcmToken(
        userUuid: _profileUuid!,
        deviceUuid: deviceUuid,
        fcmToken: token,
      );
      _savedFcmToken = token;
    } catch (error) {
      debugPrint('Could not save the FCM token: $error');
    }
  }

  Future<_SessionData> _openUserSession() async {
    if (AuthService.currentUser?.uid != widget.user.uid) {
      throw StateError('The signed-in account changed while opening lists.');
    }

    _setSessionStatus('Uploading your profile…');
    final profile = await _firestoreQuery.saveSignedInUser(
      firebaseUser: widget.user,
    );
    if (AuthService.currentUser?.uid != widget.user.uid) {
      throw StateError('The signed-in account changed while loading lists.');
    }
    _profileUuid = profile.uuid;
    _firestoreQuery = FirestoreQuery(ownerId: profile.uuid);
    _setSessionStatus('Uploading device details…');
    await _registerDevice(profile.uuid);
    if (AuthService.currentUser?.uid != widget.user.uid) {
      throw StateError('The signed-in account changed while loading lists.');
    }
    _setSessionStatus('Finishing setup…');
    await HiveService.saveLogin(
      authUid: widget.user.uid,
      profileUuid: profile.uuid,
    );
    return _SessionData(firestoreQuery: _firestoreQuery);
  }

  void _setSessionStatus(String status) {
    _sessionStatus = status;
    if (mounted) setState(() {});
  }

  Future<void> _registerDevice(String profileUuid) async {
    try {
      final query = _firestoreQuery;
      String? fcmToken;
      try {
        fcmToken = await _firebaseService
            .getFcmToken(requestPermission: true)
            .timeout(const Duration(seconds: 12));
      } catch (error) {
        // Device registration still works when FCM is temporarily unavailable.
        debugPrint('Could not get the FCM token: $error');
      }
      if (AuthService.currentUser?.uid != widget.user.uid) return;
      final tokenForDevice = _latestFcmToken ?? fcmToken;
      final device = await Utility.getDeviceDetails(fcmToken: tokenForDevice);
      if (AuthService.currentUser?.uid != widget.user.uid) return;
      await query.saveDevice(device: device, userUuid: profileUuid);
      if (AuthService.currentUser?.uid != widget.user.uid) return;
      _deviceRegistered = true;
      _savedFcmToken = tokenForDevice;
      final latestToken = _latestFcmToken;
      if (latestToken != null && latestToken != tokenForDevice) {
        _queueFcmTokenSync(latestToken);
      }
    } catch (error) {
      if (error is FirestoreQueryFailure) {
        throw StateError('Could not register your device: ${error.message}');
      }
      rethrow;
    }
  }

  String _setupErrorMessage(Object error) {
    if (error is FirestoreQueryFailure) return error.message;
    if (error is StateError) return error.message.toString();
    return AuthService.errorMessage(error);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SessionData>(
      future: _openSession,
      initialData: _restoredSession,
      builder: (context, session) {
        if (session.hasError) {
          return LoginScreen(
            setupError:
                'Could not finish setup: ${_setupErrorMessage(session.error!)}',
            onSetupRetry: () => setState(() {
              _sessionStatus = 'Opening your account…';
              _openSession = _openUserSession();
            }),
          );
        }
        if (!session.hasData) {
          return LoginScreen(setupStatus: _sessionStatus);
        }
        final data = session.data!;
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) =>
                  GroceryProvider(firestoreQuery: data.firestoreQuery),
            ),
            ChangeNotifierProvider(create: (_) => VoiceProvider()),
            ChangeNotifierProvider(
              create: (_) => OrderProvider(firestoreQuery: data.firestoreQuery),
            ),
          ],
          child: const HomeScreen(),
        );
      },
    );
  }
}

class _SessionData {
  const _SessionData({required this.firestoreQuery});

  final FirestoreQuery firestoreQuery;
}

class _StatusScreen extends StatelessWidget {
  const _StatusScreen({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onRetry == null) const CircularProgressIndicator(),
              if (onRetry == null) const SizedBox(height: 20),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
