import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color kNavy = Color(0xFF002753);
  late Future<List<dynamic>?> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = ApiService.fetchAuditHistory();
  }

  void _refresh() => setState(() => _historyFuture = ApiService.fetchAuditHistory());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>?>(
      future: _historyFuture,
      builder: (context, snapshot) {
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Audit Trail',
                        style: GoogleFonts.publicSans(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: kNavy)),
                    const SizedBox(height: 4),
                    Text(
                      snapshot.connectionState == ConnectionState.waiting
                          ? 'Loading audit history...'
                          : '${snapshot.data?.length ?? 0} records found — pull to refresh',
                      style: const TextStyle(
                          color: Color(0xFF44617D), fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),

              // ── Loading ─────────────────────────────────────
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )

              // ── Error ───────────────────────────────────────
              else if (snapshot.hasError || snapshot.data == null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      const Icon(Icons.cloud_off,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('Failed to load audit history.',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('Retry')),
                    ]),
                  ),
                )

              // ── Empty ───────────────────────────────────────
              else if (snapshot.data!.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Icon(Icons.receipt_long,
                          size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No receipts scanned yet.',
                          style: TextStyle(color: Colors.grey)),
                    ]),
                  ),
                )

              // ── List ────────────────────────────────────────
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final log = snapshot.data![i];
                        final status = log['status'] ?? 'UNKNOWN';
                        final merchant =
                            log['merchant_name'] ?? 'Unknown Merchant';
                        final amount =
                            (log['total_amount'] ?? 0) as num;
                        final risk = log['risk_score'] ?? 0;

                        Color statusColor = Colors.grey;
                        IconData statusIcon = Icons.help_outline;
                        if (status == 'SAFE') {
                          statusColor = Colors.green;
                          statusIcon = Icons.check_circle;
                        } else if (status == 'REVIEW') {
                          statusColor = Colors.orange;
                          statusIcon = Icons.warning_amber;
                        } else if (status == 'DANGER') {
                          statusColor = Colors.red;
                          statusIcon = Icons.dangerous;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      Colors.black.withOpacity(0.03),
                                  blurRadius: 10)
                            ],
                          ),
                          child: Row(children: [
                            // Icon
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                  color:
                                      statusColor.withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(12)),
                              child: Icon(Icons.receipt_long,
                                  color: statusColor, size: 22),
                            ),
                            const SizedBox(width: 14),
                            // Details
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                Text(merchant,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const SizedBox(height: 3),
                                Text('Risk Score: $risk / 100',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey)),
                              ]),
                            ),
                            // Trailing
                            Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                              Text(
                                'RM ${amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(6)),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                  Icon(statusIcon,
                                      size: 10, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(status,
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor)),
                                ]),
                              ),
                            ]),
                          ]),
                        );
                      },
                      childCount: snapshot.data!.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        );
      },
    );
  }
}