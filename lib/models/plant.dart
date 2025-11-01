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
  DateTime? lastWateringDate;

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
    this.lastWateringDate,
  });

  // УДАЛЯЕМ поля уведомлений из toMap и fromMap
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
      'isFavorite': isFavorite ? 1 : 0,
      'careLevel': careLevel,
      'lightRequirements': lightRequirements,
      'wateringFrequency': wateringFrequency,
      'lastWateringDate': lastWateringDate?.toIso8601String(),
    };
  }

  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'],
      name: map['name'],
      species: map['species'],
      price: map['price'],
      purchaseDate: DateTime.parse(map['purchaseDate']),
      plantingDate: map['plantingDate'] != null ? DateTime.parse(map['plantingDate']) : null,
      repottingReason: map['repottingReason'],
      imagePaths: map['imagePaths']?.toString().split('|||') ?? [],
      notes: map['notes'],
      isFavorite: map['isFavorite'] == 1,
      careLevel: map['careLevel'] ?? 'Средняя',
      lightRequirements: map['lightRequirements'] ?? 'Рассеянный свет',
      wateringFrequency: map['wateringFrequency'] ?? 7,
      lastWateringDate: map['lastWateringDate'] != null ? DateTime.parse(map['lastWateringDate']) : null,
    );
  }

  // Остальные геттеры остаются
  String? get mainImage => imagePaths.isNotEmpty ? imagePaths[0] : null;
  List<String> get additionalImages => imagePaths.length > 1 ? imagePaths.sublist(1) : [];
  DateTime get nextWatering {
    final lastWatering = lastWateringDate ?? purchaseDate;
    return lastWatering.add(Duration(days: wateringFrequency));
  }
  bool get needsWatering => DateTime.now().isAfter(nextWatering);
  int get daysUntilWatering {
    final now = DateTime.now();
    final next = nextWatering;
    final difference = next.difference(now).inDays;
    return difference < 0 ? 0 : difference;
  }
}