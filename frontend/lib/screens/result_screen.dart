import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the JSON data passed from the UploadScreen
    final Map<String, dynamic>? data = 
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Fallback if data is null (for testing)
    final safeData = data ?? {
      'status': 'UNKNOWN',
      'risk_score': 0,
      'impact_saved': 0,
      'ai_explanation': 'No data received.',
      'lhdn_reference': 'N/A',
      'action_recommendation': 'N/A'
    };

    final String status = safeData['status'] ?? 'UNKNOWN';
    final double riskScore = (safeData['risk_score'] ?? 0).toDouble();
    final double impactSaved = (safeData['impact_saved'] ?? 0).toDouble();
    
    // Determine colors based on status
    Color cardColor = Colors.grey;
    IconData statusIcon = Icons.help;
    if (status == 'SAFE') {
      cardColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status == 'REVIEW') {
      cardColor = Colors.orange;
      statusIcon = Icons.warning;
    } else if (status == 'DANGER') {
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
                    Text(safeData['ai_explanation'] ?? 'No explanation provided.'),
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
                        Expanded(child: Text(safeData['action_recommendation'] ?? '')),
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
}