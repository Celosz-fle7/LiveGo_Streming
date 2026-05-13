import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class PlatformChecker {
  static const String secret = "22dfb2b849814054af0491ff2ee3ffe33989313d7d38e97aae659757a4cf8960";
  
  static Future<Map<String, dynamic>> checkStatus(String platform) async {
    String ts = DateTime.now().millisecondsSinceEpoch.toString();
    String path = "/api/v2/home?category_p=$platform&lang=id";
    String payload = "GET:$path:$ts";
    
    var key = utf8.encode(secret);
    var bytes = utf8.encode(payload);
    var hmac = Hmac(sha256, key);
    var sig = hmac.convert(bytes);
    
    Stopwatch stopwatch = Stopwatch()..start();
    
    try {
      final response = await http.get(
        Uri.parse("https://api-drama.dobda.id$path"),
        headers: {
          "X-Timestamp": ts,
          "X-Signature": sig.toString(),
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 10));
      
      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;
      
      if (response.statusCode == 200) {
        if (latency > 3000) {
          return {"status": "slow", "color": "🟡", "message": "Lambat (${latency}ms)", "active": true};
        }
        return {"status": "active", "color": "🟢", "message": "Normal (${latency}ms)", "active": true};
      } else {
        return {"status": "down", "color": "🔴", "message": "Server Error", "active": false};
      }
    } catch (e) {
      stopwatch.stop();
      return {"status": "down", "color": "🔴", "message": "Timeout/Tidak merespon", "active": false};
    }
  }
}
