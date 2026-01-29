import 'package:flutter/material.dart';
import '../styles.dart';
import '../Waveform.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onMedia;
  final VoidCallback onVoiceMode;
  final VoidCallback onListen;
  final VoidCallback onStopListen;
  final bool isListening;
  final bool isEmpty;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onMedia,
    required this.onVoiceMode,
    required this.onListen,
    required this.onStopListen,
    required this.isListening,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(2),
      decoration: AppStyles.glassDecoration(radius: 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
            onPressed: onMedia,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              cursorColor: AppStyles.primaryColor,
              style: AppStyles.bodyStyle,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Message Gemini...",
                hintStyle: AppStyles.secondaryStyle,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          GestureDetector(
            onLongPressStart: (_) => onListen(),
            onLongPressEnd: (_) => onStopListen(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: !isEmpty ? AppStyles.primaryColor : Colors.white12,
                shape: BoxShape.circle,
              ),
              child: isListening
                  ? Padding(padding: const EdgeInsets.all(8.0), child: Waveform())
                  : IconButton(
                      icon: Icon(
                        isEmpty ? Icons.mic : Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: onSend,
                    ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.graphic_eq, color: AppStyles.accentColor),
            onPressed: onVoiceMode,
          ),
        ],
      ),
    );
  }
}
