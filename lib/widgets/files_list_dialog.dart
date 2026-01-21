import 'package:flutter/material.dart';
import 'package:helium/state/chat_controller.dart';
import 'package:helium/widgets/file_preview_dialog.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class FilesListDialog extends StatefulWidget {
  const FilesListDialog({super.key});

  @override
  State<FilesListDialog> createState() => _FilesListDialogState();
}

class _FilesListDialogState extends State<FilesListDialog> {
  bool _loading = true;
  List<Map<String, dynamic>> _files = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final chat = context.read<ChatController>();
    
    if (chat.currentThreadId == null || chat.currentProjectId == null) {
      setState(() {
        _error = 'No active conversation';
        _loading = false;
      });
      return;
    }

    try {
      final result = await chat.api.listFiles(
        chat.currentThreadId!,
        chat.currentProjectId!,
      );

      if (!mounted) return;

      if (result['success'] == true && result['files'] != null) {
        setState(() {
          _files = List<Map<String, dynamic>>.from(result['files']);
          _loading = false;
        });
      } else {
        setState(() {
          _error = result['detail'] ?? 'Failed to load files';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
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
        
        // Close files list dialog
        Navigator.pop(context);
        
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                        Icons.description,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Generated Files',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ),
                      if (!_loading)
                        Text(
                          '${_files.length} file${_files.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      const SizedBox(width: 12),
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
                  child: _loading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading files...',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.withValues(alpha: 0.8),
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _files.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.description,
                                          color: Colors.white.withValues(alpha: 0.3),
                                          size: 64,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No files generated yet',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.6),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _files.length,
                                  itemBuilder: (context, index) {
                                    final file = _files[index];
                                    final fileName = file['file_name'] ?? 'Unknown';
                                    final fileSize = file['file_size'] ?? 0;
                                    final fileSizeStr = _formatFileSize(fileSize);
                                    
                                    return InkWell(
                                      onTap: () => _previewFile(file),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.1),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                _getFileIcon(fileName),
                                                color: Colors.blue.withValues(alpha: 0.9),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    fileName,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.white.withValues(alpha: 0.9),
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    fileSizeStr,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white.withValues(alpha: 0.5),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.visibility,
                                              size: 18,
                                              color: Colors.blue.withValues(alpha: 0.7),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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
