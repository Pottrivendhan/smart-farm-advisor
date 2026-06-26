// lib/providers/app_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';

enum AppStatus { idle, loading, success, error }

class AppProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // ── State ─────────────────────────────────────────────────────────────────
  AppStatus status = AppStatus.idle;
  String errorMsg  = '';
  bool isOnline    = true;
  bool isTamil     = false;

  // ── Farmer ────────────────────────────────────────────────────────────────
  Farmer? currentFarmer;

  // ── Inputs ────────────────────────────────────────────────────────────────
  SoilInput soilInput = SoilInput();

  // ── Results ───────────────────────────────────────────────────────────────
  FullAdvisory?  advisory;
  DiseaseResult? diseaseResult;
  MarketResult?  marketResult;
  WeatherData?   weather;

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isTamil = prefs.getBool('isTamil') ?? false;
    final farmerId = prefs.getInt('farmer_id');
    if (farmerId != null) {
      currentFarmer = await _api.getFarmer(farmerId);
    }
    isOnline = await _api.isOnline();
    notifyListeners();
  }

  // ── Language toggle ───────────────────────────────────────────────────────
  Future<void> toggleLanguage() async {
    isTamil = !isTamil;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTamil', isTamil);
    notifyListeners();
  }

  String t(String en, String ta) => isTamil ? ta : en;

  // ── Farmer ────────────────────────────────────────────────────────────────
  Future<void> saveFarmer(Farmer farmer) async {
    final id = await _api.createFarmer(farmer);
    currentFarmer = Farmer(
      id: id, name: farmer.name, phone: farmer.phone,
      district: farmer.district, village: farmer.village, acres: farmer.acres,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('farmer_id', id);
    notifyListeners();
  }

  // ── Weather auto-fetch ────────────────────────────────────────────────────
  Future<void> fetchWeather(String district) async {
    try {
      weather = await _api.getWeather(district);
      soilInput.temperature = weather!.temperature;
      soilInput.humidity    = weather!.humidity.toDouble();
      soilInput.rainfall    = weather!.rainfall;
      notifyListeners();
    } catch (e) {
      // Silently fail — user can enter manually
    }
  }

  // ── Full advisory ─────────────────────────────────────────────────────────
  Future<void> getAdvisory() async {
    _setLoading();
    try {
      isOnline = await _api.isOnline();
      if (!isOnline) {
        _setError('No internet. Showing cached results.');
        return;
      }
      advisory = await _api.getFullAdvisory(
        soilInput, farmerId: currentFarmer?.id,
      );
      status = AppStatus.success;
    } catch (e) {
      _setError(e.toString());
    }
    notifyListeners();
  }

  // ── Disease detection ─────────────────────────────────────────────────────
  Future<void> detectDisease(dynamic imageFile) async {
    _setLoading();
    try {
      diseaseResult = await _api.detectDisease(
        imageFile, farmerId: currentFarmer?.id,
      );
      status = AppStatus.success;
    } catch (e) {
      _setError(e.toString());
    }
    notifyListeners();
  }

  // ── Market price ──────────────────────────────────────────────────────────
  Future<void> getMarketPrice(String crop, String district, int month) async {
    _setLoading();
    try {
      marketResult = await _api.getMarketPrice(
        crop, district, month, farmerId: currentFarmer?.id,
      );
      status = AppStatus.success;
    } catch (e) {
      _setError(e.toString());
    }
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _setLoading() {
    status = AppStatus.loading;
    errorMsg = '';
    notifyListeners();
  }

  void _setError(String msg) {
    status = AppStatus.error;
    errorMsg = msg;
    notifyListeners();
  }

  void reset() {
    status = AppStatus.idle;
    advisory = null;
    diseaseResult = null;
    marketResult = null;
    notifyListeners();
  }
}
