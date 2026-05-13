import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../database/database_helper.dart';
import '../player.dart';
import '../api_service.dart';

class DetailScreen extends StatefulWidget {
  final String id, source, title;
  const DetailScreen({super.key, required this.id, required this.source, required this.title});

  @override State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Map? data;
  List episodes = [];
  bool loading = true;
  bool isFavorite = false;
  int _selectedRange = 0; // 0: 1-50, 1: 51-99

  @override void initState() { 
    super.initState(); 
    _load();
    _checkFavorite();
  }

  Future<void> _load() async {
    final res = await ApiService.get("/api/v2/detail?category_p=${widget.source}&id=${widget.id}&lang=id");
    if (res != null && res['data'] != null) {
      setState(() { 
        data = res['data'];
        episodes = data?['chapters'] ?? [];
        loading = false; 
      });
    } else {
      setState(() => loading = false);
    }
  }

  Future<void> _checkFavorite() async {
    isFavorite = await DatabaseHelper().isFavorite(widget.id);
    setState(() {});
  }

  Future<void> _toggleFavorite() async {
    if (isFavorite) {
      await DatabaseHelper().removeFromFavorites(widget.id);
    } else {
      await DatabaseHelper().addToFavorites({
        'drama_id': widget.id,
        'drama_title': widget.title,
        'drama_poster': data?['cover'],
        'total_episodes': data?['total_episodes'] ?? episodes.length,
        'platform': widget.source,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
    setState(() => isFavorite = !isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isFavorite ? "Ditambahkan ke favorit" : "Dihapus dari favorit"), duration: const Duration(seconds: 1)),
    );
  }

  List _getDisplayEpisodes() {
    if (episodes.length <= 50) return episodes;
    if (_selectedRange == 0) return episodes.sublist(0, 50);
    return episodes.sublist(50);
  }

  @override
  Widget build(BuildContext context) {
    bool isT = MediaQuery.of(context).size.width > 900;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: loading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poster & Info Section
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [const Color(0xFF1F2937), const Color(0xFF0D1117)],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster
                      Container(
                        margin: const EdgeInsets.all(16),
                        width: 140,
                        height: 210,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: data?['cover'] ?? '',
                            fit: BoxFit.cover,
                            width: 140,
                            height: 210,
                            placeholder: (_, __) => Container(color: Colors.grey[800]),
                            errorWidget: (_, __, ___) => Container(color: Colors.grey[800], child: const Icon(Icons.movie, color: Colors.grey)),
                          ),
                        ),
                      ),
                      // Info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16, right: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data?['title'] ?? widget.title,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF06B6D4).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "${data?['total_episodes'] ?? episodes.length} Episode",
                                      style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 11),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text("Gratis", style: TextStyle(color: Colors.green, fontSize: 11)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                data?['synopsis'] ?? "Tidak ada sinopsis",
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // DAFTAR EPISODE
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "DAFTAR EPISODE",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${episodes.length} Episode",
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                // Range Selector (jika episode > 50)
                if (episodes.length > 50)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        _rangeButton("1-50", 0),
                        const SizedBox(width: 12),
                        _rangeButton("51-${episodes.length}", 1),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Episode Grid
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isT ? 6 : 4,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _getDisplayEpisodes().length,
                    itemBuilder: (context, index) {
                      final episode = _getDisplayEpisodes()[index];
                      final episodeNum = episode['index'] ?? index + 1;
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => PlayerPage(
                                id: widget.id,
                                source: widget.source,
                                title: widget.title,
                                ep: episodeNum.toString(),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12, width: 0.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_circle_outline, color: Color(0xFF06B6D4), size: 24),
                              const SizedBox(height: 6),
                              Text(
                                "Episode $episodeNum",
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
    );
  }

  Widget _rangeButton(String label, int range) {
    final isSelected = _selectedRange == range;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRange = range),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF06B6D4) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: isSelected ? const Color(0xFF06B6D4) : Colors.white24, width: 1),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
