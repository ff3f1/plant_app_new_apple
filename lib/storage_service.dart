import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'plant.dart';

class StorageService {
  static const String _plantsKey = 'saved_plants';
  static const String _premiumKey = 'is_premium';

  // Сохраняем список растений
  static Future<void> savePlants(List<Plant> plants) async {
    final prefs = await SharedPreferences.getInstance();
    final plantsJson = plants.map((plant) => jsonEncode(plant.toMap())).toList();
    await prefs.setStringList(_plantsKey, plantsJson);
  }

  // Загружаем список растений
  static Future<List<Plant>> loadPlants() async {
    final prefs = await SharedPreferences.getInstance();
    final plantsJson = prefs.getStringList(_plantsKey) ?? [];
    
    final plants = plantsJson.map((jsonString) {
      try {
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        return Plant.fromMap(map);
      } catch (e) {
        print('Ошибка загрузки растения: $e');
        return null;
      }
    }).where((plant) => plant != null).cast<Plant>().toList();
    
    return plants;
  }

  // Сохраняем статус премиума
  static Future<void> savePremiumStatus(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, isPremium);
  }

  // Загружаем статус премиума
  static Future<bool> loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }

  // Очистка всех данных (для тестирования)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_plantsKey);
    await prefs.remove(_premiumKey);
  }
}