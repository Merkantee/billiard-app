import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const BilliardApp());
}

class BilliardApp extends StatelessWidget {
  const BilliardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Бильярдный зал',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF131321),
        primaryColor: const Color(0xFF46F0D2),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF46F0D2),
          secondary: Color(0xFFFBE2B4),
          surface: Color(0xFF1C1C2E),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// Хранилище состояний всех столов (синглтон)
class TableStateManager {
  static final TableStateManager _instance = TableStateManager._internal();
  factory TableStateManager() => _instance;
  TableStateManager._internal();

  final Map<int, TableState> tables = {
    1: TableState(),
    2: TableState(),
    3: TableState(),
    4: TableState(),
  };
}

class TableState {
  bool isRunning = false;
  DateTime? startTime;
  Duration elapsedTime = Duration.zero;
  Timer? timer;
  double totalCost = 0.0;

  void startTimer(Function onUpdate) {
    if (!isRunning) {
      isRunning = true;
      if (startTime == null) {
        startTime = DateTime.now();
      }
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final duration = DateTime.now().difference(startTime!);
        final totalDuration = elapsedTime + duration;
        totalCost = totalDuration.inSeconds / 3600 * 20;
        onUpdate();
      });
    }
  }

  void pauseTimer() {
    if (isRunning) {
      timer?.cancel();
      isRunning = false;
      if (startTime != null) {
        elapsedTime = elapsedTime + DateTime.now().difference(startTime!);
        startTime = null;
      }
    }
  }

  void reset() {
    timer?.cancel();
    isRunning = false;
    startTime = null;
    elapsedTime = Duration.zero;
    totalCost = 0.0;
  }

  Duration getTotalDuration() {
    if (isRunning && startTime != null) {
      return elapsedTime + DateTime.now().difference(startTime!);
    }
    return elapsedTime;
  }
}

// Главный экран с кнопками столов
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text(
                'Бильярдный зал',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF46F0D2),
                ),
              ),
              const SizedBox(height: 30),
              _buildTableButton(context, 1, const Color(0xFF46F0D2)),
              const SizedBox(height: 15),
              _buildTableButton(context, 2, const Color(0xFFFBE2B4)),
              const SizedBox(height: 15),
              _buildTableButton(context, 3, const Color(0xFF46F0D2)),
              const SizedBox(height: 15),
              _buildTableButton(context, 4, const Color(0xFFFBE2B4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableButton(BuildContext context, int tableNumber, Color textColor) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TableScreen(tableNumber: tableNumber),
              ),
            );
          },
          child: Center(
            child: Text(
              'Стол $tableNumber',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Экран стола
class TableScreen extends StatefulWidget {
  final int tableNumber;

  const TableScreen({super.key, required this.tableNumber});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  late TableState tableState;

  @override
  void initState() {
    super.initState();
    tableState = TableStateManager().tables[widget.tableNumber]!;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _updateUI() {
    if (mounted) setState(() {});
  }

  void _toggleTimer() {
    if (tableState.isRunning) {
      tableState.pauseTimer();
    } else {
      tableState.startTimer(_updateUI);
    }
    _updateUI();
  }

  void _showFinishDialog() {
    if (tableState.startTime == null && tableState.elapsedTime == Duration.zero) {
      return;
    }

    tableState.pauseTimer();
    _updateUI();

    final duration = tableState.getTotalDuration();
    final cost = duration.inSeconds / 3600 * 20;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Сеанс завершён',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF46F0D2),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Время: ${_formatDuration(duration)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'К оплате: ${cost.toStringAsFixed(2)} с.',
              style: const TextStyle(
                color: Color(0xFFFBE2B4),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF46F0D2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                tableState.reset();
                _updateUI();
              },
              child: const Text(
                'ОК',
                style: TextStyle(
                  color: Color(0xFF131321),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final duration = tableState.getTotalDuration();
    final cost = duration.inSeconds / 3600 * 20;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Кнопка "Назад"
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '← Назад',
                      style: TextStyle(
                        color: Color(0xFF46F0D2),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Основной контент
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Стол ${widget.tableNumber}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Информация о времени и стоимости
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Время запуска
                        Column(
                          children: [
                            const Text(
                              'Запуск:',
                              style: TextStyle(
                                color: Color(0xFFFBE2B4),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              tableState.startTime != null
                                  ? tableState.startTime!.toString().substring(11, 19)
                                  : '--:--:--',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        // Время игры
                        Column(
                          children: [
                            const Text(
                              'Время игры',
                              style: TextStyle(
                                color: Color(0xFFFBE2B4),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(
                                color: Color(0xFF46F0D2),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // Сумма
                        Column(
                          children: [
                            const Text(
                              'Сумма:',
                              style: TextStyle(
                                color: Color(0xFFFBE2B4),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${cost.toStringAsFixed(2)} с.',
                              style: const TextStyle(
                                color: Color(0xFFFBE2B4),
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // Кнопки управления
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF46F0D2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _toggleTimer,
                              child: Text(
                                tableState.isRunning ? 'ПАУЗА' : 'СТАРТ',
                                style: const TextStyle(
                                  color: Color(0xFF131321),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _showFinishDialog,
                              child: const Text(
                                'ЗАВЕРШИТЬ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
