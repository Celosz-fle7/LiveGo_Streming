import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../widgets/tv_button.dart';
import 'settings/source_manager.dart';
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
                    icon: const Icon(Icons.delete, color: Color(0xFFEF4444)),
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
            TextButton(onPressed: _clearHistory, child: const Text("Hapus Semua", style: TextStyle(color: Color(0xFFEF4444)))),
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
                    icon: const Icon(Icons.delete, color: Color(0xFFEF4444)),
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
            TextButton(onPressed: _clearFavorites, child: const Text("Hapus Semua", style: TextStyle(color: Color(0xFFEF4444)))),
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
    bool isTV = MediaQuery.of(context).size.width > 900;
    final focusColor = isTV ? const Color(0xFF0D9488) : const Color(0xFF06B6D4);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: ListView(padding: const EdgeInsets.all(15), children: [
        const SizedBox(height: 20),
        
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)]),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Center(
                child: Text("L", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            const Text("LiveGO", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        
        const SizedBox(height: 20),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            const CircleAvatar(backgroundColor: Colors.white, radius: 30, child: Icon(Icons.person, color: Color(0xFF4F46E5), size: 30)),
            const SizedBox(width: 15),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("User Penggemar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
              const Text("Selamat datang kembali", style: TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ]),
        ),
        
        const SizedBox(height: 20),
        
        _sectionCard("📁 KOLEKSI CEPAT", [
          _menuItem(Icons.history, "Riwayat", "${_history.length} item", _showHistoryDialog, focusColor),
          _menuItem(Icons.favorite, "Favorit", "${_favorites.length} drama", _showFavoritesDialog, focusColor),
        ], focusColor),
        
        const SizedBox(height: 16),
        
        _sectionCard("⚙️ PENGATURAN", [
          _settingItem(Icons.display_settings, "Tampilan & Navigasi", nav, _showNav, focusColor),
          _switchItem(Icons.image, "Background Poster", bgPoster, (v){ setState(()=>bgPoster=v); _save('bg',v); }, focusColor),
          _switchItem(Icons.cached, "Cache Playback", useCache, (v){ setState(()=>useCache=v); _save('cache',v); }, focusColor),
          _switchItem(Icons.screen_rotation, "Rotasi Manual", rotasi, (v){ setState(()=>rotasi=v); _save('rot',v); }, focusColor),
          _settingItem(Icons.security, "Widevine DRM", drm, _showDRM, focusColor),
          _settingItem(Icons.data_usage, "Kelola Sumber Data", "Atur platform aktif", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SourceManagerPage()));
          }, focusColor),
          _settingItem(Icons.delete_sweep, "Bersihkan Cache", "Hapus data sementara", _clearCache, focusColor),
        ], focusColor),
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Center(
            child: Text(
              "LiveGO Version 1.0.0",
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _sectionCard(String title, List<Widget> children, Color focusColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle, VoidCallback onTap, Color focusColor) {
    return TVButton(
      onTap: onTap,
      focusColor: focusColor,
      child: ListTile(
        leading: Icon(icon, color: focusColor),
        title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.white30),
      ),
    );
  }

  Widget _settingItem(IconData icon, String title, String value, VoidCallback onTap, Color focusColor) {
    return TVButton(
      onTap: onTap,
      focusColor: focusColor,
      child: ListTile(
        leading: Icon(icon, color: focusColor),
        title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.white)),
        subtitle: Text(value, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.white30),
      ),
    );
  }

  Widget _switchItem(IconData icon, String title, bool value, Function(bool) onChanged, Color focusColor) {
    return TVButton(
      onTap: () => onChanged(!value),
      focusColor: focusColor,
      child: SwitchListTile(
        secondary: Icon(icon, color: focusColor),
        title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.white)),
        value: value,
        onChanged: onChanged,
        activeColor: focusColor,
      ),
    );
  }
}
