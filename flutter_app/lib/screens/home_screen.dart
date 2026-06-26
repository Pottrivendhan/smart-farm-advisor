// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _tiles = [
    _Tile('Soil & Crop\nRecommendation', Icons.grass,
          AppColors.primary, '/soil_input'),
    _Tile('Fertilizer\nPlan', Icons.science,
          Color(0xFF3A6351), '/fertilizer'),
    _Tile('Disease\nDetection', Icons.pest_control,
          Color(0xFF8B2252), '/disease'),
    _Tile('Market\nPrice', Icons.show_chart,
          Color(0xFF1A5C8C), '/market'),
    _Tile('Water\nAdvisory', Icons.water_drop,
          Color(0xFF0077B6), '/water'),
    _Tile('Reports &\nHistory', Icons.description,
          Color(0xFF5A4A6F), '/reports'),
  ];

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final farmer = prov.currentFarmer;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Smart Farm Advisor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'Toggle Tamil/English',
            onPressed: prov.toggleLanguage,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(children: [
        if (!prov.isOnline) const OfflineBanner(),

        // Farmer greeting banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            const CircleAvatar(
              radius: 28, backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                prov.isTamil
                    ? 'வணக்கம், ${farmer?.name ?? "விவசாயி"}!'
                    : 'Hello, ${farmer?.name ?? "Farmer"}!',
                style: const TextStyle(color: Colors.white,
                                       fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${farmer?.district ?? ""} · ${farmer?.acres.toStringAsFixed(1) ?? "1.0"} acres',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: prov.isOnline ? AppColors.accent : AppColors.warning,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                prov.isOnline ? '🟢 Online' : '🟡 Offline',
                style: const TextStyle(color: Colors.white,
                                       fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
        ).animate().fadeIn().slideY(begin: -0.1),

        // Feature grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12,
              mainAxisSpacing: 12, childAspectRatio: 1.1,
            ),
            itemCount: _tiles.length,
            itemBuilder: (ctx, i) {
              final tile = _tiles[i];
              return _FeatureTile(tile: tile, index: i);
            },
          ),
        ),
      ]),
    );
  }
}

class _Tile {
  final String label, route;
  final IconData icon;
  final Color color;
  const _Tile(this.label, this.icon, this.color, this.route);
}

class _FeatureTile extends StatelessWidget {
  final _Tile tile;
  final int index;
  const _FeatureTile({required this.tile, required this.index});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pushNamed(context, tile.route),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tile.color, tile.color.withOpacity(0.7)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: tile.color.withOpacity(0.3),
                    blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(tile.icon, color: Colors.white, size: 36),
          Text(tile.label, style: const TextStyle(
            color: Colors.white, fontSize: 14,
            fontWeight: FontWeight.bold, height: 1.3,
          )),
        ]),
      ),
    ),
  ).animate().fadeIn(delay: Duration(milliseconds: index * 80))
   .slideY(begin: 0.3, duration: 400.ms, curve: Curves.easeOut);
}
