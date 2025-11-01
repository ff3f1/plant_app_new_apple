// lib/main.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

/// ----------------- MyApp / Theme -----------------
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Plants',
      theme: _buildNeonTheme(),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildNeonTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Color(0xFF0A0A0A),
      primaryColor: Color(0xFF00F5FF),
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF00F5FF),
        secondary: Color(0xFF00FF88),
        tertiary: Color(0xFFFF0080),
        surface: Color(0xFF1A1A1A),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: Color(0xFF00F5FF)),
      ),
    );
  }
}

/// ----------------- Model: Plant & Wishlist -----------------
class Plant {
  String id;
  String name;
  String species;
  String type;
  double price;
  DateTime purchaseDate;
  DateTime? plantingDate; // NEW: дата посадки
  List<String> imagePaths;
  String? notes;
  bool isFavorite;
  String careLevel;
  String lightRequirements;
  int wateringFrequency;
  bool wateringEnabled;
  DateTime? lastWateringDate;

  // Fertilizer fields (NEW)
  DateTime? lastFertilizerDate; // последняя дата внесения удобрений
  bool fertilizerEnabled; // показывать напоминания
  int fertilizerFrequency; // интервал в днях, по умолчанию 14

  // Новые поля
  String location; // где стоит: "Кухня", "Окно", и т.д.
  String humidityPreference; // "Низкая", "Средняя", "Высокая"

  Plant({
    required this.id,
    required this.name,
    required this.species,
    required this.type,
    required this.price,
    required this.purchaseDate,
    this.plantingDate,
    required this.imagePaths,
    this.notes,
    this.isFavorite = false,
    this.careLevel = 'Средняя',
    this.lightRequirements = 'Рассеянный свет',
    this.wateringFrequency = 7,
    this.wateringEnabled = false,
    this.lastWateringDate,
    this.lastFertilizerDate,
    this.fertilizerEnabled = false,
    this.fertilizerFrequency = 14,
    this.location = 'Комната',
    this.humidityPreference = 'Средняя',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'type': type,
      'price': price,
      'purchaseDate': purchaseDate.toIso8601String(),
      'plantingDate': plantingDate?.toIso8601String(),
      'imagePaths': imagePaths,
      'notes': notes,
      'isFavorite': isFavorite,
      'careLevel': careLevel,
      'lightRequirements': lightRequirements,
      'wateringFrequency': wateringFrequency,
      'wateringEnabled': wateringEnabled,
      'lastWateringDate': lastWateringDate?.toIso8601String(),
      'lastFertilizerDate': lastFertilizerDate?.toIso8601String(),
      'fertilizerEnabled': fertilizerEnabled,
      'fertilizerFrequency': fertilizerFrequency,
      'location': location,
      'humidityPreference': humidityPreference,
    };
  }

  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: map['name'] ?? 'Без названия',
      species: map['species'] ?? 'Не указан',
      type: map['type'] ?? 'Комнатное',
      price: (map['price'] ?? 0).toDouble(),
      purchaseDate: DateTime.parse(map['purchaseDate'] ?? DateTime.now().toIso8601String()),
      plantingDate: map['plantingDate'] != null ? DateTime.tryParse(map['plantingDate']) : null,
      imagePaths: List<String>.from(map['imagePaths'] ?? []),
      notes: map['notes'],
      isFavorite: map['isFavorite'] ?? false,
      careLevel: map['careLevel'] ?? 'Средняя',
      lightRequirements: map['lightRequirements'] ?? 'Рассеянный свет',
      wateringFrequency: map['wateringFrequency'] ?? 7,
      wateringEnabled: map['wateringEnabled'] ?? false,
      lastWateringDate: map['lastWateringDate'] != null ? DateTime.tryParse(map['lastWateringDate']) : null,
      lastFertilizerDate: map['lastFertilizerDate'] != null ? DateTime.tryParse(map['lastFertilizerDate']) : null,
      fertilizerEnabled: map['fertilizerEnabled'] ?? false,
      fertilizerFrequency: map['fertilizerFrequency'] ?? 14,
      location: map['location'] ?? 'Комната',
      humidityPreference: map['humidityPreference'] ?? 'Средняя',
    );
  }

  bool get needsWatering {
    if (!wateringEnabled || lastWateringDate == null) return false;
    final nextWatering = lastWateringDate!.add(Duration(days: wateringFrequency));
    return DateTime.now().isAfter(nextWatering);
  }

  // NEW: определяет, нужно ли напоминание об удобрении (с марта по сентябрь)
  bool needsFertilizerReminder() {
    if (!fertilizerEnabled) return false;
    final now = DateTime.now();
    final month = now.month;
    // активный сезон: март (3) .. сентябрь (9)
    if (month < 3 || month > 9) return false;
    // если никогда не вносили — напоминаем
    if (lastFertilizerDate == null) return true;
    final next = lastFertilizerDate!.add(Duration(days: fertilizerFrequency));
    return now.isAfter(next) || now.isAtSameMomentAs(next);
  }
}

