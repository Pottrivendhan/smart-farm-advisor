// lib/screens/market_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String _crop = 'Rice';
  String _district = kDistricts[0];
  int _month = DateTime.now().month;

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final res  = prov.marketResult;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(title: Text(prov.t('Market Price', 'சந்தை விலை'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // Input card
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              DropdownButtonFormField<String>(
                value: _crop,
                decoration: const InputDecoration(labelText: 'Crop / பயிர்',
                             prefixIcon: Icon(Icons.eco, color: AppColors.primary)),
                items: kCrops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _crop = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _district,
                decoration: const InputDecoration(labelText: 'District / மாவட்டம்',
                             prefixIcon: Icon(Icons.map, color: AppColors.primary)),
                items: kDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => setState(() => _district = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _month,
                decoration: const InputDecoration(labelText: 'Month / மாதம்',
                             prefixIcon: Icon(Icons.calendar_month, color: AppColors.primary)),
                items: List.generate(12, (i) =>
                    DropdownMenuItem(value: i + 1, child: Text(_months[i + 1]))),
                onChanged: (v) => setState(() => _month = v!),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: prov.status == AppStatus.loading ? null : () =>
                      prov.getMarketPrice(_crop, _district, _month),
                  icon: prov.status == AppStatus.loading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.show_chart),
                  label: Text(prov.t('Predict Price', 'விலை கணிக்க')),
                ),
              ),
            ]),
          )),

          // Results
          if (res != null) ...[
            const SizedBox(height: 16),

            // Price card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5C8C), Color(0xFF0077B6)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(children: [
                Text(prov.t('Predicted Price', 'கணிக்கப்பட்ட விலை'),
                     style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Text('₹${res.predictedPrice.toStringAsFixed(0)}',
                     style: const TextStyle(color: Colors.white,
                                            fontSize: 36, fontWeight: FontWeight.bold)),
                const Text('per quintal', style: TextStyle(color: Colors.white60)),
              ]),
            ).animate().fadeIn().scale(),

            const SizedBox(height: 12),

            // Recommendation
            Card(
              color: _recColor(res.recommendation).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _recColor(res.recommendation),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_recLabel(res.recommendation),
                                style: const TextStyle(color: Colors.white,
                                                        fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(res.reason,
                                      style: const TextStyle(fontSize: 13, height: 1.5))),
                ]),
              ),
            ).animate().fadeIn(delay: 200.ms),

            // 6-month trend chart
            const SizedBox(height: 16),
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('6-Month Price Trend',
                           style: TextStyle(fontWeight: FontWeight.bold,
                                            fontSize: 15, color: AppColors.primary)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(LineChartData(
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: Color(0xFFE0E0E0), strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true, reservedSize: 28,
                        getTitlesWidget: (v, _) {
                          final m = v.toInt();
                          return m >= 1 && m <= 12
                              ? Text(_months[m], style: const TextStyle(fontSize: 10))
                              : const SizedBox.shrink();
                        },
                      )),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [LineChartBarData(
                      spots: res.trend.map((t) =>
                          FlSpot((t['month'] as num).toDouble(),
                                 (t['price'] as num).toDouble())).toList(),
                      isCurved: true,
                      color: const Color(0xFF0077B6),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF0077B6).withOpacity(0.15),
                      ),
                    )],
                  )),
                ),
              ]),
            )).animate().fadeIn(delay: 300.ms),
          ],

          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Color _recColor(String r) => switch (r) {
    'SELL_NOW' => AppColors.success,
    'HOLD'     => AppColors.saffron,
    _          => AppColors.primaryLight,
  };

  String _recLabel(String r) => switch (r) {
    'SELL_NOW' => '📈 SELL NOW',
    'HOLD'     => '⏳ HOLD',
    _          => '↔ FLEXIBLE',
  };
}
