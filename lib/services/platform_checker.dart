import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PlatformChecker {
  static const String secret = "22dfb2b849814054af0491ff2ee3ffe33989313d7d38e97aae659757a4cf8960";
  
  static const List<String> primaryPlatforms = [
    "melolo", "freereels", "shortmax", "dramawave", "netshort", "goodshort"
  ];
  
  static const List<String> backupPlatforms = [
    "moviebox", "anichin", "animelovers", "rapidtv", "reelshort", "meloshort",
    "flextv", "dramarush", "stardusttv", "dramanova", "fundrama", "starshort",
    "dramapops", "snackshort", "reelife", "dramabite", "sodareels", "hilitv"
  ];

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

  static Future<void> checkAllAndFailover() async {
    final prefs = await SharedPreferences.getInstance();
    
    Map<String, bool> statusMap = {};
    for (var p in primaryPlatforms) {
      final result = await checkStatus(p);
      statusMap[p] = (result['status'] == 'active' || result['status'] == 'slow');
      print("$p: ${result['status']}");
    }
    for (var p in backupPlatforms) {
      final result = await checkStatus(p);
      statusMap[p] = (result['status'] == 'active' || result['status'] == 'slow');
      print("$p: ${result['status']}");
    }
    
    List<String> currentActive = [];
    for (var p in primaryPlatforms) {
      final isActive = prefs.getBool('source_$p') ?? true;
      if (isActive) currentActive.add(p);
    }
    
    bool changed = false;
    for (int i = 0; i < primaryPlatforms.length; i++) {
      final primary = primaryPlatforms[i];
      final isActive = prefs.getBool('source_$primary') ?? true;
      final isStatusGood = statusMap[primary] == true;
      
      if (isActive && !isStatusGood) {
        String? replacement;
        for (var backup in backupPlatforms) {
          final isBackupGood = statusMap[backup] == true;
          final isBackupActive = prefs.getBool('source_$backup') ?? false;
          if (isBackupGood && !isBackupActive) {
            replacement = backup;
            break;
          }
        }
        
        if (replacement != null) {
          await prefs.setBool('source_$primary', false);
          await prefs.setBool('source_$replacement', true);
          changed = true;
          print("FAILOVER: $primary (mati) diganti dengan $replacement");
        } else {
          await prefs.setBool('source_$primary', false);
          changed = true;
          print("FAILOVER: $primary (mati) dinonaktifkan, tidak ada cadangan");
        }
      }
    }
    
    if (changed) {
      print("Failover selesai, pengaturan platform berubah");
    }
  }
}
