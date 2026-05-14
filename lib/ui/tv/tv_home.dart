import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'tv_player.dart';
import '../api_service.dart';
import '../../widgets/tv_button.dart';

class TVHomePage extends StatefulWidget {
  const TVHomePage({super.key});
  @override
  State<TVHomePage> createState() => _TVHomePageState();
}

class _TVHomePageState extends State<TVHomePage> {
  List dubbingList = [], popularList = [], terbaruList = [], platforms = [];
  Map? banner;
  bool loading = true, hasDubbing = false;
  String selS = "freereels", selC = "Dubbing";
  int _selectedMenuIdx = 0;
  
  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.home, 'label': 'Beranda'},
    {'icon': Icons.download, 'label': 'Unduhan'},
    {'icon': Icons.history, 'label': 'Riwayat'},
    {'icon': Icons.favorite, 'label': 'Favorit'},
    {'icon': Icons.person, 'label': 'Akun'},
    {'icon': Icons.search, 'label': 'Cari'},
  ];

  @override
  void initState() { super.initState(); _loadActivePlatforms(); }

  Future<void> _loadActivePlatforms() async {
    final prefs = await SharedPreferences.getInstance();
    final active = <String>[];
    for (var p in ["Melolo", "FreeReels", "ShortMax", "DramaWave", "NetShort", "GoodShort"]) {
      if (prefs.getBool('source_${p.toLowerCase()}') ?? true) active.add(p);
    }
    setState(() { 
      platforms = active; 
      if (active.isNotEmpty) selS = active[0].toLowerCase(); 
    });
    if (active.isNotEmpty) fetch();
  }

  Future<void> fetch({bool forceRefresh = false}) async {
    if (selS.isEmpty) return;
    setState(() => loading = true);
    
    final bRes = await ApiService.get("/api/v2/banner?category_p=$selS&lang=id", forceRefresh: forceRefresh);
    if (bRes != null && bRes['data'] != null && bRes['data'].isNotEmpty) {
      setState(() => banner = bRes['data'][0]);
    } else {
      setState(() => banner = null);
    }
    
    if (selC == "Dubbing") {
      final dRes = await ApiService.get("/api/v2/search?category_p=$selS&q=sulih%20suara&lang=id", forceRefresh: forceRefresh);
      final pRes = await ApiService.get("/api/v2/discover?category_p=$selS&lang=id&page=1", forceRefresh: forceRefresh);
      setState(() {
        dubbingList = dRes != null ? (dRes['data'] is List ? dRes['data'] : (dRes['data']['dramas'] ?? [])) : [];
        popularList = pRes != null ? (pRes['data'] is List ? pRes['data'] : (pRes['data']['dramas'] ?? [])) : [];
        hasDubbing = dubbingList.isNotEmpty;
      });
    } else {
      final nRes = await ApiService.get("/api/v2/home?category_p=$selS&lang=id", forceRefresh: forceRefresh);
      setState(() => terbaruList = nRes != null ? (nRes['data'] is List ? nRes['data'] : (nRes['data']['dramas'] ?? [])) : []);
    }
    setState(() => loading = false);
  }

  Widget _buildGrid(List list) {
    if (list.isEmpty) return const SizedBox(height: 80, child: Center(child: Text("Tidak ada konten", style: TextStyle(color: Colors.white30))));
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, childAspectRatio: 0.7, crossAxisSpacing: 12, mainAxisSpacing: 14),
        itemCount: list.length > 18 ? 18 : list.length,
        itemBuilder: (c, i) {
          final item = list[i];
          return TVButton(
            onTap: () => Navigator.push(c, MaterialPageRoute(builder: (ctx) => TVPlayerPage(id: item['id'].toString(), source: selS, title: item['title'] ?? 'No Title', ep: '1'))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: item['cover'] ?? '', fit: BoxFit.cover, width: double.infinity, placeholder: (_, __) => Container(color: Colors.white10), errorWidget: (_, __, ___) => Container(color: Colors.white10)))),
              const SizedBox(height: 6),
              Text(item['title'] ?? 'No Title', style: const TextStyle(color: Colors.white, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
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
          FocusScope(
            child: Container(
              width: 240, height: double.infinity,
              padding: const EdgeInsets.all(20),
              // FIXED: Mengganti Colors.white05 yang typo menjadi warna resmi Colors.white12 bawaan Flutter
              decoration: const BoxDecoration(color: Color(0xFF0F1522), border: Border(right: BorderSide(color: Colors.white12, width: 0.5))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                  child: const Row(children: [
                    Icon(Icons.play_circle_filled, color: Color(0xFF06B6D4), size: 24),
                    SizedBox(width: 10),
                    Text("CineFlow", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView.builder(
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      final isSelected = _selectedMenuIdx == index;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TVButton(
                          onTap: () => setState(() => _selectedMenuIdx = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(color: isSelected ? const Color(0xFF1E3A8A).withOpacity(0.5) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              Icon(item['icon'], color: isSelected ? const Color(0xFF06B6D4) : Colors.white60, size: 20),
                              const SizedBox(width: 16),
                              Text(item['label'], style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
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
            child: loading ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))) : SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (banner != null) Padding(
                  padding: const EdgeInsets.all(16),
                  child: TVButton(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => TVPlayerPage(id: banner!['id'].toString(), source: selS, title: banner!['title'] ?? 'No Title', ep: '1'))),
                    child: Container(
                      height: 200, width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      // FIXED: Mengganti Colors.white05 yang typo menjadi warna resmi Colors.white12 bawaan Flutter
                      decoration: BoxDecoration(color: const Color(0xFF0F1522), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12, width: 0.5)),
                      child: Row(children: [
                        Expanded(
                          flex: 3,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)), child: const Text("PROMO", style: TextStyle(color: Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.bold))),
                            const SizedBox(height: 8),
                            Text(banner!['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Text(banner!['description'] ?? 'Tonton kisah selengkapnya sekarang juga di server terbaik.', style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                          ]),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(banner!['cover'] ?? '', fit: BoxFit.cover, height: double.infinity),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
                if (platforms.isNotEmpty) SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: platforms.length,
                    itemBuilder: (context, index) {
                      final p = platforms[index]; final isSel = selS == p.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: TVButton(
                          onTap: () { setState(() => selS = p.toLowerCase()); fetch(); },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.center,
                            decoration: BoxDecoration(color: isSel ? const Color(0xFF1E3A8A) : const Color(0xFF1E293B), borderRadius: BorderRadius.circular(30), border: Border.all(color: isSel ? const Color(0xFF06B6D4) : Colors.transparent, width: 1)),
                            child: Text(p, style: TextStyle(color: isSel ? const Color(0xFF06B6D4) : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
                  child: Row(children: [
                    TVButton(onTap: () { setState(() => selC = "Dubbing"); fetch(); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: selC == "Dubbing" ? Colors.white12 : Colors.transparent, borderRadius: BorderRadius.circular(20)), child: Text("Populer", style: TextStyle(color: selC == "Dubbing" ? const Color(0xFF06B6D4) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)))),
                    const SizedBox(width: 10),
                    TVButton(onTap: () { setState(() => selC = "Terbaru"); fetch(); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: selC == "Terbaru" ? Colors.white12 : Colors.transparent, borderRadius: BorderRadius.circular(20)), child: Text("Baru", style: TextStyle(color: selC == "Terbaru" ? const Color(0xFF06B6D4) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)))),
                  ]),
                ),
                if (selC == "Dubbing") ...[
                  _buildGrid(popularList),
                ] else ...[
                  _buildGrid(terbaruList),
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
