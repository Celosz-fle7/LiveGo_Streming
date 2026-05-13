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
