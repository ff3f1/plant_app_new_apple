import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../models/plant.dart';

class EditPlantScreen extends StatefulWidget {
  final Plant? plant;

  EditPlantScreen({this.plant});

  @override
  _EditPlantScreenState createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends State<EditPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _repottingController = TextEditingController();
  
  DateTime _purchaseDate = DateTime.now();
  DateTime? _plantingDate;
  List<String> _imagePaths = [];
  
  String _careLevel = 'Средняя';
  String _lightRequirements = 'Рассеянный свет';
  int _wateringFrequency = 7;
  
  bool _notificationsEnabled = false;
  TimeOfDay _wateringTime = TimeOfDay(hour: 9, minute: 0);

  final List<String> _careLevels = ['Легкая', 'Средняя', 'Сложная'];
  final List<String> _lightOptions = [
    'Прямой свет',
    'Рассеянный свет',
    'Полутень',
    'Тень'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.plant != null) {
      _nameController.text = widget.plant!.name;
      _speciesController.text = widget.plant!.species;
      _priceController.text = widget.plant!.price.toString();
      _notesController.text = widget.plant!.notes ?? '';
      _repottingController.text = widget.plant!.repottingReason ?? '';
      _purchaseDate = widget.plant!.purchaseDate;
      _plantingDate = widget.plant!.plantingDate;
      _imagePaths = widget.plant!.imagePaths;
      _careLevel = widget.plant!.careLevel;
      _lightRequirements = widget.plant!.lightRequirements;
      _wateringFrequency = widget.plant!.wateringFrequency;
      _notificationsEnabled = widget.plant!.notificationsEnabled;
      _wateringTime = widget.plant!.wateringTime;
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    
    if (pickedFiles != null) {
      setState(() {
        _imagePaths.addAll(pickedFiles.map((file) => file.path).toList());
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isPurchaseDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPurchaseDate ? _purchaseDate : (_plantingDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Color(0xFF1A1A1A),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isPurchaseDate) {
          _purchaseDate = picked;
        } else {
          _plantingDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _wateringTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Color(0xFF1A1A1A),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _wateringTime = picked;
      });
    }
  }

  void _savePlant() {
    if (_formKey.currentState!.validate()) {
      final plant = Plant(
        id: widget.plant?.id,
        name: _nameController.text,
        species: _speciesController.text,
        price: double.parse(_priceController.text),
        purchaseDate: _purchaseDate,
        plantingDate: _plantingDate,
        repottingReason: _repottingController.text.isEmpty ? null : _repottingController.text,
        imagePaths: _imagePaths,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        isFavorite: widget.plant?.isFavorite ?? false,
        careLevel: _careLevel,
        lightRequirements: _lightRequirements,
        wateringFrequency: _wateringFrequency,
        notificationsEnabled: _notificationsEnabled,
        wateringTime: _wateringTime,
      );
      
      Navigator.pop(context, plant);
    }
  }

  void _deletePlant() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E1E),
        title: Text(
          'Удалить растение?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Это действие нельзя отменить',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена', style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, 'delete');
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.plant == null ? 'Добавить растение' : 'Редактировать'),
        backgroundColor: AppTheme.darkTheme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          if (widget.plant != null)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deletePlant,
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildImageGallery(),
              SizedBox(height: 20),
              _buildBasicInfoSection(),
              SizedBox(height: 20),
              _buildDatesSection(),
              SizedBox(height: 20),
              _buildCareSection(),
              SizedBox(height: 20),
              _buildNotificationsSection(),
              SizedBox(height: 20),
              _buildAdditionalInfoSection(),
              SizedBox(height: 30),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Фотографии',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        
        InkWell(
          onTap: _pickImages,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate, size: 40, color: Colors.green),
                SizedBox(height: 8),
                Text(
                  'Добавить фото',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
        ),
        
        if (_imagePaths.isNotEmpty) ...[
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _imagePaths.asMap().entries.map((entry) {
              final index = entry.key;
              final path = entry.value;
              return Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(File(path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Основная информация',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        
        TextFormField(
          controller: _nameController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Название растения *',
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
            labelText: 'Вид/Сорт *',
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
        
        TextFormField(
          controller: _priceController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Стоимость (руб.) *',
            labelStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Введите стоимость';
            }
            if (double.tryParse(value) == null) {
              return 'Введите корректную сумму';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Даты',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        
        _buildDateTile(
          'Дата приобретения *',
          _purchaseDate,
          true,
        ),
        SizedBox(height: 8),
        
        _buildDateTile(
          'Дата посадки',
          _plantingDate,
          false,
        ),
      ],
    );
  }

  Widget _buildDateTile(String title, DateTime? date, bool isRequired) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: Colors.white70),
      ),
      subtitle: Text(
        date != null 
            ? '${date.day}.${date.month}.${date.year}'
            : 'Не указана',
        style: TextStyle(color: date != null ? Colors.white : Colors.grey),
      ),
      trailing: Icon(Icons.calendar_today, color: Colors.green),
      onTap: () => _selectDate(context, isRequired),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.green.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildCareSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Уход',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        
        DropdownButtonFormField<String>(
          value: _careLevel,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Сложность ухода',
            labelStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(),
          ),
          items: _careLevels.map((String level) {
            return DropdownMenuItem(
              value: level,
              child: Text(level),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _careLevel = newValue!;
            });
          },
        ),
        SizedBox(height: 12),
        
        DropdownButtonFormField<String>(
          value: _lightRequirements,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Требования к свету',
            labelStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(),
          ),
          items: _lightOptions.map((String option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _lightRequirements = newValue!;
            });
          },
        ),
        SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: Text(
                'Полив каждые:',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            Container(
              width: 80,
              child: TextFormField(
                initialValue: _wateringFrequency.toString(),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  suffixText: 'дней',
                  suffixStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final days = int.tryParse(value);
                  if (days != null && days > 0) {
                    setState(() {
                      _wateringFrequency = days;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Уведомления о поливе',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        
        SwitchListTile(
          title: Text(
            'Напоминать о поливе',
            style: TextStyle(color: Colors.white70),
          ),
          subtitle: Text(
            _notificationsEnabled 
                ? 'Уведомления включены' 
                : 'Уведомления выключены',
            style: TextStyle(
              color: _notificationsEnabled ? Colors.green : Colors.grey,
            ),
          ),
          value: _notificationsEnabled,
          onChanged: (bool value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
          activeColor: Colors.green,
        ),
        
        if (_notificationsEnabled) ...[
          SizedBox(height: 12),
          ListTile(
            title: Text(
              'Время напоминания',
              style: TextStyle(color: Colors.white70),
            ),
            subtitle: Text(
              _wateringTime.format(context),
              style: TextStyle(color: Colors.white),
            ),
            trailing: Icon(Icons.access_time, color: Colors.green),
            onTap: () => _selectTime(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.green.withOpacity(0.3)),
            ),
          ),
          
          Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Text(
              'Напоминание будет приходить каждые $_wateringFrequency дней в ${_wateringTime.format(context)}',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Дополнительная информация',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        
        TextFormField(
          controller: _repottingController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Причина пересадки',
            labelStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        SizedBox(height: 12),
        
        TextFormField(
          controller: _notesController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Примечания',
            labelStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _savePlant,
      child: Text(
        'Сохранить растение',
        style: TextStyle(fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}