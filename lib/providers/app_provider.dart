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
