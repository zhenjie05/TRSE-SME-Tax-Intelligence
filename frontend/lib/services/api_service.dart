import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Change to your Cloud Run URL when deployed
  static const String _base = 'http://10.0.2.2:8000';

  static Future<Map<String, dynamic>?> analyzeReceipt(File image) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_base/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      return jsonDecode(body);
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> chat(String message, String sessionId) async {
    final res = await http.post(Uri.parse('$_base/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message, 'session_id': sessionId}));
    return jsonDecode(res.body);
  }
}