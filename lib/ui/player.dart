import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_subtitle/flutter_subtitle.dart' as sub;
import 'dart:async';
import 'package:http/http.dart' as http;
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
  sub.SubtitleController? _subtitleController;
  List episodes = [], qualities = [], audioTracks = [], subtitles = [];
  Map? dramaData;
  bool isLoading = true, isPlaying = true, showControls = true, isFavorite = false, isFullMode = false, _showEpisodeSidebar = false;
  int currentEpisode = 1, totalEpisodes = 0;
  double _position = 0, _duration = 0;
  Timer? _hideTimer;
  
  String currentQuality = "Auto";
  bool isAutoNext = true;
  double currentSpeed = 1.0;
  String currentAudio = "Default";
  
  String currentSubtitle = "Mati";
  bool isSubtitleOn = false;
  double? videoAspectRatio;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _loadData();
    _checkFavorite();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
    isAutoNext = prefs.getBool('pref_autonext') ?? true;
    
    final res = await ApiService.get("/api/v2/detail?category_p=${widget.source}&id=${widget.id}&lang=id");
    if (res != null && res['data'] != null) {
      setState(() { dramaData = res['data']; episodes = dramaData?['chapters'] ?? []; totalEpisodes = episodes.length; });
      await _loadVideo(currentEpisode);
    } else { setState(() => isLoading = false); }
  }

  Future<void> _loadVideo(int episodeNum, {Duration? startPosition}) async {
    setState(() { isLoading = true; currentEpisode = episodeNum; });
    await DatabaseHelper().addToHistory({
      'drama_id': widget.id, 'drama_title': widget.title, 'drama_poster': dramaData?['cover'],
      'episode_id': episodeNum.toString(), 'episode_number': episodeNum, 'position_seconds': startPosition?.inSeconds ?? 0,
      'duration_seconds': 0, 'last_watched': DateTime.now().millisecondsSinceEpoch, 'platform': widget.source,
    });
    
    final res = await ApiService.get("/api/v2/video?category_p=${widget.source}&id=${widget.id}&chapterId=$episodeNum&lang=id");
    if (res != null && res['success'] == true && res['data'] != null) {
      final videoData = res['data'];
      qualities = videoData['streams'] ?? [];
      audioTracks = videoData['audios'] ?? [];
      subtitles = videoData['subtitles'] ?? [];
      
      String videoUrl = '';
      if (qualities.isNotEmpty) {
        for (var q in qualities) { if (q['quality'] == currentQuality) { videoUrl = q['url'] ?? ''; break; } }
        // PERBAIKAN TOTAL: Menggunakan pengecekan list yang aman dan anti-error tipe data String/int
        if (videoUrl.isEmpty && qualities.isNotEmpty) {
          final firstStream = qualities[0];
          if (firstStream != null) videoUrl = firstStream['url'] ?? '';
        }
      }
      
      if (videoUrl.isNotEmpty) {
        _controller?.dispose();
        _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
          ..initialize().then((_) {
            setState(() { isLoading = false; _duration = _controller!.value.duration.inSeconds.toDouble(); videoAspectRatio = _controller!.value.aspectRatio; });
            if (startPosition != null) _controller!.seekTo(startPosition);
            _controller!.setPlaybackSpeed(currentSpeed);
            _controller!.play(); isPlaying = true; _startHideTimer();
            _initDefaultSubtitle();
          });
        _controller!.addListener(() {
          if (mounted) setState(() { _position = _controller!.value.position.inSeconds.toDouble(); _duration = _controller!.value.duration.inSeconds.toDouble(); });
          if (_controller!.value.position >= _controller!.value.duration && _controller!.value.duration != Duration.zero) {
            if (isAutoNext) _nextEpisode();
          }
        });
        final prefs = await SharedPreferences.getInstance(); prefs.setInt('last_ep_${widget.id}', episodeNum);
      } else { setState(() => isLoading = false); }
    } else { setState(() => isLoading = false); }
  }

  void _initDefaultSubtitle() {
    if (subtitles.isEmpty) return;
    Map? indoSub;
    for (var s in subtitles) {
      if (s['language'] == 'id-ID' || s['language'].toString().toLowerCase().contains('id')) {
        indoSub = s;
        break;
      }
    }
    if (indoSub != null) {
      if (widget.title.toLowerCase().contains('sulih suara') || currentAudio.toLowerCase().contains('indo')) {
        setState(() { currentSubtitle = "Indonesia"; isSubtitleOn = false; });
        _fetchSubtitleFile(indoSub['url']);
      } else {
        setState(() { currentSubtitle = "Indonesia"; isSubtitleOn = true; });
        _fetchSubtitleFile(indoSub['url']);
      }
    }
  }

  Future<void> _fetchSubtitleFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _subtitleController = sub.SubtitleController(
            provider: sub.SubtitleProvider.fromString(response.body),
          );
        });
      }
    } catch (_) {
      setState(() => _subtitleController = null);
    }
  }

  void _startHideTimer() { 
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

  void _toggleFullscreen() {
    setState(() {
      isFullMode = !isFullMode;
      if (isFullMode) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        if (videoAspectRatio != null && videoAspectRatio! > 1.2) {
          SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
        } else {
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        }
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
    });
  }

  void _showMainSettingsDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Pengaturan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettingsItem("Kualitas Video", currentQuality, () => _showQualitySelection(closeParent: true)),
            _buildSettingsItem("Auto Next", isAutoNext ? "Aktif" : "Mati", _toggleAutoNextSetting),
            _buildSettingsItem("Kecepatan Pemutaran", "${currentSpeed}x", _showSpeedSelection),
            _buildSettingsItem("Audio Track (Dubbing)", currentAudio, _showAudioSelection),
            _buildSettingsItem("Pengaturan Subtitle", isSubtitleOn ? currentSubtitle : "Mati", _showSubtitleSelection),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(String title, String trailingText, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.black87, fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(trailingText, style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold, fontSize: 13)),
          const Icon(Icons.chevron_right, color: Colors.black38, size: 18),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showQualitySelection({bool closeParent = false}) {
    if (closeParent) Navigator.pop(context);
    if (qualities.isEmpty) return;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Pilih Kualitas", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: qualities.map((q) {
            final quality = q['quality'] ?? 'Auto';
            return ListTile(
              title: Text(quality, style: const TextStyle(color: Colors.black87)),
              trailing: currentQuality == quality ? const Icon(Icons.check, color: Color(0xFF06B6D4)) : null,
              onTap: () async {
                setState(() => currentQuality = quality);
                final prefs = await SharedPreferences.getInstance();
                prefs.setString('pref_quality', currentQuality);
                Navigator.pop(c);
                final currentPos = _controller?.value.position ?? Duration.zero;
                _loadVideo(currentEpisode, startPosition: currentPos);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _toggleAutoNextSetting() async {
    Navigator.pop(context);
    setState(() => isAutoNext = !isAutoNext);
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('pref_autonext', isAutoNext);
  }

  void _showSpeedSelection() {
    Navigator.pop(context);
    final speeds = [0.5, 1.0, 1.25, 1.5, 2.0];
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Kecepatan Pemutaran", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: speeds.map((s) {
            return ListTile(
              title: Text("${s}x ${s == 1.0 ? '(Normal)' : ''}", style: const TextStyle(color: Colors.black87)),
              trailing: currentSpeed == s ? const Icon(Icons.check, color: Color(0xFF06B6D4)) : null,
              onTap: () {
                setState(() => currentSpeed = s);
                _controller?.setPlaybackSpeed(s);
                Navigator.pop(c);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAudioSelection() {
    Navigator.pop(context);
    if (audioTracks.isEmpty) return;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Audio Track", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: audioTracks.map((a) {
            final lang = a['language'] ?? 'Default';
            return ListTile(
              title: Text(lang, style: const TextStyle(color: Colors.black87)),
              trailing: currentAudio == lang ? const Icon(Icons.check, color: Color(0xFF06B6D4)) : null,
              onTap: () { setState(() => currentAudio = lang); Navigator.pop(c); },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSubtitleSelection() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Pengaturan Subtitle", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Matikan Subtitle (OFF)", style: TextStyle(color: Colors.black87)),
              trailing: !isSubtitleOn ? const Icon(Icons.check, color: Color(0xFF06B6D4)) : null,
              onTap: () { setState(() { isSubtitleOn = false; }); Navigator.pop(c); },
            ),
            const Divider(color: Colors.black12),
            if (subtitles.isEmpty) 
              const Padding(padding: EdgeInsets.all(12), child: Text("Tidak ada file teks", style: TextStyle(color: Colors.black38, fontSize: 12)))
            else 
              ...subtitles.map((s) {
                final subLang = s['language'] == 'id-ID' ? 'Indonesia' : (s['language'] ?? 'English');
                final isSelectedLang = isSubtitleOn && currentSubtitle == subLang;
                return ListTile(
                  title: Text(subLang, style: const TextStyle(color: Colors.black87)),
                  trailing: isSelectedLang ? const Icon(Icons.check, color: Color(0xFF06B6D4)) : null,
                  onTap: () {
                    setState(() { currentSubtitle = subLang; isSubtitleOn = true; });
                    Navigator.pop(c);
                    _fetchSubtitleFile(s['url']);
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget subOverlay = (_controller != null && _subtitleController != null && isSubtitleOn)
        ? Positioned(
            bottom: showControls ? 90 : 25, left: 20, right: 20,
            child: ValueListenableBuilder(
              valueListenable: _controller!,
              builder: (context, VideoPlayerValue value, child) {
                return sub.SubtitleView(
                  controller: _subtitleController,
                  videoPosition: value.position,
                  subtitleStyle: const sub.SubtitleStyle(
                    fontSize: 15,
                    textColor: Colors.white,
                    backgroundColor: Colors.black54,
                  ),
                );
              },
            ),
          )
        : const SizedBox.shrink();

    Widget videoWidget = Center(
      child: isLoading ? const CircularProgressIndicator(color: Color(0xFF06B6D4)) : _controller != null && _controller!.value.isInitialized
          ? AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!))
          : const Text("Video tidak tersedia", style: TextStyle(color: Colors.white)),
    );

    Widget gestureOverlay = Stack(children: [
      Positioned.fill(
        child: Row(children: [
          Expanded(child: GestureDetector(onTap: _toggleControls, onDoubleTap: _skipBackward, child: Container(color: Colors.transparent))),
          Expanded(child: GestureDetector(onTap: _toggleControls, onDoubleTap: _togglePlay, child: Container(color: Colors.transparent))),
          Expanded(child: GestureDetector(onTap: _toggleControls, onDoubleTap: _skipForward, child: Container(color: Colors.transparent))),
        ]),
      ),
      if (showControls && !isLoading && _controller != null) ...[
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.only(top: 30, left: 16, right: 16, bottom: 16),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.black54, Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () { if(isFullMode) { _toggleFullscreen(); } else { Navigator.pop(context); } }),
              const SizedBox(width: 8),
              Expanded(child: Text("${widget.title} - Ep $currentEpisode", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              TextButton(
                onPressed: () => _showQualitySelection(closeParent: false),
                child: Text(currentQuality, style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
        ),
        Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.replay_10, color: Colors.white, size: 30), onPressed: _skipBackward),
            const SizedBox(width: 40),
            ElevatedButton(onPressed: _togglePlay, style: ElevatedButton.styleFrom(shape: const CircleBorder(), backgroundColor: const Color(0xFF06B6D4), padding: const EdgeInsets.all(12)), child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 32)),
            const SizedBox(width: 40),
            IconButton(icon: const Icon(Icons.forward_10, color: Colors.white, size: 30), onPressed: _skipForward),
          ]),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.black87, Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Text(_formatDuration(_position), style: const TextStyle(color: Colors.white, fontSize: 11)),
                Expanded(child: Slider(value: _position, max: _duration > 0 ? _duration : 1, activeColor: const Color(0xFF06B6D4), inactiveColor: Colors.white24, onChanged: _seekTo)),
                Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white, fontSize: 11)),
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white, size: 20), onPressed: _prevEpisode),
                  IconButton(icon: const Icon(Icons.skip_next, color: Colors.white, size: 20), onPressed: _nextEpisode),
                ]),
                Row(children: [
                  TextButton(
                    onPressed: () => _showQualitySelection(closeParent: false),
                    child: Text(currentQuality, style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(icon: const Icon(Icons.settings, color: Colors.white, size: 20), onPressed: _showMainSettingsDialog),
                  IconButton(icon: Icon(isFullMode ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white, size: 20), onPressed: _toggleFullscreen),
                ]),
              ]),
            ]),
          ),
        ),
      ]
    ]);

    if (isFullMode) {
      return Scaffold(backgroundColor: Colors.black, body: Stack(children: [videoWidget, subOverlay, Positioned.fill(child: gestureOverlay)]));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(children: [
          Container(
            height: 340,
            color: Colors.black,
            child: Stack(children: [videoWidget, subOverlay, Positioned.fill(child: gestureOverlay)]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)), child: const Text("SEDANG DIPUTAR", style: TextStyle(color: Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.bold))),
                const SizedBox(height: 8),
                Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (dramaData != null) Text(dramaData!['description'] ?? 'Tidak ada sinopsis.', style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)]), borderRadius: BorderRadius.circular(24)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.white), const SizedBox(width: 8), const Text("Favorit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/download'),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.5))),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.download, color: Color(0xFF06B6D4)), const SizedBox(width: 8), const Text("Download", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("DAFTAR EPISODE", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  Text("$totalEpisodes Ep", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ]),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 1.0, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemCount: totalEpisodes,
                  itemBuilder: (context, index) {
                    final epNum = index + 1;
                    final isCurrent = epNum == currentEpisode;
                    return GestureDetector(
                      onTap: () => _loadVideo(epNum),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrent ? Colors.transparent : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isCurrent ? const Color(0xFF06B6D4) : Colors.transparent, width: 2),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text("EPISODE", style: TextStyle(color: isCurrent ? const Color(0xFF06B6D4) : Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(isCurrent ? "DIPUTAR\n$epNum" : "$epNum", textAlign: TextAlign.center, style: TextStyle(color: isCurrent ? const Color(0xFF06B6D4) : Colors.white, fontSize: isCurrent ? 9 : 12, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    );
                  },
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
