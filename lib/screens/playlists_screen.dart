import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../core/theme.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/scanner_provider.dart';

// ── Playlists grid ────────────────────────────────────────────────────────────

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: playlists.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.queue_music, size: 64, color: AppTheme.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'No playlists yet',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to create your first playlist',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: playlists.length,
              itemBuilder: (ctx, i) => _PlaylistCard(
                playlist: playlists[i],
                index: i,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PlaylistDetailScreen(
                        playlist: playlists[i], playlistIndex: i),
                  ),
                ),
                onDelete: () =>
                    ref.read(playlistProvider.notifier).delete(i),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(playlistProvider.notifier).create(name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Create', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }
}

// ── Playlist card ─────────────────────────────────────────────────────────────

class _PlaylistCard extends ConsumerWidget {
  const _PlaylistCard({
    required this.playlist,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  final Playlist playlist;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSongsAsync = ref.watch(allSongsProvider);
    final allSongs = allSongsAsync.valueOrNull ?? [];
    final songs = allSongs.where((s) => playlist.songIds.contains(s.id)).toList();

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _confirmDelete(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Art grid (up to 4 artworks)
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: _ArtGrid(songIds: playlist.songIds.take(4).toList()),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${songs.length} song${songs.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  Text(
                    _formatDate(playlist.createdAt),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text('Delete playlist',
                style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(ctx);
              onDelete();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

// ── Art grid ──────────────────────────────────────────────────────────────────

class _ArtGrid extends StatelessWidget {
  const _ArtGrid({required this.songIds});

  final List<int> songIds;

  @override
  Widget build(BuildContext context) {
    if (songIds.isEmpty) {
      return Container(
        color: AppTheme.surface,
        child: const Icon(Icons.queue_music,
            size: 48, color: AppTheme.textSecondary),
      );
    }

    return GridView.count(
      crossAxisCount: songIds.length >= 4 ? 2 : 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: songIds
          .take(4)
          .map((id) => QueryArtworkWidget(
                id: id,
                type: ArtworkType.AUDIO,
                artworkFit: BoxFit.cover,
                nullArtworkWidget: Container(
                  color: AppTheme.surface,
                  child: const Icon(Icons.music_note,
                      color: AppTheme.textSecondary),
                ),
              ))
          .toList(),
    );
  }
}

// ── Playlist detail ───────────────────────────────────────────────────────────

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
    required this.playlistIndex,
  });

  final Playlist playlist;
  final int playlistIndex;

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  late Playlist _playlist;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
  }

  List<Song> _getPlaylistSongs(List<Song> allSongs) {
    return _playlist.songIds
        .map((id) => allSongs.where((s) => s.id == id).firstOrNull)
        .whereType<Song>()
        .toList();
  }

  Future<void> _playAll(List<Song> songs) async {
    if (songs.isEmpty) return;
    final handler = ref.read(audioHandlerProvider);
    final items = _toMediaItems(songs);
    await handler.loadQueue(items, index: 0);
    await handler.play();
  }

  Future<void> _playSong(List<Song> songs, int index) async {
    final handler = ref.read(audioHandlerProvider);
    final items = _toMediaItems(songs);
    await handler.loadQueue(items, index: index);
    await handler.play();
  }

  List<MediaItem> _toMediaItems(List<Song> songs) => songs
      .map((s) => MediaItem(
            id: s.path,
            title: s.title,
            artist: s.artist,
            album: s.album,
            duration: Duration(milliseconds: s.duration),
            extras: {'songId': s.id},
          ))
      .toList();

  void _showRenameDialog() {
    final controller =
        TextEditingController(text: _playlist.name);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'New name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref
                    .read(playlistProvider.notifier)
                    .rename(widget.playlistIndex, name);
                setState(() {
                  _playlist = Playlist(
                    name: name,
                    songIds: _playlist.songIds,
                    createdAt: _playlist.createdAt,
                  );
                });
              }
              Navigator.pop(ctx);
            },
            child:
                const Text('Rename', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSongsAsync = ref.watch(allSongsProvider);
    final songs = allSongsAsync.whenData(_getPlaylistSongs).valueOrNull ?? [];
    final currentSong = ref.watch(currentSongProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(_playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showRenameDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              ref
                  .read(playlistProvider.notifier)
                  .delete(widget.playlistIndex);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Play All button
          if (songs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play All'),
                  onPressed: () => _playAll(songs),
                ),
              ),
            ),

          // Song list with drag handles
          Expanded(
            child: songs.isEmpty
                ? const Center(
                    child: Text(
                      'No songs in this playlist',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: songs.length,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex--;
                      ref
                          .read(playlistProvider.notifier)
                          .reorderSong(widget.playlistIndex, oldIndex, newIndex);
                      setState(() {
                        final id = _playlist.songIds.removeAt(oldIndex);
                        _playlist.songIds.insert(newIndex, id);
                      });
                    },
                    itemBuilder: (ctx, i) {
                      final song = songs[i];
                      final isPlaying = currentSong?.id == song.path;
                      return ListTile(
                        key: ValueKey(song.id),
                        leading: QueryArtworkWidget(
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          artworkWidth: 44,
                          artworkHeight: 44,
                          artworkBorderRadius: BorderRadius.circular(6),
                          nullArtworkWidget: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.card,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.music_note,
                                color: AppTheme.textSecondary, size: 20),
                          ),
                        ),
                        title: Text(
                          song.title,
                          style: TextStyle(
                            color: isPlaying
                                ? AppTheme.accent
                                : AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          song.artist,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(song.durationStr,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                            const SizedBox(width: 8),
                            const Icon(Icons.drag_handle,
                                color: AppTheme.textSecondary),
                          ],
                        ),
                        onTap: () => _playSong(songs, i),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
