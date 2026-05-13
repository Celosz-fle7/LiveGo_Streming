import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets.dart';

class SourceManagerPage extends StatefulWidget {
  const SourceManagerPage({super.key});

  @override
  State<SourceManagerPage> createState() => _SourceManagerPageState();
}

class _SourceManagerPageState extends State<SourceManagerPage> {
  List<SourceItem> _sources = [];
  
  final List<Map<String, String>> _defaultSources = [
    {"id": "melolo", "name": "Melolo"},
    {"id": "freereels", "name": "FreeReels"},
    {"id": "shortmax", "name": "ShortMax"},
    {"id": "dramawave", "name": "DramaWave"},
    {"id": "netshort", "name": "NetShort"},
    {"id": "goodshort", "name": "GoodShort"},
    {"id": "moviebox", "name": "Moviebox"},
    {"id": "anichin", "name": "Anichin"},
    {"id": "animelovers", "name": "Animelovers"},
    {"id": "rapidtv", "name": "RapidTV"},
    {"id": "reelshort", "name": "ReelShort"},
  ];

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  Future<void> _loadSources() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sources = _defaultSources.map((s) {
        final isActive = prefs.getBool('source_${s['id']}') ?? true;
        return SourceItem(
          id: s['id']!,
          name: s['name']!,
          isActive: isActive,
        );
      }).toList();
    });
  }

  Future<void> _saveSources() async {
    final prefs = await SharedPreferences.getInstance();
    for (var source in _sources) {
      await prefs.setBool('source_${source.id}', source.isActive);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengaturan sumber disimpan'), duration: Duration(seconds: 1)),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text("Kelola Sumber Data", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Aktifkan platform yang ingin ditampilkan di beranda",
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _sources.length,
              itemBuilder: (context, index) {
                final source = _sources[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      source.name,
                      style: TextStyle(
                        color: source.isActive ? Colors.white : Colors.white54,
                        fontWeight: source.isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    value: source.isActive,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (value) {
                      setState(() {
                        source.isActive = value ?? false;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _saveSources,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: const Text("Simpan Pengaturan", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class SourceItem {
  final String id;
  final String name;
  bool isActive;
  
  SourceItem({required this.id, required this.name, required this.isActive});
}
