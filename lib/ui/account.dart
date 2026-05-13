import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'widgets.dart';
import '../database/database_helper.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String nav = "Otomatis (Ikuti Hardware)";
  String drm = "Auto";
  bool bgPoster = true;
  bool useCache = true;
  bool rotasi = true;
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _favorites = [];

  @override void initState() { 
    super.initState(); 
    _load(); 
    _loadHistory();
    _loadFavorites();
  }

  _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      nav = p.getString('nav') ?? "Otomatis (Ikuti Hardware)";
      drm = p.getString('drm') ?? "Auto";
      bgPoster = p.getBool('bg') ?? true;
      useCache = p.getBool('cache') ?? true;
      rotasi = p.getBool('rot') ?? true;
    });
  }

  _loadHistory() async {
    final history = await DatabaseHelper().getHistory();
    setState(() => _history = history);
  }

  _loadFavorites() async {
    final favorites = await DatabaseHelper().getFavorites();
    setState(() => _favorites = favorites);
  }

  _save(String k, dynamic v) async {
    final p = await SharedPreferences.getInstance();
    if (v is String) p.setString(k, v); else p.setBool(k, v);
  }

  Future<void> _clearCache() async {
    final dir = await getTemporaryDirectory();
    if (dir.existsSync()) { dir.deleteSync(recursive: true); }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cache Berhasil Dibersihkan")));
  }

  Future<void> _clearHistory() async {
    await DatabaseHelper().clearHistory();
    _loadHistory();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Riwayat dibersihkan")));
  }

  Future<void> _clearFavorites() async {
    await DatabaseHelper().clearFavorites();
    _loadFavorites();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Favorit dibersihkan")));
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Riwayat Tontonan", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1F2937),
        content: _history.isEmpty 
          ? const Text("Belum ada riwayat", style: TextStyle(color: Colors.white54))
          : SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (ctx, i) => ListTile(
                  title: Text(_history[i]['drama_title'], style: const TextStyle(color: Colors.white)),
                  subtitle: Text("Episode ${_history[i]['episode_number']}", style: const TextStyle(color: Colors.white54)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await DatabaseHelper().deleteHistoryItem(_history[i]['id']);
                      _loadHistory();
                      Navigator.pop(c);
                      _showHistoryDialog();
                    },
                  ),
                ),
              ),
            ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Tutup", style: TextStyle(color: Colors.white54))),
          if (_history.isNotEmpty)
            TextButton(onPressed: _clearHistory, child: const Text("Hapus Semua", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showFavoritesDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Daftar Favorit", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1F2937),
        content: _favorites.isEmpty 
          ? const Text("Belum ada favorit", style: TextStyle(color: Colors.white54))
          : SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: _favorites.length,
                itemBuilder: (ctx, i) => ListTile(
                  title: Text(_favorites[i]['drama_title'], style: const TextStyle(color: Colors.white)),
                  subtitle: Text("${_favorites[i]['total_episodes']} Episode", style: const TextStyle(color: Colors.white54)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await DatabaseHelper().removeFromFavorites(_favorites[i]['drama_id']);
                      _loadFavorites();
                      Navigator.pop(c);
                      _showFavoritesDialog();
                    },
                  ),
                ),
              ),
            ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Tutup", style: TextStyle(color: Colors.white54))),
          if (_favorites.isNotEmpty)
            TextButton(onPressed: _clearFavorites, child: const Text("Hapus Semua", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showNav() => _dialog("Navigasi", ["Otomatis (Ikuti Hardware)", "Smartphone / Tablet", "Android TV"], nav, (v){ setState(()=>nav=v); _save('nav',v); });
  void _showDRM() => _dialog("Widevine DRM", ["Auto", "Paksa L3"], drm, (v){ setState(()=>drm=v); _save('drm',v); });

  void _dialog(String t, List<String> o, String g, Function(String) s) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: Text(t, style: const TextStyle(color: Colors.white)), 
      backgroundColor: const Color(0xFF1F2937),
      content: Column(mainAxisSize: MainAxisSize.min, children: o.map((v) => RadioListTile(
        title: Text(v, style: const TextStyle(fontSize: 14, color: Colors.white)), value: v, groupValue: g,
        onChanged: (x){ s(x!); Navigator.pop(c); }
      )).toList()),
    ));
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: ListView(padding: const EdgeInsets.all(15), children: [
        const SizedBox(height: 40),
        _header(),
        const SizedBox(height: 20),
        _label("KOLEKSI CEPAT"),
        _card([
          _item(Icons.history, "Riwayat", "Lanjutkan tontonan", _showHistoryDialog),
          _item(Icons.favorite, "Favorit", "Daftar favorit Anda", _showFavoritesDialog),
        ]),
        _label("PENGATURAN"),
        _card([
          _item(Icons.settings, "Tampilan & Navigasi", nav, _showNav),
          _switch(Icons.image, "Background Poster", bgPoster, (v){ setState(()=>bgPoster=v); _save('bg',v); }),
          _switch(Icons.cached, "Cache Playback", useCache, (v){ setState(()=>useCache=v); _save('cache',v); }),
          _switch(Icons.screen_rotation, "Rotasi Manual", rotasi, (v){ setState(()=>rotasi=v); _save('rot',v); }),
          _item(Icons.security, "Widevine DRM", drm, _showDRM),
          _item(Icons.delete_sweep, "Bersihkan Cache", "Hapus data sementara", _clearCache),
        ]),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              const Text("LiveGO", style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 5),
              Text("Versi 1.0.0", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [const Color(0xFF8B5CF6), const Color(0xFFEC4899)]),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(children: [
      CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Color(0xFF8B5CF6))),
      SizedBox(width: 15),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("User Penggemar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        Text("Selamat datang kembali", style: TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    ]),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(left: 10, bottom: 8, top: 10),
    child: Text(t, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
  );

  Widget _card(List<Widget> i) => Container(
    decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(15)),
    margin: const EdgeInsets.only(bottom: 15),
    child: Column(children: i),
  );

  Widget _item(IconData i, String t, String s, VoidCallback c) => TVButton(
    onTap: c,
    child: ListTile(
      leading: Icon(i, color: const Color(0xFF8B5CF6)),
      title: Text(t, style: const TextStyle(fontSize: 14, color: Colors.white)),
      subtitle: Text(s, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.white30),
    ),
  );

  Widget _switch(IconData i, String t, bool v, Function(bool) c) => TVButton(
    onTap: () => c(!v),
    child: SwitchListTile(
      secondary: Icon(i, color: const Color(0xFF8B5CF6)),
      title: Text(t, style: const TextStyle(fontSize: 14, color: Colors.white)),
      value: v,
      onChanged: c,
      activeColor: const Color(0xFF8B5CF6),
    ),
  );
}
