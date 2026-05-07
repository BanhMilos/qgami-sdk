import 'package:flutter/material.dart';
import 'package:qgami_sdk/qgami.dart';
import 'package:qgami_sdk/qgami_core.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Qgami Example', home: MainScreen());
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool identified = false;
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await QGami.initialize(
      apiKey: 'qgami_development_QGAMIFICATION2026',
      environment: QGamiEnvironment.development,
      locale: 'en-US',
    );
    await _identifyUser();
  }

  Future<void> _identifyUser() async {
    bool success = await QGami.identify(
      email: 'user_0001@gmail.com',
      username: 'User 0001',
      userId: 'user_0001',
    );
    setState(() {
      identified = success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qgami Example')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          QgamiButton(
            initialUrl: 'https://games-dev.qgami.com/chance/lucky-spin/',
            disabled: !identified,
            customBuilder: (context) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),

              child: const Text(
                'Spin the Wheel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            onWebViewEvent: (event) {},
          ),
          QgamiButton(
            initialUrl: 'https://games-dev.qgami.com/chance/slot-machine/',
            disabled: !identified,
            customBuilder: (context) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Slot Machine',
                style: TextStyle(color: Colors.white),
              ),
            ),
            onWebViewEvent: (event) {},
          ),
          ElevatedButton(
            onPressed: () async {
              await _identifyUser();
            },
            child: const Text('Reinitialize '),
          ),
        ],
      ),
    );
  }
}
