import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../widgets.dart';

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

  @override void initState() { super.initState(); _load(); }

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

  _save(String k, dynamic v) async {
    final p = await SharedPreferences.getInstance();
    if (v is String) p.setString(k, v); else p.setBool(k, v);
  }

  Future<void> _clearCache() async {
    final dir = await getTemporaryDirectory();
    if (dir.existsSync()) { dir.deleteSync(recursive: true); }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cache Berhasil Dibersihkan")));
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: ListView(padding: const EdgeInsets.all(15), children: [
        const SizedBox(height: 50),
        _header(),
        const SizedBox(height: 20),
        _label("KOLEKSI"),
        _card([
          _item(Icons.history, "Riwayat", "Lihat tontonan terakhir", () {}),
          _item(Icons.favorite, "Favorit", "Drama yang disimpan", () {}),
        ]),
        _label("PENGATURAN"),
        _card([
          _item(Icons.settings, "Navigasi Hardware", nav, _showNav),
          _switch(Icons.image, "Tampilkan Background Poster", bgPoster, (v){ setState(()=>bgPoster=v); _save('bg',v); }),
          _switch(Icons.cached, "Gunakan Cache Playback", useCache, (v){ setState(()=>useCache=v); _save('cache',v); }),
          _switch(Icons.screen_rotation, "Tombol Rotasi Manual", rotasi, (v){ setState(()=>rotasi=v); _save('rot',v); }),
          _item(Icons.lock, "Widevine DRM", drm, _showDRM),
          _item(Icons.delete_sweep, "Hapus Semua Cache", "Klik untuk bersihkan", _clearCache),
        ]),
      ]),
    );
  }

  void _showNav() => _dialog("Navigasi", ["Otomatis (Ikuti Hardware)", "Smartphone / Tablet", "Android TV"], nav, (v){ setState(()=>nav=v); _save('nav',v); });
  void _showDRM() => _dialog("Widevine DRM", ["Auto", "Paksa L3"], drm, (v){ setState(()=>drm=v); _save('drm',v); });

  void _dialog(String t, List<String> o, String g, Function(String) s) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: Text(t, style: const TextStyle(color: Colors.white)), 
      backgroundColor: const Color(0xFF161B22),
      content: Column(mainAxisSize: MainAxisSize.min, children: o.map((v) => RadioListTile(
        title: Text(v, style: const TextStyle(fontSize: 14, color: Colors.white)), value: v, groupValue: g,
        onChanged: (x){ s(x!); Navigator.pop(c); }
      )).toList()),
    ));
  }

  Widget _header() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(20)), child: const Row(children: [CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.person, color: Colors.white)), SizedBox(width: 15), Text("User Penggemar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))]));
  Widget _label(String t) => Padding(padding: const EdgeInsets.only(left: 10, bottom: 8), child: Text(t, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)));
  Widget _card(List<Widget> i) => Container(decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(20)), margin: const EdgeInsets.only(bottom: 20), child: Column(children: i));
  Widget _item(IconData i, String t, String s, VoidCallback c) => TVButton(onTap: c, child: ListTile(leading: Icon(i, color: Colors.red), title: Text(t, style: const TextStyle(fontSize: 14, color: Colors.white)), subtitle: Text(s, style: const TextStyle(fontSize: 11, color: Colors.grey)), trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.white)));
  Widget _switch(IconData i, String t, bool v, Function(bool) c) => TVButton(onTap: () => c(!v), child: SwitchListTile(secondary: Icon(i, color: Colors.white70), title: Text(t, style: const TextStyle(fontSize: 14, color: Colors.white)), value: v, onChanged: c, activeColor: Colors.red));
}
