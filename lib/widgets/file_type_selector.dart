import 'package:flutter/material.dart';
import 'dart:ui';

class FileTypeSelector extends StatelessWidget {
  final Function(List<String>?) onTypeSelected;
  final bool showUploadOption;
  
  const FileTypeSelector({
    super.key, 
    required this.onTypeSelected,
    this.showUploadOption = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.folder_open,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        showUploadOption ? 'Upload Files' : 'Select File Type',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a file type to upload',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 20),
                
                // All Files
                _buildFileTypeOption(
                  context,
                  icon: Icons.folder_open,
                  title: 'All Files',
                  subtitle: 'Any supported file type',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    onTypeSelected(null);
                  },
                ),
                
                const Divider(color: Colors.white24, height: 24),
                
                // Images
                _buildFileTypeOption(
                  context,
                  icon: Icons.image,
                  title: 'Images',
                  subtitle: 'PNG, JPG, GIF, SVG, WebP',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    onTypeSelected(['png', 'jpg', 'jpeg', 'gif', 'svg', 'webp']);
                  },
                ),
                
                // PDF
                _buildFileTypeOption(
                  context,
                  icon: Icons.picture_as_pdf,
                  title: 'PDF Documents',
                  subtitle: 'PDF files only',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    onTypeSelected(['pdf']);
                  },
                ),
                
                // Documents
                _buildFileTypeOption(
                  context,
                  icon: Icons.description,
                  title: 'Office Documents',
                  subtitle: 'DOCX, XLSX, PPTX, CSV',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    onTypeSelected(['docx', 'xlsx', 'pptx', 'csv']);
                  },
                ),
                
                // Code Files
                _buildFileTypeOption(
                  context,
                  icon: Icons.code,
                  title: 'Code Files',
                  subtitle: 'JSON, XML, HTML, CSS, JS, PY',
                  color: Colors.cyan,
                  onTap: () {
                    Navigator.pop(context);
                    onTypeSelected(['json', 'xml', 'html', 'css', 'js', 'ts', 'py', 'java', 'cpp', 'c', 'dart']);
                  },
                ),
                
                // Text Files
                _buildFileTypeOption(
                  context,
                  icon: Icons.text_snippet,
                  title: 'Text Files',
                  subtitle: 'TXT, MD',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    onTypeSelected(['txt', 'md']);
                  },
                ),
                
                // Audio
                _buildFileTypeOption(
                  context,
                  icon: Icons.audio_file,
                  title: 'Audio',
                  subtitle: 'MP3, WAV, FLAC, AAC',
                  color: Colors.pink,
                  onTap: () {
                    Navigator.pop(context);
                    onTypeSelected(['mp3', 'wav', 'flac', 'aac']);
                  },
                ),
                
                // Archives
                _buildFileTypeOption(
                  context,
                  icon: Icons.folder_zip,
                  title: 'Archives',
                  subtitle: 'ZIP, RAR, 7Z',
                  color: Colors.amber,
                  onTap: () {
                    Navigator.pop(context);
                    onTypeSelected(['zip', 'rar', '7z']);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileTypeOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.upload_file,
              size: 20,
              color: color.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}
