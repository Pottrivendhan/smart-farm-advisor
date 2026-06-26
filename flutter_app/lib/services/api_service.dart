// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../utils/constants.dart';

class ApiService {
  static final ApiService _i = ApiService._();
  factory ApiService() => _i;
  ApiService._();

  final _client = http.Client();
  static const _timeout = Duration(seconds: 15);

  // ── Generic helpers ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await _client
        .post(Uri.parse('$kBaseUrl$path'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body))
        .timeout(_timeout);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('API error ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await _client
        .get(Uri.parse('$kBaseUrl$path'))
        .timeout(_timeout);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('API error ${res.statusCode}');
  }

  // ── Connectivity check ───────────────────────────────────────────────────
  Future<bool> isOnline() async {
    try {
      final res = await _client
          .get(Uri.parse('$kBaseUrl/'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Full advisory (single call) ──────────────────────────────────────────
  Future<FullAdvisory> getFullAdvisory(SoilInput inp, {int? farmerId}) async {
    final body = inp.toJson();
    if (farmerId != null) body['farmer_id'] = farmerId;
    final json = await _post('/full_advisory', body);
    return FullAdvisory.fromJson(json);
  }

  // ── Crop prediction ──────────────────────────────────────────────────────
  Future<CropResult> predictCrop(SoilInput inp) async {
    final j = await _post('/predict_crop', inp.toJson());
    return CropResult.fromJson(j);
  }

  // ── Fertilizer ───────────────────────────────────────────────────────────
  Future<FertilizerResult> getFertilizer(String crop,
      {double? budgetCap, double acres = 1.0}) async {
    final j = await _post('/fertilizer_plan', {
      'crop': crop,
      if (budgetCap != null && budgetCap > 0) 'budget_cap': budgetCap,
      'acres': acres,
    });
    return FertilizerResult.fromJson(j);
  }

  // ── Water advisory ───────────────────────────────────────────────────────
  Future<WaterResult> getWaterAdvisory(
      String crop, double rainfall, double humidity) async {
    final j = await _post('/water_check',
        {'crop': crop, 'rainfall': rainfall, 'humidity': humidity});
    return WaterResult.fromJson(j);
  }

  // ── Weather ──────────────────────────────────────────────────────────────
  Future<WeatherData> getWeather(String district) async {
    final j = await _get('/weather/${Uri.encodeComponent(district)}');
    return WeatherData.fromJson(j);
  }

  // ── Market price ─────────────────────────────────────────────────────────
  Future<MarketResult> getMarketPrice(
      String crop, String district, int month, {int? farmerId}) async {
    final j = await _post('/market_price', {
      'crop': crop, 'district': district, 'month': month,
      if (farmerId != null) 'farmer_id': farmerId,
    });
    return MarketResult.fromJson(j);
  }

  // ── Disease detection ────────────────────────────────────────────────────
 Future<DiseaseResult> detectDisease(File imageFile, {int? farmerId}) async {
  print("===== DETECT DISEASE =====");
  print("URL: $kBaseUrl/detect_disease");
  print("Image Path: ${imageFile.path}");
  print("Farmer ID: $farmerId");

  final req = http.MultipartRequest(
    'POST',
    Uri.parse('$kBaseUrl/detect_disease'),
  );

  if (farmerId != null) {
    req.fields['farmer_id'] = farmerId.toString();
  }

  req.files.add(
    await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
    ),
  );

  print("Sending request...");

  final streamed = await req.send().timeout(_timeout);

  print("Status Code: ${streamed.statusCode}");

  final res = await http.Response.fromStream(streamed);

  print("Response:");
  print(res.body);

  if (res.statusCode == 200) {
    return DiseaseResult.fromJson(jsonDecode(res.body));
  }

  throw Exception('Disease detection failed: ${res.body}');
}
  // ── Districts ─────────────────────────────────────────────────────────────
  Future<List<String>> getDistricts() async {
    final j = await _get('/districts');
    return List<String>.from(j['districts']);
  }

  // ── Farmer management ────────────────────────────────────────────────────
  Future<int> createFarmer(Farmer farmer) async {
    final j = await _post('/farmer', farmer.toJson());
    return j['farmer_id'];
  }

  Future<Farmer?> getFarmer(int id) async {
    try {
      final j = await _get('/farmer/$id');
      return Farmer.fromJson(j);
    } catch (_) { return null; }
  }

  Future<List<Farmer>> listFarmers() async {
    final j = await _get('/farmers');
    return (j as List? ?? []).map((e) => Farmer.fromJson(e)).toList();
  }

  // ── History ──────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getHistory(int farmerId) async {
    final j = await _get('/history/$farmerId');
    return (j as List<dynamic>)
    .map((e) => Map<String, dynamic>.from(e))
    .toList();
  }

  // ── PDF report ───────────────────────────────────────────────────────────
  Future<List<int>> generateReport({
    required String farmerName,
    required String district,
    required Map<String, dynamic> soil,
    required Map<String, dynamic> weather,
    required Map<String, dynamic> cropResult,
    required Map<String, dynamic> fertilizerResult,
    required Map<String, dynamic> waterResult,
    required Map<String, dynamic> summary,
    Map<String, dynamic>? diseaseResult,
  }) async {
    final res = await _client
        .post(Uri.parse('$kBaseUrl/generate_report'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'farmer_name': farmerName, 'district': district,
                'soil': soil, 'weather': weather,
                'crop_result': cropResult, 'fertilizer_result': fertilizerResult,
                'water_result': waterResult, 'summary': summary,
                if (diseaseResult != null) 'disease_result': diseaseResult,
              }))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) return res.bodyBytes;
    throw Exception('Report generation failed');
  }
}
