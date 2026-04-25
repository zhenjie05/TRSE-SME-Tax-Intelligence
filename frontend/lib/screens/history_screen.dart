import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<dynamic>?> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = ApiService.fetchAuditHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Trail History')),
      body: FutureBuilder<List<dynamic>?>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Failed to load audit history.'));
          } else if (snapshot.data!.isEmpty) {
            return const Center(child: Text('No receipts scanned yet.'));
          }

          final logs = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final String status = log['status'] ?? 'UNKNOWN';
              final String merchant = log['merchant_name'] ?? 'Unknown Merchant';
              // Safely handle amounts that might be saved as strings or numbers
              final amountStr = log['total_amount']?.toString() ?? '0.00';
              
              Color statusColor = Colors.grey;
              if (status == 'SAFE') statusColor = Colors.green;
              if (status == 'REVIEW') statusColor = Colors.orange;
              if (status == 'DANGER') statusColor = Colors.red;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.2),
                    child: Icon(Icons.receipt, color: statusColor),
                  ),
                  title: Text(merchant, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Risk Score: ${log['risk_score']}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('RM $amountStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}