# qgami_sdk

Flutter SDK for integrating QGami game flows.

This package provides:

- `QGami` static API for SDK lifecycle (`initialize`, `identify`, token refresh, game URL retrieval)
- `QgamiButton` widget that preloads a game URL and opens an in-app full-screen WebView
- `QgamiWebViewEvent` model for receiving game/webview events

## Installation

Add the dependency:

```yaml
dependencies:
	qgami_sdk: ^0.0.2
```

Then run:

```bash
flutter pub get
```

## Quick Start

1. Initialize the SDK.
2. Identify the user.
3. Render `QgamiButton` with a `gameSlug`.

```dart
import 'package:flutter/material.dart';
import 'package:qgami_sdk/qgami.dart';
import 'package:qgami_sdk/qgami_core.dart';
import 'package:qgami_sdk/qgami_web_view_event.dart';

void main() {
	runApp(const MyApp());
}

class MyApp extends StatelessWidget {
	const MyApp({super.key});

	@override
	Widget build(BuildContext context) {
		return const MaterialApp(home: HomePage());
	}
}

class HomePage extends StatefulWidget {
	const HomePage({super.key});

	@override
	State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
	bool identified = false;

	@override
	void initState() {
		super.initState();
		_setup();
	}

	Future<void> _setup() async {
		await QGami.initialize(
			apiKey: 'YOUR_API_KEY',
			environment: QGamiEnvironment.development,
			locale: 'en-US',
		);

		final ok = await QGami.identify(
			email: 'user@example.com',
			username: 'User 1',
			userId: 'user_1',
		);

		if (!mounted) return;
		setState(() => identified = ok);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Qgami Demo')),
			body: Center(
				child: QgamiButton(
					gameSlug: 'slot-machine-qgami',
					disabled: !identified,
					customBuilder: (context) => Container(
						padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
						decoration: BoxDecoration(
							color: Colors.green,
							borderRadius: BorderRadius.circular(8),
						),
						child: const Text(
							'Open Game',
							style: TextStyle(color: Colors.white),
						),
					),
					onWebViewEvent: (QgamiWebViewEvent event) {
						debugPrint('Qgami event: ${event.type}, data: ${event.data}');
					},
				),
			),
		);
	}
}
```

## QgamiButton Behavior

- `QgamiButton` waits for SDK readiness (`initialize` + `identify`) before fetching the game URL.
- If tapped before URL readiness, it shows a snackbar: `Game URL is not ready. Please wait for identify.`
- On success, it opens `QgamiWebViewPage` with a full-screen slide-up transition.
- The page now closes only on `GAME_CLOSE` events.

## WebView Events

`QgamiWebViewEvent.type` can include:

- `GAME_READY`
- `ACCESS_TOKEN_EXPIRED`
- `GAME_LOADING`
- `GAME_LOADED`
- `GAME_PLAY_START`
- `GAME_PLAY_RESULT`
- `GAME_PLAY_ERROR`
- `GAME_CLOSE`

SDK internals:

- On `GAME_READY`, SDK sends `INIT_GAME` to web content.
- On `ACCESS_TOKEN_EXPIRED`, SDK refreshes token and sends `UPDATE_ACCESS_TOKEN`.

## Public API Summary

- `QGami.initialize({apiKey, environment, locale})`
- `QGami.identify({email, username, userId})`
- `QGami.waitUntilReady({timeout})`
- `QGami.getGameUrl({gameSlug})`
- `QGami.refreshAccessToken()`
- `QGami.getInitGameMessage(...)`
- `QGami.getUpdateAccessTokenMessage(...)`

State helpers:

- `QGami.isInitialized`
- `QGami.isIdentified`
- `QGami.isReady`

Environment constants:

- `QGamiEnvironment.development`
- `QGamiEnvironment.staging`
- `QGamiEnvironment.sandbox`
- `QGamiEnvironment.production`

Note: `QGami.openGame()`, `QGami.showFloatingGameWidget()`, and `QGami.openHub()` are currently placeholders.

## Platform Notes

- Requires `webview_flutter` platform support.
- Android app must allow internet access:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```
