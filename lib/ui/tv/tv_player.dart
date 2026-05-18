// lib/tv/tv_player.dart
//
// TV Player stabil untuk Android TV.
// Fitur:
// - Play / Pause (OK)
// - Seek -10 detik (LEFT)
// - Seek +10 detik (RIGHT)
// - Episode sebelumnya (DOWN)
// - Episode berikutnya (UP)
// - Back untuk kembali
// - Auto hide controls
// - Fokus remote stabil

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../api_service.dart';

class TVPlayerPage extends StatefulWidget {
  final String id;
  final String source;
  final String title;

  const TVPlayerPage({
    super.key,
    required this.id,
    required this.source,
    required this.title,
  });

  @override
  State<TVPlayerPage> createState() => _TVPlayerPageState();
}

class _TVPlayerPageState extends State<TVPlayerPage> {
  VideoPlayerController? _controller;
  final FocusNode _playerFocusNode = FocusNode();

  List<dynamic> qualities = [];

  bool isLoading = true;
  bool showControls = true;
  bool isPlaying = true;

  String currentQuality = '720p';
  int currentEpisode = 1;

  double _position = 0;
  double _duration = 0;

  Timer? _hideControlsTimer;
  Timer? _positionTimer;

  @override
  void initState() {
    super.initState();

    _loadTVVideo();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _playerFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _positionTimer?.cancel();
    _controller?.dispose();
    _playerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadTVVideo() async {
    setState(() {
      isLoading = true;
      showControls = true;
    });

    final res = await ApiService.get(
      "/api/v2/video"
      "?category_p=${widget.source}"
      "&id=${widget.id}"
      "&chapterId=$currentEpisode"
      "&lang=id",
    );

    if (!mounted) return;

    if (res == null ||
        res['success'] != true ||
        res['data'] == null) {
      setState(() => isLoading = false);
      return;
    }

    qualities = res['data']['streams'] ?? [];

    String videoUrl = '';

    // Cari 720p terlebih dahulu
    for (final q in qualities) {
      final quality = (q['quality'] ?? '').toString();
      if (quality.contains('720')) {
        videoUrl = q['url'] ?? '';
        currentQuality = quality;
        break;
      }
    }

    // Fallback ke stream pertama
    if (videoUrl.isEmpty && qualities.isNotEmpty) {
      videoUrl = qualities.first['url'] ?? '';
      currentQuality =
          (qualities.first['quality'] ?? 'Auto').toString();
    }

    if (videoUrl.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    // Dispose controller lama
    await _controller?.dispose();

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
    );

    _controller = controller;

    try {
      await controller.initialize();

      if (!mounted) return;

      _duration =
          controller.value.duration.inSeconds.toDouble();

      await controller.play();

      isPlaying = true;
      isLoading = false;

      setState(() {});

      _startHideControlsTimer();
      _startPositionTimer();
    } catch (_) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();

    _positionTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) {
        if (!mounted || _controller == null) return;

        final value = _controller!.value;

        if (!value.isInitialized) return;

        setState(() {
          _position =
              value.position.inSeconds.toDouble();
          _duration =
              value.duration.inSeconds.toDouble();
          isPlaying = value.isPlaying;
        });
      },
    );
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();

    _hideControlsTimer = Timer(
      const Duration(seconds: 5),
      () {
        if (mounted) {
          setState(() {
            showControls = false;
          });
        }
      },
    );
  }

  void _showControls() {
    if (!mounted) return;

    setState(() {
      showControls = true;
    });

    _startHideControlsTimer();
  }

  void _togglePlayPause() {
    if (_controller == null) return;

    if (_controller!.value.isPlaying) {
      _controller!.pause();
      isPlaying = false;
    } else {
      _controller!.play();
      isPlaying = true;
    }

    setState(() {});
  }

  void _seekRelative(int seconds) {
    if (_controller == null) return;

    final current =
        _controller!.value.position.inSeconds;
    final target = current + seconds;

    final clamped = target.clamp(
      0,
      _duration.toInt(),
    );

    _controller!.seekTo(
      Duration(seconds: clamped),
    );
  }

  Future<void> _changeEpisode(int delta) async {
    final newEpisode = currentEpisode + delta;

    if (newEpisode < 1) return;

    currentEpisode = newEpisode;
    await _loadTVVideo();
  }

  KeyEventResult _handleTVRemote(
    FocusNode node,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    _showControls();

    final key = event.logicalKey;

    // Back
    if (key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }

    // OK / Enter
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      _togglePlayPause();
      return KeyEventResult.handled;
    }

    // Seek +10 detik
    if (key == LogicalKeyboardKey.arrowRight) {
      _seekRelative(10);
      return KeyEventResult.handled;
    }

    // Seek -10 detik
    if (key == LogicalKeyboardKey.arrowLeft) {
      _seekRelative(-10);
      return KeyEventResult.handled;
    }

    // Episode berikutnya
    if (key == LogicalKeyboardKey.arrowUp) {
      _changeEpisode(1);
      return KeyEventResult.handled;
    }

    // Episode sebelumnya
    if (key == LogicalKeyboardKey.arrowDown) {
      _changeEpisode(-1);
      return KeyEventResult.handled;
    }

    return KeyEventResult.handled;
  }

  String _formatDuration(double seconds) {
    final duration =
        Duration(seconds: seconds.toInt());

    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);

    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }

    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _playerFocusNode,
        autofocus: true,
        onKeyEvent: _handleTVRemote,
        child: Stack(
          children: [
            // Video
            Center(
              child: isLoading
                  ? const CircularProgressIndicator(
                      color: Color(0xFF06B6D4),
                    )
                  : controller != null &&
                          controller.value.isInitialized
                      ? AspectRatio(
                          aspectRatio:
                              controller.value.aspectRatio,
                          child: VideoPlayer(controller),
                        )
                      : const Text(
                          'Video tidak tersedia',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
            ),

            // Overlay Controls
            if (showControls && !isLoading)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Episode $currentEpisode • $currentQuality',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),

                      SliderTheme(
                        data: SliderTheme.of(context)
                            .copyWith(
                          trackHeight: 4,
                          thumbShape:
                              const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                        ),
                        child: Slider(
                          value: _position.clamp(
                            0,
                            _duration > 0
                                ? _duration
                                : 1,
                          ),
                          max:
                              _duration > 0 ? _duration : 1,
                          activeColor:
                              const Color(0xFF06B6D4),
                          inactiveColor:
                              Colors.white24,
                          onChanged: (_) {},
                        ),
                      ),

                      Row(
                        children: [
                          Text(
                            _formatDuration(
                                _position),
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            isPlaying
                                ? Icons.pause_circle
                                : Icons.play_circle,
                            color: Colors.white,
                            size: 28,
                          ),
                          const Spacer(),
                          Text(
                            _formatDuration(
                                _duration),
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'OK: Play/Pause   ◀▶: Seek 10s   ▲▼: Episode   Back: Kembali',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
