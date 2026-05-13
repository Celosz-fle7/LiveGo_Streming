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

  try {
    final data = await ApiService.request(path, params);
    
    if (data != null && data['success'] == true && data['data'] != null) {
      var rawData = data['data'];
      
      // DEEP PARSER: Membongkar lapisan JSON server secara otomatis sesuai spesifikasi backend
      if (rawData is List) {
        return rawData;
      } else if (rawData is Map) {
        if (rawData.containsKey('list') && rawData['list'] is List) {
          return rawData['list'] as List<dynamic>;
        } else if (rawData.containsKey('dramas') && rawData['dramas'] is List) {
          return rawData['dramas'] as List<dynamic>;
        } else if (rawData.containsKey('data') && rawData['data'] is List) {
          return rawData['data'] as List<dynamic>;
        }
        
        // Antisipasi jika data dibungkus dalam struktur objek map beranda bertingkat
        for (var value in rawData.values) {
          if (value is List) {
            return value;
          } else if (value is Map && value.containsKey('list') && value['list'] is List) {
            return value['list'] as List<dynamic>;
          }
        }
      }
    }
    return [];
  } catch (e) {
    throw Exception("Gagal memproses struktur JSON drama: $e");
  }
});
