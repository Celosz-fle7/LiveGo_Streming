import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'detail/detail_screen.dart';
import 'api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List _results = [];
  bool isLoading = false;
  String _selectedPlatform = "freereels";
  final List<String> _platforms = ["freereels", "melolo", "shortmax", "dramawave"];

  Future<void> _search() async {
    if (_searchController.text.isEmpty) return;
    setState(() => isLoading = true);
    
    final res = await ApiService.get("/api/v2/search?category_p=$_selectedPlatform&q=${Uri.encodeComponent(_searchController.text)}&lang=id");
    if (res != null && res['data'] != null) {
      setState(() {
        _results = res['data'] is List ? res['data'] : (res['data']['dramas'] ?? []);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isT = MediaQuery.of(context).size.width > 900;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text("Pencarian", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D1117),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Cari judul drama...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1F2937),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedPlatform,
                    dropdownColor: const Color(0xFF1F2937),
                    underline: const SizedBox(),
                    style: const TextStyle(color: Colors.white),
                    items: _platforms.map((p) {
                      return DropdownMenuItem(value: p, child: Text(p.toUpperCase()));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedPlatform = v!),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
                : _results.isEmpty
                    ? const Center(child: Text("Tidak ada hasil", style: TextStyle(color: Colors.white54)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isT ? 6 : 3,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => DetailScreen(
                                    id: item['id'].toString(),
                                    source: _selectedPlatform,
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
                                const SizedBox(height: 6),
                                Text(
                                  item['title'] ?? 'No Title',
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "${item['chapters'] ?? 0} Ep",
                                  style: const TextStyle(color: Colors.white54, fontSize: 9),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
