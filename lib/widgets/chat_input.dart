import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:helium/widgets/file_type_selector.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;

class ChatInput extends StatefulWidget {
  final Function(String, {List<PlatformFile>? files}) onSend;
  final bool isStreaming;
  final VoidCallback? onStop;
  
  const ChatInput({
    super.key, 
    required this.onSend,
    this.isStreaming = false,
    this.onStop,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  List<PlatformFile> selectedFiles = [];
  
  // Supported file extensions based on API documentation
  static const List<String> supportedExtensions = [
    // Images
    'png', 'jpg', 'jpeg', 'gif', 'svg', 'webp',
    // Documents
    'pdf', 'docx', 'xlsx', 'pptx', 'csv',
    // Text
    'txt', 'json', 'xml', 'md',
    // Code files
    'html', 'css', 'js', 'ts', 'py', 'java', 'cpp', 'c', 'dart', 'go', 'rs', 'php', 'rb', 'swift', 'kt',
    // Audio
    'mp3', 'wav', 'flac', 'aac',
    // Archives
    'zip', 'rar', '7z',
  ];
  
  // File size limits from API documentation
  static const int maxFileSizeMB = 50;
  static const int maxTotalSizeMB = 200;
  static const int maxFiles = 10;

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  String _getFileExtension(String name) {
    return name.split('.').last.toLowerCase();
  }

  bool _isFileSupported(String name) {
    final extension = _getFileExtension(name);
    return supportedExtensions.contains(extension);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  IconData _getFileIcon(String path) {
    final ext = _getFileExtension(path);
    
    // Images - specific icons for each type
    if (ext == 'png' || ext == 'jpg' || ext == 'jpeg') return Icons.image;
    if (ext == 'gif') return Icons.gif_box;
    if (ext == 'svg') return Icons.image_outlined;
    if (ext == 'webp') return Icons.image;
    
    // Documents - specific icons
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (ext == 'docx' || ext == 'doc') return Icons.description;
    if (ext == 'xlsx' || ext == 'xls') return Icons.table_chart;
    if (ext == 'csv') return Icons.table_rows;
    if (ext == 'pptx' || ext == 'ppt') return Icons.slideshow;
    
    // Text files
    if (ext == 'txt') return Icons.text_snippet;
    if (ext == 'md') return Icons.article;
    
    // Code files - specific icons for different languages
    if (ext == 'json') return Icons.data_object;
    if (ext == 'xml') return Icons.code;
    if (ext == 'html') return Icons.html;
    if (ext == 'css') return Icons.css;
    if (ext == 'js' || ext == 'ts') return Icons.javascript;
    if (ext == 'py') return Icons.code;
    if (ext == 'java') return Icons.code;
    if (ext == 'cpp' || ext == 'c') return Icons.code;
    if (ext == 'dart') return Icons.code;
    if (ext == 'go' || ext == 'rs' || ext == 'php' || ext == 'rb' || ext == 'swift' || ext == 'kt') return Icons.code;
    
    // Audio files
    if (ext == 'mp3' || ext == 'wav' || ext == 'flac' || ext == 'aac') return Icons.audio_file;
    
    // Archives
    if (ext == 'zip' || ext == 'rar' || ext == '7z') return Icons.folder_zip;
    
    return Icons.insert_drive_file;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickFiles() async {
    await _pickFilesWithFilter(null);
  }

  Future<void> _showFileTypeSelector() async {
    showDialog(
      context: context,
      builder: (context) => FileTypeSelector(
        onTypeSelected: (extensions) {
          _pickFilesWithFilter(extensions);
        },
      ),
    );
  }

  Future<void> _pickFilesWithFilter(List<String>? allowedExtensions) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? supportedExtensions,
        withData: kIsWeb, // Load file data on web
      );

      if (result != null && result.files.isNotEmpty) {
        final newFiles = result.files;
        
        // Validate number of files
        if (selectedFiles.length + newFiles.length > maxFiles) {
          _showError('Maximum $maxFiles files allowed per request');
          return;
        }
        
        // Validate individual file sizes and total size
        int totalSize = selectedFiles.fold(0, (sum, file) => sum + (file.size));
        
        for (final file in newFiles) {
          // Check if file is supported
          if (!_isFileSupported(file.name)) {
            final ext = _getFileExtension(file.name);
            _showError('File type .$ext is not supported');
            return;
          }
          
          // Check individual file size
          final fileSize = file.size;
          final fileSizeMB = fileSize / (1024 * 1024);
          
          if (fileSizeMB > maxFileSizeMB) {
            _showError('File size exceeds ${maxFileSizeMB}MB limit: ${_formatFileSize(fileSize)}');
            return;
          }
          
          totalSize += fileSize;
        }
        
        // Check total size
        final totalSizeMB = totalSize / (1024 * 1024);
        if (totalSizeMB > maxTotalSizeMB) {
          _showError('Total file size exceeds ${maxTotalSizeMB}MB limit: ${totalSizeMB.toStringAsFixed(1)}MB');
          return;
        }
        
        // All validations passed, add files
        setState(() {
          selectedFiles.addAll(newFiles);
        });
      }
    } catch (e) {
      _showError('Error selecting files: $e');
    }
  }

  void _removeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
    });
  }

  void _handleSend() {
    final text = controller.text.trim();
    final hasText = text.isNotEmpty;
    final hasFiles = selectedFiles.isNotEmpty;
    
    if (hasText || hasFiles) {
      widget.onSend(
        text,
        files: hasFiles ? selectedFiles : null,
      );
      
      controller.clear();
      setState(() {
        selectedFiles = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show selected files
          if (selectedFiles.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  final fileName = file.name;
                  final fileSize = file.size;
                  final fileSizeStr = _formatFileSize(fileSize);
                  final fileExt = _getFileExtension(fileName).toUpperCase();
                  
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
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
                              _getFileIcon(fileName),
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 150),
                                  child: Text(
                                    fileName,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                                Text(
                                  '$fileExt • $fileSizeStr',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _removeFile(index),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          // Input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.enter &&
                              !HardwareKeyboard.instance.isShiftPressed) {
                            _handleSend();
                          }
                        },
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          maxLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _handleSend(),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            height: 1.5,
                          ),
                          decoration: InputDecoration(
                            hintText: "Describe what to build…",
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // File upload button
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selectedFiles.isNotEmpty
                          ? Colors.blue.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: selectedFiles.isNotEmpty
                          ? Border.all(
                              color: Colors.blue.withValues(alpha: 0.5),
                              width: 1,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showFileTypeSelector,
                        borderRadius: BorderRadius.circular(30),
                        splashColor: Colors.white.withValues(alpha: 0.2),
                        child: Stack(
                          children: [
                            Center(
                              child: Icon(
                                Icons.attach_file,
                                color: selectedFiles.isNotEmpty
                                    ? Colors.blue.withValues(alpha: 0.9)
                                    : Colors.white.withValues(alpha: 0.8),
                                size: 18,
                              ),
                            ),
                            if (selectedFiles.isNotEmpty)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${selectedFiles.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.isStreaming 
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.isStreaming ? widget.onStop : _handleSend,
                        borderRadius: BorderRadius.circular(30),
                        splashColor: Colors.white.withValues(alpha: 0.2),
                        child: Center(
                          child: Icon(
                            widget.isStreaming ? Icons.stop : Icons.send_rounded,
                            color: widget.isStreaming ? Colors.red : Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
