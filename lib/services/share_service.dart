import 'package:share_plus/share_plus.dart';
import '../models/plant.dart';

class ShareService {
  static Future<void> sharePlant(Plant plant) async {
    String shareText = _buildPlantShareText(plant);
    await Share.share(shareText);
  }

  static Future<void> shareCollection(List<Plant> plants) async {
    String shareText = _buildCollectionShareText(plants);
    await Share.share(shareText);
  }

  static String _buildPlantShareText(Plant plant) {
    return '''
🌱 ${plant.name}

Вид: ${plant.species}
💵 Стоимость: ${plant.price} руб.
🎯 Сложность ухода: ${plant.careLevel}
💡 Требования к свету: ${plant.lightRequirements}
💧 Полив: каждые ${plant.wateringFrequency} дней

${plant.notes != null ? '📝 Примечания: ${plant.notes}' : ''}

Поделено из приложения "Моя коллекция растений" 🌿
''';
  }

  static String _buildCollectionShareText(List<Plant> plants) {
    String plantsText = plants.map((plant) => 
      '• ${plant.name} (${plant.species}) - ${plant.price} руб.'
    ).join('\n');
    
    return '''
🏡 Моя коллекция растений

Общее количество: ${plants.length} растений
Общая стоимость: ${_calculateTotalPrice(plants)} руб.

Растения:
$plantsText

Поделено из приложения "Моя коллекция растений" 🌿
''';
  }

  static double _calculateTotalPrice(List<Plant> plants) {
    return plants.fold(0.0, (sum, plant) => sum + plant.price);
  }
}