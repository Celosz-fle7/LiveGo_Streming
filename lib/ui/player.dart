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
  List episodes = [], qualities = [];
  Map? dramaData;
  bool isLoading = true, isPlaying = true, showControls = true, isFavorite = false, _showEpisodeSidebar = false;
  int currentEpisode = 1, totalEpisodes = 0;
  double _position = 0, _duration = 0;
  Timer? _hideTimer;
  String currentQuality = "Auto";
  double? videoAspectRatio;

  @override
  void initState() {
    super.initState();
    // PAKSA LAYAR HP BERPUTAR LANDSCAPE SECARA TOTAL (Gaya Cineflow)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    // SEMBUNYIKAN STATUS BAR ATAS & NAVIGASI BAWAH HP
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadData();
    _checkFavorite();
  }

  @override
  void dispose() {
    // KEMBALIKAN LAYAR HP KE MODE TEGAK (PORTRAIT) SAAT KELUAR DARI PLAYER
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkFavorite() async { isFavorite = await DatabaseHelper().isFavorite(widget.id); setState(() {}); }

  Future<void> _toggleFavorite() async {
    if (isFavorite) { await DatabaseHelper().removeFromFavorites(widget.id); } 
    else {
      await DatabaseHelper().addToFavorites({
        'drama_id': widget.id, 'drama_title': widget.title, 'drama_poster': dramaData?['cover'],
        'total_episodes': dramaData?['total_episodes'] ?? totalEpisodes, 'platform': widget.source,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
    setState(() => isFavorite = !isFavorite);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    currentEpisode = widget.ep != null ? int.parse(widget.ep!) : (prefs.getInt('last_ep_${widget.id}') ?? 1);
    currentQuality = prefs.getString('pref_quality') ?? "Auto";
    
    final res = await ApiService.get("/api/v2/detail?category_p=${widget.source}&id=${widget.id}&lang=id");
    if (res != null && res['data'] != null) {
      setState(() { dramaData = res['data']; episodes = dramaData?['chapters'] ?? []; totalEpisodes = episodes.length; });
      await _loadVideo(currentEpisode);
    } else { setState(() => isLoading = false); }
  }

  Future<void> _loadVideo(int episodeNum) async {
    setState(() { isLoading = true; currentEpisode = episodeNum; });
    await DatabaseHelper().addToHistory({
      'drama_id': widget.id, 'drama_title': widget.title, 'drama_poster': dramaData?['cover'],
      'episode_id': episodeNum.toString(), 'episode_number': episodeNum, 'position_seconds': 0,
      'duration_seconds': 0, 'last_watched': DateTime.now().millisecondsSinceEpoch, 'platform': widget.source,
    });
    
    final res = await ApiService.get("/api/v2/video?category_p=${widget.source}&id=${widget.id}&chapterId=$episodeNum&lang=id");
    if (res != null && res['success'] == true && res['data'] != null) {
      qualities = res['data']['streams'] ?? [];
      String videoUrl = '';
      if (qualities.isNotEmpty) {
        for (var q in qualities) { if (q['quality'] == currentQuality) { videoUrl = q['url']; break; } }
        if (videoUrl.isEmpty) videoUrl = qualities[0]['url'];
      }
      
      if (videoUrl.isNotEmpty) {
        _controller?.dispose();
        _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
          ..initialize().then((_) {
            setState(() { isLoading = false; _duration = _controller!.value.duration.inSeconds.toDouble(); videoAspectRatio = _controller!.value.aspectRatio; });
            _controller!.play(); isPlaying = true; _startHideTimer();
          });
        _controller!.addListener(() {
          if (mounted) setState(() { _position = _controller!.value.position.inSeconds.toDouble(); _duration = _controller!.value.duration.inSeconds.toDouble(); });
          if (_controller!.value.position >= _controller!.value.duration && _controller!.value.duration != Duration.zero) _nextEpisode();
        });
        final prefs = await SharedPreferences.getInstance(); prefs.setInt('last_ep_${widget.id}', episodeNum);
      } else { setState(() => isLoading = false); }
    } else { setState(() => isLoading = false); }
  }

  void _startHideTimer() { 
    if (_showEpisodeSidebar) return; 
    _hideTimer?.cancel(); 
    _hideTimer = Timer(const Duration(seconds: 4), () { if (mounted && showControls) setState(() => showControls = false); }); 
  }
  
  void _toggleControls() { setState(() { showControls = !showControls; if (showControls) _startHideTimer(); }); }
  void _togglePlay() { if (_controller == null) return; setState(() { if (_controller!.value.isPlaying) { _controller!.pause(); isPlaying = false; } else { _controller!.play(); isPlaying = true; } }); }
  void _skipForward() { if (_controller == null) return; _controller!.seekTo(_controller!.value.position + const Duration(seconds: 10)); }
  void _skipBackward() { if (_controller == null) return; _controller!.seekTo(_controller!.value.position - const Duration(seconds: 10)); }
  void _seekTo(double s) { if (_controller == null) return; _controller!.seekTo(Duration(seconds: s.toInt())); }
  void _nextEpisode() { if (currentEpisode < totalEpisodes) _loadVideo(currentEpisode + 1); }
  void _prevEpisode() { if (currentEpisode > 1) _loadVideo(currentEpisode - 1); }

  void _showQualityDialog() {
    if (qualities.isEmpty) return;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text("Kualitas Video", style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: qualities.map((q) {
          final quality = q['quality'] ?? 'Auto';
          return ListTile(
            title: Text(quality, style: const TextStyle(color: Colors.white)),
            trailing: currentQuality == quality ? const Icon(Icons.check, color: Color(0xFF06B6D4)) : null,
            onTap: () async { currentQuality = quality; final prefs = await SharedPreferences.getInstance(); prefs.setString('pref_quality', currentQuality); Navigator.pop(c); _loadVideo(currentEpisode); },
          );
        }).toList()),
      ),
    );
  }

  String _formatDuration(double seconds) {
    final d = Duration(seconds: seconds.toInt());
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(children: [
          // 1. VIDEO DI TENGAH LAYAR LANDSCAPE (Gaya Cineflow)
          Center(
            child: isLoading ? const CircularProgressIndicator(color: Color(0xFF06B6D4)) : _controller != null && _controller!.value.isInitialized
                ? AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!))
                : const Text("Video tidak tersedia", style: TextStyle(color: Colors.white)),
          ),
          
          // 2. KONTROL OVERLAY TRANSPARAN
          if (showControls && !isLoading && _controller != null) ...[
            // Top Bar Kontrol
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 20),
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.black54, Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                child: Row(children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Expanded(child: Text("${widget.title} - Ep $currentEpisode / $totalEpisodes", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                  TextButton(onPressed: _showQualityDialog, child: Text(currentQuality, style: const TextStyle(color: Color(0xFF06B6D4)))),
                  IconButton(icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red), onPressed: _toggleFavorite),
                ]),
              ),
            ),

            // Bottom Bar Kontrol Kapsul Horizontal (Persis Seperti Aturan Cineflow)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.black87, Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Text(_formatDuration(_position), style: const TextStyle(color: Colors.white, fontSize: 12)),
                    Expanded(child: Slider(value: _position, max: _duration > 0 ? _duration : 1, activeColor: const Color(0xFF06B6D4), inactiveColor: Colors.white24, onChanged: _seekTo)),
                    Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ]),
                  const SizedBox(height: 10),
                  // Kapsul menu horizontal
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white, size: 26), onPressed: _prevEpisode),
                    const SizedBox(width: 20),
                    IconButton(icon: const Icon(Icons.replay_10, color: Colors.white, size: 26), onPressed: _skipBackward),
                    const SizedBox(width: 20),
                    ElevatedButton(onPressed: _togglePlay, style: ElevatedButton.styleFrom(shape: const CircleBorder(), backgroundColor: const Color(0xFF06B6D4), padding: const EdgeInsets.all(10)), child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 30)),
                    const SizedBox(width: 20),
                    IconButton(icon: const Icon(Icons.forward_10, color: Colors.white, size: 26), onPressed: _skipForward),
                    const SizedBox(width: 20),
                    IconButton(icon: const Icon(Icons.skip_next, color: Colors.white, size: 26), onPressed: _nextEpisode),
                    const SizedBox(width: 30),
                    // Tombol pemanggil List Episode Samping Kanan versi HP
                    IconButton(icon: const Icon(Icons.format_list_numbered, color: Colors.white, size: 26), onPressed: () => setState(() => _showEpisodeSidebar = true)),
                  ]),
                ]),
              ),
            ),
          ],

          // 3. EXPANDABLE EPISODE DRAWER KANAN VERSI HP LANDSCAPE
          if (_showEpisodeSidebar) Positioned(
            right: 0, top: 0, bottom: 0,
            child: Container(
              width: 280, color: const Color(0xFF0F172A).withOpacity(0.95),
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("Daftar Episode", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54, size: 20), onPressed: () => setState(() => _showEpisodeSidebar = false)),
                ]),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: totalEpisodes,
                    itemBuilder: (context, index) {
                      final epNum = index + 1;
                      final isCurrent = epNum == currentEpisode;
                      return GestureDetector(
                        onTap: () { setState(() => _showEpisodeSidebar = false); _loadVideo(epNum); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(color: isCurrent ? const Color(0xFF06B6D4).withOpacity(0.15) : Colors.white05, borderRadius: BorderRadius.circular(8)),
                          child: Text("Episode $epNum", style: TextStyle(color: isCurrent ? const Color(0xFF06B6D4) : Colors.white70, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                        ),
                      );
                    },
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
