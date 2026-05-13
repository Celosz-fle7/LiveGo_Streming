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
  
  // 6 platform utama
  final List<Map<String, String>> _primaryPlatforms = [
    {"id": "melolo", "name": "Melolo"},
    {"id": "freereels", "name": "FreeReels"},
    {"id": "shortmax", "name": "ShortMax"},
    {"id": "dramawave", "name": "DramaWave"},
    {"id": "netshort", "name": "NetShort"},
    {"id": "goodshort", "name": "GoodShort"},
  ];
  
  // 18 platform cadangan
  final List<Map<String, String>> _backupPlatforms = [
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
    // Jalankan failover di background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAllStatuses();
    });
  }

  Future<void> _loadSources() async {
    final prefs = await SharedPreferences.getInstance();
    final List<SourceItem> temp = [];
    
    // Primary: default aktif
    for (var p in _primaryPlatforms) {
      final isActive = prefs.getBool('source_${p['id']}') ?? true;
      temp.add(SourceItem(
        id: p['id']!,
        name: p['name']!,
        isActive: isActive,
        status: "unknown",
        statusColor: "⚪",
        statusMessage: "Belum dicek",
        isPrimary: true,
      ));
    }
    
    // Backup: default nonaktif
    for (var p in _backupPlatforms) {
      final isActive = prefs.getBool('source_${p['id']}') ?? false;
      temp.add(SourceItem(
        id: p['id']!,
        name: p['name']!,
        isActive: isActive,
        status: "unknown",
        statusColor: "⚪",
        statusMessage: "Belum dicek",
        isPrimary: false,
      ));
    }
    
    setState(() => _sources = temp);
  }

  Future<void> _checkAllStatuses() async {
    setState(() {
      _isChecking = true;
      _lastCheckTime = DateTime.now().toString().substring(11, 16);
    });
    
    // 1. Cek status semua platform
    for (int i = 0; i < _sources.length; i++) {
      final result = await PlatformChecker.checkStatus(_sources[i].id);
      setState(() {
        _sources[i].status = result['status'];
        _sources[i].statusColor = result['color'];
        _sources[i].statusMessage = result['message'];
      });
    }
    
    // 2. Jalankan failover (auto ganti platform mati dengan cadangan)
    await PlatformChecker.checkAllAndFailover();
    
    // 3. Reload sources untuk refleksi perubahan
    await _loadSources();
    
    setState(() => _isChecking = false);
    _showNotification("Pengecekan selesai, failover otomatis telah dijalankan");
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
    _showNotification("Pengaturan sumber disimpan");
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
    final primaryCount = _sources.where((s) => s.isPrimary && s.isActive).length;
    final backupActiveCount = _sources.where((s) => !s.isPrimary && s.isActive).length;
    
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
                  Text("Platform Utama Aktif: $primaryCount/6", style: const TextStyle(color: Colors.white)),
                  Text("Platform Cadangan Aktif: $backupActiveCount", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  if (_lastCheckTime.isNotEmpty)
                    Text("Terakhir cek: $_lastCheckTime", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                ]),
                ElevatedButton.icon(
                  onPressed: _isChecking ? null : _checkAllStatuses,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text("Cek & Failover"),
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
                    color: source.isPrimary ? const Color(0xFF1F2937) : const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(12),
                    border: source.isPrimary ? null : Border.all(color: Colors.white12, width: 0.5),
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
                        if (!source.isPrimary && source.isActive)
                          const Icon(Icons.star, color: Color(0xFF06B6D4), size: 16),
                        const SizedBox(width: 8),
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
          
          // Keterangan
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text("📝 Keterangan:", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  children: [
                    _legendItem("🟢", "Normal", "Server aktif"),
                    _legendItem("🟡", "Lambat", "Response >3 detik"),
                    _legendItem("🔴", "Down", "Auto nonaktif + failover"),
                    _legendItem("⭐", "Cadangan", "Aktif karena failover"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String icon, String title, String desc) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 11)),
            Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 9)),
          ],
        ),
      ],
    );
  }
}

class SourceItem {
  final String id;
  final String name;
  bool isActive;
  String status;
  String statusColor;
  String statusMessage;
  final bool isPrimary;
  
  SourceItem({
    required this.id,
    required this.name,
    required this.isActive,
    required this.status,
    required this.statusColor,
    required this.statusMessage,
    required this.isPrimary,
  });
}
