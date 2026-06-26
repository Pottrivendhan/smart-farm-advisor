// lib/utils/constants.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── API ───────────────────────────────────────────────────────────────────────
const String kBaseUrl = 'http://10.61.0.204:8000'; // Android emulator → localhost
// For real device on same WiFi: 'http://192.168.x.x:8000'

// ── Colors ────────────────────────────────────────────────────────────────────
class AppColors {
  static const primary      = Color(0xFF1B4332);
  static const primaryLight = Color(0xFF2D6A4F);
  static const accent       = Color(0xFF52B788);
  static const saffron      = Color(0xFFE07B39);
  static const cream        = Color(0xFFF8F5EF);
  static const cardBg       = Color(0xFFFFFFFF);
  static const textDark     = Color(0xFF1A1A1A);
  static const textGrey     = Color(0xFF6B6B6B);
  static const success      = Color(0xFF2D6A4F);
  static const warning      = Color(0xFFE07B39);
  static const danger       = Color(0xFFD62828);
  static const bgLight      = Color(0xFFF4F9F6);
}

// ── Theme ─────────────────────────────────────────────────────────────────────
ThemeData buildAppTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.accent,
    tertiary: AppColors.saffron,
    background: AppColors.bgLight,
    surface: AppColors.cardBg,
  ),
  textTheme: GoogleFonts.poppinsTextTheme(),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    color: AppColors.cardBg,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.accent),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.accent.withOpacity(0.4)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
);

// ── All Tamil Nadu Districts ──────────────────────────────────────────────────
const List<String> kDistricts = [
  'Ariyalur','Chengalpattu','Chennai','Coimbatore','Cuddalore',
  'Dharmapuri','Dindigul','Erode','Kallakurichi','Kancheepuram',
  'Karur','Krishnagiri','Madurai','Mayiladuthurai','Nagapattinam',
  'Namakkal','Nilgiris','Perambalur','Pudukkottai','Ramanathapuram',
  'Ranipet','Salem','Sivagangai','Tenkasi','Thanjavur','Theni',
  'Thoothukudi','Tiruchirappalli','Tirunelveli','Tirupathur',
  'Tiruppur','Tiruvallur','Tiruvannamalai','Tiruvarur',
  'Vellore','Viluppuram','Virudhunagar',
];

const List<String> kCrops = [
  'Rice','Groundnut','Maize','Millet','Wheat',
  'Sugarcane','Cotton','Banana','Coconut',
];

const List<String> kSoilTypes = [
  'Red Soil','Black Soil','Sandy Loam','Clay Loam','Alluvial','Laterite',
];