class WishlistItem {
  String id;
  String name;
  String species;
  String type;
  double estimatedPrice;
  String notes;
  int priority;

  WishlistItem({
    required this.id,
    required this.name,
    required this.species,
    required this.type,
    this.estimatedPrice = 0,
    this.notes = '',
    this.priority = 3,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'type': type,
      'estimatedPrice': estimatedPrice,
      'notes': notes,
      'priority': priority,
    };
  }

  factory WishlistItem.fromMap(Map<String, dynamic> map) {
    return WishlistItem(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: map['name'] ?? '',
      species: map['species'] ?? '',
      type: map['type'] ?? 'Комнатное',
      estimatedPrice: (map['estimatedPrice'] ?? 0).toDouble(),
      notes: map['notes'] ?? '',
      priority: map['priority'] ?? 3,
    );
  }
}

/// ----------------- StorageService -----------------
class StorageService {
  static const String _plantsKey = 'saved_plants';
  static const String _wishlistKey = 'wishlist_items';

  static Future<void> savePlants(List<Plant> plants) async {
    final prefs = await SharedPreferences.getInstance();
    final plantsJson = plants.map((plant) => jsonEncode(plant.toMap())).toList();
    await prefs.setStringList(_plantsKey, plantsJson);
  }

  static Future<List<Plant>> loadPlants() async {
    final prefs = await SharedPreferences.getInstance();
    final plantsJson = prefs.getStringList(_plantsKey) ?? [];

    return plantsJson.map((jsonString) {
      try {
        final map = jsonDecode(jsonString);
        return Plant.fromMap(map);
      } catch (e) {
        return Plant(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Ошибка загрузки',
          species: 'Ошибка',
          type: 'Комнатное',
          price: 0,
          purchaseDate: DateTime.now(),
          imagePaths: [],
        );
      }
    }).toList();
  }

  static Future<void> saveWishlist(List<WishlistItem> wishlist) async {
    final prefs = await SharedPreferences.getInstance();
    final wishlistJson = wishlist.map((item) => jsonEncode(item.toMap())).toList();
    await prefs.setStringList(_wishlistKey, wishlistJson);
  }

  static Future<List<WishlistItem>> loadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final wishlistJson = prefs.getStringList(_wishlistKey) ?? [];

    return wishlistJson.map((jsonString) {
      try {
        final map = jsonDecode(jsonString);
        return WishlistItem.fromMap(map);
      } catch (e) {
        return WishlistItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Ошибка загрузки',
          species: 'Ошибка',
          type: 'Комнатное',
        );
      }
    }).toList();
  }
}

