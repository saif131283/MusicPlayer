import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../core/theme.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';

// ── Full-screen player ────────────────────────────────────────────────────────

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    final position = ref.watch(positionProvider).valueOrNull ?? Duration.zero;
    final playbackState = ref.watch(playbackStateProvider).valueOrNull;
    final handler = ref.read(audioHandlerProvider);
    final favorites = ref.watch(favoritesProvider);

    final duration = currentSong?.duration ?? Duration.zero;
    final songId = currentSong?.extras?['songId'] as int?;
    final isFavorite = songId != null && favorites.contains(songId);

    final shuffleMode = playbackState?.shuffleMode ?? AudioServiceShuffleMode.none;
    final repeatMode = playbackState?.repeatMode ?? AudioServiceRepeatMode.none;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          children: [
            Text(
              'Now Playing',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? AppTheme.accent : null,
            ),
            onPressed: () {
              if (songId != null) {
                ref.read(favoritesProvider.notifier).toggle(songId);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Album art ───────────────────────────────────────────────────
            Expanded(
              flex: 5,
              child: Center(
                child: AnimatedScale(
                  scale: isPlaying ? 1.0 : 0.88,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: currentSong != null && songId != null
                          ? QueryArtworkWidget(
                              id: songId,
                              type: ArtworkType.AUDIO,
                              artworkFit: BoxFit.cover,
                              artworkBorderRadius: BorderRadius.circular(16),
                              nullArtworkWidget: _placeholderArt(),
                            )
                          : _placeholderArt(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Song info ───────────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    currentSong?.title ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentSong?.artist ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Progress bar ─────────────────────────────────────────────────
            Row(
              children: [
                Text(
                  _formatDuration(position),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
                Expanded(
                  child: Slider(
                    value: (duration.inMilliseconds > 0)
                        ? (position.inMilliseconds / duration.inMilliseconds)
                            .clamp(0.0, 1.0)
                        : 0.0,
                    onChanged: (v) {
                      final target = Duration(
                          milliseconds: (v * duration.inMilliseconds).round());
                      handler.seek(target);
                    },
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Main controls ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.skip_previous),
                  onPressed: handler.skipToPrevious,
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: isPlaying ? handler.pause : handler.play,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.skip_next),
                  onPressed: handler.skipToNext,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Secondary controls ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Shuffle
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: shuffleMode == AudioServiceShuffleMode.all
                        ? AppTheme.accent
                        : AppTheme.textSecondary,
                  ),
                  onPressed: () => handler.setShuffleMode(
                    shuffleMode == AudioServiceShuffleMode.all
                        ? AudioServiceShuffleMode.none
                        : AudioServiceShuffleMode.all,
                  ),
                ),
                // Repeat
                IconButton(
                  icon: Icon(
                    repeatMode == AudioServiceRepeatMode.one
                        ? Icons.repeat_one
                        : Icons.repeat,
                    color: repeatMode != AudioServiceRepeatMode.none
                        ? AppTheme.accent
                        : AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    final next = switch (repeatMode) {
                      AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
                      AudioServiceRepeatMode.all => AudioServiceRepeatMode.one,
                      _ => AudioServiceRepeatMode.none,
                    };
                    handler.setRepeatMode(next);
                  },
                ),
                // Queue
                IconButton(
                  icon: const Icon(Icons.queue_music, color: AppTheme.textSecondary),
                  onPressed: () {},
                ),
                // Lyrics
                IconButton(
                  icon: const Icon(Icons.lyrics_outlined, color: AppTheme.textSecondary),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _placeholderArt() {
    return Container(
      color: AppTheme.card,
      child: const Icon(
        Icons.music_note,
        size: 80,
        color: AppTheme.textSecondary,
      ),
    );
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

// ── Mini player ───────────────────────────────────────────────────────────────

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    final position = ref.watch(positionProvider).valueOrNull ?? Duration.zero;
    final handler = ref.read(audioHandlerProvider);

    if (currentSong == null) return const SizedBox.shrink();

    final duration = currentSong.duration ?? Duration.zero;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final songId = currentSong.extras?['songId'] as int?;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PlayerScreen()),
      ),
      child: Container(
        color: AppTheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thin progress strip
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.divider,
              color: AppTheme.accent,
              minHeight: 2,
            ),

            // Content
            Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 8,
                bottom: MediaQuery.of(context).padding.bottom + 8,
              ),
              child: Row(
                children: [
                  // Artwork
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: songId != null
                        ? QueryArtworkWidget(
                            id: songId,
                            type: ArtworkType.AUDIO,
                            artworkWidth: 40,
                            artworkHeight: 40,
                            artworkBorderRadius: BorderRadius.circular(6),
                            nullArtworkWidget: _fallbackArt(),
                          )
                        : _fallbackArt(),
                  ),
                  const SizedBox(width: 12),

                  // Title / artist
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          currentSong.artist ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  // Prev / play / next
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: AppTheme.textPrimary),
                    onPressed: handler.skipToPrevious,
                  ),
                  GestureDetector(
                    onTap: isPlaying ? handler.pause : handler.play,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: AppTheme.textPrimary),
                    onPressed: handler.skipToNext,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackArt() {
    return Container(
      width: 40,
      height: 40,
      color: AppTheme.card,
      child: const Icon(Icons.music_note, color: AppTheme.textSecondary, size: 20),
    );
  }
}
