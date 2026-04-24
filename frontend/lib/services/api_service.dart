import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String _base = 'http://127.0.0.1:8000';

  static Future<Map<String, dynamic>?> analyzeReceipt(XFile imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_base/upload'));
      var bytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file', bytes,
        filename: imageFile.name.isNotEmpty ? imageFile.name : 'receipt.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
      var response = await request.send();
      if (response.statusCode == 200) {
        var body = await response.stream.bytesToString();
        return json.decode(body);
      }
      return null;
    } catch (e) {
      print("API Error: $e");
      return null;
    }
  }

  static Future<List<dynamic>?> fetchAuditHistory() async {
    try {
      var response = await http.get(Uri.parse('$_base/logs'));
      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}