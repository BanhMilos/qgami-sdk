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
  List<String> gameSlugs = ['slot-machine-qgami', 'lucky-spin-qgami'];

  // Debug parameters
  final TextEditingController _paddingTopController = TextEditingController(
    text: '0',
  );
  final TextEditingController _paddingBottomController = TextEditingController(
    text: '0',
  );
  bool _debugShowCloseBtn = true;
  bool _showDebugPanel = false;
  bool _isClosed = false;
  double _debugAssitiveTouchBtnSize = 80;

  QgamiInitGameMessage _buildInitMessage(String gameSlug) {
    return QGami.getInitGameMessage(
      gameSlug: gameSlug,
      mode: 'REMOTE',
      showCloseBtn: _debugShowCloseBtn,
      showRewardHistoryBtn: true,
      paddingTop: double.tryParse(_paddingTopController.text) ?? 0,
      paddingBottom: double.tryParse(_paddingBottomController.text) ?? 0,
    );
  }

  @override
  void dispose() {
    _paddingTopController.dispose();
    _paddingBottomController.dispose();
    super.dispose();
  }

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
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Qgami Example'),
        actions: [
          IconButton(
            icon: Icon(
              _showDebugPanel ? Icons.bug_report : Icons.bug_report_outlined,
            ),
            onPressed: () => setState(() => _showDebugPanel = !_showDebugPanel),
            tooltip: 'Toggle Debug Panel',
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _identifyUser();
              setState(() {
                _isClosed = false;
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height,
                color: Colors.amber[50],

                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 12,
                  children: [
                    ...gameSlugs.map(
                      (slug) => QgamiButton(
                        gameSlug: slug,
                        initMessage: _buildInitMessage(slug),
                        disabled: !identified,
                        customBuilder: (context) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),

                          child: Text(
                            slug,
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        onWebViewEvent: (event) {},
                      ),
                    ),
                    // TODO : Comment this
                    ElevatedButton(
                      onPressed: () {
                        QGami.openGame(
                          context,
                          url:
                              "http://10.10.3.146:5173/games/chance/slot-machine/v1/",
                          gameSlug: gameSlugs[0],
                          initMessage: _buildInitMessage(gameSlugs[0]),
                        );
                      },
                      child: const Text('LAN url'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _identifyUser();
                      },
                      child: const Text('Reinitialize '),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showDebugPanel)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Debug: Init Message Parameters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _paddingTopController,
                        decoration: InputDecoration(
                          labelText: 'Padding Top',
                          hintText: 'Enter padding top value',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _paddingBottomController,
                        decoration: InputDecoration(
                          labelText: 'Padding Bottom',
                          hintText: 'Enter padding bottom value',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Show Close Button:'),
                          const SizedBox(width: 12),
                          Switch(
                            value: _debugShowCloseBtn,
                            onChanged: (value) {
                              setState(() {
                                _debugShowCloseBtn = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Button Size:'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Slider(
                              value: _debugAssitiveTouchBtnSize,
                              min: 80,
                              max: 100,
                              divisions: 20,
                              label: _debugAssitiveTouchBtnSize.toStringAsFixed(
                                0,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _debugAssitiveTouchBtnSize = value;
                                });
                              },
                            ),
                          ),
                          Text(
                            _debugAssitiveTouchBtnSize.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'These values will be passed to INIT_GAME message',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          QgamiAssistiveTouchButton(
            gameSlug: gameSlugs[1],
            isClosed: _isClosed,
            startFromBottomEdge: true,
            size: _debugAssitiveTouchBtnSize,
            initMessage: _buildInitMessage(gameSlugs[1]),
            onCloseTap: () {
              setState(() {
                _isClosed = true;
              });
            },
          ),
        ],
      ),
    );
  }
}
