import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../detail/detail_screen.dart';
import '../api_service.dart';

class TVHomePage extends StatefulWidget {
  const TVHomePage({super.key});

  @override
  State<TVHomePage> createState() => _TVHomePageState();
}

class _TVHomePageState extends State<TVHomePage> {
  List dubbingList = [];
  List popularList = [];
  List terbaruList = [];
  Map? banner;
  bool loading = true;
  String selS = "freereels";
  String selC = "Dubbing";
  List<String> platforms = [];
  bool hasDubbing = false;
  
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
      if (platforms.isNotEmpty && selS.isEmpty) {
        selS = platforms[0].toLowerCase();
      }
    });
    if (platforms.isNotEmpty) fetch();
  }

  Future<void> fetch({bool forceRefresh = false}) async {
    if (selS.isEmpty) return;
    setState(() { loading = true; hasDubbing = false; });
    
    final bRes = await ApiService.get("/api/v2/banner?category_p=$selS&lang=id", forceRefresh: forceRefresh);
    if (bRes != null && bRes['data'] != null && bRes['data'].isNotEmpty) {
      setState(() => banner = bRes['data'][0]);
    }
    
    if (selC == "Dubbing") {
      final dubRes = await ApiService.get("/api/v2/search?category_p=$selS&q=sulih%20suara&lang=id", forceRefresh: forceRefresh);
      if (dubRes != null && dubRes['data'] != null) {
        final dubData = dubRes['data'] is List ? dubRes['data'] : (dubRes['data']['dramas'] ?? []);
        setState(() {
          dubbingList = dubData;
          hasDubbing = dubData.isNotEmpty;
        });
      }
      
      final popRes = await ApiService.get("/api/v2/discover?category_p=$selS&lang=id&page=1", forceRefresh: forceRefresh);
      if (popRes != null && popRes['data'] != null) {
        final popData = popRes['data'] is List ? popRes['data'] : (popRes['data']['dramas'] ?? []);
        setState(() => popularList = popData);
      }
    } else {
      final newRes = await ApiService.get("/api/v2/home?category_p=$selS&lang=id", forceRefresh: forceRefresh);
      if (newRes != null && newRes['data'] != null) {
        final newData = newRes['data'] is List ? newRes['data'] : (newRes['data']['dramas'] ?? []);
        setState(() => terbaruList = newData);
      }
    }
    
    setState(() => loading = false);
  }

  Widget _buildGrid(List list) {
    if (list.isEmpty) {
      return const Center(child: Text("Tidak ada konten", style: TextStyle(color: Colors.white54)));
    }
    return GridView.builder(
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(), 
      padding: const EdgeInsets.all(16), 
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 0.65, 
        crossAxisSpacing: 12, 
        mainAxisSpacing: 16
      ),
      itemCount: list.length > 30 ? 30 : list.length,
      itemBuilder: (c, i) {
        final item = list[i];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => DetailScreen(
                  id: item['id'].toString(),
                  source: selS,
                  title: item['title'] ?? 'No Title',
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: item['cover'] ?? '',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (_, __) => Container(color: Colors.grey[800]),
                    errorWidget: (_, __, ___) => Container(color: Colors.grey[800]),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['title'] ?? 'No Title',
                style: const TextStyle(color: Colors.white, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    "${item['chapters'] ?? 0} Ep",
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${item['views'] ?? 0}",
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Banner
                  if (banner != null)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => DetailScreen(
                              id: banner!['id'].toString(),
                              source: selS,
                              title: banner!['title'] ?? 'No Title',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
                        ),
                        child: Stack(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(banner!['cover'], fit: BoxFit.cover, width: double.infinity),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(begin: Alignment.bottomCenter, colors: [Colors.black, Colors.transparent]),
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            left: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(banner!['title'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF06B6D4),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text("Tonton Sekarang", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                  
                  // Platform Cards
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
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
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : Colors.white12),
                            ),
                            child: Text(
                              platform,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Category Tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() { selC = "Dubbing"; fetch(); }),
                          child: Column(
                            children: [
                              Text(
                                "Dubbing",
                                style: TextStyle(
                                  color: selC == "Dubbing" ? const Color(0xFF06B6D4) : Colors.white70,
                                  fontSize: 16,
                                  fontWeight: selC == "Dubbing" ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              if (selC == "Dubbing")
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  height: 2,
                                  width: 60,
                                  color: const Color(0xFF06B6D4),
                                ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() { selC = "Terbaru"; fetch(); }),
                          child: Column(
                            children: [
                              Text(
                                "Terbaru",
                                style: TextStyle(
                                  color: selC == "Terbaru" ? const Color(0xFF06B6D4) : Colors.white70,
                                  fontSize: 16,
                                  fontWeight: selC == "Terbaru" ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              if (selC == "Terbaru")
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  height: 2,
                                  width: 60,
                                  color: const Color(0xFF06B6D4),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Content
                  if (selC == "Dubbing")
                    Column(children: [
                      if (hasDubbing) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("Dubbing (Sulih Suara)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        _buildGrid(dubbingList),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text("Populer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      if (hasDubbing) const SizedBox(height: 8),
                      _buildGrid(popularList),
                    ])
                  else
                    Column(children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text("Terbaru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      _buildGrid(terbaruList),
                    ]),
                ],
              ),
            ),
    );
  }
}
