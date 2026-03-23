import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/song.dart';
import '../services/scanner.dart';

// ── Scanner ───────────────────────────────────────────────────────────────────

final scannerProvider = Provider<MusicScanner>((ref) => MusicScanner());

// ── All songs ─────────────────────────────────────────────────────────────────

final allSongsProvider = FutureProvider<List<Song>>((ref) async {
  final scanner = ref.watch(scannerProvider);
  final granted = await scanner.requestPermission();
  if (!granted) return [];
  return scanner.scan();
});

// ── Search ────────────────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

// ── Sort ──────────────────────────────────────────────────────────────────────

enum SongSort { title, artist, album, duration }

final sortProvider = StateProvider<SongSort>((ref) => SongSort.title);

// ── Filtered + sorted songs ───────────────────────────────────────────────────

final filteredSongsProvider = Provider<AsyncValue<List<Song>>>((ref) {
  final songsAsync = ref.watch(allSongsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final sort = ref.watch(sortProvider);

  return songsAsync.whenData((songs) {
    // Filter
    final filtered = query.isEmpty
        ? songs
        : songs
            .where((s) =>
                s.title.toLowerCase().contains(query) ||
                s.artist.toLowerCase().contains(query) ||
                s.album.toLowerCase().contains(query))
            .toList();

    // Sort
    filtered.sort((a, b) => switch (sort) {
          SongSort.title => a.title.compareTo(b.title),
          SongSort.artist => a.artist.compareTo(b.artist),
          SongSort.album => a.album.compareTo(b.album),
          SongSort.duration => a.duration.compareTo(b.duration),
        });

    return filtered;
  });
});
