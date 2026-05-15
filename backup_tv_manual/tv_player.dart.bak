import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../api_service.dart';
import '../../database/database_helper.dart';
import '../../widgets/tv_button.dart';

class TVPlayerPage extends StatefulWidget {
  final String id, source, title;
  final String? ep;
  const TVPlayerPage({super.key, required this.id, required this.source, required this.title, this.ep});

  @override
  State<TVPlayerPage> createState() => _TVPlayerPageState();
}

class _TVPlayerPageState extends State<TVPlayerPage> {
  VideoPlayerController? _controller;
  List episodes = [], qualities = [];
  Map? dramaData;
  bool isLoading = true, isPlaying = true, showControls = true, isFavorite = false, _showEpisodeSidebar = false;
  int currentEpisode = 1, totalEpisodes = 0;
  double _position = 0, _duration = 0;
  Timer? _hideTimer;
  String currentQuality = "Auto";
  double? videoAspectRatio;
  bool isStretchMode = false;

  @override
  void initState() { super.initState(); _loadData(); _checkFavorite(); }

  @override
  void dispose() { _controller?.dispose(); _hideTimer?.cancel(); super.dispose(); }

  Future<void> _checkFavorite() async { 
    isFavorite = await DatabaseHelper().isFavorite(widget.id); 
    setState(() {}); 
  }

  Future<void> _toggleFavorite() async {
    if (isFavorite) { 
      await DatabaseHelper().removeFromFavorites(widget.id); 
    } else {
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
        for (var q in qualities) { 
          if (q['quality'] == currentQuality) { videoUrl = q['url']; break; } 
        }
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
    _hideTimer = Timer(const Duration(seconds: 5), () { if (mounted && showControls) setState(() => showControls = false); }); 
  }
  
  void _toggleControls() { setState(() { showControls = !showControls; if (showControls) _startHideTimer(); }); }
  void _togglePlay() { if (_controller == null) return; setState(() { if (_controller!.value.isPlaying) { _controller!.pause(); isPlaying = false; } else { _controller!.play(); isPlaying = true; } }); }
  void _skipForward() { if (_controller == null) return; _controller!.seekTo(_controller!.value.position + const Duration(seconds: 10)); }
  void _skipBackward() { if (_controller == null) return; _controller!.seekTo(_controller!.value.position - const Duration(seconds: 10)); }
  void _seekTo(double s) { if (_controller == null) return; _controller!.seekTo(Duration(seconds: s.toInt())); }
  void _nextEpisode() { if (currentEpisode < totalEpisodes) _loadVideo(currentEpisode + 1); }
  void _prevEpisode() { if (currentEpisode > 1) _loadVideo(currentEpisode - 1); }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final label = event.logicalKey.keyLabel.toLowerCase();
    
    if (label == 'go back' || label == 'escape' || event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_showEpisodeSidebar) {
        setState(() => _showEpisodeSidebar = false);
        _startHideTimer();
        return;
      }
    }

    if (_showEpisodeSidebar) return; 
    _startHideTimer();
    if (!showControls) { setState(() => showControls = true); return; }

    if (label == 'select' || label == 'enter' || event.logicalKey == LogicalKeyboardKey.space) { _togglePlay(); } 
    else if (label == 'arrow right') { _skipForward(); } 
    else if (label == 'arrow left') { _skipBackward(); } 
    else if (label == 'arrow up') { _nextEpisode(); } 
    else if (label == 'arrow down') { _prevEpisode(); }
  }

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
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          child: Stack(children: [
            Center(
              child: isLoading ? const CircularProgressIndicator(color: Color(0xFF06B6D4)) : _controller != null && _controller!.value.isInitialized
                  ? SizedBox.expand(child: FittedBox(fit: isStretchMode ? BoxFit.fill : BoxFit.contain, child: SizedBox(width: _controller!.value.size.width, height: _controller!.value.size.height, child: VideoPlayer(_controller!))))
                  : const Text("Video tidak tersedia", style: TextStyle(color: Colors.white)),
            ),
            
            if (showControls && !isLoading && _controller != null) Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.only(top: 40, left: 40, right: 40, bottom: 40),
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.black87, Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("${widget.title} - Ep $currentEpisode / $totalEpisodes", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  // FIX 2: Mengganti maxWidth mentah menggunakan BoxConstraints
                  if (dramaData != null) Container(constraints: const BoxConstraints(maxWidth: 600), child: Text(dramaData!['description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)), child: const Text("Gratis", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF06B6D4).withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: const Text("Dubbing", style: TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.bold))),
                  ])
                ]),
              ),
            ),

            if (showControls && !isLoading && _controller != null) Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(30),
                // FIX 3: Mengganti warna typo Colors.black90 menjadi Colors.black87 resmi Flutter
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.black87, Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Text(_formatDuration(_position), style: const TextStyle(color: Colors.white, fontSize: 12)),
                    Expanded(child: Slider(value: _position, max: _duration > 0 ? _duration : 1, activeColor: const Color(0xFF06B6D4), inactiveColor: Colors.white24, onChanged: _seekTo)),
                    Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ]),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF1F2937).withOpacity(0.85), borderRadius: BorderRadius.circular(40)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      TVButton(onTap: _prevEpisode, child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.skip_previous, color: Colors.white))),
                      TVButton(onTap: _togglePlay, child: Padding(padding: const EdgeInsets.all(8.0), child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: const Color(0xFF06B6D4), size: 28))),
                      TVButton(onTap: _nextEpisode, child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.skip_next, color: Colors.white))),
                      const SizedBox(width: 14),
                      TVButton(onTap: () => setState(() => _showEpisodeSidebar = true), child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.format_list_numbered, color: Colors.white))),
                      TVButton(onTap: _showQualityDialog, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), child: Text(currentQuality, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)))),
                      TVButton(onTap: () => setState(() => isStretchMode = !isStretchMode), child: Padding(padding: const EdgeInsets.all(8.0), child: Icon(Icons.aspect_ratio, color: isStretchMode ? const Color(0xFF06B6D4) : Colors.white))),
                      TVButton(onTap: _toggleFavorite, child: Padding(padding: const EdgeInsets.all(8.0), child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red))),
                      TVButton(onTap: () {}, child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.menu, color: Colors.white70))),
                    ]),
                  ),
                ]),
              ),
            ),

            if (_showEpisodeSidebar) Positioned(
              right: 0, top: 0, bottom: 0,
              child: FocusScope(
                child: FocusTraversalGroup(
                  child: Container(
                    width: 340, color: const Color(0xFF0F172A).withOpacity(0.96),
                    padding: const EdgeInsets.all(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text("Daftar Episode", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => setState(() => _showEpisodeSidebar = false)),
                      ]),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: totalEpisodes,
                          itemBuilder: (context, index) {
                            final epNum = index + 1;
                            final isCurrent = epNum == currentEpisode;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: TVButton(
                                // FIX 4: Menghapus parameter autoFocus pemicu error
                                onTap: () { setState(() => _showEpisodeSidebar = false); _loadVideo(epNum); },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  decoration: BoxDecoration(color: isCurrent ? const Color(0xFF06B6D4).withOpacity(0.2) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                                  child: Row(children: [
                                    Icon(isCurrent ? Icons.play_circle_filled : Icons.play_arrow, color: isCurrent ? const Color(0xFF06B6D4) : Colors.white38),
                                    const SizedBox(width: 12),
                                    Text("Episode $epNum", style: TextStyle(color: isCurrent ? const Color(0xFF06B6D4) : Colors.white70, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                                  ]),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
