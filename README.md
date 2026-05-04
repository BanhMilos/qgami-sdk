# qgami

qgami provides a tappable Flutter widget that opens a full-screen in-app WebView.

## Features

- Drop-in `QgamiButton` widget
- Opens a full-screen WebView route on tap
- Configurable start URL via `initialUrl`
- Optional custom button builder via `customBuilder`

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
	qgami: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:qgami/qgami.dart';

class DemoPage extends StatelessWidget {
	const DemoPage({super.key});

	@override
	Widget build(BuildContext context) {
		return Center(
			child: QgamiButton(
				initialUrl: 'https://flutter.dev',
				customBuilder: (context) => Container(
					padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
					decoration: BoxDecoration(
						color: Colors.green,
						borderRadius: BorderRadius.circular(10),
					),
					child: const Text(
						'Open WebView',
						style: TextStyle(color: Colors.white),
					),
				),
			),
		);
	}
}
```

## Notes

- `QgamiButton` depends on `webview_flutter` and requires platform WebView support.
- If no platform implementation is available, the widget safely logs a debug message instead of crashing.
