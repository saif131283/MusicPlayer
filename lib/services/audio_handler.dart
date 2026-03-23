import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class PulseAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  PulseAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty) {
        mediaItem.add(queue.value[index]);
      }
    });
  }

  // ── Queue ─────────────────────────────────────────────────────────────────

  /// Loads [items] into a [ConcatenatingAudioSource] and starts playback at
  /// [index].
  Future<void> loadQueue(List<MediaItem> items, {int index = 0}) async {
    queue.add(items);

    final sources = items
        .map((item) => AudioSource.uri(Uri.parse(item.id)))
        .toList();

    final concatenating = ConcatenatingAudioSource(children: sources);
    await _player.setAudioSource(concatenating, initialIndex: index);
    mediaItem.add(items[index]);
  }

  /// Seeks to [index] in the current queue and starts playback.
  Future<void> jumpTo(int index) async {
    await _player.seek(Duration.zero, index: index);
    await _player.play();
  }

  // ── Playback controls ─────────────────────────────────────────────────────

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) => jumpTo(index);

  // ── Shuffle / Repeat ──────────────────────────────────────────────────────

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await super.setShuffleMode(shuffleMode);
    await _player
        .setShuffleModeEnabled(shuffleMode == AudioServiceShuffleMode.all);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await super.setRepeatMode(repeatMode);
    final loopMode = switch (repeatMode) {
      AudioServiceRepeatMode.one => LoopMode.one,
      AudioServiceRepeatMode.all => LoopMode.all,
      _ => LoopMode.off,
    };
    await _player.setLoopMode(loopMode);
  }

  // ── Position ──────────────────────────────────────────────────────────────

  Stream<Duration> get positionStream => _player.positionStream;

  Duration get position => _player.position;

  // ── State broadcast ──────────────────────────────────────────────────────

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: switch (_player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
      ),
    );
  }
}
