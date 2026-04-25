import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

// Reusing the same Message class structure
class Message {
  final String text;
  final bool isUser;
  Message({required this.text, required this.isUser});
}

class ChatWeb extends StatefulWidget {
  const ChatWeb({super.key});

  @override
  State<ChatWeb> createState() => _ChatWebState();
}

class _ChatWebState extends State<ChatWeb> {
  static const Color kNavy = Color(0xFF002753);
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  bool _isLoading = false;
  Map<String, dynamic>? _contextData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_contextData == null) {
      _contextData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _messages.add(Message(
        text: _contextData != null 
            ? "I have loaded your receipt analysis context. How can I assist you with this document or LHDN regulations?" 
            : "Hello! Ask me anything about LHDN 2026 taxes and compliance.",
        isUser: false,
      ));
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userText = _controller.text.trim();
    setState(() {
      _messages.add(Message(text: userText, isUser: true));
      _isLoading = true;
    });
    _controller.clear();

    final aiResponse = await ApiService.sendChatMessage(userText, _contextData);

    setState(() {
      _messages.add(Message(text: aiResponse, isUser: false));
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFE),
      appBar: AppBar(
        title: Text('TSRE AI Assistant', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: kNavy,
        elevation: 1,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Max width for web chat
          child: Column(
            children: [
              if (_contextData != null && _contextData!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.amber.shade50,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.attachment, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Document context attached for AI Analysis', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(32),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildMessageBubble(msg);
                  },
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: msg.isUser ? kNavy : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(20),
            bottomLeft: !msg.isUser ? const Radius.circular(0) : const Radius.circular(20),
          ),
          border: msg.isUser ? null : Border.all(color: Colors.grey.shade200),
          boxShadow: [
            if (!msg.isUser) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: Text(
          msg.text,
          style: TextStyle(color: msg.isUser ? Colors.white : Colors.black87, fontSize: 15, height: 1.5),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ask about taxes, compliance, etc...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _isLoading ? null : _sendMessage,
            backgroundColor: kNavy,
            elevation: 0,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}