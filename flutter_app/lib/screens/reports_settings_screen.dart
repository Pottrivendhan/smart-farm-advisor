// lib/screens/reports_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _generating = false;

  Future<void> _generateAndOpen(AppProvider prov, {bool share = false}) async {
    final adv = prov.advisory;
    if (adv == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please get a recommendation first')));
      return;
    }
    setState(() => _generating = true);
    try {
      final inp     = prov.soilInput;
      final farmer  = prov.currentFarmer;
      final weather = prov.weather;

      final bytes = await ApiService().generateReport(
        farmerName:       farmer?.name ?? 'Farmer',
        district:         inp.district,
        soil:             {'N': inp.n, 'P': inp.p, 'K': inp.k, 'pH': inp.ph},
        weather:          {
          'Temperature': '${inp.temperature}°C',
          'Humidity':    '${inp.humidity}%',
          'Rainfall':    '${inp.rainfall} mm',
          if (weather != null) 'Source': weather.source,
        },
        cropResult: {
          'best_crop':   adv.crop.bestCrop,
          'confidence':  adv.crop.confidence,
          'explanation': adv.crop.explanation,
          'alternatives': adv.crop.alternatives,
          'top_crops':   adv.crop.topCrops,
          'top_factors': adv.crop.topFactors,
        },
        fertilizerResult: {
          'crop':          adv.fertilizer.crop,
          'npk_target':    adv.fertilizer.npkTarget,
          'fertilizer_mix': {
            'urea_kg': adv.fertilizer.ureaKg,
            'dap_kg':  adv.fertilizer.dapKg,
            'mop_kg':  adv.fertilizer.mopKg,
          },
          'cost_per_acre': adv.fertilizer.costPerAcre,
          'note':          adv.fertilizer.note,
        },
        waterResult: {
          'advice': adv.water.advice,
          'reason': adv.water.reason,
          'rainfall_range': adv.water.rainfallRange,
        },
        summary:        Map<String, dynamic>.from(adv.summary),
        diseaseResult:  prov.diseaseResult != null ? {
          'disease':    prov.diseaseResult!.disease,
          'confidence': prov.diseaseResult!.confidence,
          'severity':   prov.diseaseResult!.severity,
          'treatment':  prov.diseaseResult!.treatment,
          'prevention': prov.diseaseResult!.prevention,
        } : null,
      );

      final dir  = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/farm_report.pdf');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      if (share) {
        await Share.shareXFiles([XFile(file.path)], text: 'My Farm Advisory Report');
      } else {
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
    setState(() => _generating = false);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final adv  = prov.advisory;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(title: Text(prov.t('Reports', 'அறிக்கைகள்'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          if (adv == null)
            Card(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const Icon(Icons.description_outlined,
                           size: 48, color: AppColors.accent),
                const SizedBox(height: 12),
                Text(prov.t(
                  'No advisory available. Please get a recommendation first.',
                  'ஆலோசனை இல்லை. முதலில் பரிந்துரை பெறவும்.',
                ), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/soil_input'),
                  child: const Text('Go to Soil Input'),
                ),
              ]),
            ))
          else ...[
            // Summary preview
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Latest Advisory',
                           style: TextStyle(fontWeight: FontWeight.bold,
                                            fontSize: 16, color: AppColors.primary)),
                const Divider(),
                _row('Crop', adv.crop.bestCrop),
                _row('Confidence', '${(adv.crop.confidence * 100).toStringAsFixed(1)}%'),
                _row('Water Advisory', adv.water.advice),
                _row('Urea', '${adv.fertilizer.ureaKg.toStringAsFixed(1)} kg/acre'),
                _row('DAP', '${adv.fertilizer.dapKg.toStringAsFixed(1)} kg/acre'),
                _row('MOP', '${adv.fertilizer.mopKg.toStringAsFixed(1)} kg/acre'),
                _row('Cost', '₹${adv.fertilizer.costPerAcre.toStringAsFixed(0)}/acre'),
              ]),
            )).animate().fadeIn(),

            const SizedBox(height: 16),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generating ? null : () => _generateAndOpen(prov),
                icon: _generating
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf),
                label: Text(prov.t('Download PDF Report', 'PDF அறிக்கை பதிவிறக்க')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _generating ? null : () => _generateAndOpen(prov, share: true),
                icon: const Icon(Icons.share),
                label: Text(prov.t('Share via WhatsApp', 'வாட்ஸ்அப்பில் பகிர்')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF25D366),
                  side: const BorderSide(color: Color(0xFF25D366)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],

          // History placeholder
          const SizedBox(height: 24),
          const SectionHeader(title: 'Recommendation History', icon: Icons.history),
          _HistoryList(),
        ]),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text('$k:', style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
      const SizedBox(width: 8),
      Text(v, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );
}