/// ----------------- HomeScreen and UI -----------------
enum SortMode { name, priceAsc, priceDesc, species, date }

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Plant> plants = [];
  List<WishlistItem> wishlist = [];
  bool _isLoading = true;
  late TabController _tabController;

  // UI state
  SortMode _sortMode = SortMode.name;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  void _loadInitialData() async {
    final loadedPlants = await StorageService.loadPlants();
    final loadedWishlist = await StorageService.loadWishlist();

    setState(() {
      plants = loadedPlants;
      wishlist = loadedWishlist;
      _isLoading = false;
    });

    // Покажем уведомление в приложении если есть растения, требующие удобрений
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFertilizerSummaryIfNeeded();
    });
  }

  void _showFertilizerSummaryIfNeeded() {
    final needs = plants.where((p) => p.needsFertilizerReminder()).toList();
    if (needs.isNotEmpty) {
      final cnt = needs.length;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Напоминание: $cnt растений требуют удобрения (сезон Мар–Сен).'),
        duration: Duration(seconds: 4),
        backgroundColor: Color(0xFF333333),
      ));
    }
  }

  void _savePlants() async {
    await StorageService.savePlants(plants);
  }

  void _saveWishlist() async {
    await StorageService.saveWishlist(wishlist);
  }

  void _addPlant() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPlantScreen()),
    );

    if (result != null && result is Plant) {
      setState(() {
        plants.add(result);
      });
      _savePlants();
    }
  }

  void _editPlant(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPlantScreen(plant: plants[index])),
    );

    if (result != null && result is Plant) {
      setState(() {
        plants[index] = result;
      });
      _savePlants();
    }
  }

  void _deletePlant(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text('Удалить растение?', style: TextStyle(color: Colors.white)),
        content: Text('Вы уверены, что хотите удалить ${plants[index].name}?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                plants.removeAt(index);
              });
              _savePlants();
              Navigator.pop(context);
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addWishlistItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditWishlistScreen()),
    );

    if (result != null && result is WishlistItem) {
      setState(() {
        wishlist.add(result);
      });
      _saveWishlist();
    }
  }

  void _editWishlistItem(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditWishlistScreen(item: wishlist[index])),
    );

    if (result != null && result is WishlistItem) {
      setState(() {
        wishlist[index] = result;
      });
      _saveWishlist();
    }
  }

  void _deleteWishlistItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text('Удалить из списка желаний?', style: TextStyle(color: Colors.white)),
        content: Text('Вы уверены, что хотите удалить ${wishlist[index].name}?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                wishlist.removeAt(index);
              });
              _saveWishlist();
              Navigator.pop(context);
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openSupportScreen() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Row(
          children: [
            Icon(Icons.favorite, color: Colors.red),
            SizedBox(width: 8),
            Text('Поддержать разработчика', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Если вам нравится приложение:', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 16),
            _buildDonationMethod('Карта', '2200 7019 5422 7812', Icons.credit_card),
            SizedBox(height: 16),
            Text('Спасибо! 💚', style: TextStyle(color: Color(0xFF00FF88))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Закрыть', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationMethod(String title, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF252525),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF00F5FF), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white, fontSize: 12)),
                SizedBox(height: 4),
                SelectableText(value, style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- новые полезные методы статистики ---
  double totalCollectionValue() {
    return plants.fold(0.0, (sum, p) => sum + p.price);
  }

  double averagePrice() {
    if (plants.isEmpty) return 0;
    return totalCollectionValue() / plants.length;
  }

  Map<String, int> countsBySpecies() {
    final Map<String, int> map = {};
    for (var p in plants) {
      map[p.species] = (map[p.species] ?? 0) + 1;
    }
    return map;
  }

  List<Plant> _getFilteredAndSortedPlants() {
    List<Plant> list = plants.where((p) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.species.toLowerCase().contains(q) ||
          p.type.toLowerCase().contains(q) ||
          p.location.toLowerCase().contains(q);
    }).toList();

    switch (_sortMode) {
      case SortMode.name:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortMode.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortMode.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortMode.species:
        list.sort((a, b) => a.species.toLowerCase().compareTo(b.species.toLowerCase()));
        break;
      case SortMode.date:
        list.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
        break;
    }
    return list;
  }

  String _formatDateShort(DateTime? dt) {
    if (dt == null) return '—';
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  // UI
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF00F5FF)),
              SizedBox(height: 20),
              Text('Загрузка...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.eco, color: Color(0xFF00FF88)),
            SizedBox(width: 8),
            Text('Neon Plants'),
          ],
        ),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.eco), text: 'Растения'),
            Tab(icon: Icon(Icons.favorite), text: 'Желания'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'Советы'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: _openSupportScreen,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlantsTab(),
          _buildWishlistTab(),
          _buildTipsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _addPlant();
          } else if (_tabController.index == 1) {
            _addWishlistItem();
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Color(0xFF00F5FF),
      ),
    );
  }

  Widget _buildPlantsTab() {
    final filtered = _getFilteredAndSortedPlants();

    return Column(
      children: [
        // Статистика и фильтры
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Color(0xFF0E0E0E),
            border: Border(bottom: BorderSide(color: Color(0xFF222222))),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSearchField(),
                  ),
                  SizedBox(width: 8),
                  _buildSortButton(),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  _buildStatCard('Всего', '${totalCollectionValue().toStringAsFixed(0)}₽'),
                  SizedBox(width: 8),
                  _buildStatCard('Средняя', '${averagePrice().toStringAsFixed(0)}₽'),
                  SizedBox(width: 8),
                  _buildStatCard('Растений', '${plants.length}'),
                ],
              ),
              SizedBox(height: 10),
              // График: количества по видам
              Container(
                height: 100,
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SpeciesBarChart(data: countsBySpecies()),
              ),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty ? _buildEmptyPlantsState() : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final plant = filtered[index];
              final originalIndex = plants.indexWhere((p) => p.id == plant.id);
              return AnimatedContainer(
                duration: Duration(milliseconds: 250),
                margin: EdgeInsets.only(bottom: 12),
                child: Card(
                  color: Color(0xFF121212),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: plant.imagePaths.isNotEmpty
                        ? CircleAvatar(
                            radius: 28,
                            backgroundImage: FileImage(File(plant.imagePaths.first)),
                          )
                        : CircleAvatar(
                            radius: 28,
                            child: Icon(Icons.eco, color: Color(0xFF00F5FF)),
                            backgroundColor: Color(0xFF252525),
                          ),
                    title: Text(plant.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plant.species, style: TextStyle(color: Color(0xFF00F5FF))),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.place, size: 14, color: Colors.white54),
                            SizedBox(width: 6),
                            Text(plant.location, style: TextStyle(color: Colors.white70, fontSize: 12)),
                            SizedBox(width: 12),
                            Icon(Icons.opacity, size: 14, color: Colors.white54),
                            SizedBox(width: 6),
                            Text(plant.humidityPreference, style: TextStyle(color: Colors.white70, fontSize: 12)),
                            SizedBox(width: 8),
                            // Fertilizer indicator: show small icon when needs fertilizer
                            if (plant.needsFertilizerReminder())
                              Row(
                                children: [
                                  SizedBox(width: 8),
                                  Icon(Icons.grass, size: 14, color: Colors.orangeAccent),
                                  SizedBox(width: 4),
                                  Text('Нужно удобрить', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (plant.needsWatering)
                          Icon(Icons.water_drop, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.edit, color: Color(0xFF00F5FF)),
                          onPressed: () => _editPlant(originalIndex),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePlant(originalIndex),
                        ),
                      ],
                    ),
                    onTap: () => _showPlantDetails(plant),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Поиск по имени, виду, местоположению...',
        hintStyle: TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Color(0xFF0D0D0D),
        prefixIcon: Icon(Icons.search, color: Colors.white54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: (v) {
        setState(() {
          _searchQuery = v;
        });
      },
    );
  }

  Widget _buildSortButton() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: PopupMenuButton<SortMode>(
        tooltip: 'Сортировка',
        padding: EdgeInsets.zero,
        icon: Icon(Icons.sort, color: Colors.white),
        onSelected: (mode) {
          setState(() {
            _sortMode = mode;
          });
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: SortMode.name, child: Text('По имени')),
          PopupMenuItem(value: SortMode.priceAsc, child: Text('По цене (возр.)')),
          PopupMenuItem(value: SortMode.priceDesc, child: Text('По цене (убыв.)')),
          PopupMenuItem(value: SortMode.species, child: Text('По виду')),
          PopupMenuItem(value: SortMode.date, child: Text('По дате покупки')),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.white70, fontSize: 12)),
            SizedBox(height: 6),
            Text(value, style: TextStyle(color: Color(0xFF00F5FF), fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlantsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Color(0xFF052B2A),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(Icons.eco, size: 60, color: Color(0xFF00F5FF)),
          ),
          SizedBox(height: 20),
          Text('Нет растений', style: TextStyle(color: Colors.white, fontSize: 20)),
          SizedBox(height: 10),
          Text('Нажмите + чтобы добавить', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildWishlistTab() {
    if (wishlist.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 100, color: Colors.red.withOpacity(0.5)),
            SizedBox(height: 20),
            Text('Список желаний пуст', style: TextStyle(color: Colors.white, fontSize: 20)),
            SizedBox(height: 10),
            Text('Нажмите + чтобы добавить', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: wishlist.length,
      itemBuilder: (context, index) {
        final item = wishlist[index];
        return Card(
          color: Color(0xFF1A1A1A),
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(Icons.eco, color: Color(0xFF00FF88)),
              backgroundColor: Color(0xFF252525),
            ),
            title: Text(item.name, style: TextStyle(color: Colors.white)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.species, style: TextStyle(color: Color(0xFF00F5FF))),
                if (item.estimatedPrice > 0)
                  Text('~${item.estimatedPrice.toInt()}₽', style: TextStyle(color: Colors.white70)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: item.priority >= 4 ? Colors.orange : Colors.white54, size: 20),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.edit, color: Color(0xFF00F5FF)),
                  onPressed: () => _editWishlistItem(index),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteWishlistItem(index),
                ),
              ],
            ),
            onTap: () => _editWishlistItem(index),
          ),
        );
      },
    );
  }

  Widget _buildTipsTab() {
    return TipsScreen();
  }

  void _showPlantDetails(Plant plant) {
    showModalBottomSheet(
      backgroundColor: Color(0xFF0A0A0A),
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, ctrl) => SingleChildScrollView(
          controller: ctrl,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _PlantDetail(plant: plant, onUpdate: (updated) {
              final idx = plants.indexWhere((p) => p.id == updated.id);
              if (idx >= 0) {
                setState(() {
                  plants[idx] = updated;
                });
                _savePlants();
              }
            }),
          ),
        ),
      ),
    );
  }
}

