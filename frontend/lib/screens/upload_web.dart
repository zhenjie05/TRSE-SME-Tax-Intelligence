import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart'; // ← FilePicker for PDF support
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../widget/chatbar.dart';

class UploadWeb extends StatefulWidget {
  const UploadWeb({super.key});
  @override
  State<UploadWeb> createState() => _UploadWebState();
}

class _UploadWebState extends State<UploadWeb> {
  XFile? _selectedImage;
  bool _isPdf = false;
  bool _isLoading = false;
  late Future<List<dynamic>?> _recentUploadsFuture;
  static const Color kNavy = Color(0xFF002753);

  @override
  void initState() {
    super.initState();
    _recentUploadsFuture = ApiService.fetchAuditHistory();
  }

  // ── Unified picker for web — JPG, PNG, PDF ────────────────────
  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true, // Required for web to populate bytes
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bool isPdf = file.name.toLowerCase().endsWith('.pdf');
      setState(() {
        _isPdf = isPdf;
        _selectedImage = kIsWeb
            ? XFile.fromData(file.bytes!, name: file.name)
            : XFile(file.path!, name: file.name);
      });
    }
  }

  Future<void> _analyze() async {
    if (_selectedImage == null) return;
    setState(() => _isLoading = true);
    final result = await ApiService.analyzeReceipt(_selectedImage!);
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (result != null) {
      Navigator.pushNamed(context, '/result', arguments: result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to backend engine.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header + ChatBar ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Upload Document',
                        style: GoogleFonts.publicSans(fontSize: 32, fontWeight: FontWeight.bold, color: kNavy)),
                    const SizedBox(height: 8),
                    const Text('Supports JPG, PNG, and PDF invoices for AI compliance analysis.',
                        style: TextStyle(fontSize: 15, color: Colors.grey)),
                  ]),
                  const Expanded(
                    child: Padding(padding: EdgeInsets.only(left: 40), child: ChatBar()),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── LEFT: Upload Canvas ───────────────────────
                Expanded(
                  flex: 5,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    // Drop zone / browse box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(60),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: kNavy.withOpacity(0.1), width: 2),
                      ),
                      child: Column(children: [
                        // Icon changes based on selection state
                        Icon(
                          _isPdf ? Icons.picture_as_pdf : Icons.cloud_upload,
                          color: _isPdf ? Colors.redAccent : kNavy,
                          size: 64,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _selectedImage == null
                              ? 'Select a file from your computer'
                              : _isPdf ? 'PDF Ready for Analysis' : 'Image Ready for Analysis',
                          style: GoogleFonts.publicSans(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('Accepts JPG, PNG, PDF',
                            style: TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 28),
                        ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.folder_open, color: Colors.white),
                          label: Text(
                            _selectedImage == null ? 'BROWSE FILES' : 'CHANGE FILE',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kNavy,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // ── File Preview ──────────────────────────
                    if (_selectedImage != null) ...[
                      Stack(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _isPdf
                              // PDF Preview
                              ? Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: Colors.red.shade50,
                                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    const Icon(Icons.picture_as_pdf, size: 72, color: Colors.redAccent),
                                    const SizedBox(height: 12),
                                    const Text('PDF Document Loaded',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 16)),
                                    const SizedBox(height: 6),
                                    Text(
                                      _selectedImage!.name.length > 45
                                          ? '${_selectedImage!.name.substring(0, 45)}...'
                                          : _selectedImage!.name,
                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  ]),
                                )
                              // Image Preview
                              : Image.network(
                                  _selectedImage!.path,
                                  height: 360,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                ),
                        ),
                        // Close button
                        Positioned(
                          top: 12, right: 12,
                          child: GestureDetector(
                            onTap: () => setState(() { _selectedImage = null; _isPdf = false; }),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // ── Analyse Button ────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _analyze,
                          icon: _isLoading
                              ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Icon(_isPdf ? Icons.picture_as_pdf : Icons.document_scanner, color: Colors.white),
                          label: Text(
                            _isLoading ? 'Analysing...' : 'Analyse Document',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kNavy,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
                const SizedBox(width: 60),

                // ── RIGHT: Info Card + Recent Uploads ─────────
                Expanded(
                  flex: 4,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    // Compliance info card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF002753), Color(0xFF1565C0)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('LHDN 2026 Engine',
                            style: GoogleFonts.publicSans(color: Colors.white70, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text('AI-Powered Pre-Audit',
                            style: GoogleFonts.publicSans(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 16),
                        const Text(
                          'Upload a receipt image or PDF invoice to get an instant compliance verdict with LHDN citations.',
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        // Supported format chips
                        Row(children: [
                          _formatChip('JPG / PNG', Icons.image),
                          const SizedBox(width: 8),
                          _formatChip('PDF', Icons.picture_as_pdf),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 40),

                    // Recent uploads
                    const Text('RECENT UPLOADS',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    FutureBuilder<List<dynamic>?>(
                      future: _recentUploadsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text('No recent uploads.',
                              style: TextStyle(color: Colors.grey));
                        }
                        return Column(
                          children: snapshot.data!.take(4).map((item) {
                            final status = item['status'] ?? '';
                            Color statusColor = status == 'SAFE'
                                ? Colors.green
                                : status == 'REVIEW' ? Colors.orange : Colors.red;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                leading: Icon(Icons.description, color: statusColor),
                                title: Text(item['merchant_name'] ?? 'Unknown',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('RM ${item['total_amount'] ?? '0.00'}'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(status,
                                      style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 12)),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ]),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formatChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}