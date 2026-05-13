import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class DramaAPI {
  static const String baseUrl = 'https://api-drama.dobda.id';
  static const String apiSecret = '22dfb2b849814054af0491ff2ee3ffe33989313d7d38e97aae659757a4cf8960';
  
  static String _generateSignature(String method, String path, String timestamp) {
    String payload = '$method:$path:$timestamp';
    var hmac = Hmac(sha256, utf8.encode(apiSecret));
    var digest = hmac.convert(utf8.encode(payload));
    return digest.toString();
  }
  
  static Future<Map<String, dynamic>> _request(String method, String path, Map<String, String> queryParams) async {
    String fullPath = path;
    if (queryParams.isNotEmpty) {
      String queryString = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      fullPath = '$path?$queryString';
    }
    
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String signature = _generateSignature(method, fullPath, timestamp);
    
    final response = await http.get(
      Uri.parse('$baseUrl$fullPath'),
      headers: {
        'X-Timestamp': timestamp,
        'X-Signature': signature,
      },
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal: ${response.statusCode}');
    }
  }
  
  static Future<List<dynamic>> getHome(String category, String lang) async {
    try {
      final data = await _request('GET', '/api/v2/home', {'category_p': category, 'lang': lang});
      return data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }
  
  static Future<List<dynamic>> getBanner(String category, String lang) async {
    try {
      final data = await _request('GET', '/api/v2/banner', {'category_p': category, 'lang': lang});
      return data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> getDetail(String category, String id, String lang) async {
    try {
      final data = await _request('GET', '/api/v2/detail', {'category_p': category, 'id': id, 'lang': lang});
      return data['data'] ?? {};
    } catch (e) {
      return {};
    }
  }
  
  static Future<Map<String, dynamic>> getVideo(String category, String id, String chapterId, String lang) async {
    try {
      final data = await _request('GET', '/api/v2/video', {'category_p': category, 'id': id, 'chapterId': chapterId, 'lang': lang});
      return data['data'] ?? {};
    } catch (e) {
      return {};
    }
  }
  
  static Future<List<dynamic>> search(String category, String query, String lang, {int page = 1}) async {
    try {
      final data = await _request('GET', '/api/v2/search', {'category_p': category, 'q': query, 'lang': lang, 'page': page.toString()});
      return data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }
}
