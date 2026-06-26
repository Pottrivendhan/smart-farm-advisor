// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'utils/constants.dart';

// Screens
import 'screens/splash_login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/soil_input_screen.dart';
import 'screens/crop_result_screen.dart';
import 'screens/disease_screen.dart';
import 'screens/market_screen.dart';
import 'screens/reports_settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const SmartFarmApp(),
    ),
  );
}

class SmartFarmApp extends StatelessWidget {
  const SmartFarmApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Smart Farm Advisor',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    initialRoute: '/splash',
    routes: {
      '/splash':      (_) => const SplashScreen(),
      '/login':       (_) => const LoginScreen(),
      '/home':        (_) => const HomeScreen(),
      '/soil_input':  (_) => const SoilInputScreen(),
      '/crop_result': (_) => const CropResultScreen(),
      '/fertilizer':  (_) => const CropResultScreen(),   // opens on fertilizer tab
      '/water':       (_) => const CropResultScreen(),   // opens on water tab
      '/disease':     (_) => const DiseaseScreen(),
      '/market':      (_) => const MarketScreen(),
      '/reports':     (_) => const ReportsScreen(),
      '/settings':    (_) => const SettingsScreen(),
    },
  );
}
