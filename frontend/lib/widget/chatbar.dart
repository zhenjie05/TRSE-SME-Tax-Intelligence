import 'package:flutter/material.dart';

class ChatBar extends StatelessWidget {
  final Map<String, dynamic>? initialContext;

  const ChatBar({super.key, this.initialContext});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Route to chat page, passing the analysis result as context if it exists
        Navigator.pushNamed(context, '/chat', arguments: initialContext);
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF002753).withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber.shade600),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Ask AI about your taxes or compliance...',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
            ),
            const Icon(Icons.send, color: Color(0xFF002753), size: 20),
          ],
        ),
      ),
    );
  }
}