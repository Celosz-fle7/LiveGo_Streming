import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../api_service.dart';

class TVPlayerPage extends StatefulWidget {
  final String id, source, title;
  const TVPlayerPage({super.key, required this.id, required this.source, required this.title});
  @override State<TVPlayerPage> createState() => _TVPlayerPageState();
}

class _TVPlayerPageState extends State<TVPlayerPage> {
  VideoPlayerController? _controller;
  final FocusNode _playerFocusNode = FocusNode();
  List qualities = [];
  bool isLoading = true, isPlaying = true, showControls = true;
  String currentQuality = "720p";
  int currentEpisode = 1;
  double _position = 0, _duration = 0;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _playerFocusNode.requestFocus();
    _loadTVVideo();
  }

  @override
  void dispose() {
    _playerFocusNode.dispose();
    _controller?.dispose();
    _controlsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTVVideo() async {
    setState(() => isLoading = true);
    final res = await ApiService.get("/api/v2/video?category_p=${widget.source}&id=${widget.id}&chapterId=$currentEpisode&lang=id");
    if (res != null && res['success'] == true && res['data'] != null) {
      qualities = res['data']['streams'] ?? [];
      String videoUrl = '';
      
      // Logika Estafet Default: Cari 720p, jika tidak ada fallback ke resolusi pertama
      for (var q in qualities) { if (q['quality'].toString().contains('720')) { videoUrl = q['url'] ?? ''; break; } }
      if (videoUrl.isEmpty && qualities.isNotEmpty) videoUrl = qualities[0]['url'] ?? '';

      if (videoUrl.isNotEmpty) {
        _controller?.dispose();
        _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
          ..initialize().then((_) {
            setState(() {
              isLoading = false;
              _duration = _controller!.value.duration.inSeconds.toDouble();
            });
            _controller!.play();
            _startTimer();
          });

        _controller!.addListener(() {
          if (!mounted) return;
          setState(() {
            _position = _controller!.value.position.inSeconds.toDouble();
          });
        });
      } else { setState(() => isLoading = false); }
    } else { setState(() => isLoading = false); }
  }

  void _startTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => showControls = false);
    });
  }

  void _handleTVRemote(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    setState(() => showControls = true);
    _startTimer();

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (_controller != null) {
        setState(() {
          if (_controller!.value.isPlaying) {
            _controller!.pause(); isPlaying = false;
          } else {
            _controller!.play(); isPlaying = true;
          }
        });
      }
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _controller?.seekTo(_controller!.value.position + const Duration(seconds: 10));
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _controller?.seekTo(_controller!.value.position - const Duration(seconds: 10));
    } else if (key == LogicalKeyboardKey.arrowUp) {
      currentEpisode++;
      _loadTVVideo();
    } else if (key == LogicalKeyboardKey.arrowDown && currentEpisode > 1) {
      currentEpisode--;
      _loadTVVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: RawKeyboardListener(
        focusNode: _playerFocusNode,
        onKey: _handleTVRemote,
        child: Stack(
          children: [
            Center(
              child: isLoading
                  ? const CircularProgressIndicator(color: Color(0xFF06B6D4))
                  : _controller != null && _controller!.value.isInitialized
                      ? AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!))
                      : const Text("Video tidak tersedia", style: TextStyle(color: Colors.white)),
            ),
            if (showControls && !isLoading)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("${widget.title} - Episode $currentEpisode", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Text("${_position.toInt()}s", style: const TextStyle(color: Colors.white)),
                          Expanded(child: Slider(value: _position, max: _duration > 0 ? _duration : 1, activeColor: const Color(0xFF06B6D4), onChanged: (v) {})),
                          Text("${_duration.toInt()}s", style: const TextStyle(color: Colors.white)),
                        ],
                      )
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
