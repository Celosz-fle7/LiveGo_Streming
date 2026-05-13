import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'player.dart';
import 'api_service.dart';

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
  
  final List<String> allPlatforms = [
    "Melolo", "FreeReels", "ShortMax", "DramaWave", "NetShort", "GoodShort"
  ];

  @override
  void initState() { 
    super.initState(); 
    _loadActivePlatforms();
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
        selS = platforms[0].toLowerCase();
      }
    });
    if (platforms.isNotEmpty) fetch();
  }

  Future<void> fetch({bool forceRefresh = false}) async {
    if (selS.isEmpty) return;
    setState(() { 
      loading = true; 
      hasDubbing = false;
      _loadingProgress = 0;
      _totalTasks = 0;
    });
    
    // Hitung total tugas yang akan dijalankan
    int totalTasks = 1; // banner
    totalTasks += 2; // dubbing + popular
    setState(() => _totalTasks = totalTasks);
    
    // Load banner
    final bRes = await ApiService.get("/api/v2/banner?category_p=$selS&lang=id", forceRefresh: forceRefresh);
    if (bRes != null && bRes['data'] != null && bRes['data'].isNotEmpty) {
      setState(() => banner = bRes['data'][0]);
    }
    setState(() => _loadingProgress++);
    
    if (selC == "Dubbing") {
      // Load Dubbing
      final dubRes = await ApiService.get("/api/v2/search?category_p=$selS&q=sulih%20suara&lang=id", forceRefresh: forceRefresh);
      if (dubRes != null && dubRes['data'] != null) {
        final dubData = dubRes['data'] is List ? dubRes['data'] : (dubRes['data']['dramas'] ?? []);
        setState(() {
          dubbingList = dubData;
          hasDubbing = dubData.isNotEmpty;
          _loadingProgress++;
        });
      } else {
        setState(() => _loadingProgress++);
      }
      
      // Load Popular
      final popRes = await ApiService.get("/api/v2/discover?category_p=$selS&lang=id&page=1", forceRefresh: forceRefresh);
      if (popRes != null && popRes['data'] != null) {
        final popData = popRes['data'] is List ? popRes['data'] : (popRes['data']['dramas'] ?? []);
        setState(() => popularList = popData);
      }
      setState(() => _loadingProgress++);
    } else {
      // Load Terbaru
      final newRes = await ApiService.get("/api/v2/home?category_p=$selS&lang=id", forceRefresh: forceRefresh);
      if (newRes != null && newRes['data'] != null) {
        final newData = newRes['data'] is List ? newRes['data'] : (newRes['data']['dramas'] ?? []);
        setState(() => terbaruList = newData);
      }
      setState(() => _loadingProgress++);
    }
    
    setState(() => loading = false);
  }

  Future<void> _onRefresh() async {
    setState(() => refreshing = true);
    await fetch(forceRefresh: true);
    setState(() => refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    bool isT = MediaQuery.of(context).size.width > 900;
    
    Widget buildGrid(List list, {String? title}) {
      if (list.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text("Tidak ada konten", style: TextStyle(color: Colors.white54))),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 15, top: 10, bottom: 5),
              child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          GridView.builder(
            shrinkWrap: true, 
            physics: const NeverScrollableScrollPhysics(), 
            padding: const EdgeInsets.all(15), 
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isT ? 7 : 4, 
              childAspectRatio: 0.65, 
              crossAxisSpacing: 10, 
              mainAxisSpacing: 10
            ),
            itemCount: list.length > 20 ? 20 : list.length,
            itemBuilder: (c, i) => GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => DetailScreen(id: list[i]['id'], source: selS, title: list[i]['title']))),
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5)]),
                child: Column(children: [
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(list[i]['cover'] ?? '', fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey[800])))),
                  const SizedBox(height: 6),
                  Text(list[i]['title'] ?? 'No Title', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.white)),
                  const SizedBox(height: 2),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(list[i]['chapters']?.toString() ?? "0 Ep", style: const TextStyle(color: Colors.white54, fontSize: 8)),
                    const SizedBox(width: 6),
                    Text(list[i]['views']?.toString() ?? "0", style: const TextStyle(color: Colors.white54, fontSize: 8)),
                  ]),
                ]),
              ),
            ),
          ),
        ],
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text("LiveGO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.favorite_border, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.history, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF06B6D4),
        backgroundColor: const Color(0xFF1F2937),
        child: platforms.isEmpty
          ? const Center(child: Text("Tidak ada platform aktif.\nKelola Sumber Data untuk mengaktifkan.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)))
          : loading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF06B6D4)),
                      const SizedBox(height: 16),
                      Text(
                        "Memuat data... ($_loadingProgress/$_totalTasks)",
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(children: [
                    // Banner
                    if (banner != null)
                      Container(
                        margin: const EdgeInsets.all(15), height: 180,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)]),
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DetailScreen(id: banner!['id'], source: selS, title: banner!['title']))),
                          child: Stack(children: [
                            ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(banner!['cover'], fit: BoxFit.cover, width: double.infinity)),
                            Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(begin: Alignment.bottomCenter, colors: [Colors.black, Colors.transparent])),
                              padding: const EdgeInsets.all(15),
                              alignment: Alignment.bottomLeft,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(banner!['title'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFF06B6D4), borderRadius: BorderRadius.circular(15)),
                                  child: const Text("Tonton Sekarang", style: TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                              ]),
                            ),
                          ]),
                        ),
                      ),
                    
                    // Platform Cards
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: platforms.map((platform) {
                          final isSelected = selS == platform.toLowerCase();
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selS = platform.toLowerCase();
                                fetch();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF06B6D4) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : Colors.white12, width: 0.5),
                              ),
                              child: Text(
                                platform,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Category Tabs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(width: 15),
                        _categoryTab("Dubbing", selC == "Dubbing", () => setState(() { selC = "Dubbing"; fetch(); })),
                        const SizedBox(width: 30),
                        _categoryTab("Terbaru", selC == "Terbaru", () => setState(() { selC = "Terbaru"; fetch(); })),
                      ],
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Content
                    if (selC == "Dubbing")
                      Column(children: [
                        if (hasDubbing) buildGrid(dubbingList, title: "Dubbing (Sulih Suara)"),
                        buildGrid(popularList, title: hasDubbing ? "Populer" : null),
                      ])
                    else
                      buildGrid(terbaruList, title: "Terbaru"),
                  ]),
                ),
      ),
    );
  }

  Widget _categoryTab(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            height: 2,
            width: title == "Dubbing" ? 50.0 : 45.0,
            color: isSelected ? const Color(0xFF06B6D4) : Colors.transparent,
          ),
        ],
      ),
    );
  }
}
