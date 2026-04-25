import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart'; //
import '../services/api_service.dart';
import '../widget/chatbar.dart';

class UploadWeb extends StatefulWidget {
  const UploadWeb({super.key});
  @override
  State<UploadWeb> createState() => _UploadWebState();
}

class _UploadWebState extends State<UploadWeb> {
  XFile? _selectedImage;
  bool _isLoading = false;
  late Future<List<dynamic>?> _recentUploadsFuture;
  static const Color kNavy = Color(0xFF002753);

  @override
  void initState() {
    super.initState();
    _recentUploadsFuture = ApiService.fetchAuditHistory();
  }

  // Updated to use FilePicker to allow PDF selection
  Future<void> _pickFromGallery() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      final file = result.files.single;
      setState(() {
        if (kIsWeb) {
          _selectedImage = XFile.fromData(file.bytes!, name: file.name);
        } else {
          _selectedImage = XFile(file.path!, name: file.name);
        }
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
        const SnackBar(content: Text('Failed to connect to backend engine.')),
      );
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upload Document', 
                        style: GoogleFonts.publicSans(fontSize: 32, fontWeight: FontWeight.bold, color: kNavy)),
                      const SizedBox(height: 8),
                      const Text('Add tax invoices or receipts for AI compliance analysis.', 
                        style: TextStyle(fontSize: 16)),
                    ]
                  ),
                  const Expanded(child: Padding(padding: EdgeInsets.only(left: 40), child: ChatBar())),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT SIDE: Upload Canvas
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(60),
                          decoration: BoxDecoration(
                            color: Colors.white, 
                            borderRadius: BorderRadius.circular(24), 
                            border: Border.all(color: kNavy.withOpacity(0.1), width: 2)),
                          child: Column(children: [
                            const Icon(Icons.cloud_upload, color: kNavy, size: 64),
                            const SizedBox(height: 24),
                            Text('Select a file from your computer', 
                              style: GoogleFonts.publicSans(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _pickFromGallery,
                              icon: const Icon(Icons.folder, color: Colors.white),
                              label: const Text('BROWSE FILES', 
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kNavy, 
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20)),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 24),
                        
                        // Updated preview logic to handle PDFs
                        if (_selectedImage != null) ...[
                          Text('Selected Document', 
                            style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, fontSize: 15, color: kNavy)),
                          const SizedBox(height: 10),
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: _selectedImage!.name.toLowerCase().endsWith('.pdf')
                                    ? Container(
                                        height: 300, 
                                        width: double.infinity, 
                                        color: Colors.grey.shade100, 
                                        child: const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.picture_as_pdf, size: 80, color: Colors.redAccent),
                                            SizedBox(height: 10),
                                            Text("PDF Document Detected", 
                                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      )
                                    : Image.network(
                                        _selectedImage!.path,
                                        height: 400,
                                        width: double.infinity,
                                        fit: BoxFit.contain,
                                      ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _analyze,
                              style: ElevatedButton.styleFrom(backgroundColor: kNavy),
                              child: _isLoading 
                                  ? const CircularProgressIndicator(color: Colors.white) 
                                  : const Text('Analyse Document', 
                                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(width: 60),

                  // RIGHT SIDE: Compliance Card & History
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF002753), Color(0xFF1565C0)]), 
                            borderRadius: BorderRadius.circular(20)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('LHDN 2026 Engine', 
                              style: GoogleFonts.publicSans(color: Colors.white70, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text('AI-Powered Pre-Audit', 
                              style: GoogleFonts.publicSans(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 16),
                            const Text('Upload a receipt to get an instant compliance verdict with LHDN citations.', 
                              style: TextStyle(color: Colors.white70, height: 1.5)),
                          ]),
                        ),
                        const SizedBox(height: 40),
                        const Text('RECENT UPLOADS', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
                        const SizedBox(height: 16),
                        FutureBuilder<List<dynamic>?>(
                          future: _recentUploadsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text('No recent uploads.');
                            return Column(
                              children: snapshot.data!.take(4).map((item) => Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: const Icon(Icons.description, color: kNavy),
                                  title: Text(item['merchant_name'] ?? 'Unknown'),
                                  subtitle: Text('RM ${item['total_amount']}'),
                                  trailing: Text(item['status'] ?? '', 
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              )).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}