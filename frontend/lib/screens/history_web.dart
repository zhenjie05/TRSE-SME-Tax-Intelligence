import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class HistoryWeb extends StatefulWidget {
  const HistoryWeb({super.key});
  @override
  State<HistoryWeb> createState() => _HistoryWebState();
}

class _HistoryWebState extends State<HistoryWeb> {
  static const Color kNavy = Color(0xFF002753);
  late Future<List<dynamic>?> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = ApiService.fetchAuditHistory();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>?>(
      future: _historyFuture,
      builder: (context, snapshot) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Audit Trail', style: GoogleFonts.publicSans(fontSize: 32, fontWeight: FontWeight.bold, color: kNavy)),
                  const SizedBox(height: 24),
                  
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (!snapshot.hasData || snapshot.data!.isEmpty)
                    const Text('No records found.')
                  else
                    Expanded(
                      // Web Layout: Grid View
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          mainAxisExtent: 140, // Fixed height for cards
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, i) {
                          final log = snapshot.data![i];
                          final status = log['status'] ?? 'UNKNOWN';
                          Color sColor = status == 'SAFE' ? Colors.green : (status == 'REVIEW' ? Colors.orange : Colors.red);
                          
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(Icons.receipt, color: sColor),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: sColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                      child: Text(status, style: TextStyle(color: sColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                    )
                                  ],
                                ),
                                const Spacer(),
                                Text(log['merchant_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Risk: ${log['risk_score']}', style: const TextStyle(color: Colors.grey)),
                                    Text('RM ${log['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}