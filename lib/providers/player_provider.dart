import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio_handler.dart';

// ── Handler ───────────────────────────────────────────────────────────────────

/// Injected from main.dart after AudioService is initialised.
final audioHandlerProvider = Provider<PulseAudioHandler>(
  (ref) => throw UnimplementedError('Override audioHandlerProvider in main.dart'),
);

// ── Current song ─────────────────────────────────────────────────────────────

final currentSongProvider = StreamProvider<MediaItem?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.mediaItem.stream;
});

// ── Is playing ───────────────────────────────────────────────────────────────

final isPlayingProvider = StreamProvider<bool>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.playbackState.stream.map((s) => s.playing);
});

// ── Position ─────────────────────────────────────────────────────────────────

final positionProvider = StreamProvider<Duration>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.positionStream;
});

// ── Full playback state ───────────────────────────────────────────────────────

final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.playbackState.stream;
});
