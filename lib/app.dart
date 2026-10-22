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
import 'services/firestore_query.dart';
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

class _UserSessionState extends State<_UserSession> {
  late Future<_SessionData> _openSession;

  @override
  void initState() {
    super.initState();
    _openSession = _openUserSession();
  }

  Future<_SessionData> _openUserSession() async {
    final query = FirestoreQuery();
    final deviceUuid = await Utility.getUniqueId();
    final profile = await query
        .saveSignedInUser(firebaseUser: widget.user)
        .timeout(const Duration(seconds: 20));
    await query
        .setActiveUserId(deviceUuid: deviceUuid, userUuid: profile.uuid)
        .timeout(const Duration(seconds: 20));
    final orders = await HiveOrderRepository.open(widget.user.uid);
    final orderUuid = await orders.ensureActiveOrder();
    return _SessionData(orders: orders, orderUuid: orderUuid);
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