/// ----------------- SpeciesBarChart (unchanged) -----------------
class SpeciesBarChart extends StatelessWidget {
  final Map<String, int> data;

  const SpeciesBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(child: Text('Нет данных', style: TextStyle(color: Colors.white54)));
    }
    // Ограничим топ-6 видов
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();
    return LayoutBuilder(builder: (context, constraints) {
      return CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: _SpeciesBarChartPainter(top),
      );
    });
  }
}

class _SpeciesBarChartPainter extends CustomPainter {
  final List<MapEntry<String, int>> data;
  _SpeciesBarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final maxVal = data.map((e) => e.value).fold<int>(0, (prev, e) => max(prev, e));
    final barWidth = size.width / (data.length * 1.6);

    for (int i = 0; i < data.length; i++) {
      final x = i * (barWidth * 1.6) + 8;
      final h = maxVal == 0 ? 0.0 : (data[i].value / maxVal) * (size.height - 24);
      // gradient-like color by index
      final t = i / max(1, data.length - 1);
      final color = Color.lerp(Color(0xFF00F5FF), Color(0xFF00FF88), t) ?? Color(0xFF00F5FF);
      paint.color = color;
      final rect = Rect.fromLTWH(x, size.height - h - 16, barWidth, h);
      final r = RRect.fromRectAndRadius(rect, Radius.circular(6));
      canvas.drawRRect(r, paint);

      // label
      final label = data[i].key.length > 8 ? data[i].key.substring(0, 8) + '…' : data[i].key;
      textPainter.text = TextSpan(text: label, style: TextStyle(color: Colors.white70, fontSize: 10));
      textPainter.layout(minWidth: 0, maxWidth: barWidth + 10);
      textPainter.paint(canvas, Offset(x - 2, size.height - 14));
    }
  }

  @override
  bool shouldRepaint(covariant _SpeciesBarChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

/// ----------------- EditPlantScreen (updated) -----------------
class EditPlantScreen extends StatefulWidget {
  final Plant? plant;

  const EditPlantScreen({this.plant});

  @override
  _EditPlantScreenState createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends State<EditPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  String _type = 'Комнатное';
  String _careLevel = 'Средняя';
  String _lightRequirements = 'Рассеянный свет';
  int _wateringFrequency = 7;
  bool _wateringEnabled = false;
  List<String> _imagePaths = [];

  // новые
  String _location = 'Комната';
  String _humidityPreference = 'Средняя';

  // NEW: purchaseDate & plantingDate & fertilizer settings
  DateTime _purchaseDate = DateTime.now();
  DateTime? _plantingDate;
  bool _fertilizerEnabled = false;
  int _fertilizerFrequency = 14;
  DateTime? _lastFertilizerDate;

  @override
  void initState() {
    super.initState();
    if (widget.plant != null) {
      _nameController.text = widget.plant!.name;
      _speciesController.text = widget.plant!.species;
      _priceController.text = widget.plant!.price.toString();
      _notesController.text = widget.plant!.notes ?? '';
      _type = widget.plant!.type;
      _careLevel = widget.plant!.careLevel;
      _lightRequirements = widget.plant!.lightRequirements;
      _wateringFrequency = widget.plant!.wateringFrequency;
      _wateringEnabled = widget.plant!.wateringEnabled;
      _imagePaths = List.from(widget.plant!.imagePaths);
      _location = widget.plant!.location;
      _humidityPreference = widget.plant!.humidityPreference;

      _purchaseDate = widget.plant!.purchaseDate;
      _plantingDate = widget.plant!.plantingDate;
      _fertilizerEnabled = widget.plant!.fertilizerEnabled;
      _fertilizerFrequency = widget.plant!.fertilizerFrequency;
      _lastFertilizerDate = widget.plant!.lastFertilizerDate;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

    if (pickedFile != null) {
      setState(() {
        _imagePaths.add(pickedFile.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  Future<void> _pickPurchaseDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (dt != null) setState(() => _purchaseDate = dt);
  }

  Future<void> _pickPlantingDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: _plantingDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (dt != null) setState(() => _plantingDate = dt);
  }

  void _savePlant() {
    if (_formKey.currentState!.validate()) {
      final plant = Plant(
        id: widget.plant?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        species: _speciesController.text,
        type: _type,
        price: double.tryParse(_priceController.text) ?? 0,
        purchaseDate: _purchaseDate,
        plantingDate: _plantingDate,
        imagePaths: _imagePaths,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        careLevel: _careLevel,
        lightRequirements: _lightRequirements,
        wateringFrequency: _wateringFrequency,
        wateringEnabled: _wateringEnabled,
        lastWateringDate: widget.plant?.lastWateringDate,
        location: _location,
        humidityPreference: _humidityPreference,
        lastFertilizerDate: _lastFertilizerDate,
        fertilizerEnabled: _fertilizerEnabled,
        fertilizerFrequency: _fertilizerFrequency,
        isFavorite: widget.plant?.isFavorite ?? false,
      );

      Navigator.pop(context, plant);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(widget.plant == null ? 'Добавить растение' : 'Редактировать растение'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _savePlant,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // основные данные
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Название',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _speciesController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Вид растения',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите вид растения';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Стоимость (₽)',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      dropdownColor: Color(0xFF1A1A1A),
                      decoration: InputDecoration(
                        labelText: 'Тип',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                      items: ['Комнатное', 'Уличное', 'Суккулент', 'Тропическое'].map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (v) => setState(() => _type = v ?? 'Комнатное'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // purchase & planting dates
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickPurchaseDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: TextEditingController(text: '${_purchaseDate.day.toString().padLeft(2,'0')}.${_purchaseDate.month.toString().padLeft(2,'0')}.${_purchaseDate.year}'),
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Дата приобретения',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today, color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickPlantingDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: TextEditingController(text: _plantingDate != null ? '${_plantingDate!.day.toString().padLeft(2,'0')}.${_plantingDate!.month.toString().padLeft(2,'0')}.${_plantingDate!.year}' : ''),
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Дата посадки (опционально)',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.grass, color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                style: TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Заметки',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              // дополнительные параметры
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _humidityPreference,
                      dropdownColor: Color(0xFF1A1A1A),
                      decoration: InputDecoration(
                        labelText: 'Влажность',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                      items: ['Низкая', 'Средняя', 'Высокая'].map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (v) => setState(() => _humidityPreference = v ?? 'Средняя'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: _location,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Местоположение',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => _location = v,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      value: _wateringEnabled,
                      onChanged: (v) => setState(() => _wateringEnabled = v),
                      title: Text('Напоминание о поливе', style: TextStyle(color: Colors.white)),
                      inactiveTrackColor: Colors.grey,
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    width: 140,
                    child: TextFormField(
                      initialValue: _wateringFrequency.toString(),
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Каждые (дн.)',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => _wateringFrequency = int.tryParse(v) ?? 7,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),
              // Fertilizer options
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: Color(0xFF0F0F0F), borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Удобрения', style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: Text('Напоминания о внесении удобрений', style: TextStyle(color: Colors.white))),
                        Switch(
                          value: _fertilizerEnabled,
                          onChanged: (v) => setState(() => _fertilizerEnabled = v),
                          activeColor: Color(0xFF00F5FF),
                        )
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Интервал (дн.)', style: TextStyle(color: Colors.white70)),
                        SizedBox(width: 12),
                        Container(
                          width: 90,
                          child: TextFormField(
                            initialValue: _fertilizerFrequency.toString(),
                            style: TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(border: OutlineInputBorder()),
                            onChanged: (v) => _fertilizerFrequency = int.tryParse(v) ?? 14,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(child: Text('Работает с марта по сентябрь', style: TextStyle(color: Colors.white54))),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Последнее внесение:', style: TextStyle(color: Colors.white70)),
                        SizedBox(width: 8),
                        Text(_lastFertilizerDate != null ? '${_lastFertilizerDate!.day.toString().padLeft(2,'0')}.${_lastFertilizerDate!.month.toString().padLeft(2,'0')}.${_lastFertilizerDate!.year}' : '—', style: TextStyle(color: Colors.white)),
                        Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _lastFertilizerDate = DateTime.now();
                            });
                          },
                          child: Text('Внесено сегодня'),
                          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00F5FF)),
                        )
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),
              // изображения
              Text('Фото', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              _imagePaths.isEmpty
                  ? ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.add_a_photo),
                      label: Text('Добавить фото'),
                      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00F5FF), foregroundColor: Colors.black),
                    )
                  : Column(
                      children: [
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, i) => Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(File(_imagePaths[i]), width: 100, height: 100, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(i),
                                    child: CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 16)),
                                  ),
                                ),
                              ],
                            ),
                            separatorBuilder: (_, __) => SizedBox(width: 8),
                            itemCount: _imagePaths.length,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: Icon(Icons.add),
                              label: Text('Добавить ещё'),
                              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00F5FF), foregroundColor: Colors.black),
                            ),
                            SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () => setState(() => _imagePaths.clear()),
                              icon: Icon(Icons.delete_forever),
                              label: Text('Удалить все'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _savePlant,
                child: Text('Сохранить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00FF88),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------- EditWishlistScreen (unchanged) -----------------
class EditWishlistScreen extends StatefulWidget {
  final WishlistItem? item;

  const EditWishlistScreen({this.item});

  @override
  _EditWishlistScreenState createState() => _EditWishlistScreenState();
}

class _EditWishlistScreenState extends State<EditWishlistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  String _type = 'Комнатное';
  int _priority = 3;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _speciesController.text = widget.item!.species;
      _priceController.text = widget.item!.estimatedPrice.toString();
      _notesController.text = widget.item!.notes;
      _type = widget.item!.type;
      _priority = widget.item!.priority;
    }
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final item = WishlistItem(
        id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        species: _speciesController.text,
        type: _type,
        estimatedPrice: double.tryParse(_priceController.text) ?? 0,
        notes: _notesController.text,
        priority: _priority,
      );

      Navigator.pop(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(widget.item == null ? 'Добавить в список желаний' : 'Редактировать'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveItem,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Название растения',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _speciesController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Вид растения',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите вид растения';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Примерная стоимость (₽)',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                style: TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Заметки',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _priority,
                dropdownColor: Color(0xFF1A1A1A),
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Приоритет',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                items: [1, 2, 3, 4, 5].map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        Icon(Icons.star, color: priority >= 4 ? Colors.orange : Colors.white),
                        SizedBox(width: 8),
                        Text('Приоритет $priority'),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _priority = value!;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveItem,
                child: Text('Сохранить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00FF88),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------- Plant Detail modal (updated: fertilizer + planting date) -----------------
class _PlantDetail extends StatefulWidget {
  final Plant plant;
  final void Function(Plant) onUpdate;

  const _PlantDetail({required this.plant, required this.onUpdate});

  @override
  __PlantDetailState createState() => __PlantDetailState();
}

class __PlantDetailState extends State<_PlantDetail> {
  late Plant _plant;

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
  }

  void _markWatered() {
    setState(() {
      _plant.lastWateringDate = DateTime.now();
    });
    widget.onUpdate(_plant);
  }

  void _toggleFavorite() {
    setState(() {
      _plant.isFavorite = !_plant.isFavorite;
    });
    widget.onUpdate(_plant);
  }

  void _sharePlant() {
    final text = 'Растение: ${_plant.name}\nВид: ${_plant.species}\nЦена: ${_plant.price.toStringAsFixed(0)}₽';
    Share.share(text);
  }

  void _markFertilizedNow() {
    setState(() {
      _plant.lastFertilizerDate = DateTime.now();
    });
    widget.onUpdate(_plant);
  }

  String _formatDateShort(DateTime? dt) {
    if (dt == null) return '—';
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Color(0xFF0A0A0A), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _plant.imagePaths.isNotEmpty
                  ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_plant.imagePaths.first), width: 84, height: 84, fit: BoxFit.cover))
                  : Container(width: 84, height: 84, decoration: BoxDecoration(color: Color(0xFF252525), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.eco, color: Color(0xFF00F5FF), size: 36)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_plant.name, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('${_plant.species} • ${_plant.type}', style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 6),
                    Text('Цена: ${_plant.price.toStringAsFixed(0)}₽', style: TextStyle(color: Color(0xFF00FF88))),
                  ],
                ),
              ),
              IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(_plant.isFavorite ? Icons.favorite : Icons.favorite_border, color: _plant.isFavorite ? Colors.red : Colors.white),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _markWatered,
                icon: Icon(Icons.water),
                label: Text('Пометить как полито'),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00F5FF), foregroundColor: Colors.black),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _sharePlant,
                icon: Icon(Icons.share),
                label: Text('Поделиться'),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1A1A1A), foregroundColor: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text('Заметки', style: TextStyle(color: Colors.white70)),
          SizedBox(height: 8),
          Text(_plant.notes ?? '—', style: TextStyle(color: Colors.white)),
          SizedBox(height: 12),
          Row(
            children: [
              _infoChip(Icons.wb_sunny, _plant.lightRequirements),
              SizedBox(width: 8),
              _infoChip(Icons.local_florist, _plant.careLevel),
              SizedBox(width: 8),
              _infoChip(Icons.place, _plant.location),
              SizedBox(width: 8),
              _infoChip(Icons.opacity, _plant.humidityPreference),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Text('Последний полив:', style: TextStyle(color: Colors.white70)),
              SizedBox(width: 8),
              Text(_plant.lastWateringDate != null ? _plant.lastWateringDate!.toLocal().toString().split('.').first : 'Не отмечен', style: TextStyle(color: Colors.white)),
            ],
          ),
          SizedBox(height: 12),
          // Planting date and Fertilizer section
          Row(
            children: [
              Text('Дата покупки:', style: TextStyle(color: Colors.white70)),
              SizedBox(width: 8),
              Text(_formatDateShort(_plant.purchaseDate), style: TextStyle(color: Colors.white)),
              Spacer(),
              Text('Дата посадки:', style: TextStyle(color: Colors.white70)),
              SizedBox(width: 8),
              Text(_formatDateShort(_plant.plantingDate), style: TextStyle(color: Colors.white)),
            ],
          ),
          SizedBox(height: 12),
          Divider(color: Colors.white10),
          SizedBox(height: 8),
          Row(
            children: [
              Text('Удобрения', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              Spacer(),
              if (_plant.fertilizerEnabled)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [Icon(Icons.notifications_active, color: Colors.greenAccent, size: 14), SizedBox(width: 6), Text('Напоминания: ВКЛ', style: TextStyle(color: Colors.white70))]),
                )
              else
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [Icon(Icons.notifications_off, color: Colors.redAccent, size: 14), SizedBox(width: 6), Text('Напоминания: ВЫКЛ', style: TextStyle(color: Colors.white54))]),
                ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text('Последнее внесение:', style: TextStyle(color: Colors.white70)),
              SizedBox(width: 8),
              Text(_plant.lastFertilizerDate != null ? _formatDateShort(_plant.lastFertilizerDate) : '—', style: TextStyle(color: Colors.white)),
              Spacer(),
              ElevatedButton.icon(
                onPressed: _markFertilizedNow,
                icon: Icon(Icons.add),
                label: Text('Внесено сегодня'),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00F5FF), foregroundColor: Colors.black),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (_plant.fertilizerEnabled && _plant.needsFertilizerReminder())
            Container(
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(child: Text('Пора вносить удобрение (сезон марта — сентября).', style: TextStyle(color: Colors.orangeAccent))),
                ],
              ),
            ),
          SizedBox(height: 18),
          Text('Подробнее', style: TextStyle(color: Colors.white70)),
          SizedBox(height: 8),
          // Возможность редактировать этот элемент напрямую
          ElevatedButton.icon(
            onPressed: () async {
              final updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditPlantScreen(plant: _plant)));
              if (updated != null && updated is Plant) {
                setState(() => _plant = updated);
                widget.onUpdate(_plant);
              }
            },
            icon: Icon(Icons.edit),
            label: Text('Редактировать'),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00FF88), foregroundColor: Colors.black),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Color(0xFF121212), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF00F5FF), size: 14),
          SizedBox(width: 6),
          Text(text, style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

/// ----------------- TipsScreen (unchanged) -----------------
class TipsScreen extends StatefulWidget {
  @override
  _TipsScreenState createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  final List<Map<String, String>> tips = [
    {'title': 'Освещение', 'content': 'Разным растениям нужен разный свет. Южные окна — для светолюбивых, северные — для теневыносливых.'},
    {'title': 'Полив', 'content': 'Поливайте утром. Проверяйте влажность почвы перед поливом. Суккуленты предпочитают сухой режим.'},
    {'title': 'Температура', 'content': 'Большинство растений предпочитает 18–24°C. Избегайте резких перепадов.'},
    {'title': 'Влажность', 'content': 'Тропические растения любят высокую влажность. Низкая влажность вредна для папоротников.'},
    {'title': 'Пересадка', 'content': 'Пересаживайте при заполнении корнями горшка или каждые 2–3 года.'},
    {'title': 'Питание', 'content': 'Подкармливайте удобрением в сезон роста, следуя инструкции.'},
    {'title': 'Вредители', 'content': 'Проверяйте листья на наличие тли и паутинного клеща. Мягкая мыльная вода — первое средство.'},
    {'title': 'Свет и цена', 'content': 'Дорогие декоративные виды часто требуют более тщательного ухода.'},
    {'title': 'Уход зимой', 'content': 'Зимой полив сокращаем и избегаем холодных подоконников.'},
  ];

  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final filtered = tips.where((t) {
      final q = _filter.toLowerCase();
      return q.isEmpty || t['title']!.toLowerCase().contains(q) || t['content']!.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(12),
          child: TextField(
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Поиск советов...',
              hintStyle: TextStyle(color: Colors.white54),
              prefixIcon: Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Color(0xFF0D0D0D),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (v) => setState(() => _filter = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final t = filtered[index];
              return Card(
                color: Color(0xFF121212),
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  collapsedIconColor: Color(0xFF00F5FF),
                  iconColor: Color(0xFF00F5FF),
                  title: Text(t['title']!, style: TextStyle(color: Color(0xFF00F5FF), fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(t['content']!, style: TextStyle(color: Colors.white70)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Share.share('${t['title']}\n\n${t['content']}');
                          },
                          icon: Icon(Icons.share, color: Colors.white70),
                          label: Text('Поделиться', style: TextStyle(color: Colors.white70)),
                        ),
                        SizedBox(width: 12),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
