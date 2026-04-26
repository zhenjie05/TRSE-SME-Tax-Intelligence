import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart'; // ← ADD THIS
import 'dart:io';
import '../services/api_service.dart';
import '../widget/chatbar.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  XFile? _selectedImage;
  bool _isPdf = false; // ← Track if selected file is PDF
  bool _isLoading = false;
  late Future<List<dynamic>?> _recentUploadsFuture;

  static const Color kNavy = Color(0xFF002753);
  static const Color kNavyLight = Color(0xFF44617D);

  @override
  void initState() {
    super.initState();
    _recentUploadsFuture = ApiService.fetchAuditHistory();
  }

  // ── Camera (images only, not PDF) ─────────────────────────────
  Future<void> _pickFromCamera() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera is not supported on desktop.')));
      return;
    }
    final picked = await ImagePicker().pickImage(
        source: ImageSource.camera, imageQuality: 85);
    if (picked != null) {
      setState(() { _selectedImage = picked; _isPdf = false; });
    }
  }

  // ── File picker — accepts JPG, PNG, PDF ───────────────────────
  Future<void> _pickFromFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true, // Required for web & PDF bytes
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bool isPdf = file.name.toLowerCase().endsWith('.pdf');

      setState(() {
        _isPdf = isPdf;
        if (kIsWeb) {
          _selectedImage = XFile.fromData(file.bytes!, name: file.name);
        } else {
          _selectedImage = XFile(file.path!, name: file.name);
        }
      });
    }
  }

  // ── Analyse ───────────────────────────────────────────────────
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
        const SnackBar(
          content: Text('Failed to connect to backend engine.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          const ChatBar(),
          const SizedBox(height: 16),
          _buildUploadCanvas(),
          const SizedBox(height: 14),
          _buildSecurityBanner(),
          if (_selectedImage != null) ...[
            const SizedBox(height: 20),
            _buildFilePreview(), // ← Handles both image & PDF preview
          ],
          const SizedBox(height: 24),
          _buildAnalyseButton(),
          const SizedBox(height: 32),
          _buildRecentUploadsHeader(),
          const SizedBox(height: 12),
          FutureBuilder<List<dynamic>?>(
            future: _recentUploadsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError ||
                  snapshot.data == null ||
                  snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No recent uploads found.',
                      style: TextStyle(color: Colors.grey)),
                );
              }
              final items = snapshot.data!.take(3).toList();
              return Column(
                children: items
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RecentItem(
                            title: item['merchant_name'] ?? 'Unknown Merchant',
                            subtitle:
                                'RM ${item['total_amount']?.toString() ?? '0.00'} • Risk Score: ${item['risk_score'] ?? 0}',
                            status: item['status'] ?? 'PROCESSING',
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 32),
          _buildComplianceCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Upload Document',
          style: GoogleFonts.publicSans(
              fontSize: 28, fontWeight: FontWeight.bold, color: kNavy)),
      const SizedBox(height: 6),
      const Text(
          'Add tax invoices or receipts for AI compliance analysis. Supports JPG, PNG, PDF.',
          style: TextStyle(color: kNavyLight, fontSize: 14, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildUploadCanvas() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kNavy.withOpacity(0.1), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 10))],
      ),
      child: Column(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: kNavy.withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.add_a_photo, color: kNavy, size: 32),
        ),
        const SizedBox(height: 20),
        Text('Take Photo or Upload',
            style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF171C1F))),
        const SizedBox(height: 6),
        // ── Updated to mention PDF ──
        const Text('Camera, JPG, PNG or PDF accepted',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 28),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Camera button
          ElevatedButton.icon(
            onPressed: _pickFromCamera,
            icon: const Icon(Icons.camera_alt, size: 18),
            label: Text('CAMERA', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kNavy, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 12),
          // Files button — now opens FilePicker with PDF support
          OutlinedButton.icon(
            onPressed: _pickFromFiles,
            icon: const Icon(Icons.file_present, size: 18),
            label: Text('FILES', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kNavy.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.verified_user, color: kNavy, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Secure processing: All documents (images & PDFs) are encrypted and PII is removed before AI analysis.',
            style: TextStyle(fontSize: 11, height: 1.5, fontWeight: FontWeight.w600, color: kNavy),
          ),
        ),
      ]),
    );
  }

  // ── Unified preview for both image and PDF ────────────────────
  Widget _buildFilePreview() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Selected Document',
          style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, fontSize: 15, color: kNavy)),
      const SizedBox(height: 10),
      Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _isPdf
              // PDF preview placeholder
              ? Container(
                  height: 160,
                  width: double.infinity,
                  color: Colors.red.shade50,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.picture_as_pdf, size: 56, color: Colors.redAccent),
                    const SizedBox(height: 8),
                    const Text('PDF Document Ready',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    const SizedBox(height: 4),
                    Text(
                      _selectedImage!.name.length > 35
                          ? '${_selectedImage!.name.substring(0, 35)}...'
                          : _selectedImage!.name,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ]),
                )
              // Image preview
              : kIsWeb
                  ? Image.network(_selectedImage!.path,
                      height: 200, width: double.infinity, fit: BoxFit.cover)
                  : Image.file(File(_selectedImage!.path),
                      height: 200, width: double.infinity, fit: BoxFit.cover),
        ),
        // Close button
        Positioned(
          top: 8, right: 8,
          child: GestureDetector(
            onTap: () => setState(() { _selectedImage = null; _isPdf = false; }),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
        // Filename tag (for images only — PDF already shows name above)
        if (!_isPdf)
          Positioned(
            bottom: 8, left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
              child: Text(
                _selectedImage!.name.length > 25
                    ? '${_selectedImage!.name.substring(0, 25)}...'
                    : _selectedImage!.name,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ]),
    ]);
  }

  Widget _buildAnalyseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_selectedImage != null && !_isLoading) ? _analyze : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: kNavy,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                const SizedBox(width: 14),
                Text('Analysing document...',
                    style: GoogleFonts.publicSans(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ])
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                // Change icon based on file type
                Icon(_isPdf ? Icons.picture_as_pdf : Icons.document_scanner, color: Colors.white),
                const SizedBox(width: 10),
                Text('Analyse Document',
                    style: GoogleFonts.publicSans(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ]),
      ),
    );
  }

  Widget _buildRecentUploadsHeader() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('RECENT UPLOADS',
          style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey)),
      TextButton(
        onPressed: () {},
        child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kNavy)),
      ),
    ]);
  }

  Widget _buildComplianceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF002753), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: kNavy.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.verified_user, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text('LHDN 2026 Compliance Engine',
              style: GoogleFonts.publicSans(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 12),
        Text('AI-Powered Pre-Audit Intelligence',
            style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        const Text('Upload a receipt or PDF invoice above to get an instant compliance verdict with LHDN citations and tax-saving tips.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
        const SizedBox(height: 18),
        Row(children: [_statChip('15 Rules', Icons.gavel), const SizedBox(width: 10), _statChip('Z.AI GLM', Icons.psychology), const SizedBox(width: 10), _statChip('PDF & Image', Icons.description)]),
      ]),
    );
  }

  Widget _statChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

// ── _RecentItem unchanged ─────────────────────────────────────────────────
class _RecentItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;

  const _RecentItem({required this.title, required this.subtitle, required this.status});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    bool isProcessing = status == 'PROCESSING';
    switch (status) {
      case 'SAFE':   statusColor = Colors.green;  statusIcon = Icons.check_circle; break;
      case 'REVIEW': statusColor = Colors.orange; statusIcon = Icons.warning_amber; break;
      case 'DANGER': statusColor = Colors.red;    statusIcon = Icons.dangerous; break;
      default:       statusColor = const Color(0xFF002753); statusIcon = Icons.hourglass_top;
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: statusColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.description, color: statusColor)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            isProcessing
                ? const SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 1.5))
                : Icon(statusIcon, color: statusColor, size: 12),
            const SizedBox(width: 5),
            Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor)),
          ]),
        ),
      ]),
    );
  }
}