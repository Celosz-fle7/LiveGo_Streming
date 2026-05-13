import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../widgets.dart';
import 'api_service.dart';

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

  @override void initState() { super.initState(); _initData(); }

  _initData() async {
    final p = await SharedPreferences.getInstance();
    currentEp = widget.ep != null ? int.parse(widget.ep!) : (p.getInt('last_ep_${widget.id}') ?? 1);
    currentQual = p.getString('pref_quality') ?? "Auto";
    
    final res = await ApiService.get("/api/v2/detail?category_p=${widget.source}&id=${widget.id}&lang=id");
    if (res != null && res['data'] != null) {
      setState(() { d = res['data']; });
      _loadVideo(currentEp);
    } else {
      setState(() => loading = false);
    }
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
          });
        
        _v!.addListener(() {
          if (mounted) setState(() {});
          if (_v!.value.position >= _v!.value.duration && _v!.value.duration != Duration.zero) _next();
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
      backgroundColor: const Color(0xFF161B22),
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
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    if (isLandscape) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    }
  }

  @override void dispose() { 
    _v?.dispose(); _hideTimer?.cancel(); 
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose(); 
  }

  @override Widget build(BuildContext context) {
    bool isT = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: Colors.black,
      body: d == null ? const Center(child: CircularProgressIndicator(color: Colors.red)) : 
      SingleChildScrollView(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: GestureDetector(
                onTap: () { setState(() => showOverlay = !showOverlay); if(showOverlay) _startTimer(); },
                child: Stack(
                  children: [
                    Container(color: Colors.black, child: Center(
                      child: _v != null && _v!.value.isInitialized 
                        ? FittedBox(fit: videoFit, child: SizedBox(width: _v!.value.size.width, height: _v!.value.size.height, child: VideoPlayer(_v!))) 
                        : (loading ? const CircularProgressIndicator(color: Colors.red) : const Text("Tidak dapat memuat video", style: TextStyle(color: Colors.white))))),
                    if (showOverlay && _v != null && _v!.value.isInitialized) _buildOverlay(),
                    if (loading) Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator(color: Colors.red))),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d!['title'] ?? widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                Text(d!['synopsis'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 3),
                const SizedBox(height: 20),
                Container(height: 50, width: double.infinity, decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(30)), child: const Center(child: Text("Favorit", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)))),
                const SizedBox(height: 30),
                const Text("DAFTAR EPISODE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 15),
                GridView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: isT ? 7 : 5, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.2),
                  itemCount: d!['total_episodes'] ?? 0,
                  itemBuilder: (c, i) => TVButton(
                    onTap: () => _loadVideo(i + 1),
                    child: Container(
                      decoration: BoxDecoration(color: (i + 1) == currentEp ? Colors.red.withOpacity(0.2) : Colors.white10, borderRadius: BorderRadius.circular(15), border: (i + 1) == currentEp ? Border.all(color: Colors.red) : null),
                      alignment: Alignment.center, child: Text("${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.black87, Colors.transparent, Colors.black87], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: Column(children: [
        Padding(padding: const EdgeInsets.only(top: 30, left: 10), child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)), 
          Text("${d!['title']} - Eps $currentEp", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))
        ])),
        const Spacer(),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(icon: const Icon(Icons.replay_10, size: 30, color: Colors.white), onPressed: () => _v!.seekTo(_v!.value.position - const Duration(seconds: 10))),
          IconButton(icon: Icon(_v!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 60, color: Colors.white), onPressed: () => setState(() => _v!.value.isPlaying ? _v!.pause() : _v!.play())),
          IconButton(icon: const Icon(Icons.forward_10, size: 30, color: Colors.white), onPressed: () => _v!.seekTo(_v!.value.position + const Duration(seconds: 10))),
        ]),
        const Spacer(),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 15), child: VideoProgressIndicator(_v!, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Colors.red))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white), onPressed: _prev),
          IconButton(icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: _next),
          TextButton(onPressed: _showQualDialog, child: Text(currentQual, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          IconButton(icon: const Icon(Icons.fullscreen, color: Colors.white), onPressed: _toggleFullscreen),
        ])),
      ]),
    );
  }
}
