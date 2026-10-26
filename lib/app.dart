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
import 'services/hive_order_repository.dart';
import 'utils/app_theme.dart';
import 'utils/utility.dart';

class GroceryVoiceApp extends StatelessWidget {
  const GroceryVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Vocart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const _AuthGate(),
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
          builder: (context, session) {
            if (session.hasError) {
              return _StatusScreen(
                message: AuthService.errorMessage(session.error!),
                onRetry: _retrySession,
              );
            }
            if (session.connectionState == ConnectionState.waiting) {
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
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription<String>? _fcmTokenSubscription;
  Future<void> _fcmTokenSync = Future<void>.value();
  Future<void>? _profileSync;
  bool _profileSynced = false;
  bool _profileRetryAllowed = true;
  bool _profileFailureDialogOpen = false;
  String? _latestFcmToken;
  String? _savedFcmToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fcmTokenSubscription = _firebaseService.onTokenRefresh.listen(
      _onTokenRefresh,
      onError: (Object error) =>
          debugPrint('Could not refresh the FCM token: $error'),
    );
    _openSession = _openUserSession();
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
    if (state == AppLifecycleState.resumed) {
      _startProfileSync();
      if (_profileSynced) unawaited(_refreshFcmToken());
    }
  }

  void _onTokenRefresh(String token) {
    if (token.isEmpty) return;
    _latestFcmToken = token;
    if (_profileSynced && token != _savedFcmToken) {
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
      final deviceUuid = await Utility.getUniqueId();
      if (!mounted || AuthService.currentUser?.uid != widget.user.uid) return;
      await FirestoreQuery().saveFcmToken(
        deviceUuid: deviceUuid,
        fcmToken: token,
      );
      _savedFcmToken = token;
    } catch (error) {
      debugPrint('Could not save the FCM token: $error');
    }
  }

  Future<_SessionData> _openUserSession() async {
    final orders = await HiveOrderRepository.open(widget.user.uid);
    final orderUuid = await orders.ensureActiveOrder();
    _startProfileSync();
    return _SessionData(orders: orders, orderUuid: orderUuid);
  }

  void _startProfileSync() {
    if (_profileSynced ||
        !_profileRetryAllowed ||
        _profileFailureDialogOpen ||
        _profileSync != null ||
        AuthService.currentUser?.uid != widget.user.uid) {
      return;
    }
    final sync = _syncRemoteProfile();
    _profileSync = sync;
    unawaited(sync.whenComplete(() => _profileSync = null));
  }

  Future<void> _syncRemoteProfile() async {
    try {
      final query = FirestoreQuery();
      final profile = await query.saveSignedInUser(firebaseUser: widget.user);
      if (AuthService.currentUser?.uid != widget.user.uid) return;

      String? fcmToken;
      try {
        fcmToken = await _firebaseService.getFcmToken(requestPermission: true);
      } catch (error) {
        // Device registration still works when FCM is temporarily unavailable.
        debugPrint('Could not get the FCM token: $error');
      }
      if (AuthService.currentUser?.uid != widget.user.uid) return;
      final tokenForDevice = _latestFcmToken ?? fcmToken;
      final device = await Utility.getDeviceDetails(fcmToken: tokenForDevice);
      if (AuthService.currentUser?.uid != widget.user.uid) return;
      await query.saveDevice(device: device);
      if (AuthService.currentUser?.uid != widget.user.uid) return;
      await query.setActiveUserId(
        deviceUuid: device.uuid,
        userUuid: profile.uuid,
      );
      _profileSynced = true;
      _savedFcmToken = tokenForDevice;
      final latestToken = _latestFcmToken;
      if (latestToken != null && latestToken != tokenForDevice) {
        _queueFcmTokenSync(latestToken);
      }
    } catch (error) {
      debugPrint('Could not sync user and device details: $error');
      final failure = FirestoreQueryFailure.from(error);
      if (!failure.canRetry) _profileRetryAllowed = false;
      _showProfileSyncFailure(failure);
    }
  }

  void _showProfileSyncFailure(FirestoreQueryFailure failure) {
    if (!mounted ||
        _profileFailureDialogOpen ||
        AuthService.currentUser?.uid != widget.user.uid) {
      return;
    }
    _profileFailureDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || AuthService.currentUser?.uid != widget.user.uid) {
        _profileFailureDialogOpen = false;
        return;
      }
      final retry = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            failure.kind == FirestoreQueryFailureKind.offline
                ? 'No internet connection'
                : 'Profile sync failed',
          ),
          content: Text(
            '${failure.message}\n\nYour local lists are still available.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(failure.canRetry ? 'Continue offline' : 'Close'),
            ),
            if (failure.canRetry)
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Retry'),
              ),
          ],
        ),
      );
      _profileFailureDialogOpen = false;
      if (retry == true && mounted) _startProfileSync();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SessionData>(
      future: _openSession,
      builder: (context, session) {
        if (session.hasError) {
          return _StatusScreen(
            message: 'Could not open your session: ${session.error}',
            onRetry: () => setState(() {
              _openSession = _openUserSession();
            }),
          );
        }
        if (session.connectionState != ConnectionState.done) {
          return const _StatusScreen(message: 'Opening your session…');
        }
        final data = session.data!;
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => GroceryProvider(orderRepository: data.orders),
            ),
            ChangeNotifierProvider(create: (_) => VoiceProvider()),
            ChangeNotifierProvider(
              create: (_) => OrderProvider(
                orderRepository: data.orders,
                activeOrderUuid: data.orderUuid,
              ),
            ),
          ],
          child: const _AppLoader(),
        );
      },
    );
  }
}

class _SessionData {
  const _SessionData({required this.orders, required this.orderUuid});

  final HiveOrderRepository orders;
  final String orderUuid;
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

class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  bool _loaded = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      await Future.wait([
        context.read<GroceryProvider>().loadItems(),
        context.read<OrderProvider>().refreshOrders(),
      ]);
      if (mounted) setState(() => _loaded = true);
    } catch (error) {
      if (mounted) setState(() => _loadError = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return _StatusScreen(
        message: 'Could not load your lists: $_loadError',
        onRetry: () {
          setState(() => _loadError = null);
          _load();
        },
      );
    }
    return _loaded
        ? const HomeScreen()
        : const _StatusScreen(message: 'Loading your lists…');
  }
}
