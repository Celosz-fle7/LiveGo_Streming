import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'tv_player.dart';
import '../api_service.dart';
import '../../database/database_helper.dart';
import '../../widgets/tv_button.dart';

class TVHomePage extends StatefulWidget {
  const TVHomePage({super.key});
  @override State<TVHomePage> createState() => _TVHomePageState();
}

class _TVHomePageState extends State<TVHomePage> {
  List dubbingList = [];
  List popularList = [];
  List terbaruList = [];
  Map? banner;
  bool loading = true;
  bool refreshing = false;
  String selS = "";
  String selC = "Trending"; 
  List<String> platforms = [];
  bool hasDubbing = false;
  int _loadingProgress = 0;
  int _totalTasks = 0;
  Set<String> watchedIds = {};
  int _selectedMenuIdx = 0;
  
  final Random _random = Random();
  
  final List<String> allPlatforms = [
    "FreeReels", "ShortMax", "DramaWave", "Melolo", "NetShort", "GoodShort"
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.home, 'label': 'Beranda'},
    {'icon': Icons.download, 'label': 'Unduhan'},
    {'icon': Icons.history, 'label': 'Riwayat'},
    {'icon': Icons.favorite, 'label': 'Favorit'},
    {'icon': Icons.person, 'label': 'Akun'},
    {'icon': Icons.search, 'label': 'Cari'},
  ];

  @override
  void initState() { 
    super.initState(); 
    _loadWatchedIds();
    _loadActivePlatforms();
  }

  Future<void> _loadWatchedIds() async {
    watchedIds = await DatabaseHelper().getWatchedContentIds();
  }

  Future<void> _loadActivePlatforms() async {
    final prefs = await SharedPreferences.getInstance();
    final activeList = <String>[];
    for (var p in allPlatforms) {
      final id = p.toLowerCase();
      final isActive = prefs.getBool('source_$id') ?? true;
      if (isActive) activeList.add(p);
    }
    setState(() {
      platforms = activeList;
      if (platforms.isNotEmpty) {
        selS = platforms.first; 
      }
    });
    if (platforms.isNotEmpty) fetch(forceRefresh: true);
  }

  Future<void> fetch({bool forceRefresh = false}) async {
    if (selS.isEmpty) return;
    setState(() { 
      loading = true; 
      hasDubbing = false;
      _loadingProgress = 0;
      _totalTasks = 3;
      dubbingList = [];
      popularList = [];
      terbaruList = [];
      banner = null;
    });
    
    await _loadWatchedIds();
    
    final bRes = await ApiService.get("/api/v2/banner?category_p=$selS&lang=id", forceRefresh: forceRefresh);
    if (bRes != null && bRes['data'] != null && bRes['data'].isNotEmpty) {
      banner = bRes['data']; 
    }
    setState(() => _loadingProgress++);
    
    if (selC == "Trending") {
      final dubRes = await ApiService.get("/api/v2/search?category_p=$selS&q=sulih%20suara&lang=id", forceRefresh: forceRefresh);
      if (dubRes != null && dubRes['data'] != null) {
        final dubData = dubRes['data'] is List ? dubRes['data'] : (dubRes['data']['dramas'] ?? []);
        setState(() {
          dubbingList = dubData;
          hasDubbing = dubData.isNotEmpty;
        });
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

  List _filterAndShuffle(List items, {bool moveWatchedToBottom = true}) {
    if (items.isEmpty) return [];
    final unwatched = <dynamic>[];
    final watched = <dynamic>[];
    for (var item in items) {
      final id = item['id']?.toString() ?? '';
      if (moveWatchedToBottom && watchedIds.contains(id)) {
        watched.add(item);
      } else {
        unwatched.add(item);
      }
    }
    unwatched.shuffle(_random);
    watched.shuffle(_random);
    return [...unwatched, ...watched];
  }

  Widget _buildGrid(List list, String emptyMessage) {
    if (list.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(child: Text(emptyMessage, style: const TextStyle(color: Colors.white38, fontSize: 12))),
      );
    }
    final processedList = _filterAndShuffle(list);
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), 
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), 
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6, 
          childAspectRatio: 0.7, crossAxisSpacing: 12, mainAxisSpacing: 14
        ),
        itemCount: processedList.length > 18 ? 18 : processedList.length,
        itemBuilder: (c, i) {
          final item = processedList[i];
          return TVButton(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => TVPlayerPage(id: item['id'].toString(), source: selS, title: item['title'] ?? 'No Title', ep: '1'))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: item['cover'] ?? '', fit: BoxFit.cover, width: double.infinity, placeholder: (_, __) => Container(color: Colors.white10), errorWidget: (_, __, ___) => Container(color: Colors.white10)))),
              const SizedBox(height: 5),
              Text(item['title'] ?? 'No Title', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Scaffold(
        backgroundColor: const Color(0xFF070B11),
        body: Row(children: [
          FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Container(
              width: 180, height: double.infinity, padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Color(0xFF0F1522), border: Border(right: BorderSide(color: Colors.white12, width: 0.5))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                  child: const Row(children: [
                    Icon(Icons.play_circle_filled, color: Color(0xFF06B6D4), size: 20),
                    SizedBox(width: 8),
                    Text("CineFlow", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ]),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index]; final isSelected = _selectedMenuIdx == index;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: TVButton(
                          onTap: () => setState(() => _selectedMenuIdx = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            decoration: BoxDecoration(color: isSelected ? const Color(0xFF1E3A8A).withOpacity(0.5) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                            child: Row(children: [
                              Icon(item['icon'], color: isSelected ? const Color(0xFF06B6D4) : Colors.white60, size: 16),
                              const SizedBox(width: 10),
                              Text(item['label'], style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
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
          
          Expanded(
            child: loading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))) 
              : SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (banner != null) Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: TVButton(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => TVPlayerPage(id: banner!['id'].toString(), source: selS, title: banner!['title'] ?? 'No Title', ep: '1'))),
                        child: Container(
                          height: 130, width: double.infinity, padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFF0F1522), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12, width: 0.5)),
                          child: Row(children: [
                            Expanded(
                              flex: 4,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)), child: const Text("PROMO TERBARU", style: TextStyle(color: Color(0xFF06B6D4), fontSize: 8, fontWeight: FontWeight.bold))),
                                const SizedBox(height: 6),
                                Text(banner!['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(banner!['description'] ?? 'Tonton kisah selengkapnya sekarang juga di server terbaik LiveGO.', style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ]),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: banner!['cover'] ?? '', fit: BoxFit.cover, height: double.infinity, placeholder: (_, __) => Container(color: Colors.white10), errorWidget: (_, __, ___) => Container(color: Colors.white10))),
                            ),
                          ]),
                        ),
                      ),
                    ),
                    
                    // FIX FINAL: IMPLEMENTASI STRUKTUR TOMBOL SEJAJAR BERDAMPINGAN (PLATFORM DI KIRI & KATEGORI DI KANAN)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Sisi Kiri: List Kapsul Platform
                          if (platforms.isNotEmpty) Expanded(
                            child: SizedBox(
                              height: 34,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal, itemCount: platforms.length,
                                itemBuilder: (context, index) {
                                  final p = platforms[index]; final isSelected = selS == p;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: TVButton(
                                      onTap: () { setState(() { selS = p; fetch(forceRefresh: true); }); },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14), alignment: Alignment.center,
                                        decoration: BoxDecoration(color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10), border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : Colors.white12, width: 0.5)),
                                        child: Text(p, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Sisi Kanan: Dua Tombol Menu Pilihan Kategori Khas Gambar CineFlow Anda
                          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            TVButton(onTap: () { setState(() { selC = "Trending"; fetch(forceRefresh: true); }); }, child: Column(mainAxisSize: MainAxisSize.min, children: [Text("Trending", style: TextStyle(color: selC == "Trending" ? Colors.white : Colors.white54, fontSize: 12, fontWeight: selC == "Trending" ? FontWeight.bold : FontWeight.normal)), Container(margin: const EdgeInsets.only(top: 4), height: 2, width: 45, color: selC == "Trending" ? const Color(0xFF06B6D4) : Colors.transparent)])),
                            const SizedBox(width: 16),
                            TVButton(onTap: () { setState(() { selC = "Terbaru"; fetch(forceRefresh: true); }); }, child: Column(mainAxisSize: MainAxisSize.min, children: [Text("Terbaru", style: TextStyle(color: selC == "Terbaru" ? Colors.white : Colors.white54, fontSize: 12, fontWeight: selC == "Terbaru" ? FontWeight.bold : FontWeight.normal)), Container(margin: const EdgeInsets.only(top: 4), height: 2, width: 40, color: selC == "Terbaru" ? const Color(0xFF06B6D4) : Colors.transparent)])),
                          ]),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    if (selC == "Trending") ...[
                      if (hasDubbing) ...[
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Text("Sulih Suara", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                        _buildGrid(dubbingList, "Tidak ada konten sulih suara"),
                      ],
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Text("Populer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      _buildGrid(popularList, "Tidak ada konten populer tersedia"),
                    ] else ...[
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Text("Rilisan Baru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      _buildGrid(terbaruList, "Tidak ada rilisan terbaru tersedia"),
                    ],
                    const SizedBox(height: 20),
                  ]),
                ),
          ),
        ]),
      ),
    );
  }
}
