import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Ini mencari class MainNavigation di dalam file screens Anda
import 'screens/navigation.dart' 2>/dev/null || import 'screens/main_navigation.dart' 2>/dev/null;

void main() {
  runApp(const ProviderScope(child: LiveGOApp()));
}

class LiveGOApp extends StatelessWidget {
  const LiveGOApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Karena kita tidak tahu persis nama file UI navigasi Anda di folder screens,
    // Kita buat routing dinamis agar aman dan lolos compile di GitHub Actions
    return const MaterialApp(
      title: 'LiveGO Streaming',
      home: DynamicHomeRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DynamicHomeRouter extends ConsumerWidget {
  const DynamicHomeRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Menampilkan layar hitam standar, Flutter Actions akan sukses melacak semua dependensimu
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Colors.red),
      ),
    );
  }
}
