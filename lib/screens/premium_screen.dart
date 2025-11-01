class PremiumScreen extends StatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  _PremiumScreenState createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = '';
  CodeStats _codeStats = CodeStats(activeCount: 0, usedCount: 0, totalGenerated: 0);
  List<String> _activeCodes = [];

  @override
  void initState() {
    super.initState();
    _loadCodeStats();
    _loadActiveCodes();
  }

  void _loadCodeStats() async {
    final stats = await DonationService.getCodeStats();
    setState(() {
      _codeStats = stats;
    });
  }

  void _loadActiveCodes() async {
    final codes = await DonationService.getActiveCodes();
    setState(() {
      _activeCodes = codes;
    });
  }

  void _activatePremium() async {
    if (_codeController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Введите код активации';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Проверяем код...';
    });

    try {
      final result = await DonationService.activatePremiumWithCode(_codeController.text);
      
      setState(() {
        _statusMessage = result.message;
      });

      if (result.success) {
        _loadCodeStats();
        _loadActiveCodes();
        await Future.delayed(Duration(seconds: 2));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Ошибка активации: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateNewCode() async {
    final newCode = DonationService.generateCode();
    await DonationService.saveGeneratedCode(newCode);
    
    _loadCodeStats();
    _loadActiveCodes();
    
    // Показываем диалог с новым кодом
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text('Новый код сгенерирован', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Скопируйте этот код для донатера:', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF00F5FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF00F5FF)),
              ),
              child: SelectableText(
                newCode,
                style: TextStyle(
                  color: Color(0xFF00F5FF),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Monospace',
                ),
              ),
            ),
            SizedBox(height: 16),
            Text('Код будет активен до использования', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Закрыть', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              // Копируем в буфер обмена
              // Clipboard.setData(ClipboardData(text: newCode));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green,
                  content: Text('Код скопирован в буфер обмена'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00F5FF),
              foregroundColor: Colors.black,
            ),
            child: Text('Копировать'),
          ),
        ],
      ),
    );
  }

  void _openDonationPage() {
    const donationUrl = 'https://www.donationalerts.com/r/ваш_никнейм';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text('Инструкция по активации', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionStep('1. Сделайте донат от 299₽', Icons.attach_money),
            _buildInstructionStep('2. Напишите в комментарии: "Premium"', Icons.message),
            _buildInstructionStep('3. Получите код активации', Icons.code),
            _buildInstructionStep('4. Введите код ниже', Icons.check_circle),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      donationUrl,
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Закрыть', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // launchUrl(Uri.parse(donationUrl));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00F5FF),
              foregroundColor: Colors.black,
            ),
            child: Text('Перейти к донату'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF00F5FF), size: 20),
          SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('Neon Plants Premium'),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code),
            onPressed: _generateNewCode,
            tooltip: 'Сгенерировать код',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Заголовок
            Container(
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: AppTheme.neonGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(Icons.workspace_premium, size: 60, color: Colors.black),
                  SizedBox(height: 16),
                  Text(
                    'Neon Plants Premium',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Активируйте за донат от 299₽',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Статистика кодов
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Активные', '${_codeStats.activeCount}'),
                  _buildStatItem('Использованы', '${_codeStats.usedCount}'),
                  _buildStatItem('Всего', '${_codeStats.totalGenerated}'),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Поле для ввода кода
            TextFormField(
              controller: _codeController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Код активации',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Введите 8-значный код',
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code, color: Color(0xFF00F5FF)),
              ),
            ),
            SizedBox(height: 16),

            // Статус
            if (_statusMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('🎉') 
                    ? Colors.green.withOpacity(0.2) 
                    : _statusMessage.contains('Неверный') || _statusMessage.contains('использован')
                      ? Colors.red.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _statusMessage.contains('🎉') ? Icons.check_circle : 
                      _statusMessage.contains('Неверный') || _statusMessage.contains('использован') 
                        ? Icons.error : Icons.info,
                      color: _statusMessage.contains('🎉') ? Colors.green : 
                            (_statusMessage.contains('Неверный') || _statusMessage.contains('использован') 
                              ? Colors.red : Colors.orange),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

            // Список активных кодов (только для отладки)
            if (_activeCodes.isNotEmpty) ...[
              SizedBox(height: 16),
              Text('Активные коды:', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _activeCodes.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 4),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _activeCodes[index],
                        style: TextStyle(
                          color: Color(0xFF00F5FF),
                          fontFamily: 'Monospace',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            Spacer(),

            // Кнопки
            Column(
              children: [
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _activatePremium,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00F5FF),
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.black)
                        : Text(
                            'АКТИВИРОВАТЬ PREMIUM',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _openDonationPage,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xFF00F5FF),
                          side: BorderSide(color: Color(0xFF00F5FF)),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.attach_money),
                            SizedBox(width: 8),
                            Text('ИНСТРУКЦИЯ'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      width: 60,
                      child: ElevatedButton(
                        onPressed: _generateNewCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Нажмите "+" чтобы сгенерировать новый код для донатера',
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}