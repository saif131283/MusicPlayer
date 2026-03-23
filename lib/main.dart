import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme.dart';
import 'models/playlist.dart';
import 'models/song.dart';
import 'providers/player_provider.dart';
import 'screens/library_screen.dart';
import 'services/audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Hive ────────────────────────────────────────────────────────────────────
  await Hive.initFlutter();
  Hive.registerAdapter(SongAdapter());
  Hive.registerAdapter(PlaylistAdapter());
  await Hive.openBox<int>('favorites');
  await Hive.openBox<Playlist>('playlists');

  // ── Audio Service ────────────────────────────────────────────────────────────
  final handler = await AudioService.init<PulseAudioHandler>(
    builder: () => PulseAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.pulse.audio',
      androidNotificationChannelName: 'Pulse Player',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: false,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(handler),
      ],
      child: const PulseApp(),
    ),
  );
}

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const LibraryScreen(),
    );
  }
}
