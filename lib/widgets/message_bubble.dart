import 'package:flutter/material.dart';
import 'package:helium/config/app_theme.dart';
import 'package:helium/models/chat_message.dart';
import 'package:helium/utils/text_formatter.dart';
import 'package:helium/widgets/file_preview_dialog.dart';
import 'package:helium/state/chat_controller.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isStreaming;

  const MessageBubble({
    super.key, 
    required this.message,
    this.isStreaming = false,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;
  
  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 530),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _previewFile(Map<String, dynamic> fileInfo) async {
    final fileId = fileInfo['file_id'];
    final fileName = fileInfo['file_name'] ?? 'Unknown';
    
    if (fileId == null) {
      _showError('File ID not available');
      return;
    }
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading file...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    try {
      // Get file content from API
      final chat = context.read<ChatController>();
      
      if (chat.currentThreadId == null || chat.currentProjectId == null) {
        Navigator.pop(context); // Close loading
        _showError('No active conversation');
        return;
      }
      
      final result = await chat.api.getFile(
        fileId,
        chat.currentThreadId!,
        chat.currentProjectId!,
      );
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      if (result['success'] == true && result['file'] != null) {
        final file = result['file'];
        final content = file['content'] ?? 'No content available';
        final fileType = file['file_type'] ?? 'text/plain';
        
        // Show preview dialog
        showDialog(
          context: context,
          builder: (context) => FilePreviewDialog(
            fileName: fileName,
            fileContent: content,
            fileType: fileType,
          ),
        );
      } else {
        _showError('Failed to load file content: ${result['detail'] ?? 'Unknown error'}');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      _showError('Error: $e');
    }
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    
    // Images - specific icons for each type
    if (ext == 'png') return Icons.image;
    if (ext == 'jpg' || ext == 'jpeg') return Icons.image;
    if (ext == 'gif') return Icons.gif;
    if (ext == 'svg') return Icons.image;
    if (ext == 'webp') return Icons.image;
    
    // Documents - specific icons
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (ext == 'docx' || ext == 'doc') return Icons.description;
    if (ext == 'xlsx' || ext == 'xls') return Icons.table_chart;
    if (ext == 'csv') return Icons.table_chart;
    if (ext == 'pptx' || ext == 'ppt') return Icons.slideshow;
    
    // Text files
    if (ext == 'txt') return Icons.text_snippet;
    if (ext == 'json') return Icons.code;
    if (ext == 'xml') return Icons.code;
    if (ext == 'md') return Icons.article;
    
    // Code files
    if (['html', 'css', 'js', 'ts', 'py', 'java', 'cpp', 'c', 'dart'].contains(ext)) {
      return Icons.code;
    }
    
    // Audio files
    if (ext == 'mp3') return Icons.audio_file;
    if (ext == 'wav') return Icons.audio_file;
    if (ext == 'flac') return Icons.audio_file;
    if (ext == 'aac') return Icons.audio_file;
    
    // Archives
    if (ext == 'zip') return Icons.folder_zip;
    if (ext == 'rar') return Icons.folder_zip;
    if (ext == '7z') return Icons.folder_zip;
    
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    // Don't show cursor during streaming - user should see clean text only
    final showCursor = false;

    return Align(
      alignment: widget.message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: widget.message.isUser ? 80 : 0,
          right: widget.message.isUser ? 0 : 80,
        ),
        child: Column(
          crossAxisAlignment: widget.message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label: "you" or "helium"
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 20, right: 20),
              child: Text(
                widget.message.isUser ? 'you' : 'helium',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryCoolAsh,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Message content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Message content with typing cursor if streaming
                  widget.message.isUser || !TextFormatter.hasFormatting(widget.message.content)
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: SelectableText(
                                widget.message.content,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.textPrimarySoftPearl,
                                  height: 1.6,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            if (showCursor)
                              Padding(
                                padding: const EdgeInsets.only(left: 4, top: 2),
                                child: FadeTransition(
                                  opacity: _cursorController,
                                  child: Container(
                                    width: 8,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppTheme.brandPrimaryLuminousTeal,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SelectableText.rich(
                              TextSpan(
                                children: TextFormatter.formatResponse(widget.message.content),
                              ),
                            ),
                            if (showCursor)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: FadeTransition(
                                  opacity: _cursorController,
                                  child: Container(
                                    width: 8,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                  
                  // File and code indicators
                  if (widget.message.hasFiles && widget.message.files != null && widget.message.files!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.message.files!.map((file) {
                          final fileName = file['file_name'] ?? 'Unknown';
                          final fileSize = file['file_size'];
                          
                          return InkWell(
                            onTap: () => _previewFile(file),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDarkSlateTeal,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.borderDivider.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getFileIcon(fileName),
                                    size: 16,
                                    color: AppTheme.brandPrimaryLuminousTeal,
                                  ),
                                  const SizedBox(width: 8),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 200),
                                    child: Text(
                                      fileName,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textPrimarySoftPearl,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.visibility,
                                    size: 14,
                                    color: AppTheme.brandSecondaryEucalyptus,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  else if (widget.message.hasFiles || widget.message.hasCode)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (widget.message.hasFiles)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.attach_file,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.message.files?.length ?? 0} file${(widget.message.files?.length ?? 0) > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (widget.message.hasCode)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.code,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.message.codeBlocks?.length ?? 0} code block${(widget.message.codeBlocks?.length ?? 0) > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
