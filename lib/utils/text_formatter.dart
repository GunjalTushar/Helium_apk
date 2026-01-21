import 'package:flutter/material.dart';

class TextFormatter {
  /// Format text with proper indentation and styling - works with pre-cleaned text
  static List<TextSpan> formatResponse(String text) {
    final List<TextSpan> spans = [];
    final lines = text.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Skip empty lines but add spacing
      if (line.trim().isEmpty) {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }
      
      // Detect headers by pattern: standalone lines that are short and followed by content
      // Headers are typically capitalized and don't end with punctuation
      final isLikelyHeader = line.trim().length < 60 && 
                             line.trim().length > 3 &&
                             !line.trim().endsWith('.') &&
                             !line.trim().endsWith(',') &&
                             !line.trim().endsWith(':') &&
                             RegExp(r'^[A-Z🌍🦠⚠️✈️🚨💼🇮🇷🇻🇪🇨🇳🐄]').hasMatch(line.trim()) &&
                             i < lines.length - 1 &&
                             lines[i + 1].trim().isNotEmpty;
      
      if (isLikelyHeader) {
        // Determine header level by context
        final headerText = line.trim();
        final hasEmoji = RegExp(r'[🌍🦠⚠️✈️🚨💼🇮🇷🇻🇪🇨🇳🐄]').hasMatch(headerText);
        
        spans.add(TextSpan(
          text: '\n$headerText\n',
          style: TextStyle(
            fontSize: hasEmoji ? 19 : 17,
            fontWeight: FontWeight.w700,
            height: 1.5,
            color: Colors.white,
          ),
        ));
      }
      // Bullet points (already converted to •)
      else if (line.trim().startsWith('•')) {
        final content = line.trim().substring(1).trim();
        spans.add(TextSpan(
          text: '  • $content\n',
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Colors.white.withValues(alpha: 0.95),
          ),
        ));
      }
      // Numbered lists (detect pattern like "1. " or just indented content)
      else if (RegExp(r'^\s+').hasMatch(line) && !line.trim().startsWith('•')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Colors.white.withValues(alpha: 0.95),
          ),
        ));
      }
      // Regular text
      else {
        spans.add(TextSpan(
          text: '$line\n',
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Colors.white.withValues(alpha: 0.95),
          ),
        ));
      }
    }
    
    return spans;
  }
  
  /// Parse text with bold formatting - no longer needed since we clean before streaming
  static void _parseBoldText(String line, List<TextSpan> spans) {
    // This method is kept for backward compatibility but won't be called
    // since we clean markdown before streaming
    spans.add(TextSpan(
      text: '$line\n',
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: Colors.white.withValues(alpha: 0.95),
      ),
    ));
  }
  
  /// Check if text contains markdown formatting
  static bool hasFormatting(String text) {
    // Since we now clean markdown before streaming, check for actual formatting
    // Look for patterns that indicate the text was formatted (like multiple newlines, bullets)
    return text.contains('\n\n') || 
           text.contains('  •') ||
           text.contains('\n  ') ||
           RegExp(r'\n[A-Z][^.!?]*\n').hasMatch(text); // Detect heading-like patterns
  }
}
