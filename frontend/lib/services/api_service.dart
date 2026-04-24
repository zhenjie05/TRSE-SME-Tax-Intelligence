import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String _base = 'http://127.0.0.1:8000';
  static const bool useMockData = true; // FLIP THIS TO FALSE WHEN BACKEND IS READY

  static Future<Map<String, dynamic>?> analyzeReceipt(XFile imageFile) async {
    if(useMockData) {
      await Future.delayed(const Duration(seconds: 2));
      return {
        "status": "DANGER",
        "risk_score": 92,
        "confidence_level": 0.95,
        "extracted_data": {
          "merchant_name": "Mega Tech Supplies Sdn Bhd",
          "tin": "NOT_FOUND",
          "total_amount": 14500.00,
          "tax_amount": 870.00,
          "date": "2026-04-20",
          "currency": "MYR"
        },
        "ai_explanation": "This invoice exceeds the RM10,000 threshold but lacks a valid Tax Identification Number (TIN). E-Invoicing is strictly mandatory for transactions of this size under the 2026 guidelines.",
        "lhdn_reference": "LHDN E-Invoice Guideline v3.0, Section 4.1 (Mandatory Issuance)",
        "action_recommendation": "Do NOT process payment. Request a formal LHDN-validated e-Invoice from the supplier immediately.",
        "impact_saved": 3480.00
      };
    } else {
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
  } 

  static Future<List<dynamic>?> fetchAuditHistory() async {
    if(useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return [
        {
          "status": "DANGER",
          "merchant_name": "Tech Corp Server Hosting",
          "risk_score": 88,
          "total_amount": 12500.00
        },
        {
          "status": "SAFE",
          "merchant_name": "Office Supplies Co",
          "risk_score": 12,
          "total_amount": 450.00
        },
        {
          "status": "REVIEW",
          "merchant_name": "Client Lunch - Ali Cafe",
          "risk_score": 55,
          "total_amount": 120.50
        }
      ];
    } else {
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

  // Dynamic Tax Calculation Endpoint
  static Future<double> calculateTaxes(double annualIncome) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      // Basic mock Malaysian tax bracket calculation
      if (annualIncome <= 35000) return 0;
      if (annualIncome <= 100000) return annualIncome * 0.11;
      return annualIncome * 0.24; 
    } else {
      // Future backend connection
      // var response = await http.post('$_base/calculate_tax', body: {'income': annualIncome});
      return 0.0;
    }
  }

  // Dynamic Tax Tips Endpoint
  static Future<List<String>> getDashboardTips() async {
    if (useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return [
        "E-Invoicing becomes mandatory for all taxpayers by July 2026.",
        "Ensure all capital expenditures above RM10,000 have verified TINs.",
        "Consider consolidating monthly utility bills under the e-Invoice exemption rule."
      ];
    } else {
      // var response = await http.get('$_base/tips');
      return [];
    }
  }

  // NEW: Chat Endpoint
  static Future<String> sendChatMessage(String message, Map<String, dynamic>? contextData) async {
    if (useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock response generation based on whether context was provided
      if (contextData != null && contextData.isNotEmpty) {
        final status = contextData['status'] ?? 'unknown';
        return "I can see you are asking about your $status receipt. How can I help clarify the LHDN rules regarding this specific transaction?";
      } else {
        return "I am the TSRE AI Assistant. I can help answer questions about LHDN 2026 E-Invoicing rules and compliance. What do you need help with?";
      }
    } else {
      try {
        var response = await http.post(
          Uri.parse('$_base/chat'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'message': message,
            'context': contextData, // Pass the analysis result as context
          }),
        );
        if (response.statusCode == 200) {
          return json.decode(response.body)['response'];
        }
        return "Sorry, I couldn't reach the AI engine.";
      } catch (e) {
        return "Connection error. Please try again.";
      }
    }
  }
}

