import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://api-drama.dobda.id";
  static const String secret = "22dfb2b849814054af0491ff2ee3ffe33989313d7d38e97aae659757a4cf8960";

  static final Map<String, _CachedResponse> _cache = {};
  static final Map<String, Future<dynamic>> _pendingRequests = {};

  static Future<void> init() async {}

  static Future<dynamic> get(String path, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cache.containsKey(path)) {
      final cached = _cache[path]!;
      if (DateTime.now().difference(cached.timestamp).inMinutes < 15) {
        return cached.data;
      } else {
        _cache.remove(path);
      }
    }

    if (_pendingRequests.containsKey(path)) {
      return _pendingRequests[path];
    }

    final future = _fetch(path);
    _pendingRequests[path] = future;
    try {
      return await future;
    } finally {
      _pendingRequests.remove(path);
    }
  }

  static Future<dynamic> _fetch(String path) async {
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
        _cache[path] = _CachedResponse(data, DateTime.now());
        return data;
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}

class _CachedResponse {
  final dynamic data;
  final DateTime timestamp;
  _CachedResponse(this.data, this.timestamp);
}
