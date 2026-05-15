# qgami_sdk

Flutter SDK for integrating QGami game flows into your app.

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  qgami_sdk: ^0.0.3
```

Then run:

```bash
flutter pub get
```

## How To Use

### 1. Initialize & Identify the User

Call `QGami.initialize()` and `QGami.identify()` early in your app lifecycle (usually in `initState`):

```dart
Future<void> _setup() async {
  // Initialize with your API key
  await QGami.initialize(
    apiKey: 'YOUR_API_KEY',
    environment: QGamiEnvironment.development,
    locale: 'en-US',
  );

  // Identify the user
  final ok = await QGami.identify(
    email: 'user@example.com',
    username: 'User 1',
    userId: 'user_1',
  );

  if (!mounted) return;
  setState(() => identified = ok);
}
```

**Environment options:**

- `QGamiEnvironment.development`
- `QGamiEnvironment.staging`
- `QGamiEnvironment.sandbox`
- `QGamiEnvironment.production`

### 2. Add a Game Button

Use `QgamiButton` to let users tap and play a game. Customize the button appearance with `customBuilder`:

```dart
QgamiButton(
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
    debugPrint('Game event: ${event.type}, data: ${event.data}');
  },
)
```

**QgamiButton behavior:**

- Waits for SDK readiness before fetching the game URL
- On tap, opens the game in a full-screen WebView
- Shows a snackbar if the game URL is not ready yet
- Calls `onWebViewEvent` for all game/webview events

### 3. Add a Floating Game Button

Use `QgamiAssistiveTouchButton` for a draggable floating button that sticks to edges:

```dart
QgamiAssistiveTouchButton(
  gameSlug: 'lucky-spin-qgami',
  startFromRightEdge: true,      // Start on the right side
  startFromBottomEdge: true,     // Start at the bottom
  horizontalEdgeMargin: 16,      // 16px from left/right edge
  verticalEdgeMargin: 16,        // 16px from top/bottom edge
  size: 80,                      // Button diameter
  onCloseTap: () {
    // Handle close action
    setState(() => buttonClosed = true);
  },
)
```

**Key options:**

- `gameSlug`: Which game to open (optional; use `onTap` for custom behavior)
- `startFromRightEdge`: Position on right (true) or left (false)
- `startFromBottomEdge`: Position at bottom (true) or top (false)
- `size`: Button diameter (default 80)
- `horizontalEdgeMargin`: Spacing from side edges (default 16)
- `verticalEdgeMargin`: Spacing from top/bottom (default 16)
- `onTap`: Custom tap handler (overrides default game-open behavior)
- `onCloseTap`: Handle close button tap

**Important:** The button requires bounded parent constraints (e.g., inside a `Stack` in `Scaffold` body).

### 4. Listen to Game Events

Games emit events that you can listen to via `onWebViewEvent`. Common event types:

```dart
onWebViewEvent: (QgamiWebViewEvent event) {
  switch (event.type) {
    case 'GAME_READY':
      print('Game is ready to play');
      break;
    case 'GAME_LOADED':
      print('Game has loaded');
      break;
    case 'GAME_PLAY_START':
      print('User started playing');
      break;
    case 'GAME_PLAY_RESULT':
      print('Game result: ${event.data}');
      break;
    case 'GAME_CLOSE':
      print('User closed the game');
      break;
    case 'ACCESS_TOKEN_EXPIRED':
      print('Token expired, SDK will refresh automatically');
      break;
    default:
      print('Event: ${event.type}, Data: ${event.data}');
  }
}
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:qgami_sdk/qgami.dart';
import 'package:qgami_sdk/qgami_core.dart';

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
          onWebViewEvent: (event) {
            debugPrint('Event: ${event.type}');
          },
        ),
      ),
    );
  }
}
```

## API Reference

### QGami Static Methods

**Lifecycle:**

- `initialize({apiKey, environment, locale})` — Initialize the SDK (call once at app start)
- `identify({email, username, userId})` — Identify the current user (call after initialize)
- `openGame(context, {url, gameSlug})` — Programmatically open a game
- `refreshAccessToken()` — Manually refresh auth token
- `waitUntilReady({timeout})` — Wait for SDK to be initialized and identified (default 2s timeout)
- `getGameUrl({gameSlug})` — Fetch the game URL for a specific game
- `getInitGameMessage(...)` — Build the INIT_GAME message payload
- `getUpdateAccessTokenMessage(...)` — Build the UPDATE_ACCESS_TOKEN message payload

**State Checks:**

- `isInitialized` — Check if SDK is initialized
- `isIdentified` — Check if user is identified
- `isReady` — Check if both initialize and identify are complete

### Widget Components

- `QgamiButton` — Tap to open a game in full-screen WebView
- `QgamiAssistiveTouchButton` — Draggable floating button that snaps to edges

### Event Types

Games can emit these event types via `onWebViewEvent`:

- `GAME_READY` — Game content is loaded and ready
- `GAME_LOADING` — Game is loading
- `GAME_LOADED` — Game render complete
- `GAME_PLAY_START` — User started playing
- `GAME_PLAY_RESULT` — Game outcome available
- `GAME_PLAY_ERROR` — An error occurred during play
- `GAME_CLOSE` — User closed the game (WebView auto-pops)
- `ACCESS_TOKEN_EXPIRED` — Auth token expired (SDK auto-refreshes)

## Platform Notes

- Requires `webview_flutter` platform support.
- **Android:** Add internet permission to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```
