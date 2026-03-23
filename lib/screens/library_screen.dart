import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../core/theme.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/scanner_provider.dart';
import 'player_screen.dart';
import 'playlists_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Sort bottom sheet ──────────────────────────────────────────────────────

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Sort by', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          for (final sort in SongSort.values)
            ListTile(
              title: Text(sort.name[0].toUpperCase() + sort.name.substring(1)),
              trailing: ref.watch(sortProvider) == sort
                  ? const Icon(Icons.check, color: AppTheme.accent)
                  : null,
              onTap: () {
                ref.read(sortProvider.notifier).state = sort;
                Navigator.pop(ctx);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Song options sheet ─────────────────────────────────────────────────────

  void _showSongOptions(Song song) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final favorites = ref.watch(favoritesProvider);
          final isFav = favorites.contains(song.id);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? AppTheme.accent : null,
                ),
                title: Text(isFav ? 'Remove from Favorites' : 'Add to Favorites'),
                onTap: () {
                  ref.read(favoritesProvider.notifier).toggle(song.id);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Add to Playlist'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddToPlaylist(song);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddToPlaylist(Song song) {
    final playlists = ref.read(playlistProvider);
    if (playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No playlists yet — create one first.')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Choose playlist', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (int i = 0; i < playlists.length; i++)
            ListTile(
              title: Text(playlists[i].name),
              onTap: () {
                ref.read(playlistProvider.notifier).addSong(i, song.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added to ${playlists[i].name}')),
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Play a song ──────────────────────────────────────────────────────────

  Future<void> _playSong(List<Song> songs, int index) async {
    final handler = ref.read(audioHandlerProvider);
    final items = songs
        .map((s) => MediaItem(
              id: s.path,
              title: s.title,
              artist: s.artist,
              album: s.album,
              duration: Duration(milliseconds: s.duration),
              extras: {'songId': s.id},
            ))
        .toList();
    await handler.loadQueue(items, index: index);
    await handler.play();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredSongsProvider);
    final currentSong = ref.watch(currentSongProvider).valueOrNull;

    return Scaffold(
      body: Column(
        children: [
          _buildAppBar(filteredAsync),
          _buildSearchBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSongsTab(filteredAsync, currentSong),
                _buildGroupedTab(filteredAsync, groupBy: (s) => s.album, label: 'Albums'),
                _buildGroupedTab(filteredAsync, groupBy: (s) => s.artist, label: 'Artists'),
                const PlaylistsScreen(),
              ],
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar(AsyncValue<List<Song>> songsAsync) {
    final count = songsAsync.valueOrNull?.length ?? 0;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pulse',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '$count songs',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: _showSortSheet,
              tooltip: 'Sort',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(allSongsProvider),
              tooltip: 'Rescan',
            ),
          ],
        ),
      ),
    );
  }

  // ── Search bar ───────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Search songs, artists, albums…',
          prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Songs'),
        Tab(text: 'Albums'),
        Tab(text: 'Artists'),
        Tab(text: 'Playlists'),
      ],
    );
  }

  // ── Songs tab ─────────────────────────────────────────────────────────────

  Widget _buildSongsTab(
      AsyncValue<List<Song>> songsAsync, MediaItem? currentSong) {
    return songsAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.accent),
            SizedBox(height: 16),
            Text('Scanning device…', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e', style: const TextStyle(color: AppTheme.textSecondary)),
      ),
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_off, size: 64, color: AppTheme.textSecondary),
                SizedBox(height: 16),
                Text(
                  'No music found on device',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          itemExtent: 64,
          itemCount: songs.length,
          itemBuilder: (ctx, i) => _SongTile(
            song: songs[i],
            isPlaying: currentSong?.id == songs[i].path,
            onTap: () => _playSong(songs, i),
            onLongPress: () => _showSongOptions(songs[i]),
          ),
        );
      },
    );
  }

  // ── Grouped tab (Albums / Artists) ────────────────────────────────────────

  Widget _buildGroupedTab(
    AsyncValue<List<Song>> songsAsync, {
    required String Function(Song) groupBy,
    required String label,
  }) {
    return songsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (songs) {
        if (songs.isEmpty) {
          return Center(
            child: Text('No $label found', style: const TextStyle(color: AppTheme.textSecondary)),
          );
        }
        final grouped = <String, List<Song>>{};
        for (final song in songs) {
          grouped.putIfAbsent(groupBy(song), () => []).add(song);
        }
        final keys = grouped.keys.toList()..sort();
        return ListView.builder(
          itemCount: keys.length,
          itemBuilder: (ctx, i) {
            final key = keys[i];
            final group = grouped[key]!;
            return ListTile(
              leading: QueryArtworkWidget(
                id: group.first.id,
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
                  child: const Icon(Icons.music_note, color: AppTheme.textSecondary, size: 20),
                ),
              ),
              title: Text(key, style: const TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text(
                '${group.length} song${group.length == 1 ? '' : 's'}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Song tile ────────────────────────────────────────────────────────────────

class _SongTile extends StatelessWidget {
  const _SongTile({
    required this.song,
    required this.isPlaying,
    required this.onTap,
    required this.onLongPress,
  });

  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        height: 64,
        color: isPlaying ? AppTheme.accent.withValues(alpha: 0.12) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Artwork
            QueryArtworkWidget(
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
            const SizedBox(width: 12),
            // Title + artist · album
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isPlaying ? AppTheme.accent : AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${song.artist} · ${song.album}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Duration
            Text(
              song.durationStr,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
