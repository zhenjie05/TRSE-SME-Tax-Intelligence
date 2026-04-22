import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the JSON data passed from the UploadScreen
    final Map<String, dynamic>? data = 
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Fallback if data is null (prevents crashes)
    final safeData = data ?? {
      'status': 'UNKNOWN',
      'risk_score': 0,
      'impact_saved': 0.0,
      'ai_explanation': 'No data received from backend.',
      'lhdn_reference': 'N/A',
      'action_recommendation': 'N/A',
      'extracted_data': {
        'merchant_name': 'Unknown',
        'tin': 'N/A',
        'total_amount': 0.0,
        'date': 'N/A'
      }
    };

    final String status = safeData['status'] ?? 'UNKNOWN';
    // Use num to safely handle both int and double from JSON
    final num riskScore = safeData['risk_score'] ?? 0;
    final num impactSaved = safeData['impact_saved'] ?? 0;
    
    // Extract the nested AI data
    final extractedData = safeData['extracted_data'] ?? {};
    final String merchantName = extractedData['merchant_name']?.toString() ?? 'N/A';
    final String tin = extractedData['tin']?.toString() ?? 'N/A';
    final num totalAmount = extractedData['total_amount'] ?? 0;
    final String date = extractedData['date']?.toString() ?? 'N/A';
    
    // Determine colors based on status
    Color cardColor = Colors.grey;
    IconData statusIcon = Icons.help;
    if (status == 'SAFE') {
      cardColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status == 'REVIEW') {
      cardColor = Colors.orange;
      statusIcon = Icons.warning;
    } else if (status == 'DANGER' || status == 'INVALID') {
      cardColor = Colors.red;
      statusIcon = Icons.error;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Compliance Verdict')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.1),
                border: Border.all(color: cardColor, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(statusIcon, size: 60, color: cardColor),
                  const SizedBox(height: 12),
                  Text(
                    status,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cardColor),
                  ),
                  Text(
                    'Audit Risk Score: ${riskScore.toInt()}/100',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // NEW: Extracted Data Section (Shows off the AI Vision)
            const Text('Extracted Receipt Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDataRow('Merchant:', merchantName),
                    const Divider(),
                    _buildDataRow('Tax ID (TIN):', tin),
                    const Divider(),
                    _buildDataRow('Date:', date),
                    const Divider(),
                    _buildDataRow('Total Amount:', 'RM ${totalAmount.toStringAsFixed(2)}', isBold: true),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // AI Explanation Section
            const Text('AI Analysis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LHDN Reference: ${safeData['lhdn_reference']}', 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    const SizedBox(height: 8),
                    Text(safeData['ai_explanation']?.toString() ?? 'No explanation provided.'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Actionable Insight Section
            const Text('Actionable Recommendation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              color: Colors.blue[50],
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(child: Text(safeData['action_recommendation']?.toString() ?? '')),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'Potential Capital Protected: RM ${impactSaved.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to keep the extracted data rows clean
  Widget _buildDataRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        Flexible(
          child: Text(
            value, 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}