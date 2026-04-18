import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/app_shell.dart';
import 'theme/kago_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: KagoTheme.cardBg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const KagoApp());
}

class KagoApp extends StatelessWidget {
  const KagoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: MaterialApp(
        title: 'Kago Africa',
        debugShowCheckedModeBanner: false,
        theme: KagoTheme.darkTheme,
        home: const _Loader(),
      ),
    );
  }
}

/// Shows a branded splash while the database initialises.
class _Loader extends StatefulWidget {
  const _Loader();

  @override
  State<_Loader> createState() => _LoaderState();
}

class _LoaderState extends State<_Loader> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Give the provider a moment to seed the database on first launch
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const AppShell();

    return Scaffold(
      backgroundColor: KagoTheme.darkBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: KagoTheme.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KagoTheme.orange.withOpacity(0.3)),
              ),
              child: const Center(
                child: Text('🚛', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'KAGO AFRICA',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Color(0xFFE8EAF0),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Fleet Management · Offline First',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                color: KagoTheme.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(KagoTheme.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
