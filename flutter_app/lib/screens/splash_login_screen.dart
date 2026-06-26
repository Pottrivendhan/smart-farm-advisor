// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await context.read<AppProvider>().init();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final prov = context.read<AppProvider>();
    if (prov.currentFarmer != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.primary,
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.eco, size: 80, color: Colors.white)
          .animate().scale(duration: 600.ms, curve: Curves.elasticOut),
      const SizedBox(height: 20),
      const Text('Smart Farm Advisor',
          style: TextStyle(color: Colors.white, fontSize: 26,
                           fontWeight: FontWeight.bold))
          .animate().fadeIn(delay: 300.ms),
      const SizedBox(height: 8),
      Text('தமிழ்நாட்டு விவசாயிகளுக்காக',
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14))
          .animate().fadeIn(delay: 500.ms),
      const SizedBox(height: 40),
      const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
          .animate().fadeIn(delay: 800.ms),
    ])),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// lib/screens/login_screen.dart
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _villageCtrl  = TextEditingController();
  String _district    = kDistricts[0];
  double _acres       = 1.0;
  bool   _saving      = true;

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')));
      return;
    }
    setState(() => _saving = true);
    await context.read<AppProvider>().saveFarmer(Farmer(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      district: _district,
      village: _villageCtrl.text.trim(),
      acres: _acres,
    ));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgLight,
    body: SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.agriculture, color: Colors.white, size: 40),
            SizedBox(height: 12),
            Text('Welcome, Farmer!',
                style: TextStyle(color: Colors.white, fontSize: 22,
                                 fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('விவசாயியே வணக்கம்!',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ]),
        ).animate().fadeIn().slideY(begin: -0.2),

        const SizedBox(height: 28),
        _field('Your Name / உங்கள் பெயர்', _nameCtrl,
               icon: Icons.person, hint: 'e.g. Murugan'),
        const SizedBox(height: 16),
        _field('Phone / தொலைபேசி', _phoneCtrl,
               icon: Icons.phone, hint: '9XXXXXXXXX',
               type: TextInputType.phone),
        const SizedBox(height: 16),
        _field('Village / கிராமம்', _villageCtrl,
               icon: Icons.location_on, hint: 'e.g. Kodaikanal'),
        const SizedBox(height: 16),

        // District picker
        DropdownButtonFormField<String>(
          value: _district,
          decoration: const InputDecoration(
            labelText: 'District / மாவட்டம்',
            prefixIcon: Icon(Icons.map, color: AppColors.primary),
          ),
          items: kDistricts.map((d) =>
              DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) => setState(() => _district = v!),
        ),
        const SizedBox(height: 20),

        // Acres slider
        Text('Farm Size: ${_acres.toStringAsFixed(1)} acres',
             style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
        Slider(
          value: _acres, min: 0.5, max: 50, divisions: 99,
          activeColor: AppColors.primary,
          onChanged: (v) => setState(() => _acres = v),
        ),

        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
  onPressed: () {
    print("BUTTON CLICKED");
    Navigator.pushReplacementNamed(context, '/home');
  },
            icon: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.arrow_forward),
            label: const Text('Get Started / தொடங்கு'),
          ),
        ).animate().fadeIn(delay: 400.ms),
      ]),
    )),
  );

  Widget _field(String label, TextEditingController ctrl,
      {IconData? icon, String hint = '', TextInputType type = TextInputType.text}) =>
    TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: AppColors.primary) : null,
      ),
    );
}
