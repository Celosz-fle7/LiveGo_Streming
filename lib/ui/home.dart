import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'player.dart';
import 'api_service.dart';
import '../database/database_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List dubbingList = [];
  List popularList = [];
  List terbaruList = [];
  Map? banner;
  bool loading = true;
  bool refreshing = false;
  String selS = "";
  String selC = "Dubbing";
  List<String> platforms = [];
  bool hasDubbing = false;
  int _loadingProgress = 0;
  int _totalTasks = 0;
  Set<String> watchedIds = {};
  
  final Random _random = Random();
  final List<String> allPlatforms = ["FreeReels", "ShortMax", "DramaWave", "Melolo", "NetShort", "GoodShort"];

  @override
  void initState() { 
    super.initState(); 
    _loadWatchedIds();
    _loadActivePlatforms();
  }

  Future<void> _loadWatchedIds() async { watchedIds = await DatabaseHelper().getWatchedContentIds(); }

  Future<void> _loadActivePlatforms() async {
    final prefs = await SharedPreferences.getInstance();
    final activeList = <String>[];
    for (var p in allPlatforms) {
      if (prefs.getBool('source_${p.toLowerCase()}') ?? true) activeList.add(p);
    }
    setState(() {
      platforms = activeList;
      if (platforms.isNotEmpty) selS = platforms[0].toLowerCase();
    });
    if (platforms.isNotEmpty) fetch();
  }

  Future<void> fetch({bool forceRefresh = false}) async {
    if (selS.isEmpty) return;
    setState(() { loading = true; hasDubbing = false; _loadingProgress = 0; _totalTasks = 3; });
    await _loadWatchedIds();
    
    final bRes = await ApiService.get("/api/v2/banner?category_p=$selS&lang=id", forceRefresh: forceRefresh);
    if (bRes != null && bRes['data'] != null && bRes['data'].isNotEmpty) {
      setState(() => banner = bRes['data'][0]);
    }
    setState(() => _loadingProgress++);
    
    if (selC == "Dubbing") {
      final dubRes = await ApiService.get("/api/v2/search?category_p=$selS&q=sulih%20suara&lang=id", forceRefresh: forceRefresh);
      if (dubRes != null && dubRes['data'] != null) {
        final dubData = dubRes['data'] is List ? dubRes['data'] : (dubRes['data']['dramas'] ?? []);
        setState(() { dubbingList = dubData; hasDubbing = dubData.isNotEmpty; });
      }
      setState(() => _loadingProgress++);
      
      final popRes = await ApiService.get("/api/v2/discover?category_p=$selS&lang=id&page=1", forceRefresh: forceRefresh);
      if (popRes != null && popRes['data'] != null) {
        final popData = popRes['data'] is List ? popRes['data'] : (popRes['data']['dramas'] ?? []);
        setState(() => popularList = popData);
      }
      setState(() => _loadingProgress++);
    } else {
      final newRes = await ApiService.get("/api/v2/home?category_p=$selS&lang=id", forceRefresh: forceRefresh);
      if (newRes != null && newRes['data'] != null) {
        final newData = newRes['data'] is List ? newRes['data'] : (newRes['data']['dramas'] ?? []);
        setState(() => terbaruList = newData);
      }
      setState(() => _loadingProgress += 2);
    }
    setState(() => loading = false);
  }

  Future<void> _onRefresh() async {
    setState(() => refreshing = true);
    await fetch(forceRefresh: true);
    setState(() => refreshing = false);
  }

  Widget _buildGrid(List list) {
    if (list.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("Tidak ada konten", style: TextStyle(color: Colors.white54))));
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.all(12), 
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.65, crossAxisSpacing: 10, mainAxisSpacing: 16),
      itemCount: list.length > 32 ? 32 : list.length,
      itemBuilder: (c, i) {
        final item = list[i];
        final isWatched = watchedIds.contains(item['id']?.toString());
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => PlayerPage(id: item['id'].toString(), source: selS, title: item['title'] ?? 'No Title', ep: '1'))),
          child: Stack(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: item['cover'] ?? '', fit: BoxFit.cover, width: double.infinity, placeholder: (_, __) => Container(color: Colors.white10), errorWidget: (_, __, ___) => Container(color: Colors.white10)))),
              const SizedBox(height: 6),
              Text(item['title'] ?? 'No Title', style: const TextStyle(color: Colors.white, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [Text("${item['chapters'] ?? 0} Ep", style: const TextStyle(color: Colors.white54, fontSize: 9)), const SizedBox(width: 6), Text("${item['views'] ?? 0}", style: const TextStyle(color: Colors.white54, fontSize: 9))]),
            ]),
            if (isWatched) Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.check_circle, color: Colors.green, size: 16))),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        // PERUBAHAN UTAMA: Nama aplikasi diubah paten menjadi LiveGO
        title: const Text("LiveGO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22)), 
        backgroundColor: const Color(0xFF0D1117), 
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.history, color: Colors.white), onPressed: () => Navigator.pushNamed(context, '/history')),
          IconButton(icon: const Icon(Icons.favorite_border, color: Colors.white), onPressed: () => Navigator.pushNamed(context, '/profile')),
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () => Navigator.pushNamed(context, '/search')),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh, color: const Color(0xFF06B6D4), backgroundColor: const Color(0xFF1F2937),
        child: platforms.isEmpty
          ? const Center(child: Text("Tidak ada platform aktif.", style: TextStyle(color: Colors.white54)))
          : loading ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(color: Color(0xFF06B6D4)), const SizedBox(height: 16), Text("Memuat data... ($_loadingProgress/$_totalTasks)", style: const TextStyle(color: Colors.white54))]))
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(children: [
                // DETAIL 1: BANNER DENGAN BINGKAI NEON BERSINAR CYAN (Khas Gambar Rujukan)
                if (banner != null) Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => PlayerPage(id: banner!['id'].toString(), source: selS, title: banner!['title'] ?? 'No Title', ep: '1'))),
                    child: Container(
                      height: 200, width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        // Garis Neon Bersinar Cyan
                        border: Border.all(color: const Color(0xFF06B6D4), width: 1.2),
                        boxShadow: [BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.15), blurRadius: 10, spreadRadius: 1)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: Stack(children: [
                          Positioned.fill(child: Image.network(banner!['cover'] ?? '', fit: BoxFit.cover)),
                          Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black87, Colors.transparent])))),
                          Positioned(
                            bottom: 15, left: 15, right: 15, 
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF06B6D4), width: 0.5)), child: const Text("MOVIEBOX", style: TextStyle(color: Color(0xFF06B6D4), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                              const SizedBox(height: 6),
                              Text(banner!['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(banner!['description'] ?? 'Tonton kisah romansa drama pendek terbaik sekarang juga.', style: const TextStyle(color: Colors.white60, fontSize: 10, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ])
                          )
                        ]),
                      ),
                    ),
                  ),
                ),
                
                // PLATFORM SELECTION TABS ROW
                if (platforms.isNotEmpty) Container(
                  height: 36, margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 15), itemCount: platforms.length,
                    itemBuilder: (context, index) {
                      final p = platforms[index]; final isSel = selS == p.toLowerCase();
                      return GestureDetector(
                        onTap: () { setState(() { selS = p.toLowerCase(); fetch(); }); },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 14), alignment: Alignment.center,
                          decoration: BoxDecoration(color: isSel ? const Color(0xFF06B6D4) : const Color(0xFF1F2937), borderRadius: BorderRadius.circular(20)),
                          child: Text(p, style: TextStyle(color: isSel ? Colors.black : Colors.white60, fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                        ),
                      );
                    },
                  ),
                ),
                
                // DETAIL 2: TOMBOL KATEGORI BERBENTUK KAPSUL OVAL (Khas Gambar Rujukan)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Row(children: [
                    _buildCapsuleTab("Trending", selC == "Dubbing", () => setState(() { selC = "Dubbing"; fetch(); })),
                    const SizedBox(width: 8),
                    _buildCapsuleTab("Terbaru", selC == "Terbaru", () => setState(() { selC = "Terbaru"; fetch(); })),
                  ]),
                ),
                
                // GRID DAFTAR POSTER FILM
                if (selC == "Dubbing") Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (hasDubbing) ...[const Padding(padding: EdgeInsets.symmetric(horizontal: 15, vertical: 4), child: Text("Dubbing (Sulih Suara)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))), _buildGrid(dubbingList)],
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 15, vertical: 4), child: Text("Populer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                  _buildGrid(popularList),
                ]) else Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 15, vertical: 4), child: Text("Terbaru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                  _buildGrid(terbaruList),
                ]),
                const SizedBox(height: 20),
              ]),
            ),
      ),
    );
  }

  // WIDGET KAPSUL OVAL ADAPTIF (ON/OFF HIGHLIGHT CYAN)
  Widget _buildCapsuleTab(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A).withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : Colors.white12, width: 1),
        ),
        child: Text(
          title,
          style: TextStyle(color: isSelected ? const Color(0xFF06B6D4) : Colors.white54, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }
}
