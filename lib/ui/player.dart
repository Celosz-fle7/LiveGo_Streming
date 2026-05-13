import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'widgets.dart';
import 'api_service.dart';
import '../database/database_helper.dart';

class PlayerPage extends StatefulWidget {
  final String id, source, title;
  final String? ep;
  const PlayerPage({super.key, required this.id, required this.source, required this.title, this.ep});

  @override State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  VideoPlayerController? _v;
  Map? d;
  Map? videoData;
  bool loading = true;
  bool showOverlay = true;
  int currentEp = 1;
  String currentQual = "Auto";
  Timer? _hideTimer;
  BoxFit videoFit = BoxFit.contain;
  int resumePosition = 0;

  @override void initState() { 
    super.initState(); 
    _initData();
  }

  _initData() async {
    final p = await SharedPreferences.getInstance();
    currentEp = widget.ep != null ? int.parse(widget.ep!) : (p.getInt('last_ep_${widget.id}') ?? 1);
    currentQual = p.getString('pref_quality') ?? "Auto";
    
    // Cek resume position dari history
    final resumeData = await DatabaseHelper().getResumeWatching(widget.id);
    if (resumeData != null && resumeData['episode_number'] == currentEp) {
      resumePosition = resumeData['position_seconds'] ?? 0;
    }
    
    final res = await ApiService.get("/api/v2/detail?category_p=${widget.source}&id=${widget.id}&lang=id");
    if (res != null && res['data'] != null) {
      setState(() { d = res['data']; });
      _loadVideo(currentEp);
    } else {
      setState(() => loading = false);
    }
  }

  _saveToHistory() async {
    await DatabaseHelper().addToHistory({
      'drama_id': widget.id,
      'drama_title': widget.title,
      'drama_poster': d?['cover'],
      'episode_id': currentEp.toString(),
      'episode_number': currentEp,
      'position_seconds': _v?.value.position.inSeconds ?? 0,
      'duration_seconds': _v?.value.duration.inSeconds ?? 0,
      'last_watched': DateTime.now().millisecondsSinceEpoch,
      'platform': widget.source,
    });
  }

  _loadVideo(int ep) async {
    setState(() { loading = true; currentEp = ep; });
    final res = await ApiService.get("/api/v2/video?category_p=${widget.source}&id=${widget.id}&chapterId=$ep&lang=id");
    
    if (res != null && res['success'] == true && res['data'] != null) {
      videoData = res['data'];
      List streams = videoData!['streams'] ?? [];
      
      var stream = streams.isNotEmpty ? streams[0] : null;
      if (stream != null && stream['url'] != null) {
        if (_v != null) await _v!.dispose();
        _v = VideoPlayerController.networkUrl(Uri.parse(stream['url']))
          ..initialize().then((_) {
            setState(() { loading = false; _v!.play(); _startTimer(); });
            if (ep == currentEp && resumePosition > 0) {
              _v!.seekTo(Duration(seconds: resumePosition));
            }
          });
        
        _v!.addListener(() {
          if (mounted) setState(() {});
          if (_v!.value.position >= _v!.value.duration && _v!.value.duration != Duration.zero) {
            _next();
          }
          _saveToHistory(); // Auto save progress
        });
        
        final p = await SharedPreferences.getInstance();
        p.setInt('last_ep_${widget.id}', ep);
      } else {
        setState(() => loading = false);
      }
    } else {
      setState(() => loading = false);
    }
  }

  void _next() { if (currentEp < (d?['total_episodes'] ?? 0)) _loadVideo(currentEp + 1); }
  void _prev() { if (currentEp > 1) _loadVideo(currentEp - 1); }

  void _startTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => showOverlay = false);
    });
  }

  void _showQualDialog() {
    if (videoData == null) return;
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF1F2937),
      title: const Text("Pilih Kualitas", style: TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, children: (videoData!['streams'] as List).map((s) => ListTile(
        title: Text(s['quality'] ?? 'Auto', style: const TextStyle(color: Colors.white)),
        onTap: () async {
          currentQual = s['quality'] ?? 'Auto';
          final p = await SharedPreferences.getInstance();
          p.setString('pref_quality', currentQual);
          Navigator.pop(c);
          _loadVideo(currentEp);
        },
      )).toList()),
    ));
  }

  void _toggleFullscreen() {
    setState(() {
      videoFit = videoFit == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
    });
  }

  @override void dispose() { 
    _v?.dispose(); _hideTimer?.cancel(); 
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose(); 
  }

  @override Widget build(BuildContext context) {
    // (kode build sama seperti sebelumnya)
    return Scaffold(
      backgroundColor: Colors.black,
      body: const Center(child: Text("Player")),
    );
  }
}
