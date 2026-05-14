import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../player.dart';
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
  bool loading = true, hasDubbing = false, _showSidebar = false;
  String selS = "freereels", selC = "Dubbing";
  
  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.home, 'label': 'Beranda', 'route': '/'},
    {'icon': Icons.history, 'label': 'Riwayat', 'route': '/history'},
    {'icon': Icons.search, 'label': 'Cari', 'route': '/search'},
    {'icon': Icons.download, 'label': 'Unduhan', 'route': '/download'},
    {'icon': Icons.person, 'label': 'Akun', 'route': '/profile'},
  ];

  @override
  void initState() { super.initState(); _loadActivePlatforms(); }

  Future<void> _loadActivePlatforms() async {
    final prefs = await SharedPreferences.getInstance();
    final active = <String>[];
    for (var p in ["Melolo", "FreeReels", "ShortMax", "DramaWave", "NetShort", "GoodShort"]) {
      if (prefs.getBool('source_${p.toLowerCase()}') ?? true) active.add(p);
    }
    setState(() { platforms = active; if (active.isNotEmpty) selS = active[0].toLowerCase(); });
    if (active.isNotEmpty) fetch();
  }

  Future<void> fetch({bool forceRefresh = false}) async {
    if (selS.isEmpty) return;
    setState(() => loading = true);
    final bRes = await ApiService.get("/api/v2/banner?category_p=$selS&lang=id", forceRefresh: forceRefresh);
    if (bRes != null && bRes['data'] != null && bRes['data'].isNotEmpty) setState(() => banner = bRes['data'][0]);
    
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

  void _toggleSidebar() => setState(() => _showSidebar = !_showSidebar);

  Widget _buildGrid(List list) {
    if (list.isEmpty) return const Center(child: Text("Tidak ada konten", style: TextStyle(color: Colors.white54)));
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.7, crossAxisSpacing: 16, mainAxisSpacing: 20),
        itemCount: list.length > 20 ? 20 : list.length,
        itemBuilder: (c, i) {
          final item = list[i];
          return TVButton(
            onTap: () => Navigator.push(c, MaterialPageRoute(builder: (ctx) => PlayerPage(id: item['id'].toString(), source: selS, title: item['title'] ?? 'No Title', ep: '1'))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: CachedNetworkImage(imageUrl: item['cover'] ?? '', fit: BoxFit.cover, width: double.infinity, placeholder: (_, __) => Container(color: Colors.grey[800]), errorWidget: (_, __, ___) => Container(color: Colors.grey[800])))),
              const SizedBox(height: 8),
              Text(item['title'] ?? 'No Title', style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text("${item['chapters'] ?? 0} Ep  •  ${item['views'] ?? 0} Views", style: const TextStyle(color: Colors.white54, fontSize: 10)),
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
        backgroundColor: const Color(0xFF0D1117),
        body: Stack(children: [
          Positioned.fill(
            child: loading ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))) : SingleChildScrollView(
              padding: const EdgeInsets.only(left: 60),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (banner != null) TVButton(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => PlayerPage(id: banner!['id'].toString(), source: selS, title: banner!['title'] ?? 'No Title', ep: '1'))),
                  child: Container(
                    margin: const EdgeInsets.all(20), height: 220, width: double.infinity,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15)]),
                    child: Stack(children: [
                      Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.network(banner!['cover'], fit: BoxFit.cover))),
                      Positioned.fill(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.9), Colors.transparent])))),
                      Positioned(bottom: 20, left: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(banner!['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: const Color(0xFF06B6D4), borderRadius: BorderRadius.circular(30)), child: const Text("Tonton Sekarang", style: TextStyle(color: Colors.white, fontSize: 14)))]))
                    ]),
                  ),
                ),
                if (platforms.isNotEmpty) SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: platforms.length,
                    itemBuilder: (context, index) {
                      final p = platforms[index]; final isSel = selS == p.toLowerCase();
                      return TVButton(onTap: () { setState(() { selS = p.toLowerCase(); fetch(); }); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), margin: const EdgeInsets.only(right: 16), decoration: BoxDecoration(color: isSel ? const Color(0xFF06B6D4) : const Color(0xFF1F2937), borderRadius: BorderRadius.circular(30), border: Border.all(color: isSel ? const Color(0xFF06B6D4) : Colors.white12)), child: Text(p, style: TextStyle(color: isSel ? Colors.white : Colors.white70, fontSize: 14))));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    TVButton(onTap: () => setState(() { selC = "Dubbing"; fetch(); }), child: Column(children: [Text("Dubbing", style: TextStyle(color: selC == "Dubbing" ? const Color(0xFF06B6D4) : Colors.white70, fontSize: 18, fontWeight: selC == "Dubbing" ? FontWeight.bold : FontWeight.normal)), if (selC == "Dubbing") Container(margin: const EdgeInsets.only(top: 6), height: 3, width: 70, color: const Color(0xFF06B6D4))])),
                    const SizedBox(width: 30),
                    TVButton(onTap: () => setState(() { selC = "Terbaru"; fetch(); }), child: Column(children: [Text("Terbaru", style: TextStyle(color: selC == "Terbaru" ? const Color(0xFF06B6D4) : Colors.white70, fontSize: 18, fontWeight: selC == "Terbaru" ? FontWeight.bold : FontWeight.normal)), if (selC == "Terbaru") Container(margin: const EdgeInsets.only(top: 6), height: 3, width: 70, color: const Color(0xFF06B6D4))]))
                  ]),
                ),
                if (selC == "Dubbing") ...[
                  if (hasDubbing) ...[const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Dubbing (Sulih Suara)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))), _buildGrid(dubbingList)],
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Populer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))), _buildGrid(popularList)
                ] else ...[
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Terbaru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))), _buildGrid(terbaruList)
                ]
              ]),
            ),
          ),
          Positioned(
            left: 16, top: 16,
            child: TVButton(onTap: _toggleSidebar, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.menu, color: Colors.white, size: 28))),
          ),
          if (_showSidebar) Positioned.fill(child: GestureDetector(onTap: _toggleSidebar, child: Container(color: Colors.black45))),
          if (_showSidebar) Positioned(
            left: 0, top: 0, bottom: 0,
            child: FocusScope(
              child: Container(
                width: 300, color: const Color(0xFF1F2937),
                child: Column(children: [
                  const SizedBox(height: 60),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text("LiveGO", style: TextStyle(color: Color(0xFF06B6D4), fontSize: 28, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 40),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _menuItems.length,
                      itemBuilder: (context, index) {
                        final item = _menuItems[index];
                        return TVButton(
                          onTap: () {
                            setState(() => _showSidebar = false);
                            if (item['route'] != '/') Navigator.pushNamed(context, item['route']);
                          },
                          child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [Icon(item['icon'], color: Colors.white54, size: 28), const SizedBox(width: 16), Text(item['label'], style: const TextStyle(color: Colors.white70, fontSize: 16))])),
                        );
                      },
                    ),
                  ),
                  Padding(padding: const EdgeInsets.all(20), child: TVButton(onTap: _toggleSidebar, child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: const Color(0xFF06B6D4).withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Center(child: Text("Tutup Menu", style: TextStyle(color: Color(0xFF06B6D4), fontSize: 14)))))),
                  const SizedBox(height: 30)
                ]),
              ),
            ),
          )
        ]),
      ),
    );
  }
}
