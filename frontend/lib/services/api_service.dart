import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String _base = 'http://127.0.0.1:8000';
  static const bool useMockData = false; // FLIP THIS TO FALSE WHEN BACKEND IS READY

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
        
        // ADDED: Check if it's a PDF based on the file extension
        bool isPdf = imageFile.name.toLowerCase().endsWith('.pdf');
        
        request.files.add(http.MultipartFile.fromBytes(
          'file', bytes,
          filename: imageFile.name.isNotEmpty ? imageFile.name : (isPdf ? 'document.pdf' : 'receipt.jpg'),
          // ADDED: Dynamically assign the correct content type!
          contentType: MediaType(isPdf ? 'application' : 'image', isPdf ? 'pdf' : 'jpeg'),
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
      // Keep this for offline testing, but updated to progressive logic
      if (annualIncome <= 5000) return 0;
      if (annualIncome <= 20000) return (annualIncome - 5000) * 0.01;
      if (annualIncome <= 35000) return 150 + (annualIncome - 20000) * 0.03;
      return 600 + (annualIncome - 35000) * 0.06; // Simplification for mock
    } else {
      try {
        // FIXED: Calling the correct backend route with parameters
        var response = await http.get(Uri.parse('$_base/calculate-tax?income=$annualIncome'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return (data['taxes_to_pay'] as num).toDouble();
        }
        return 0.0;
      } catch (e) {
        print("Tax calculation error: $e");
        return 0.0;
      }
    }
  }

  // Dynamic Tax Tips Endpoint
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
      try {
        var response = await http.get(Uri.parse('$_base/tips'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          // Convert the dynamic list to a List<String>
          return List<String>.from(data['tips']); 
        }
        return ["Keep track of your receipts for LHDN compliance."]; // Fallback
      } catch (e) {
        print("Error fetching tips: $e");
        return ["Unable to load AI recommendations at this time."];
      }
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
          Uri.parse('$_base/ai-chat'), // FIXED: Added 'ai-' to match backend
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'user_query': message, // FIXED: Changed 'message' to 'user_query'
            // We removed 'context' from the body because your Python backend 
            // is designed to fetch the context directly from the Supabase database!
          }),
        );
        if (response.statusCode == 200) {
          return json.decode(response.body)['reply']; // FIXED: Changed 'response' to 'reply'
        }
        return "Sorry, I couldn't reach the AI engine. Error: ${response.statusCode}";
      } catch (e) {
        return "Connection error. Please try again. Error: $e";
      }
    }
  }
}
