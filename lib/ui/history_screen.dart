import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'detail/detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await DatabaseHelper().getHistory();
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  Future<void> _clearHistory() async {
    await DatabaseHelper().clearHistory();
    _loadHistory();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Riwayat dibersihkan")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text("Riwayat Tontonan", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D1117),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
          : _history.isEmpty
              ? const Center(
                  child: Text(
                    "Belum ada riwayat tontonan",
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (ctx, i) {
                    final item = _history[i];
                    return ListTile(
                      leading: Container(
                        width: 50,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: item['drama_poster'] != null && item['drama_poster'].isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(item['drama_poster'], fit: BoxFit.cover),
                              )
                            : const Icon(Icons.movie, color: Colors.grey),
                      ),
                      title: Text(item['drama_title'] ?? 'Drama', style: const TextStyle(color: Colors.white)),
                      subtitle: Text("Episode ${item['episode_number']}", style: const TextStyle(color: Colors.white54)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await DatabaseHelper().deleteHistoryItem(item['id']);
                          _loadHistory();
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => DetailScreen(
                              id: item['drama_id'],
                              source: item['platform'] ?? 'freereels',
                              title: item['drama_title'] ?? 'Drama',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
