import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/platform_checker.dart';
import '../widgets.dart';

class SourceManagerPage extends StatefulWidget {
  const SourceManagerPage({super.key});

  @override
  State<SourceManagerPage> createState() => _SourceManagerPageState();
}

class _SourceManagerPageState extends State<SourceManagerPage> {
  List<SourceItem> _sources = [];
  bool _isChecking = false;
  String _lastCheckTime = "";
  
  final List<Map<String, String>> _allPlatforms = [
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
    {"id": "meloshort", "name": "MeloShort"},
    {"id": "flextv", "name": "FlexTV"},
    {"id": "dramarush", "name": "DramaRush"},
    {"id": "stardusttv", "name": "StardustTV"},
    {"id": "dramanova", "name": "DramaNova"},
    {"id": "fundrama", "name": "FunDrama"},
    {"id": "starshort", "name": "StarShort"},
    {"id": "dramapops", "name": "Dramapops"},
    {"id": "snackshort", "name": "SnackShort"},
    {"id": "reelife", "name": "Reelife"},
    {"id": "dramabite", "name": "DramaBite"},
    {"id": "sodareels", "name": "SodaReels"},
    {"id": "hilitv", "name": "HiliTV"},
  ];

  @override
  void initState() {
    super.initState();
    _loadSources();
    _checkAllStatuses();
  }

  Future<void> _loadSources() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sources = _allPlatforms.map((p) {
        final isActive = prefs.getBool('source_${p['id']}') ?? true;
        return SourceItem(
          id: p['id']!,
          name: p['name']!,
          isActive: isActive,
          status: "unknown",
          statusColor: "⚪",
          statusMessage: "Belum dicek",
        );
      }).toList();
    });
  }

  Future<void> _checkAllStatuses() async {
    setState(() {
      _isChecking = true;
      _lastCheckTime = DateTime.now().toString().substring(11, 16);
    });
    
    for (int i = 0; i < _sources.length; i++) {
      final result = await PlatformChecker.checkStatus(_sources[i].id);
      setState(() {
        _sources[i].status = result['status'];
        _sources[i].statusColor = result['color'];
        _sources[i].statusMessage = result['message'];
        
        // Auto nonaktif jika server down
        if (result['status'] == 'down' && _sources[i].isActive) {
          _sources[i].isActive = false;
          _showNotification("${_sources[i].name} server down, otomatis dinonaktifkan");
        }
      });
    }
    
    setState(() => _isChecking = false);
    _saveSources();
    _showNotification("Pengecekan selesai");
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _saveSources() async {
    final prefs = await SharedPreferences.getInstance();
    for (var source in _sources) {
      await prefs.setBool('source_${source.id}', source.isActive);
    }
  }

  Future<void> _checkSingleStatus(int index) async {
    setState(() {
      _sources[index].status = "checking";
      _sources[index].statusColor = "🟡";
      _sources[index].statusMessage = "Memeriksa...";
    });
    
    final result = await PlatformChecker.checkStatus(_sources[index].id);
    setState(() {
      _sources[index].status = result['status'];
      _sources[index].statusColor = result['color'];
      _sources[index].statusMessage = result['message'];
      
      if (result['status'] == 'down' && _sources[index].isActive) {
        _sources[index].isActive = false;
        _showNotification("${_sources[index].name} server down, dinonaktifkan");
      }
    });
    await _saveSources();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _sources.where((s) => s.isActive).length;
    final downCount = _sources.where((s) => s.status == 'down').length;
    
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
        actions: [
          if (_isChecking)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5))),
        ],
      ),
      body: Column(
        children: [
          // Header info
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Total Platform: ${_sources.length}", style: const TextStyle(color: Colors.white)),
                  Text("Aktif: $activeCount | Down: $downCount", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  if (_lastCheckTime.isNotEmpty)
                    Text("Terakhir cek: $_lastCheckTime", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                ]),
                ElevatedButton.icon(
                  onPressed: _isChecking ? null : _checkAllStatuses,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text("Cek Semua"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    minimumSize: const Size(100, 36),
                  ),
                ),
              ],
            ),
          ),
          
          // List platform
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
                  child: ListTile(
                    leading: Text(source.statusColor, style: const TextStyle(fontSize: 20)),
                    title: Text(
                      source.name,
                      style: TextStyle(
                        color: source.isActive ? Colors.white : Colors.white54,
                        fontWeight: source.isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      source.statusMessage,
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 18, color: Colors.white54),
                          onPressed: () => _checkSingleStatus(index),
                        ),
                        Switch(
                          value: source.isActive,
                          onChanged: (value) {
                            setState(() => source.isActive = value);
                            _saveSources();
                            _showNotification("${source.name} ${value ? 'diaktifkan' : 'dinonaktifkan'}");
                          },
                          activeColor: const Color(0xFF4F46E5),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Keterangan warna
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text("📝 Keterangan Indikator:", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _legendItem("🟢", "Normal", "Server aktif & cepat"),
                  _legendItem("🟡", "Lambat", "Response >3 detik"),
                  _legendItem("🔴", "Down", "Server error/tidak merespon (otomatis nonaktif)"),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String icon, String title, String desc) {
    return Column(children: [
      Text(icon, style: const TextStyle(fontSize: 20)),
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 11)),
      Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 9), textAlign: TextAlign.center),
    ]);
  }
}

class SourceItem {
  final String id;
  final String name;
  bool isActive;
  String status;
  String statusColor;
  String statusMessage;
  
  SourceItem({
    required this.id,
    required this.name,
    required this.isActive,
    required this.status,
    required this.statusColor,
    required this.statusMessage,
  });
}
