import 'dart:typed_data';

import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/song.dart';

/// Minimum duration (ms) for a file to be treated as a song.
const int _kMinDurationMs = 20 * 1000;

class MusicScanner {
  final OnAudioQuery _query = OnAudioQuery();

  // ── Permissions ─────────────────────────────────────────────────────────────

  /// Requests the appropriate storage permission depending on Android version.
  ///
  /// Returns `true` if granted.
  Future<bool> requestPermission() async {
    // On Android 13+ READ_MEDIA_AUDIO is used; on older versions
    // READ_EXTERNAL_STORAGE suffices.  permission_handler abstracts this:
    // - [Permission.audio]   → READ_MEDIA_AUDIO (Android 13+)
    // - [Permission.storage] → READ_EXTERNAL_STORAGE (Android < 13)
    PermissionStatus audioStatus = await Permission.audio.request();
    if (audioStatus.isGranted) return true;

    PermissionStatus storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  // ── Scanning ─────────────────────────────────────────────────────────────

  /// Queries all songs from the device MediaStore, filters clips shorter than
  /// [_kMinDurationMs] and maps [SongModel] → [Song].
  Future<List<Song>> scan() async {
    final List<SongModel> models = await _query.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    return models
        .where((m) => (m.duration ?? 0) >= _kMinDurationMs)
        .map((m) => Song(
              id: m.id,
              title: _clean(m.title ?? m.displayName ?? 'Unknown'),
              artist: m.artist ?? 'Unknown Artist',
              album: m.album ?? 'Unknown Album',
              path: m.data ?? '',
              duration: m.duration ?? 0,
            ))
        .toList();
  }

  // ── Artwork ──────────────────────────────────────────────────────────────

  /// Returns the embedded cover art for [songId], or `null` if unavailable.
  Future<Uint8List?> artwork(int songId) async {
    return _query.queryArtwork(songId, ArtworkType.AUDIO);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Strips file extensions and leading track numbers from a raw filename.
  ///
  /// Examples:
  ///   "01 - My Song.mp3" → "My Song"
  ///   "Track03_MyFavourite.flac" → "MyFavourite"
  ///   "Hello World" → "Hello World"
  String _clean(String title) {
    // Remove common audio extensions.
    String result = title.replaceAll(
        RegExp(r'\.(mp3|flac|aac|ogg|m4a|wav|wma|opus)$',
            caseSensitive: false),
        '');

    // Strip leading track numbers like "01 ", "01 - ", "01. ", "Track01 - ".
    result = result.replaceFirst(
        RegExp(r'^(track\s*)?\d+[\s.\-_]+', caseSensitive: false), '');

    return result.trim();
  }
}
