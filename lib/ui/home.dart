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
  String selS = "";
  String selC = "Dubbing";
  List<String> platforms = [];
  bool hasDubbing = false;
  
  List<String> allPlatforms = [
    "Melolo", "FreeReels", "ShortMax", "DramaWave", "NetShort", "GoodShort",
    "Moviebox", "Anichin", "Animelovers", "RapidTV", "ReelShort"
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

  Future<void> fetch() async {
    if (selS.isEmpty) return;
    setState(() { loading = true; hasDubbing = false; });
    
    // Load banner
    final bRes = await ApiService.get("/api/v2/banner?category_p=$selS&lang=id");
    if (bRes != null && bRes['data'] != null && bRes['data'].isNotEmpty) {
      setState(() => banner = bRes['data'][0]);
    }
    
    if (selC == "Dubbing") {
      // Load Dubbing
      final dubRes = await ApiService.get("/api/v2/search?category_p=$selS&q=sulih%20suara&lang=id");
      if (dubRes != null && dubRes['data'] != null) {
        final dubData = dubRes['data'] is List ? dubRes['data'] : (dubRes['data']['dramas'] ?? []);
        setState(() {
          dubbingList = dubData;
          hasDubbing = dubData.isNotEmpty;
        });
      }
      
      // Load Popular
      final popRes = await ApiService.get("/api/v2/discover?category_p=$selS&lang=id&page=1");
      if (popRes != null && popRes['data'] != null) {
        final popData = popRes['data'] is List ? popRes['data'] : (popRes['data']['dramas'] ?? []);
        setState(() => popularList = popData);
      }
    } else {
      // Load Terbaru
      final newRes = await ApiService.get("/api/v2/home?category_p=$selS&lang=id");
      if (newRes != null && newRes['data'] != null) {
        final newData = newRes['data'] is List ? newRes['data'] : (newRes['data']['dramas'] ?? []);
        setState(() => terbaruList = newData);
      }
    }
    
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    bool isT = MediaQuery.of(context).size.width > 900;
    
    Widget buildGrid(List list) {
      if (list.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text("Tidak ada konten", style: TextStyle(color: Colors.white54))),
        );
      }
      return GridView.builder(
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
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => PlayerPage(id: list[i]['id'], source: selS, title: list[i]['title']))),
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
      body: platforms.isEmpty
          ? const Center(child: Text("Tidak ada platform aktif.\nKelola Sumber Data untuk mengaktifkan.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)))
          : loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
              : SingleChildScrollView(
                  child: Column(children: [
                    if (banner != null)
                      Container(
                        margin: const EdgeInsets.all(15), height: 180,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)]),
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => PlayerPage(id: banner!['id'], source: selS, title: banner!['title']))),
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
                                  decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(15)),
                                  child: const Text("Tonton Sekarang", style: TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                              ]),
                            ),
                          ]),
                        ),
                      ),
                    _list(platforms, selS, (v){ setState(()=> selS = v.toLowerCase()); fetch(); }, const Color(0xFF4F46E5)),
                    const SizedBox(height: 10),
                    _list(["Dubbing", "Terbaru"], selC, (v){ setState(()=> selC = v); fetch(); }, const Color(0xFF4F46E5)),
                    
                    if (selC == "Dubbing")
                      Column(children: [
                        if (hasDubbing) ...[
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Row(children: [Text("Dubbing (Sulih Suara)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))])),
                          buildGrid(dubbingList),
                        ],
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Row(children: [Text("Populer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))])),
                        if (hasDubbing) const SizedBox(height: 10),
                        buildGrid(popularList),
                      ])
                    else
                      Column(children: [
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Row(children: [Text("Terbaru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))])),
                        buildGrid(terbaruList),
                      ]),
                  ]),
                ),
    );
  }

  Widget _list(List l, String s, Function(String) o, Color c) => SizedBox(
    height: 40,
    child: ListView.builder(
      scrollDirection: Axis.horizontal, 
      padding: const EdgeInsets.only(left: 15), 
      itemCount: l.length,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: GestureDetector(
          onTap: () => o(l[i]),
          child: Column(children: [
            Text(l[i], style: TextStyle(color: s == l[i].toLowerCase() || s == l[i] ? Colors.white : Colors.white54, fontSize: 14, fontWeight: s == l[i].toLowerCase() || s == l[i] ? FontWeight.bold : FontWeight.normal)),
            Container(margin: const EdgeInsets.only(top: 4), height: 2, width: 20, color: s == l[i].toLowerCase() || s == l[i] ? c : Colors.transparent),
          ]),
        ),
      ),
    ),
  );
}
