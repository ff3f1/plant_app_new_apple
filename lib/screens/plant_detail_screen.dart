import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/plant.dart';
import '../services/share_service.dart';
import 'edit_plant_screen.dart';

class PlantDetailScreen extends StatelessWidget {
  final Plant plant;
  final int plantIndex;

  const PlantDetailScreen({required this.plant, required this.plantIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(plant.name),
        backgroundColor: AppTheme.darkTheme.appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _sharePlant(context),
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _editPlant(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основное фото
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: plant.mainImage != null
                    ? DecorationImage(
                        image: FileImage(File(plant.mainImage!)),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: plant.mainImage == null ? Color(0xFF2A2A2A) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: plant.mainImage == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.eco,
                            size: 80,
                            color: Color(0xFF00C853).withOpacity(0.5),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Нет фото',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
            SizedBox(height: 24),
            
            // Заголовок
            Text(
              plant.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              plant.species,
              style: TextStyle(
                color: Color(0xFF00C853),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20),
            
            // Статус полива
            _buildWateringStatus(),
            SizedBox(height: 20),
            
            // Все характеристики
            _buildAllCharacteristics(),
            SizedBox(height: 20),
            
            // Уведомления
            _buildNotificationsSection(context),
            
            // Дополнительные фото
            if (plant.additionalImages.isNotEmpty) ...[
              SizedBox(height: 20),
              _buildPhotoGallery(),
            ],
            
            // Примечания
            if (plant.notes != null && plant.notes!.isNotEmpty) ...[
              SizedBox(height: 20),
              _buildNotesSection(),
            ],
            
            // Причина пересадки
            if (plant.repottingReason != null && plant.repottingReason!.isNotEmpty) ...[
              SizedBox(height: 20),
              _buildRepottingSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWateringStatus() {
    final needsWater = plant.needsWatering;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: needsWater ? AppTheme.warningGradient : AppTheme.successGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            needsWater ? Icons.warning : Icons.check_circle,
            color: Colors.white,
            size: 30,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  needsWater ? 'Нужен полив!' : 'Все в порядке',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  needsWater 
                      ? 'Растение ждет полива'
                      : 'Следующий полив через ${plant.daysUntilWatering} дней',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllCharacteristics() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildCharacteristicRow('💰 Стоимость', '${plant.price} руб.', Icons.attach_money),
          _buildDivider(),
          _buildCharacteristicRow('🎯 Сложность ухода', plant.careLevel, Icons.thermostat),
          _buildDivider(),
          _buildCharacteristicRow('💡 Требования к свету', plant.lightRequirements, Icons.lightbulb),
          _buildDivider(),
          _buildCharacteristicRow('💧 Частота полива', 'Каждые ${plant.wateringFrequency} дней', Icons.water_drop),
          _buildDivider(),
          _buildCharacteristicRow('📅 Дата приобретения', 
              '${plant.purchaseDate.day}.${plant.purchaseDate.month}.${plant.purchaseDate.year}', 
              Icons.shopping_cart),
          if (plant.plantingDate != null) ...[
            _buildDivider(),
            _buildCharacteristicRow('🌱 Дата посадки', 
                '${plant.plantingDate!.day}.${plant.plantingDate!.month}.${plant.plantingDate!.year}', 
                Icons.eco),
          ],
        ],
      ),
    );
  }

  Widget _buildCharacteristicRow(String title, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Color(0xFF00C853)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(vertical: 4),
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildNotificationsSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Уведомления',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          
          Row(
            children: [
              Icon(
                plant.notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                color: plant.notificationsEnabled ? Colors.green : Colors.grey,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.notificationsEnabled ? 'Уведомления включены' : 'Уведомления выключены',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    if (plant.notificationsEnabled)
                      Text(
                        'Напоминание в ${plant.wateringTime.format(context)} каждые ${plant.wateringFrequency} дней',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Дополнительные фото',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: plant.additionalImages.length,
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                margin: EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: FileImage(File(plant.additionalImages[index])),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Примечания',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          Text(
            plant.notes!,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepottingSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Причина пересадки',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          Text(
            plant.repottingReason!,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _sharePlant(BuildContext context) {
    ShareService.sharePlant(plant);
  }

  void _editPlant(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPlantScreen(plant: plant),
      ),
    );
    
    if (result != null) {
      Navigator.pop(context, result);
    }
  }
}