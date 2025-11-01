import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import '../theme/app_theme.dart';
import '../models/plant.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/share_service.dart';
import 'edit_plant_screen.dart';
import 'plant_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Plant> plants = [];
  bool _isLoading = true;
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadPlants();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  Future<void> _loadPlants() async {
    try {
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        plants = [
          Plant(
            name: 'Монстера',
            species: 'Monstera deliciosa',
            price: 2500,
            purchaseDate: DateTime(2024, 1, 15),
            imagePaths: [],
            notes: 'Любит рассеянный свет',
            isFavorite: true,
            careLevel: 'Средняя',
            lightRequirements: 'Рассеянный свет',
            wateringFrequency: 7,
          ),
          Plant(
            name: 'Фикус Бенджамина',
            species: 'Ficus benjamina',
            price: 1800,
            purchaseDate: DateTime(2024, 2, 10),
            imagePaths: [],
            notes: 'Полив 2 раза в неделю',
            isFavorite: false,
            careLevel: 'Легкая',
            lightRequirements: 'Прямой свет',
            wateringFrequency: 5,
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadPlants();
  }

  void _deletePlant(int index) async {
    final plant = plants[index];
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text(
          'Удалить растение?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${plant.name} будет удалено из коллекции',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Удалить',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      if (plant.id != null) {
        await _databaseService.deletePlant(plant.id!);
        await _notificationService.cancelReminder(plant.id!);
      }
      setState(() {
        plants.removeAt(index);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('${plant.name} удалено'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _waterPlant(int index) {
    setState(() {
      plants[index].lastWateringDate = DateTime.now();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text('${plants[index].name} полито!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _sharePlant(Plant plant) {
    ShareService.sharePlant(plant);
  }

  void _shareCollection() {
    if (plants.isNotEmpty) {
      ShareService.shareCollection(plants);
    }
  }

  void _showQuickActions(BuildContext context, Plant plant, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.share, color: Colors.green),
              title: Text('Поделиться', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _sharePlant(plant);
              },
            ),
            ListTile(
              leading: Icon(Icons.water_drop, color: Colors.blue),
              title: Text('Отметить полив', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _waterPlant(index);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Colors.orange),
              title: Text('Редактировать', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _editPlant(context, plant, index);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Удалить', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _deletePlant(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Моя коллекция'),
        backgroundColor: AppTheme.darkTheme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          if (plants.isNotEmpty)
            IconButton(
              icon: Icon(Icons.share),
              onPressed: _shareCollection,
            ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingShimmer() : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addPlant(context),
        child: Icon(Icons.add, size: 30),
        backgroundColor: Color(0xFF00C853),
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildContent() {
    return LiquidPullToRefresh(
      onRefresh: _handleRefresh,
      color: Color(0xFF00C853),
      height: 150,
      backgroundColor: Color(0xFF00C853).withOpacity(0.1),
      animSpeedFactor: 2,
      child: plants.isEmpty ? _buildEmptyState() : _buildPlantGrid(),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Color(0xFF1A1A1A),
          highlightColor: Color(0xFF2A2A2A),
          child: Container(
            margin: EdgeInsets.only(bottom: 16),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: Duration(seconds: 1),
            child: Icon(
              Icons.eco,
              size: 120,
              color: Color(0xFF00C853).withOpacity(0.3),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Коллекция пуста',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Добавьте первое растение в вашу коллекцию',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlantGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: plants.length,
      itemBuilder: (context, index) {
        return _buildPlantCard(plants[index], index);
      },
    );
  }

  Widget _buildPlantCard(Plant plant, int index) {
    final needsWater = plant.needsWatering;
    final cardContent = Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMainImage(plant),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plant.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (plant.isFavorite)
                      Icon(Icons.favorite, color: Colors.red, size: 16),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  plant.species,
                  style: TextStyle(
                    color: Color(0xFF00C853),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                _buildCharacteristics(plant),
                SizedBox(height: 8),
                _buildWateringIndicator(plant, index),
              ],
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onLongPress: () => _showQuickActions(context, plant, index),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _showPlantDetails(context, plant, index),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              child: cardContent,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _deletePlant(index),
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              onTap: () => _sharePlant(plant),
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.share, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainImage(Plant plant) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        image: plant.mainImage != null
            ? DecorationImage(
                image: FileImage(File(plant.mainImage!)),
                fit: BoxFit.cover,
              )
            : null,
        color: plant.mainImage == null ? Color(0xFF2A2A2A) : null,
      ),
      child: plant.mainImage == null
          ? Center(
              child: Icon(
                Icons.eco,
                size: 40,
                color: Color(0xFF00C853).withOpacity(0.5),
              ),
            )
          : Stack(
              children: [
                if (plant.additionalImages.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${plant.additionalImages.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildCharacteristics(Plant plant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_money, size: 12, color: Colors.white60),
            SizedBox(width: 4),
            Text(
              '${plant.price.toInt()} руб.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.thermostat, size: 12, color: _getCareLevelColor(plant.careLevel)),
            SizedBox(width: 4),
            Text(
              plant.careLevel,
              style: TextStyle(
                color: _getCareLevelColor(plant.careLevel),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.lightbulb, size: 12, color: Colors.amber),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                plant.lightRequirements,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.water_drop, size: 12, color: Colors.blue),
            SizedBox(width: 4),
            Text(
              '${plant.wateringFrequency} дн.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWateringIndicator(Plant plant, int index) {
    final needsWater = plant.needsWatering;
    final daysLeft = plant.daysUntilWatering;
    
    return GestureDetector(
      onTap: () => _waterPlant(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: needsWater ? AppTheme.warningGradient : AppTheme.successGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water_drop, size: 12, color: Colors.white),
            SizedBox(width: 4),
            Text(
              needsWater ? 'Полить!' : '$daysLeft д.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCareLevelColor(String level) {
    switch (level) {
      case 'Легкая': return Colors.green;
      case 'Средняя': return Colors.orange;
      case 'Сложная': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _addPlant(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPlantScreen(),
        fullscreenDialog: true,
      ),
    );
    
    if (result != null && result != 'delete') {
      setState(() {
        plants.add(result);
      });
      _schedulePlantNotifications(result);
    }
  }

  void _editPlant(BuildContext context, Plant plant, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPlantScreen(plant: plant),
      ),
    );
    
    if (result != null) {
      if (result == 'delete') {
        _deletePlant(index);
      } else {
        setState(() {
          plants[index] = result;
        });
        _schedulePlantNotifications(result);
      }
    }
  }

  void _showPlantDetails(BuildContext context, Plant plant, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantDetailScreen(plant: plant, plantIndex: index),
      ),
    );
    
    if (result != null) {
      if (result == 'delete') {
        _deletePlant(index);
      } else if (result is Plant) {
        setState(() {
          plants[index] = result;
        });
        _schedulePlantNotifications(result);
      }
    }
  }

  void _schedulePlantNotifications(Plant plant) async {
    if (plant.notificationsEnabled && plant.id != null) {
      final firstNotificationTime = DateTime.now().add(Duration(days: plant.wateringFrequency));
      final notificationDateTime = DateTime(
        firstNotificationTime.year,
        firstNotificationTime.month,
        firstNotificationTime.day,
        plant.wateringTime.hour,
        plant.wateringTime.minute,
      );
      
      await _notificationService.scheduleWateringReminder(
        plantId: plant.id!,
        plantName: plant.name,
        wateringTime: notificationDateTime,
        daysFrequency: plant.wateringFrequency,
      );
    }
  }
}