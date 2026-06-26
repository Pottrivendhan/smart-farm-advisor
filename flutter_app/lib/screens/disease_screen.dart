// lib/screens/disease_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';
import 'package:flutter/foundation.dart';

class DiseaseScreen extends StatefulWidget {
  const DiseaseScreen({super.key});
  @override State<DiseaseScreen> createState() => _DiseaseScreenState();
}

class _DiseaseScreenState extends State<DiseaseScreen> {
  File? _image;
  final _picker = ImagePicker();

  Future<void> _pick(ImageSource src) async {
  print("STEP 1: Opening picker");

  final xf = await _picker.pickImage(
    source: src,
    imageQuality: 75,
  );

  if (xf == null) {
    print("STEP 2: No image selected");
    return;
  }

  print("STEP 3: Image selected");
  print(xf.path);

  setState(() {
    _image = File(xf.path);
  });

  if (!mounted) return;

  print("STEP 4: Calling detectDisease");

  try {
    await context.read<AppProvider>().detectDisease(_image!);
    print("STEP 5: detectDisease completed");
  } catch (e) {
    print("ERROR:");
    print(e);
  }

  print("STEP 6: Finished");
}

  Color _severityColor(String s) => switch (s.toLowerCase()) {
    'none'     => AppColors.success,
    'low'      => const Color(0xFF8BC34A),
    'moderate' => AppColors.warning,
    'high'     => AppColors.danger,
    _          => AppColors.textGrey,
  };

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final dis  = prov.diseaseResult;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(prov.t('Disease Detection', 'நோய் கண்டறிதல்')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // Upload card
          GestureDetector(
            onTap: () => _showSourceSheet(),
            child: Container(
              width: double.infinity, height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent, width: 2,
                                   style: BorderStyle.solid),
              ),
              child: _image == null
                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.add_photo_alternate,
                               size: 52, color: AppColors.accent),
                    const SizedBox(height: 12),
                    Text(prov.t('Tap to upload leaf photo', 'இலை படம் பதிவேற்றவும்'),
                         style: const TextStyle(color: AppColors.textGrey, fontSize: 15)),
                    const SizedBox(height: 4),
                    const Text('Camera or Gallery',
                               style: TextStyle(color: AppColors.accent, fontSize: 13)),
                  ])
                : ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: kIsWeb
        ? Image.network(
            _image!.path,
            fit: BoxFit.cover,
            width: double.infinity,
          )
        : Image.file(
            _image!,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
  ),
),
).animate().fadeIn(),

          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: Text(prov.t('Camera', 'கேமரா')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: Text(prov.t('Gallery', 'கேலரி')),
              ),
            ),
          ]),

          // Loading
          if (prov.status == AppStatus.loading) ...[
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 8),
            Text(prov.t('Analysing leaf...', 'இலை பரிசோதிக்கிறது...')),
          ],

          // Results
          if (dis != null) ...[
            const SizedBox(height: 20),

            // Disease name + confidence
            Card(
              color: dis.disease == 'Healthy'
                  ? const Color(0xFFD8F3DC) : const Color(0xFFFDECEA),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Icon(
                    dis.disease == 'Healthy' ? Icons.check_circle : Icons.warning,
                    size: 42,
                    color: dis.disease == 'Healthy' ? AppColors.success : AppColors.danger,
                  ),
                  const SizedBox(height: 8),
                  Text(dis.disease, style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold,
                  )),
                  const SizedBox(height: 8),
                  ConfidenceBar(value: dis.confidence, label: 'Confidence'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _severityColor(dis.severity),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Severity: ${dis.severity}',
                                style: const TextStyle(color: Colors.white,
                                                        fontWeight: FontWeight.bold)),
                  ),
                ]),
              ),
            ).animate().fadeIn().scale(),

            // Top predictions
            if (dis.topPredictions.length > 1) ...[
              const SizedBox(height: 12),
              Card(child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('All Predictions',
                             style: TextStyle(fontWeight: FontWeight.bold,
                                              color: AppColors.primary)),
                  const SizedBox(height: 10),
                  ...dis.topPredictions.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ConfidenceBar(
                      value: (p['confidence'] as num).toDouble(),
                      label: p['disease'].toString(),
                    ),
                  )),
                ]),
              )),
            ],

            if (dis.disease != 'Healthy') ...[
              // Treatment
              _infoCard(Icons.medical_services, 'Treatment / சிகிச்சை',
                        dis.treatment, AppColors.primary),
              // Prevention
              _infoCard(Icons.shield, 'Prevention / தடுப்பு',
                        dis.prevention, AppColors.saffron),
            ],
          ],

          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  void _showSourceSheet() => showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.camera_alt),
                 title: const Text('Camera'),
                 onTap: () { Navigator.pop(context); _pick(ImageSource.camera); }),
        ListTile(leading: const Icon(Icons.photo_library),
                 title: const Text('Gallery'),
                 onTap: () { Navigator.pop(context); _pick(ImageSource.gallery); }),
      ]),
    ),
  );

  Widget _infoCard(IconData icon, String title, String text, Color color) =>
    Card(child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold,
                                       color: color, fontSize: 14)),
        ]),
        const SizedBox(height: 8),
        Text(text, style: const TextStyle(height: 1.6, fontSize: 13)),
      ]),
    )).animate().fadeIn(delay: 200.ms);
}
