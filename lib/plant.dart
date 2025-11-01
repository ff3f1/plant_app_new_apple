class Plant {
  int? id;
  String name;
  String species;
  double price;
  DateTime purchaseDate;
  DateTime? plantingDate;
  String? repottingReason;
  List<String> imagePaths;
  String? notes;
  bool isFavorite;
  String careLevel;
  String lightRequirements;
  int wateringFrequency;
  bool wateringEnabled;
  DateTime? lastWateringDate;
  bool get isWateringActive => wateringEnabled && lastWateringDate != null;

  void toggleWatering() {
    wateringEnabled = !wateringEnabled;
    if (wateringEnabled) {
      lastWateringDate = DateTime.now();
    } else {
      lastWateringDate = null;
    }
  }

  void waterNow() {
    if (!wateringEnabled) {
      wateringEnabled = true;
    }
    lastWateringDate = DateTime.now();
  }
}
  Plant({
    this.id,
    required this.name,
    required this.species,
    required this.price,
    required this.purchaseDate,
    this.plantingDate,
    this.repottingReason,
    required this.imagePaths,
    this.notes,
    this.isFavorite = false,
    this.careLevel = 'Средняя',
    this.lightRequirements = 'Рассеянный свет',
    this.wateringFrequency = 7,
    this.wateringEnabled = false,
    this.lastWateringDate,
  });

  String? get mainImage => imagePaths.isNotEmpty ? imagePaths[0] : null;
  List<String> get additionalImages => imagePaths.length > 1 ? imagePaths.sublist(1) : [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'price': price,
      'purchaseDate': purchaseDate.toIso8601String(),
      'plantingDate': plantingDate?.toIso8601String(),
      'repottingReason': repottingReason,
      'imagePaths': imagePaths.join('|||'),
      'notes': notes,
      'isFavorite': isFavorite,
      'careLevel': careLevel,
      'lightRequirements': lightRequirements,
      'wateringFrequency': wateringFrequency,
      'wateringEnabled': wateringEnabled,
      'lastWateringDate': lastWateringDate?.toIso8601String(),
    };
  }

  factory Plant.fromMap(Map<String, dynamic> map) {
    // Обработка списка изображений
    List<String> images = [];
    if (map['imagePaths'] != null) {
      if (map['imagePaths'] is String) {
        images = map['imagePaths'].toString().split('|||');
      } else if (map['imagePaths'] is List) {
        images = List<String>.from(map['imagePaths']);
      }
    }

    // Обработка дат
    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      try {
        return DateTime.parse(date.toString());
      } catch (e) {
        return null;
      }
    }

    return Plant(
      id: map['id'],
      name: map['name'] ?? 'Без названия',
      species: map['species'] ?? 'Не указан',
      price: (map['price'] is int ? (map['price'] as int).toDouble() : map['price']) ?? 0.0,
      purchaseDate: parseDate(map['purchaseDate']) ?? DateTime.now(),
      plantingDate: parseDate(map['plantingDate']),
      repottingReason: map['repottingReason'],
      imagePaths: images,
      notes: map['notes'],
      isFavorite: map['isFavorite'] ?? false,
      careLevel: map['careLevel'] ?? 'Средняя',
      lightRequirements: map['lightRequirements'] ?? 'Рассеянный свет',
      wateringFrequency: map['wateringFrequency'] ?? 7,
      wateringEnabled: map['wateringEnabled'] ?? false,
      lastWateringDate: parseDate(map['lastWateringDate']),
    );
  }

  DateTime? get nextWatering {
    if (!wateringEnabled || lastWateringDate == null) return null;
    return lastWateringDate!.add(Duration(days: wateringFrequency));
  }

  bool get needsWatering {
    if (!wateringEnabled || nextWatering == null) return false;
    return DateTime.now().isAfter(nextWatering!);
  }
  
  int get daysUntilWatering {
    if (!wateringEnabled || nextWatering == null) return 0;
    final now = DateTime.now();
    final next = nextWatering!;
    final difference = next.difference(now).inDays;
    return difference < 0 ? 0 : difference;
  }

  String get healthStatus {
    if (!wateringEnabled) return 'normal';
    if (needsWatering) return 'needs_water';
    if (daysUntilWatering < 2) return 'thirsty';
    return 'healthy';
  }
}