import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'player.dart';
import 'api_service.dart';

class DetailScreen extends StatefulWidget {
  final String id, source, title;
  const DetailScreen({super.key, required this.id, required this.source, required this.title});

  @override State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Map? data;
  bool loading = true;
  bool isFavorite = false;

  @override void initState() { 
    super.initState(); 
    _load();
    _checkFavorite();
  }

  Future<void> _load() async {
    final res = await ApiService.get("/api/v2/detail?category_p=${widget.source}&id=${widget.id}&lang=id");
    if (res != null && res['data'] != null) {
      setState(() { data = res['data']; loading = false; });
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
        'total_episodes': data?['total_episodes'] ?? 0,
        'platform': widget.source,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
    setState(() => isFavorite = !isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isFavorite ? "Ditambahkan ke favorit" : "Dihapus dari favorit")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: loading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(children: [
              Image.network(data?['cover'] ?? ''),
              Text(data?['title'] ?? ''),
              Text(data?['synopsis'] ?? ''),
              ElevatedButton.icon(
                onPressed: _toggleFavorite,
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                label: Text(isFavorite ? "Hapus Favorit" : "Tambah Favorit"),
              ),
              // Episode grid...
            ]),
          ),
    );
  }
}
