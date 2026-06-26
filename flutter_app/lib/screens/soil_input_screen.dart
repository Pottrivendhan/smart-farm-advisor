// lib/screens/soil_input_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class SoilInputScreen extends StatefulWidget {
  const SoilInputScreen({super.key});
  @override State<SoilInputScreen> createState() => _SoilInputScreenState();
}

class _SoilInputScreenState extends State<SoilInputScreen> {
  final _speech = stt.SpeechToText();
  bool _listening = false;
  bool _fetchingWeather = false;

  Future<void> _startVoice(AppProvider prov) async {
    bool avail = await _speech.initialize(
      onStatus: (s) { if (s == 'done') setState(() => _listening = false); },
      onError:  (_) => setState(() => _listening = false),
    );
    if (!avail) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone not available')));
      return;
    }
    setState(() => _listening = true);
    _speech.listen(
      localeId: prov.isTamil ? 'ta_IN' : 'en_IN',
      onResult: (r) {
        final text = r.recognizedWords.toLowerCase();
        // Parse district
        for (final d in kDistricts) {
          if (text.contains(d.toLowerCase())) {
            setState(() => prov.soilInput.district = d);
            break;
          }
        }
        // Parse numbers like "nitrogen 80"
        final nMatch = RegExp(r'nitrogen\s*(\d+)').firstMatch(text);
        if (nMatch != null) prov.soilInput.n = double.tryParse(nMatch.group(1)!) ?? prov.soilInput.n;
        final pMatch = RegExp(r'phosphorus\s*(\d+)').firstMatch(text);
        if (pMatch != null) prov.soilInput.p = double.tryParse(pMatch.group(1)!) ?? prov.soilInput.p;
        setState(() {});
      },
    );
  }

  Future<void> _fetchWeather(AppProvider prov) async {
    setState(() => _fetchingWeather = true);
    await prov.fetchWeather(prov.soilInput.district);
    setState(() => _fetchingWeather = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(
        prov.weather != null
            ? 'Weather fetched: ${prov.weather!.temperature}°C'
            : 'Using seasonal averages',
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final inp  = prov.soilInput;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(prov.t('Soil & Crop Input', 'மண் & பயிர் தகவல்')),
        actions: [
          IconButton(
            icon: Icon(_listening ? Icons.mic : Icons.mic_none,
                       color: _listening ? Colors.red : Colors.white),
            tooltip: prov.t('Voice Input', 'குரல் உள்ளீடு'),
            onPressed: () => _startVoice(prov),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // District + soil type
          _sectionCard(
            prov.t('Location & Soil Type', 'இடம் & மண் வகை'),
            Icons.map, [
              _dropdown('District / மாவட்டம்', inp.district, kDistricts,
                        (v) => setState(() => inp.district = v!)),
              const SizedBox(height: 12),
              _dropdown('Soil Type / மண் வகை', inp.soilType, kSoilTypes,
                        (v) => setState(() => inp.soilType = v!)),
            ],
          ),

          // Soil nutrients
          _sectionCard(
            prov.t('Soil Nutrients (kg/ha)', 'மண் ஊட்டச்சத்துக்கள்'),
            Icons.biotech, [
              NumericField(label: 'Nitrogen (N)', unit: 'kg/ha',
                           value: inp.n, min: 0, max: 200,
                           onChanged: (v) => setState(() => inp.n = v)),
              NumericField(label: 'Phosphorus (P)', unit: 'kg/ha',
                           value: inp.p, min: 0, max: 200,
                           onChanged: (v) => setState(() => inp.p = v)),
              NumericField(label: 'Potassium (K)', unit: 'kg/ha',
                           value: inp.k, min: 0, max: 200,
                           onChanged: (v) => setState(() => inp.k = v)),
              NumericField(label: 'Soil pH', unit: '',
                           value: inp.ph, min: 3.5, max: 9.5,
                           onChanged: (v) => setState(() => inp.ph = v)),
            ],
          ),

          // Weather
          _sectionCard(
            prov.t('Weather Conditions', 'வானிலை நிலை'),
            Icons.cloud, [
              OutlinedButton.icon(
                onPressed: _fetchingWeather ? null : () => _fetchWeather(prov),
                icon: _fetchingWeather
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download),
                label: Text(prov.t('Auto-fetch Weather', 'வானிலை தானாக பெறு')),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
              ),
              const SizedBox(height: 12),
              NumericField(label: 'Temperature (°C)', unit: '°C',
                           value: inp.temperature, min: 5, max: 50,
                           onChanged: (v) => setState(() => inp.temperature = v)),
              NumericField(label: 'Humidity (%)', unit: '%',
                           value: inp.humidity, min: 10, max: 100,
                           onChanged: (v) => setState(() => inp.humidity = v)),
              NumericField(label: 'Rainfall (mm/month)', unit: 'mm',
                           value: inp.rainfall, min: 0, max: 500,
                           onChanged: (v) => setState(() => inp.rainfall = v)),
            ],
          ),

          // Budget & acres
          _sectionCard(
            prov.t('Farm Details', 'பண்ணை விவரங்கள்'),
            Icons.agriculture, [
              NumericField(label: 'Farm Size (acres)', unit: 'ac',
                           value: inp.acres, min: 0.5, max: 100,
                           onChanged: (v) => setState(() => inp.acres = v)),
              NumericField(label: 'Budget Cap (₹/acre)', unit: '₹',
                           value: inp.budgetCap, min: 0, max: 20000,
                           onChanged: (v) => setState(() => inp.budgetCap = v)),
            ],
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: prov.status == AppStatus.loading ? null : () async {
                await prov.getAdvisory();
                if (!mounted) return;
                if (prov.status == AppStatus.success) {
                  Navigator.pushNamed(context, '/crop_result');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(prov.errorMsg), backgroundColor: Colors.red));
                }
              },
              icon: prov.status == AppStatus.loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.agriculture),
              label: Text(prov.t('Get Recommendation', 'பரிந்துரை பெற'),
                          style: const TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.saffron,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _sectionCard(String title, IconData icon, List<Widget> children) =>
    Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary,
            )),
          ]),
          const Divider(height: 20),
          ...children,
        ]),
      ),
    );

  Widget _dropdown(String label, String value, List<String> items,
                   ValueChanged<String?> onChanged) =>
    DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
      onChanged: onChanged,
    );
}
