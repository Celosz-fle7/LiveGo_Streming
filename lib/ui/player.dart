import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'api_service.dart';
import '../database/database_helper.dart';

class PlayerPage extends StatefulWidget {
  final String id, source, title;
  final String? ep;
  const PlayerPage({super.key, required this.id, required this.source, required this.title, this.ep});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  VideoPlayerController? _controller;
  List episodes = [];
  Map? dramaData;
  bool isLoading = true;
  bool isPlaying = true;
  bool showControls = true;
  int currentEpisode = 1;
  int totalEpisodes = 0;
  double _position = 0;
  double _duration = 0;
  Timer? _hideTimer;
  String currentQuality = "Auto";
  List qualities = [];
  bool isFullMode = false;
  bool isFavorite = false;
  double? videoAspectRatio;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    isFavorite = await DatabaseHelper().isFavorite(widget.id);
    setState(() {});
  }

  Future<void> _toggleFavorite() async {
    if (isFavorite) {
      await DatabaseHelper().removeFromFavorites(widget.id);
    } else {
      await DatabaseHelper().addToFavorites({
        'drama_id': widget.id,
        'drama_title': widget.title,
        'drama_poster': dramaData?['cover'],
        'total_episodes': dramaData?['total_episodes'] ?? totalEpisodes,
        'platform': widget.source,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
    setState(() => isFavorite = !isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isFavorite ? "Ditambahkan ke favorit" : "Dihapus dari favorit"), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    currentEpisode = widget.ep != null ? int.parse(widget.ep!) : (prefs.getInt('last_ep_${widget.id}') ?? 1);
    currentQuality = prefs.getString('pref_quality') ?? "Auto";
    
    final res = await ApiService.get("/api/v2/detail?category_p=${widget.source}&id=${widget.id}&lang=id");
    if (res != null && res['data'] != null) {
      setState(() {
        dramaData = res['data'];
        episodes = dramaData?['chapters'] ?? [];
        totalEpisodes = episodes.length;
      });
      await _loadVideo(currentEpisode);
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadVideo(int episodeNum) async {
    setState(() {
      isLoading = true;
      currentEpisode = episodeNum;
    });
    
    await DatabaseHelper().addToHistory({
      'drama_id': widget.id,
      'drama_title': widget.title,
      'drama_poster': dramaData?['cover'],
      'episode_id': episodeNum.toString(),
      'episode_number': episodeNum,
      'position_seconds': 0,
      'duration_seconds': 0,
      'last_watched': DateTime.now().millisecondsSinceEpoch,
      'platform': widget.source,
    });
    
    final res = await ApiService.get("/api/v2/video?category_p=${widget.source}&id=${widget.id}&chapterId=$episodeNum&lang=id");
    
    if (res != null && res['success'] == true && res['data'] != null) {
      final videoData = res['data'];
      qualities = videoData['streams'] ?? [];
      
      String videoUrl = '';
      if (qualities.isNotEmpty) {
        for (var q in qualities) {
          if (q['quality'] == currentQuality) {
            videoUrl = q['url'];
            break;
          }
        }
        if (videoUrl.isEmpty) videoUrl = qualities[0]['url'];
      }
      
      if (videoUrl.isNotEmpty) {
        _controller?.dispose();
        _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
          ..initialize().then((_) {
            setState(() {
              isLoading = false;
              _duration = _controller!.value.duration.inSeconds.toDouble();
              videoAspectRatio = _controller!.value.aspectRatio;
            });
            _controller!.play();
            isPlaying = true;
            _startHideTimer();
          });
        
        _controller!.addListener(() {
          if (mounted) {
            setState(() {
              _position = _controller!.value.position.inSeconds.toDouble();
              _duration = _controller!.value.duration.inSeconds.toDouble();
            });
          }
          if (_controller!.value.position >= _controller!.value.duration && _controller!.value.duration != Duration.zero) {
            _nextEpisode();
          }
        });
        
        final prefs = await SharedPreferences.getInstance();
        prefs.setInt('last_ep_${widget.id}', episodeNum);
      } else {
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && showControls) setState(() => showControls = false);
    });
  }

  void _toggleControls() {
    setState(() {
      showControls = !showControls;
      if (showControls) _startHideTimer();
    });
  }

  void _togglePlay() {
    if (_controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        isPlaying = false;
      } else {
        _controller!.play();
        isPlaying = true;
      }
    });
  }

  void _skipForward() {
    if (_controller == null) return;
    final newPos = _controller!.value.position + const Duration(seconds: 10);
    _controller!.seekTo(newPos);
  }

  void _skipBackward() {
    if (_controller == null) return;
    final newPos = _controller!.value.position - const Duration(seconds: 10);
    _controller!.seekTo(newPos);
  }

  void _seekTo(double seconds) {
    if (_controller == null) return;
    _controller!.seekTo(Duration(seconds: seconds.toInt()));
  }

  void _nextEpisode() {
    if (currentEpisode < totalEpisodes) {
      _loadVideo(currentEpisode + 1);
    }
  }

  void _prevEpisode() {
    if (currentEpisode > 1) {
      _loadVideo(currentEpisode - 1);
    }
  }

  void _toggleFullMode() {
    setState(() {
      isFullMode = !isFullMode;
    });
  }

  void _showQualityDialog() {
    if (qualities.isEmpty) return;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text("Kualitas Video", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: qualities.map((q) {
            final quality = q['quality'] ?? 'Auto';
            return ListTile(
              title: Text(quality, style: const TextStyle(color: Colors.white)),
              trailing: currentQuality == quality ? const Icon(Icons.check, color: Color(0xFF06B6D4)) : null,
              onTap: () async {
                currentQuality = quality;
                final prefs = await SharedPreferences.getInstance();
                prefs.setString('pref_quality', currentQuality);
                Navigator.pop(c);
                _loadVideo(currentEpisode);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  bool _isPotrait() {
    return videoAspectRatio != null && videoAspectRatio! < 1;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = videoAspectRatio != null && videoAspectRatio! > 1;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Video Player
            Center(
              child: isLoading
                  ? const CircularProgressIndicator(color: Color(0xFF06B6D4))
                  : _controller != null && _controller!.value.isInitialized
                      ? (isFullMode
                          ? (isLandscape
                              ? AspectRatio(
                                  aspectRatio: _controller!.value.aspectRatio,
                                  child: VideoPlayer(_controller!),
                                )
                              : Center(
                                  child: AspectRatio(
                                    aspectRatio: _controller!.value.aspectRatio,
                                    child: VideoPlayer(_controller!),
                                  ),
                                ))
                          : AspectRatio(
                              aspectRatio: _controller!.value.aspectRatio,
                              child: VideoPlayer(_controller!),
                            ))
                      : const Center(
                          child: Text("Video tidak tersedia", style: TextStyle(color: Colors.white)),
                        ),
            ),
            
            // Top Bar (judul, kualitas, favorit, fullscreen)
            if (showControls && !isLoading && _controller != null && _controller!.value.isInitialized)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.black54, Colors.transparent]),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${widget.title} - Ep $currentEpisode / $totalEpisodes",
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: _showQualityDialog,
                        child: Text(
                          currentQuality,
                          style: const TextStyle(color: Color(0xFF06B6D4)),
                        ),
                      ),
                      IconButton(
                        icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                        onPressed: _toggleFavorite,
                      ),
                      IconButton(
                        icon: Icon(isFullMode ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white),
                        onPressed: _toggleFullMode,
                      ),
                    ],
                  ),
                ),
              ),
            
            // Bottom Controls (play/pause, skip, prev/next)
            if (showControls && !isLoading && _controller != null && _controller!.value.isInitialized)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.black87, Colors.transparent]),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(_formatDuration(_position), style: const TextStyle(color: Colors.white, fontSize: 12)),
                          Expanded(
                            child: Slider(
                              value: _position,
                              max: _duration,
                              activeColor: const Color(0xFF06B6D4),
                              inactiveColor: Colors.white30,
                              onChanged: _seekTo,
                            ),
                          ),
                          Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _controlButton(Icons.replay_10, _skipBackward),
                          const SizedBox(width: 30),
                          _controlButton(isPlaying ? Icons.pause : Icons.play_arrow, _togglePlay, isPlay: true),
                          const SizedBox(width: 30),
                          _controlButton(Icons.forward_10, _skipForward),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _controlButton(Icons.skip_previous, _prevEpisode),
                          const SizedBox(width: 40),
                          _controlButton(Icons.skip_next, _nextEpisode),
                        ],
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

  Widget _controlButton(IconData icon, VoidCallback onTap, {bool isPlay = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isPlay ? 12 : 8),
        decoration: isPlay
            ? BoxDecoration(color: const Color(0xFF06B6D4), shape: BoxShape.circle)
            : null,
        child: Icon(icon, color: Colors.white, size: isPlay ? 32 : 24),
      ),
    );
  }
}
