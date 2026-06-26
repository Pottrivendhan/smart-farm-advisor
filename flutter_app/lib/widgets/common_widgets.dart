// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';

// ── Section Header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const SectionHeader({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(
        fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary,
      )),
    ]),
  );
}

// ── Info Card ─────────────────────────────────────────────────────────────────
class InfoCard extends StatelessWidget {
  final String label, value;
  final Color? accentColor;
  final IconData? icon;
  const InfoCard({super.key, required this.label, required this.value,
                  this.accentColor, this.icon});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        if (icon != null) ...[
          Icon(icon, color: accentColor ?? AppColors.accent, size: 28),
          const SizedBox(width: 12),
        ],
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textGrey,
                                       fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold,
            color: accentColor ?? AppColors.textDark,
          )),
        ])),
      ]),
    ),
  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
}

// ── Confidence Bar ────────────────────────────────────────────────────────────
class ConfidenceBar extends StatelessWidget {
  final double value; // 0–1
  final String label;
  const ConfidenceBar({super.key, required this.value, this.label = ''});

  Color get _color {
    if (value >= 0.7) return AppColors.success;
    if (value >= 0.45) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        if (label.isNotEmpty)
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
        Text('${(value * 100).toStringAsFixed(1)}%',
             style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _color)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: value, minHeight: 10,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation(_color),
        ).animate().slideX(begin: -1, duration: 600.ms, curve: Curves.easeOut),
      ),
    ],
  );
}

// ── Advice Pill ───────────────────────────────────────────────────────────────
class AdvicePill extends StatelessWidget {
  final String advice;
  const AdvicePill({super.key, required this.advice});

  Color get _bg => switch (advice) {
    'GO'     => const Color(0xFFD8F3DC),
    'MODIFY' => const Color(0xFFFFF3CD),
    'AVOID'  => const Color(0xFFFDECEA),
    _        => Colors.grey.shade100,
  };
  Color get _fg => switch (advice) {
    'GO'     => const Color(0xFF1B4332),
    'MODIFY' => const Color(0xFF7D4E00),
    'AVOID'  => const Color(0xFFA50000),
    _        => Colors.black,
  };
  IconData get _icon => switch (advice) {
    'GO'     => Icons.check_circle,
    'MODIFY' => Icons.warning_amber,
    'AVOID'  => Icons.cancel,
    _        => Icons.info,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(_icon, color: _fg, size: 18),
      const SizedBox(width: 6),
      Text(advice, style: TextStyle(color: _fg, fontWeight: FontWeight.bold, fontSize: 15)),
    ]),
  ).animate().scale(duration: 300.ms);
}

// ── Soil Input Field ──────────────────────────────────────────────────────────
class NumericField extends StatelessWidget {
  final String label, unit;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  const NumericField({super.key, required this.label, required this.unit,
                      required this.value, required this.min, required this.max,
                      required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                            color: AppColors.primary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${value.toStringAsFixed(1)} $unit',
                      style: const TextStyle(fontWeight: FontWeight.bold,
                                             color: AppColors.primary, fontSize: 13)),
        ),
      ]),
      Slider(
        value: value, min: min, max: max,
        divisions: ((max - min) * 10).toInt(),
        activeColor: AppColors.primary,
        inactiveColor: AppColors.accent.withOpacity(0.3),
        onChanged: onChanged,
      ),
    ],
  );
}

// ── Loading Overlay ───────────────────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final String message;
  const LoadingOverlay({super.key, this.message = 'Analysing...'});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black45,
    child: Center(child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ]),
      ),
    )),
  );
}

// ── Offline Banner ────────────────────────────────────────────────────────────
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.warning,
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
    child: const Row(children: [
      Icon(Icons.wifi_off, color: Colors.white, size: 16),
      SizedBox(width: 8),
      Text('Offline AI Available', style: TextStyle(color: Colors.white,
                                                     fontWeight: FontWeight.w600)),
    ]),
  );
}

// ── Crop Rank Card ────────────────────────────────────────────────────────────
class CropRankCard extends StatelessWidget {
  final int rank;
  final String crop;
  final double confidence;
  const CropRankCard({super.key, required this.rank,
                      required this.crop, required this.confidence});

  static const _medals = ['🥇', '🥈', '🥉'];
  static const _colors = [Color(0xFFFFD700), Color(0xFFC0C0C0), Color(0xFFCD7F32)];

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _colors[rank - 1].withOpacity(0.5)),
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
    ),
    child: Row(children: [
      Text(_medals[rank - 1], style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(crop, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 6),
        ConfidenceBar(value: confidence),
      ])),
    ]),
  ).animate().fadeIn(delay: Duration(milliseconds: rank * 100)).slideX(begin: 0.2);
}
