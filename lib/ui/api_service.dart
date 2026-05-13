import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../services/cache_service.dart';

class ApiService {
  static const String baseUrl = "https://api-drama.dobda.id";
  static const String secret = "22dfb2b849814054af0491ff2ee3ffe33989313d7d38e97aae659757a4cf8960";
  static final CacheService _cache = CacheService();
  static int _remainingRequests = -1;

  static Future<void> init() async {
    await _cache.autoCleanIfNeeded();
    await _getRemainingRequests();
  }

  static Future<void> _getRemainingRequests() async {
    try {
      String ts = DateTime.now().millisecondsSinceEpoch.toString();
      String path = "/api/v2/key/status";
      String payload = "GET:$path:$ts";
      
      var key = utf8.encode(secret);
      var bytes = utf8.encode(payload);
      var hmac = Hmac(sha256, key);
      var sig = hmac.convert(bytes);
      
      final response = await http.get(
        Uri.parse(baseUrl + path),
        headers: {
          "X-Timestamp": ts,
          "X-Signature": sig.toString(),
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // TODO: parsing limit dari response
      }
    } catch (e) { print("Error getting limit: $e"); }
  }

  static Future<dynamic> get(String path, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _cache.get(path);
      if (cached != null) return cached;
    }
    
    String ts = DateTime.now().millisecondsSinceEpoch.toString();
    String payload = "GET:$path:$ts";
    
    var key = utf8.encode(secret);
    var bytes = utf8.encode(payload);
    var hmac = Hmac(sha256, key);
    var sig = hmac.convert(bytes);

    try {
      final response = await http.get(
        Uri.parse(baseUrl + path),
        headers: {
          "X-Timestamp": ts,
          "X-Signature": sig.toString(),
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        int ttlMinutes = 30;
        if (path.contains('/search')) ttlMinutes = 30;
        else if (path.contains('/discover')) ttlMinutes = 60;
        else if (path.contains('/home')) ttlMinutes = 15;
        else if (path.contains('/detail')) ttlMinutes = 60;
        else if (path.contains('/banner')) ttlMinutes = 60;
        
        await _cache.set(path, data, ttlMinutes: ttlMinutes);
        return data;
      }
    } catch (e) { print("API Error: $e"); }
    return null;
  }
}
