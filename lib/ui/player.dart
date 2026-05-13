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

  @override State<PlayerPage> createState() => _PlayerPageState();
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

  @override
  void initState() {
    super.initState();
    _loadData();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    currentEpisode = widget.ep != null ? int.parse(widget.ep!) : (prefs.getInt('last_ep_${widget.id}') ?? 1);
    currentQuality = prefs.getString('pref_quality') ?? "Auto";
    
    // Load detail drama + episodes
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
    
    // Save to history
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
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => showControls = false);
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

  @override
  void dispose() {
    _controller?.dispose();
    _hideTimer?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Video Player Area
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _toggleControls,
              child: Stack(
                children: [
                  Center(
                    child: isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF06B6D4))
                        : _controller != null && _controller!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: _controller!.value.aspectRatio,
                                child: VideoPlayer(_controller!),
                              )
                            : const Center(
                                child: Text("Video tidak tersedia", style: TextStyle(color: Colors.white)),
                              ),
                  ),
                  if (showControls && !isLoading && _controller != null && _controller!.value.isInitialized)
                    Container(
                      color: Colors.black54,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top bar
                          Padding(
                            padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "$widget.title - Episode $currentEpisode",
                                    style: const TextStyle(color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _showQualityDialog,
                                  child: Text(currentQuality, style: const TextStyle(color: Color(0xFF06B6D4))),
                                ),
                              ],
                            ),
                          ),
                          // Bottom controls
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Slider(
                                  value: _position,
                                  max: _duration,
                                  activeColor: const Color(0xFF06B6D4),
                                  inactiveColor: Colors.white30,
                                  onChanged: _seekTo,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.skip_previous, color: Colors.white),
                                      onPressed: _prevEpisode,
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isPlaying ? Icons.pause : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                      onPressed: _togglePlay,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.skip_next, color: Colors.white),
                                      onPressed: _nextEpisode,
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    TextButton(
                                      onPressed: _skipBackward,
                                      child: const Text("-10s", style: TextStyle(color: Colors.white70)),
                                    ),
                                    TextButton(
                                      onPressed: _skipForward,
                                      child: const Text("+10s", style: TextStyle(color: Colors.white70)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Episode List
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFF0D1117),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "DAFTAR EPISODE",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "$totalEpisodes Episode",
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: episodes.length,
                      itemBuilder: (context, index) {
                        final episode = episodes[index];
                        final episodeNum = episode['index'] ?? index + 1;
                        final isCurrent = episodeNum == currentEpisode;
                        return GestureDetector(
                          onTap: () => _loadVideo(episodeNum),
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isCurrent ? const Color(0xFF06B6D4) : const Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_circle_outline,
                                  color: isCurrent ? Colors.white : const Color(0xFF06B6D4),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$episodeNum",
                                  style: TextStyle(
                                    color: isCurrent ? Colors.white : Colors.white70,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
