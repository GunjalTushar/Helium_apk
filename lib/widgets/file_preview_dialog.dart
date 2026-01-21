import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class FilePreviewDialog extends StatefulWidget {
  final String fileName;
  final String fileContent;
  final String fileType;
  
  const FilePreviewDialog({
    super.key,
    required this.fileName,
    required this.fileContent,
    required this.fileType,
  });

  @override
  State<FilePreviewDialog> createState() => _FilePreviewDialogState();
}

class _FilePreviewDialogState extends State<FilePreviewDialog> {
  bool _copied = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.fileContent));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  IconData _getFileIcon(String fileType) {
    final type = fileType.toLowerCase();
    if (type.contains('image')) return Icons.image;
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('text')) return Icons.text_snippet;
    if (type.contains('json')) return Icons.code;
    if (type.contains('html')) return Icons.code;
    if (type.contains('javascript')) return Icons.code;
    if (type.contains('python')) return Icons.code;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 800,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getFileIcon(widget.fileType),
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.fileName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _copied ? Icons.check : Icons.copy,
                          color: _copied 
                              ? Colors.green.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.8),
                          size: 20,
                        ),
                        onPressed: _copyToClipboard,
                        tooltip: _copied ? 'Copied!' : 'Copy content',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: SelectableText(
                      widget.fileContent,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
