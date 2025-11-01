import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

class PremiumService {
  static const String _premiumKey = 'is_premium';
  static const String _purchaseDateKey = 'purchase_date';
  
  static const int maxFreePlants = 10;
  
  static Future<bool> get isPremium async {
    return await StorageService.loadPremiumStatus();
  }
  
  static Future<void> activatePremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, true);
    await prefs.setString(_purchaseDateKey, DateTime.now().toIso8601String());
    await StorageService.savePremiumStatus(true);
  }
  
  static Future<void> resetPremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, false);
    await prefs.remove(_purchaseDateKey);
    await StorageService.savePremiumStatus(false);
  }
  
  static Future<bool> canAddPlant(int currentCount) async {
    final premium = await isPremium;
    return premium || currentCount < maxFreePlants;
  }
  
  static Future<int> getRemainingPlants(int currentCount) async {
    final premium = await isPremium;
    if (premium) return 999;
    return maxFreePlants - currentCount;
  }
}