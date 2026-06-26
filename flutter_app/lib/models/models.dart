// lib/models/models.dart
// All data models for the Smart Farm Advisor app

class Farmer {
  final int? id;
  final String name;
  final String phone;
  final String district;
  final String village;
  final double acres;

  Farmer({this.id, required this.name, this.phone = '',
          this.district = '', this.village = '', this.acres = 1.0});

  factory Farmer.fromJson(Map<String, dynamic> j) => Farmer(
    id: j['id'], name: j['name'], phone: j['phone'] ?? '',
    district: j['district'] ?? '', village: j['village'] ?? '',
    acres: (j['acres'] ?? 1.0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'name': name, 'phone': phone, 'district': district,
    'village': village, 'acres': acres,
  };
}

class SoilInput {
  double n, p, k, ph, temperature, humidity, rainfall;
  String district, soilType;
  double budgetCap, acres;

  SoilInput({
    this.n = 80, this.p = 40, this.k = 40, this.ph = 6.0,
    this.temperature = 25, this.humidity = 70, this.rainfall = 100,
    this.district = 'Chennai', this.soilType = 'Red Soil',
    this.budgetCap = 0, this.acres = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'N': n, 'P': p, 'K': k, 'pH': ph,
    'temperature': temperature, 'humidity': humidity, 'rainfall': rainfall,
    'district': district, 'soil_type': soilType,
  };
}

class CropResult {
  final String bestCrop;
  final double confidence;
  final List<Map<String, dynamic>> topCrops;
  final List<String> alternatives;
  final List<Map<String, dynamic>> topFactors;
  final String explanation;

  CropResult({
    required this.bestCrop, required this.confidence,
    required this.topCrops, required this.alternatives,
    required this.topFactors, required this.explanation,
  });

  factory CropResult.fromJson(Map<String, dynamic> j) => CropResult(
    bestCrop:    j['best_crop'] ?? '',
    confidence:  (j['confidence'] ?? 0).toDouble(),
    topCrops:    List<Map<String, dynamic>>.from(j['top_crops'] ?? []),
    alternatives: List<String>.from(j['alternatives'] ?? []),
    topFactors:  List<Map<String, dynamic>>.from(j['top_factors'] ?? []),
    explanation: j['explanation'] ?? '',
  );
}

class FertilizerResult {
  final String crop;
  final Map<String, dynamic> npkTarget;
  final double ureaKg, dapKg, mopKg;
  final double costPerAcre;
  final String? note;

  FertilizerResult({
    required this.crop, required this.npkTarget,
    required this.ureaKg, required this.dapKg, required this.mopKg,
    required this.costPerAcre, this.note,
  });

  factory FertilizerResult.fromJson(Map<String, dynamic> j) {
    final mix = j['fertilizer_mix'] ?? {};
    return FertilizerResult(
      crop: j['crop'] ?? '',
      npkTarget: Map<String, dynamic>.from(j['npk_target'] ?? {}),
      ureaKg: (mix['urea_kg'] ?? 0).toDouble(),
      dapKg:  (mix['dap_kg']  ?? 0).toDouble(),
      mopKg:  (mix['mop_kg']  ?? 0).toDouble(),
      costPerAcre: (j['cost_per_acre'] ?? 0).toDouble(),
      note: j['note'],
    );
  }
}

class WaterResult {
  final String advice, reason;
  final String rainfallRange;

  WaterResult({required this.advice, required this.reason, this.rainfallRange = ''});

  factory WaterResult.fromJson(Map<String, dynamic> j) => WaterResult(
    advice: j['advice'] ?? 'GO',
    reason: j['reason'] ?? '',
    rainfallRange: j['rainfall_range'] ?? '',
  );
}

class DiseaseResult {
  final String disease, severity, treatment, prevention;
  final double confidence;
  final List<Map<String, dynamic>> topPredictions;

  DiseaseResult({
    required this.disease, required this.severity,
    required this.treatment, required this.prevention,
    required this.confidence, required this.topPredictions,
  });

  factory DiseaseResult.fromJson(Map<String, dynamic> j) => DiseaseResult(
    disease:    j['disease'] ?? '',
    severity:   j['severity'] ?? '',
    treatment:  j['treatment'] ?? '',
    prevention: j['prevention'] ?? '',
    confidence: (j['confidence'] ?? 0).toDouble(),
    topPredictions: List<Map<String, dynamic>>.from(j['top_predictions'] ?? []),
  );
}

class MarketResult {
  final String crop, district, recommendation, reason;
  final int month;
  final double predictedPrice;
  final List<Map<String, dynamic>> trend;

  MarketResult({
    required this.crop, required this.district,
    required this.recommendation, required this.reason,
    required this.month, required this.predictedPrice,
    required this.trend,
  });

  factory MarketResult.fromJson(Map<String, dynamic> j) => MarketResult(
    crop: j['crop'] ?? '', district: j['district'] ?? '',
    recommendation: j['recommendation'] ?? '',
    reason: j['reason'] ?? '',
    month: j['month'] ?? 1,
    predictedPrice: (j['predicted_price'] ?? 0).toDouble(),
    trend: List<Map<String, dynamic>>.from(j['trend'] ?? []),
  );
}

class WeatherData {
  final double temperature, rainfall;
  final int humidity;
  final String source, description;

  WeatherData({
    required this.temperature, required this.rainfall,
    required this.humidity, this.source = '', this.description = '',
  });

  factory WeatherData.fromJson(Map<String, dynamic> j) => WeatherData(
    temperature: (j['temperature'] ?? 25).toDouble(),
    rainfall:    (j['rainfall'] ?? 80).toDouble(),
    humidity:    (j['humidity'] ?? 70).toInt(),
    source:      j['source'] ?? '',
    description: j['description'] ?? '',
  );
}

class FullAdvisory {
  final CropResult crop;
  final FertilizerResult fertilizer;
  final WaterResult water;
  final Map<String, String> summary;

  FullAdvisory({
    required this.crop, required this.fertilizer,
    required this.water, required this.summary,
  });

  factory FullAdvisory.fromJson(Map<String, dynamic> j) => FullAdvisory(
    crop:       CropResult.fromJson(j['crop']),
    fertilizer: FertilizerResult.fromJson(j['fertilizer']),
    water:      WaterResult.fromJson(j['water']),
    summary:    Map<String, String>.from(j['summary'] ?? {}),
  );
}
