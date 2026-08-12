import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../providers/order_provider.dart';
import 'package:provider/provider.dart';

import 'providers/grocery_provider.dart';
import 'providers/voice_provider.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';

class GroceryVoiceApp extends StatelessWidget {
  const GroceryVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GroceryProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: GetMaterialApp(
        title: 'GroceryVoice',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const _AppLoader(),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    unawaited(context.read<VoiceProvider>().warmUpIfPermitted());
    await context.read<GroceryProvider>().loadItems();
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_rounded, size: 56, color: Colors.amber),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }
    return HomeScreen();
  }
}
