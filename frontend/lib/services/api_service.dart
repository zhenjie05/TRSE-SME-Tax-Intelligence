import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static Future<Map<String, dynamic>?> analyzeReceipt(XFile imageFile) async {
    try {
      // 1. Point to your local Python server running Uvicorn
      var uri = Uri.parse('http://127.0.0.1:8000/upload');
      
      var request = http.MultipartRequest('POST', uri);

      // 2. Read the image as bytes
      var bytes = await imageFile.readAsBytes();
      
      // We add a fallback name and force the contentType so Python accepts it
      String safeFilename = imageFile.name.isNotEmpty ? imageFile.name : 'receipt.jpg';
      
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        bytes,
        filename: safeFilename,
        contentType: MediaType('image', 'jpeg'), // THIS IS THE MAGIC KEY
      ));

      // 3. Fire the request to Gemini/Supabase
      var response = await request.send();

      // 4. Return the data if successful
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        return json.decode(responseData);
      } else {
        print("Server Rejected Request: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("System Error (Is the backend running?): $e");
      return null;
    }
  }

  static Future<List<dynamic>?> fetchAuditHistory() async {
    try {
      var uri = Uri.parse('http://127.0.0.1:8000/logs');
      var response = await http.get(uri);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        return responseData['data']; // Returns the list of past receipts
      } else {
        print("Failed to fetch history: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("System Error: $e");
      return null;
    }
  }
  
}