class _HistoryList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final fid  = prov.currentFarmer?.id;
    if (fid == null) return const SizedBox.shrink();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiService().getHistory(fid),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(padding: EdgeInsets.all(16),
                               child: CircularProgressIndicator());
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Padding(padding: EdgeInsets.all(16),
                               child: Text('No history yet'));
        }
        return ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final h = items[i];
            return Card(child: ListTile(
              leading: const Icon(Icons.eco, color: AppColors.primary),
              title: Text(h['best_crop'] ?? ''),
              subtitle: Text('${h['district'] ?? ''} · ${h['created_at']?.toString().substring(0, 10) ?? ''}'),
              trailing: Text('${((h['confidence'] as num?) ?? 0) * 100 ~/ 1}%',
                             style: const TextStyle(fontWeight: FontWeight.bold,
                                                    color: AppColors.primary)),
            ));
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// lib/screens/settings_screen.dart
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final f    = prov.currentFarmer;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(title: Text(prov.t('Settings', 'அமைப்புகள்'))),
      body: ListView(children: [
        const SizedBox(height: 16),

        // Farmer profile
        if (f != null) Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Farmer Profile',
                         style: TextStyle(fontWeight: FontWeight.bold,
                                          fontSize: 15, color: AppColors.primary)),
              const Divider(),
              _row(Icons.person, 'Name', f.name),
              _row(Icons.phone, 'Phone', f.phone.isEmpty ? '—' : f.phone),
              _row(Icons.map, 'District', f.district),
              _row(Icons.location_on, 'Village', f.village.isEmpty ? '—' : f.village),
              _row(Icons.landscape, 'Farm Size', '${f.acres} acres'),
            ]),
          ),
        ),

        // Language toggle
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SwitchListTile(
            value: prov.isTamil,
            onChanged: (_) => prov.toggleLanguage(),
            secondary: const Icon(Icons.language, color: AppColors.primary),
            title: const Text('Tamil Language Mode'),
            subtitle: Text(prov.isTamil ? 'தமிழ் இயக்கத்தில் உள்ளது' : 'English mode active'),
            activeColor: AppColors.primary,
          ),
        ),

        // API URL info
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('API Connection',
                         style: TextStyle(fontWeight: FontWeight.bold,
                                          fontSize: 15, color: AppColors.primary)),
              const SizedBox(height: 8),
              Row(children: [
                Icon(prov.isOnline ? Icons.wifi : Icons.wifi_off,
                     color: prov.isOnline ? AppColors.success : AppColors.danger),
                const SizedBox(width: 8),
                Text(prov.isOnline ? 'Connected to API' : 'Offline mode'),
              ]),
              const SizedBox(height: 8),
              const Text('API URL: http://10.0.2.2:8000',
                         style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
              const Text('Edit lib/utils/constants.dart to change',
                         style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
            ]),
          ),
        ),

        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Smart Farm Advisor v2.0\nAI-powered Tamil Nadu Farming Assistant',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _row(IconData icon, String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.accent),
      const SizedBox(width: 10),
      Text('$label: ', style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
      Expanded(child: Text(val, style: const TextStyle(fontWeight: FontWeight.w600,
                                                        fontSize: 13))),
    ]),
  );
}
