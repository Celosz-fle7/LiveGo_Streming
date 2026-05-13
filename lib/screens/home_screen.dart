import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livego_streaming/providers/app_providers.dart'; // Jalur absolut, bebas error titik

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dramasAsync = ref.watch(dramasProvider);
    final bool isTV = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFF090D1A),
      appBar: AppBar(
        title: Text(isTV ? 'LiveGO [TV Mode]' : 'LiveGO [HP Mode]', 
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF090D1A),
      ),
      body: dramasAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('Tidak ada drama aktif di platform ini.', 
                  style: TextStyle(color: Colors.white70)),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTV ? 6 : 3,
              childAspectRatio: 0.7,
              crossAxisSpacing: 8, mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final item = list[index];
              return Card(
                color: const Color(0xFF1E293B),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Image.network(
                        item['cover'] ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(Icons.movie, size: 40, color: Colors.white24),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(item['title'] ?? 'No Title', maxLines: 1, 
                          style: const TextStyle(color: Colors.white, fontSize: 11), 
                          overflow: TextOverflow.ellipsis),
                    )
                  ],
                ),
              );
            },
          );
        },
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error Panggilan API:\n$err', 
                style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
      ),
    );
  }
}
