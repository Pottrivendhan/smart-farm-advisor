// lib/screens/crop_result_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class CropResultScreen extends StatelessWidget {
  const CropResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final adv  = prov.advisory;
    if (adv == null) {
      return const Scaffold(body: Center(child: Text('No results yet')));
    }
    final crop  = adv.crop;
    final fert  = adv.fertilizer;
    final water = adv.water;
    final summ  = adv.summary;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          title: Text(prov.t('Advisory Results', 'ஆலோசனை முடிவுகள்')),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: AppColors.saffron,
            tabs: [
              Tab(text: prov.t('Crop', 'பயிர்')),
              Tab(text: prov.t('Fertilizer', 'உரம்')),
              Tab(text: prov.t('Water', 'நீர்')),
              Tab(text: prov.t('Summary', 'சுருக்கம்')),
            ],
          ),
        ),
        body: TabBarView(children: [
          // ── TAB 1: Crop ────────────────────────────────────────────────────
          _cropTab(context, prov, crop),
          // ── TAB 2: Fertilizer ─────────────────────────────────────────────
          _fertTab(context, prov, fert),
          // ── TAB 3: Water ──────────────────────────────────────────────────
          _waterTab(context, prov, water),
          // ── TAB 4: Summary ────────────────────────────────────────────────
          _summaryTab(context, prov, summ),
        ]),

        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.saffron,
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          label: Text(prov.t('Download PDF', 'PDF பதிவிறக்க'),
                      style: const TextStyle(color: Colors.white)),
          onPressed: () => Navigator.pushNamed(context, '/reports'),
        ),
      ),
    );
  }

  Widget _cropTab(BuildContext ctx, AppProvider prov, dynamic crop) =>
    ListView(padding: const EdgeInsets.all(16), children: [
      // Best crop hero card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(children: [
          const Icon(Icons.eco, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(crop.bestCrop, style: const TextStyle(
            color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 8),
          ConfidenceBar(value: crop.confidence),
        ]),
      ).animate().fadeIn().scale(),
      const SizedBox(height: 20),

      // Top 3 crops
      Text(prov.t('Top 3 Recommendations', 'சிறந்த 3 பரிந்துரைகள்'),
           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                                   color: AppColors.primary)),
      const SizedBox(height: 10),
      ...crop.topCrops.asMap().entries.map((e) =>
        CropRankCard(rank: e.key + 1, crop: e.value['crop'],
                     confidence: (e.value['confidence'] as num).toDouble())),

      // Key factors
      const SizedBox(height: 16),
      Text(prov.t('Key Decision Factors', 'முக்கிய காரணிகள்'),
           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                                   color: AppColors.primary)),
      const SizedBox(height: 10),
      ...crop.topFactors.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ConfidenceBar(
          value: (f['importance'] as num).toDouble(),
          label: f['feature'].toString().toUpperCase(),
        ),
      )),

      // Explanation
      Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.lightbulb, color: AppColors.saffron),
            SizedBox(width: 8),
            Text('Why this crop?',
                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const SizedBox(height: 8),
          Text(crop.explanation, style: const TextStyle(height: 1.5)),
        ]),
      )),

      // Alternatives
      const SizedBox(height: 12),
      Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.swap_horiz, color: AppColors.primaryLight),
            const SizedBox(width: 8),
            Text(prov.t('If Rainfall Drops', 'மழை குறைந்தால்'),
                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: crop.alternatives.map<Widget>((a) =>
            Chip(label: Text(a.toString()),
                 backgroundColor: AppColors.accent.withOpacity(0.15),
                 labelStyle: const TextStyle(color: AppColors.primary,
                                              fontWeight: FontWeight.w600)),
          ).toList()),
        ]),
      )),
    ]);

  Widget _fertTab(BuildContext ctx, AppProvider prov, dynamic fert) =>
    ListView(padding: const EdgeInsets.all(16), children: [
      _fertCard('Urea', fert.ureaKg, '46% N', Icons.science,
                const Color(0xFF2196F3)),
      _fertCard('DAP', fert.dapKg, '18% N + 46% P', Icons.science,
                const Color(0xFF4CAF50)),
      _fertCard('MOP', fert.mopKg, '60% K', Icons.science,
                const Color(0xFFFF9800)),

      Card(
        color: AppColors.primary,
        child: ListTile(
          leading: const Icon(Icons.currency_rupee, color: Colors.white, size: 28),
          title: Text(prov.t('Cost per Acre', 'செலவு / ஏக்கர்'),
                      style: const TextStyle(color: Colors.white70)),
          trailing: Text('₹${fert.costPerAcre.toStringAsFixed(0)}',
                         style: const TextStyle(color: Colors.white,
                                                 fontSize: 22, fontWeight: FontWeight.bold)),
        ),
      ),
      if (fert.note != null) ...[
        const SizedBox(height: 8),
        Card(
          color: const Color(0xFFFFF8E1),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const Icon(Icons.info_outline, color: AppColors.saffron),
              const SizedBox(width: 10),
              Expanded(child: Text(fert.note!, style: const TextStyle(height: 1.5))),
            ]),
          ),
        ),
      ],

      const SizedBox(height: 16),
      Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('NPK Target (per acre)',
                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                                      color: AppColors.primary)),
          const SizedBox(height: 10),
          _npkRow('N', fert.npkTarget['N'] ?? 0),
          _npkRow('P', fert.npkTarget['P'] ?? 0),
          _npkRow('K', fert.npkTarget['K'] ?? 0),
        ]),
      )),
    ]);

  Widget _fertCard(String name, double kg, String label,
                   IconData icon, Color color) =>
    Card(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        CircleAvatar(backgroundColor: color.withOpacity(0.15),
                     child: Icon(icon, color: color)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        ])),
        Text('${kg.toStringAsFixed(1)} kg',
             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ]),
    )).animate().fadeIn().slideX(begin: 0.2);

  Widget _npkRow(String label, dynamic val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Container(width: 28, height: 28,
        decoration: BoxDecoration(
          color: AppColors.primary, borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(color: Colors.white,
                                                    fontWeight: FontWeight.bold)),
      ),
      const SizedBox(width: 10),
      Text('$val kg/acre',
           style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
    ]),
  );

  Widget _waterTab(BuildContext ctx, AppProvider prov, dynamic water) =>
    ListView(padding: const EdgeInsets.all(16), children: [
      Center(child: AdvicePill(advice: water.advice)),
      const SizedBox(height: 20),
      Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Advisory Reason',
                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                                      color: AppColors.primary)),
          const SizedBox(height: 10),
          Text(water.reason, style: const TextStyle(height: 1.6, fontSize: 14)),
        ]),
      )),
      if (water.rainfallRange.isNotEmpty)
        Card(
          color: AppColors.accent.withOpacity(0.1),
          child: ListTile(
            leading: const Icon(Icons.water_drop, color: AppColors.accent),
            title: const Text('Ideal Rainfall Range'),
            trailing: Text(water.rainfallRange,
                           style: const TextStyle(fontWeight: FontWeight.bold,
                                                   color: AppColors.primary)),
          ),
        ),
    ]);

  Widget _summaryTab(BuildContext ctx, AppProvider prov, Map<String, String> summ) =>
    ListView(padding: const EdgeInsets.all(16), children: [
      _summaryCard('English Summary', summ['english_summary'] ?? '',
                   Icons.translate, AppColors.primary),
      const SizedBox(height: 12),
      _summaryCard('தமிழ் சுருக்கம்', summ['tamil_summary'] ?? '',
                   Icons.language, AppColors.saffron),
    ]);

  Widget _summaryCard(String title, String text, IconData icon, Color color) =>
    Card(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold,
                                       fontSize: 15, color: color)),
        ]),
        const Divider(height: 16),
        Text(text, style: const TextStyle(height: 1.7, fontSize: 14)),
      ]),
    )).animate().fadeIn();
}
