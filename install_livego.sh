#!/bin/bash

echo "🏗️ 1. Membuat folder Flat Architecture di direktori baru..."
mkdir -p lib/services lib/providers lib/screens .github/workflows

# =========================================================================
# CONFIG 1: PUBSPEC.YAML
# =========================================================================
echo "📦 Menulis file pubspec.yaml..."
cat << 'INNER_EOF' > pubspec.yaml
name: livego_streaming
description: "Aplikasi Streaming Dracin Flat Architecture"
publish_to: 'none'
version: 1.0.0+1
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  http: ^1.2.1
  crypto: ^3.0.3
flutter:
  uses-material-design: true
INNER_EOF

# =========================================================================
# CONFIG 2: API ENGINE METHOD:PATH:TIMESTAMP
# =========================================================================
echo "🔐 Menulis file lib/services/api_service.dart..."
cat << 'INNER_EOF' > lib/services/api_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'dobda.id';
  static const String secret = "22dfb2b849814054af0491ff2ee3ffe33989313d7d38e97aae659757a4cf8960";

  static Future<dynamic> request(String path, Map<String, String> params) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final uri = Uri.parse(baseUrl + path).replace(queryParameters: params);
      
      // FORMULA SIGNATURE POSTMAN: METHOD:PATH:TIMESTAMP
      final String payload = "GET:$path:$timestamp";
      
      final key = utf8.encode(secret);
      final bytes = utf8.encode(payload);
      final hmacSha256 = Hmac(sha256, key);
      final String signature = hmacSha256.convert(bytes).toString();
      
      final response = await http.get(
        uri,
        headers: {
          "X-Timestamp": timestamp,
          "X-Signature": signature,
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Server Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      throw Exception("Koneksi Macet: $e");
    }
  }
}
INNER_EOF

# =========================================================================
# CONFIG 3: STATE PROVIDER TARGET: FREEREELS
# =========================================================================
echo "🧠 Menulis file lib/providers/app_provider.dart..."
cat << 'INNER_EOF' > lib/providers/app_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final platformProvider = StateProvider<String>((ref) => "freereels");
final categoryProvider = StateProvider<String>((ref) => "Reelshort Home");

final dramasProvider = FutureProvider<List<dynamic>>((ref) async {
  final plat = ref.watch(platformProvider);
  final cat = ref.watch(categoryProvider);
  
  String path = "/api/v2/home";
  final Map<String, String> params = {
    "category_p": plat,
    "lang": "id"
  };

  if (cat == "Dubbing") {
    path = "/api/v2/search";
    params["q"] = "sulih suara";
  } else if (cat == "Populer") {
    path = "/api/v2/discover";
    params["page"] = "1";
  }

  final data = await ApiService.request(path, params);
  
  if (data != null && data['success'] == true && data['data'] != null) {
    var rawData = data['data'];
    if (rawData is Map && rawData.containsKey('list')) {
      return rawData['list'] as List<dynamic>;
    } else if (rawData is List) {
      return rawData;
    }
  }
  return [];
});
INNER_EOF

# =========================================================================
# CONFIG 4: HOME SCREEN FLAT LAYOUT
# =========================================================================
echo "🎨 Menulis file lib/screens/home_screen.dart..."
cat << 'INNER_EOF' > lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';

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
