import 'dart:ui';
import 'package:flutter/material.dart';
import '../styles.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isSender;
  final List<Widget>? actions;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isSender,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isSender
                      ? AppStyles.primaryColor.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  isSender
                      ? AppStyles.primaryColor.withOpacity(0.05)
                      : Colors.white.withOpacity(0.05),
                ],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    text,
                    style: AppStyles.bodyStyle.copyWith(
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
