import 'package:flutter/material.dart';
import 'package:qgami/qgami.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qgami Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Qgami Example')),
        body: Center(
          child: QgamiButton(
            initialUrl: 'https://flutter.dev',
            customBuilder: (context) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Open WebView',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
