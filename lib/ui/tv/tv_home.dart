import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../detail/detail_screen.dart';
import '../player.dart';
import '../api_service.dart';
import '../../widgets/tv_button.dart';

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
  int _selectedMenuIndex = 0;
  bool _showSidebar = false;
  
  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.home, 'label': 'Beranda', 'route': '/'},
    {'icon': Icons.history, 'label': 'Riwayat', 'route': '/history'},
    {'icon': Icons.search, 'label': 'Cari', 'route': '/search'},
    {'icon': Icons.download, 'label': 'Unduhan', 'route': '/download'},
    {'icon': Icons.person, 'label': 'Akun', 'route': '/profile'},
  ];
  
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

  void _onKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        setState(() => _showSidebar = true);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() => _showSidebar = false);
      }
    }
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
        childAspectRatio: 0.55,  // Lebih ramping, muat banyak
        crossAxisSpacing: 12, 
        mainAxisSpacing: 16
      ),
      itemCount: list.length > 30 ? 30 : list.length,
      itemBuilder: (c, i) {
        final item = list[i];
        return TVButton(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => PlayerPage(
                  id: item['id'].toString(),
                  source: selS,
                  title: item['title'] ?? 'No Title',
                  ep: '1',
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
              const SizedBox(height: 6),
              Text(
                item['title'] ?? 'No Title',
                style: const TextStyle(color: Colors.white, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    "${item['chapters'] ?? 0} Ep",
                    style: const TextStyle(color: Colors.white54, fontSize: 9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${item['views'] ?? 0}",
                    style: const TextStyle(color: Colors.white54, fontSize: 9),
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
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _onKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Stack(
          children: [
            // Konten Utama
            loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Banner
                        if (banner != null)
                          TVButton(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (c) => PlayerPage(
                                    id: banner!['id'].toString(),
                                    source: selS,
                                    title: banner!['title'] ?? 'No Title',
                                    ep: '1',
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              height: 200,
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
                              return TVButton(
                                onTap: () {
                                  setState(() {
                                    selS = platform.toLowerCase();
                                    fetch();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                      fontSize: 13,
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
                              TVButton(
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
                              TVButton(
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
                                child: Text("Dubbing (Sulih Suara)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              _buildGrid(dubbingList),
                            ],
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text("Populer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            if (hasDubbing) const SizedBox(height: 8),
                            _buildGrid(popularList),
                          ])
                        else
                          Column(children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text("Terbaru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            _buildGrid(terbaruList),
                          ]),
                      ],
                    ),
                  ),
            
            // Sidebar Overlay
            if (_showSidebar)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 280,
                  color: const Color(0xFF1F2937),
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "LiveGO",
                          style: TextStyle(color: Color(0xFF06B6D4), fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _menuItems.length,
                          itemBuilder: (context, index) {
                            final item = _menuItems[index];
                            return TVButton(
                              onTap: () {
                                setState(() => _showSidebar = false);
                                if (item['route'] == '/history') {
                                  Navigator.pushNamed(context, '/history');
                                } else if (item['route'] == '/search') {
                                  Navigator.pushNamed(context, '/search');
                                } else if (item['route'] == '/download') {
                                  Navigator.pushNamed(context, '/download');
                                } else if (item['route'] == '/profile') {
                                  Navigator.pushNamed(context, '/profile');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(item['icon'], color: Colors.white54),
                                    const SizedBox(width: 12),
                                    Text(
                                      item['label'],
                                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TVButton(
                          onTap: () => setState(() => _showSidebar = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF06B6D4).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text("Tutup Menu", style: TextStyle(color: Color(0xFF06B6D4))),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            
            // Tap area tutup sidebar
            if (_showSidebar)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _showSidebar = false),
                  child: Container(color: Colors.transparent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
