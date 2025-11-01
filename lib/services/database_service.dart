import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'premium_service.dart'; // импортируем ваш существующий сервис

class DonationService {
  static const String _activeCodesKey = 'active_premium_codes';
  static const String _usedCodesKey = 'used_premium_codes';
  
  static String generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }
  
  static Future<void> saveGeneratedCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final activeCodes = await getActiveCodes();
    activeCodes.add(code);
    await prefs.setStringList(_activeCodesKey, activeCodes);
  }
  
  static Future<List<String>> getActiveCodes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_activeCodesKey) ?? [];
  }
  
  static Future<List<String>> getUsedCodes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_usedCodesKey) ?? [];
  }
  
  static Future<ActivationResult> activatePremiumWithCode(String code) async {
    if (code.isEmpty) {
      return ActivationResult(false, 'Введите код активации');
    }
    
    final activeCodes = await getActiveCodes();
    final usedCodes = await getUsedCodes();
    
    if (usedCodes.contains(code)) {
      return ActivationResult(false, 'Этот код уже был использован');
    }
    
    if (activeCodes.contains(code)) {
      await PremiumService.activatePremium();
      
      activeCodes.remove(code);
      usedCodes.add(code);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_activeCodesKey, activeCodes);
      await prefs.setStringList(_usedCodesKey, usedCodes);
      
      return ActivationResult(true, '🎉 Premium успешно активирован!');
    }
    
    return ActivationResult(false, 'Неверный код активации');
  }
  
  static Future<CodeStats> getCodeStats() async {
    final activeCodes = await getActiveCodes();
    final usedCodes = await getUsedCodes();
    return CodeStats(
      activeCount: activeCodes.length,
      usedCount: usedCodes.length,
      totalGenerated: activeCodes.length + usedCodes.length,
    );
  }
}

class ActivationResult {
  final bool success;
  final String message;
  
  ActivationResult(this.success, this.message);
}

class CodeStats {
  final int activeCount;
  final int usedCount;
  final int totalGenerated;
  
  CodeStats({
    required this.activeCount,
    required this.usedCount,
    required this.totalGenerated,
  });
}