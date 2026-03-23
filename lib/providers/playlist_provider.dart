import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/playlist.dart';

// ── Playlists ─────────────────────────────────────────────────────────────────

class PlaylistNotifier extends StateNotifier<List<Playlist>> {
  PlaylistNotifier() : super([]) {
    _load();
  }

  Box<Playlist> get _box => Hive.box<Playlist>('playlists');

  void _load() {
    state = _box.values.toList();
  }

  Future<void> create(String name) async {
    final playlist = Playlist(
      name: name,
      songIds: [],
      createdAt: DateTime.now(),
    );
    await _box.add(playlist);
    _load();
  }

  Future<void> addSong(int playlistIndex, int songId) async {
    final playlist = _box.getAt(playlistIndex);
    if (playlist == null) return;
    playlist.songIds.add(songId);
    await playlist.save();
    _load();
  }

  Future<void> removeSong(int playlistIndex, int songId) async {
    final playlist = _box.getAt(playlistIndex);
    if (playlist == null) return;
    playlist.songIds.remove(songId);
    await playlist.save();
    _load();
  }

  Future<void> reorderSong(
      int playlistIndex, int oldIndex, int newIndex) async {
    final playlist = _box.getAt(playlistIndex);
    if (playlist == null) return;
    final id = playlist.songIds.removeAt(oldIndex);
    playlist.songIds.insert(newIndex, id);
    await playlist.save();
    _load();
  }

  Future<void> rename(int playlistIndex, String newName) async {
    final playlist = _box.getAt(playlistIndex);
    if (playlist == null) return;
    playlist.name = newName;
    await playlist.save();
    _load();
  }

  Future<void> delete(int playlistIndex) async {
    await _box.deleteAt(playlistIndex);
    _load();
  }
}

final playlistProvider =
    StateNotifierProvider<PlaylistNotifier, List<Playlist>>(
  (ref) => PlaylistNotifier(),
);

// ── Favorites ─────────────────────────────────────────────────────────────────

class FavoritesNotifier extends StateNotifier<Set<int>> {
  FavoritesNotifier() : super({}) {
    _load();
  }

  Box<int> get _box => Hive.box<int>('favorites');

  void _load() {
    state = _box.values.toSet();
  }

  Future<void> toggle(int songId) async {
    if (state.contains(songId)) {
      // Remove
      final key = _box.keys.firstWhere(
        (k) => _box.get(k) == songId,
        orElse: () => null,
      );
      if (key != null) await _box.delete(key);
    } else {
      await _box.add(songId);
    }
    _load();
  }

  bool isFavorite(int songId) => state.contains(songId);
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<int>>(
  (ref) => FavoritesNotifier(),
);
