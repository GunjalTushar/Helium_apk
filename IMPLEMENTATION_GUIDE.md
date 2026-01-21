# Implementation Guide: Advanced Features

This guide provides step-by-step instructions to implement the following features:
1. Enhanced conversation history with session topics
2. Folder icon with file type filters
3. File preview system with Get File Content API
4. Stop Agent functionality

---

## Feature 1: Enhanced Conversation History with Session Topics

### Overview
Save each conversation session locally with an auto-generated topic from the first user message.

### Files to Modify
- `lib/state/chat_controller.dart`
- `lib/widgets/sidebar.dart`

### Implementation Steps

#### Step 1.1: Update Chat Controller to Extract Topics

In `lib/state/chat_controller.dart`, add a method to extract topic from message:

```dart
/// Extract a short topic from the first message
String _extractTopic(String message) {
  // Remove extra whitespace and newlines
  final cleaned = message.trim().replaceAll(RegExp(r'\s+'), ' ');
  
  // Take first 50 characters or until first sentence
  if (cleaned.length <= 50) {
    return cleaned;
  }
  
  // Try to find first sentence
  final firstSentence = cleaned.split(RegExp(r'[.!?]')).first;
  if (firstSentence.length <= 50) {
    return firstSentence.trim();
  }
  
  // Truncate to 47 chars and add ellipsis
  return '${cleaned.substring(0, 47)}...';
}
```

#### Step 1.2: Update History Saving

Modify the `_createNewConversation` method to save topic:

```dart
// Save to history with extracted topic
final topic = _extractTopic(prompt.isEmpty ? "[Files attached]" : prompt);
threadsBox.add({
  "prompt": prompt.isEmpty ? "[Files attached]" : prompt,
  "topic": topic,  // Add this line
  "thread_id": threadId,
  "project_id": projectId,
  "agent_run_id": agentRunId,
  "timestamp": DateTime.now().toIso8601String(),
  "message_count": messages.length,
});
```

#### Step 1.3: Update Sidebar to Display Topics

In `lib/widgets/sidebar.dart`, modify the conversation list to show topics:

```dart
final topic = item["topic"] ?? item["prompt"] ?? "Untitled";
final summary = _generateSummary(topic);

// In the Text widget:
Text(
  summary,
  maxLines: 2,  // Allow 2 lines for better readability
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    fontSize: 13,
    color: Colors.white.withValues(alpha: 0.8),
    fontWeight: chat.currentThreadId == threadId
        ? FontWeight.w600
        : FontWeight.normal,
  ),
),
```

---

## Feature 2: Folder Icon with File Type Filters

### Overview
Add a folder icon in the top-right corner that opens a modal showing all supported file types with icons. Clicking a type filters the file picker.

### Files to Create/Modify
- Create: `lib/widgets/file_type_selector.dart`
- Modify: `lib/widgets/chat_input.dart`
- Modify: `lib/widgets/landing_page.dart`

### Implementation Steps

#### Step 2.1: Create File Type Selector Widget

Create `lib/widgets/file_type_selector.dart`:

```dart
import 'package:flutter/material.dart';
import 'dart:ui';

class FileTypeSelector extends StatelessWidget {
  final Function(List<String>?) onTypeSelected;
  
  const FileTypeSelector({super.key, required this.onTypeSelected});

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
                Text(
                  'Select File Type',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 20),
                
                // All Files
                _buildFileTypeOption(
                  context,
                  icon: Icons.folder_open,
                  title: 'All Files',
                  subtitle: 'Any supported file type',
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
                  onTap: () {
                    Navigator.pop(context);
                    onTypeSelected(['png', 'jpg', 'jpeg', 'gif', 'svg', 'webp']);
                  },
                ),
                
                // Documents
                _buildFileTypeOption(
                  context,
                  icon: Icons.description,
                  title: 'Documents',
                  subtitle: 'PDF, DOCX, XLSX, PPTX, CSV',
                  onTap: () {
                    Navigator.pop(context);
                    onTypeSelected(['pdf', 'docx', 'xlsx', 'pptx', 'csv']);
                  },
                ),
                
                // Text Files
                _buildFileTypeOption(
                  context,
                  icon: Icons.text_snippet,
                  title: 'Text Files',
                  subtitle: 'TXT, JSON, XML, MD',
                  onTap: () {
                    Navigator.pop(context);
                    onTypeSelected(['txt', 'json', 'xml', 'md']);
                  },
                ),
                
                // Audio
                _buildFileTypeOption(
                  context,
                  icon: Icons.audio_file,
                  title: 'Audio',
                  subtitle: 'MP3, WAV, FLAC, AAC',
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.8),
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
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Step 2.2: Add Folder Icon to Chat Input

In `lib/widgets/chat_input.dart`, add folder icon button:

```dart
// Add this method to _ChatInputState class
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

// Modify _pickFiles to accept optional filter
Future<void> _pickFilesWithFilter(List<String>? allowedExtensions) async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: allowedExtensions ?? supportedExtensions,
    );
    
    // Rest of the validation logic...
  } catch (e) {
    _showError('Error selecting files: $e');
  }
}

// Update _pickFiles to call _pickFilesWithFilter
Future<void> _pickFiles() async {
  await _pickFilesWithFilter(null);
}
```

#### Step 2.3: Add Folder Icon to UI

In the input row, add folder icon button before the file upload button:

```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    // Folder icon for file type selection
    ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showFileTypeSelector,
              borderRadius: BorderRadius.circular(30),
              child: Center(
                child: Icon(
                  Icons.folder_open,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    const SizedBox(width: 12),
    
    // Existing file upload button...
    // Existing input field...
    // Existing send button...
  ],
),
```

---

## Feature 3: File Preview System with Get File Content API

### Overview
When files are generated by the AI, provide preview links that fetch and display file content using the Get File Content API.

### Files to Modify
- `lib/services/helium_api.dart` (already has getFile method)
- `lib/widgets/message_bubble.dart`
- Create: `lib/widgets/file_preview_dialog.dart`

### Implementation Steps

#### Step 3.1: Verify Get File Content API

The API method already exists in `lib/services/helium_api.dart`:

```dart
/// 8. Get File Content
/// Download a specific file
Future<Map<String, dynamic>> getFile(
  String fileId,
  String threadId,
  String projectId, {
  bool download = false,
}) async {
  // Implementation already exists
}
```

#### Step 3.2: Create File Preview Dialog

Create `lib/widgets/file_preview_dialog.dart`:

```dart
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
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 20,
                        ),
                        onPressed: _copyToClipboard,
                        tooltip: 'Copy content',
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

  IconData _getFileIcon(String fileType) {
    if (fileType.contains('image')) return Icons.image;
    if (fileType.contains('pdf')) return Icons.picture_as_pdf;
    if (fileType.contains('text')) return Icons.text_snippet;
    if (fileType.contains('json')) return Icons.code;
    if (fileType.contains('html')) return Icons.code;
    return Icons.insert_drive_file;
  }
}
```

#### Step 3.3: Update Message Bubble to Show Preview Links

In `lib/widgets/message_bubble.dart`, add file preview functionality:

```dart
// Add this method to _MessageBubbleState class
Future<void> _previewFile(Map<String, dynamic> fileInfo) async {
  final fileId = fileInfo['file_id'];
  final fileName = fileInfo['file_name'];
  
  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );
  
  try {
    // Get file content from API
    final chat = context.read<ChatController>();
    final result = await chat.api.getFile(
      fileId,
      chat.currentThreadId!,
      chat.currentProjectId!,
    );
    
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
      _showError('Failed to load file content');
    }
  } catch (e) {
    Navigator.pop(context); // Close loading
    _showError('Error: $e');
  }
}

// Update the files display section to add preview buttons
if (widget.message.hasFiles && widget.message.files != null)
  Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.message.files!.map((file) {
        final fileName = file['file_name'] ?? 'Unknown';
        final fileSize = file['file_size'] ?? 0;
        
        return InkWell(
          onTap: () => _previewFile(file),
          borderRadius: BorderRadius.circular(12),
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
                  Icons.insert_drive_file,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.visibility,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  ),
```

---

## Feature 4: Stop Agent Functionality

### Overview
Add a stop button that appears during streaming to allow users to stop the agent execution.

### Files to Modify
- `lib/state/chat_controller.dart`
- `lib/screens/chat_screen.dart`

### Implementation Steps

#### Step 4.1: Verify Stop Agent API

The API method already exists in `lib/services/helium_api.dart`:

```dart
/// 5. Stop Agent
/// Stop a running task
Future<Map<String, dynamic>> stopAgent(
  String threadId,
  String projectId,
) async {
  // Implementation already exists
}
```

The chat controller also has the method:

```dart
/// Stop the current agent execution
Future<void> stopCurrentAgent() async {
  if (currentThreadId == null || currentProjectId == null) {
    return;
  }

  try {
    await api.stopAgent(currentThreadId!, currentProjectId!);
    status = "Stopped";
    loading = false;
    notifyListeners();
  } catch (e) {
    // Silently fail
  }
}
```

#### Step 4.2: Add Stop Button to Chat Screen

In `lib/screens/chat_screen.dart`, add stop button in the header:

```dart
// Header with Helium title
Container(
  padding: const EdgeInsets.all(16),
  child: Row(
    children: [
      const Spacer(),
      Text(
        'Helium',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.9),
          letterSpacing: -0.5,
        ),
      ),
      const Spacer(),
      
      // Stop button (only show when streaming)
      if (chat.isStreaming)
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      await chat.stopCurrentAgent();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stop,
                            size: 16,
                            color: Colors.red.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Stop',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      
      // New Chat button
      if (chat.currentThreadId != null && !chat.isStreaming)
        TextButton.icon(
          onPressed: chat.startNewConversation,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Chat'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withValues(alpha: 0.7),
          ),
        ),
    ],
  ),
),
```

#### Step 4.3: Update Stop Agent to Handle Streaming State

In `lib/state/chat_controller.dart`, enhance the stop method:

```dart
/// Stop the current agent execution
Future<void> stopCurrentAgent() async {
  if (currentThreadId == null || currentProjectId == null) {
    return;
  }

  try {
    await api.stopAgent(currentThreadId!, currentProjectId!);
    
    // Update states
    status = "Stopped by user";
    loading = false;
    isStreaming = false;
    
    // Add a message indicating the stop
    if (messages.isNotEmpty && messages.last.content.isEmpty) {
      messages.removeLast();
    }
    messages.add(ChatMessage.assistant("⏹️ Agent execution stopped by user"));
    
    notifyListeners();
  } catch (e) {
    print("Error stopping agent: $e");
    status = "Failed to stop";
    notifyListeners();
  }
}
```

---

## Testing Checklist

After implementing all features, test the following:

### Conversation History
- [ ] Create a new conversation
- [ ] Verify topic is extracted from first message
- [ ] Check sidebar shows topic correctly
- [ ] Verify topic is saved in Hive database
- [ ] Test loading old conversations

### File Type Selector
- [ ] Click folder icon
- [ ] Verify modal appears with all file types
- [ ] Test filtering by Images
- [ ] Test filtering by Documents
- [ ] Test filtering by Text files
- [ ] Test filtering by Audio
- [ ] Test filtering by Archives
- [ ] Test "All Files" option

### File Preview
- [ ] Upload files and get AI response with generated files
- [ ] Click on a generated file
- [ ] Verify preview dialog appears
- [ ] Test copy to clipboard functionality
- [ ] Test with different file types (HTML, JSON, TXT)
- [ ] Verify error handling for failed previews

### Stop Agent
- [ ] Start a conversation that triggers streaming
- [ ] Verify stop button appears during streaming
- [ ] Click stop button
- [ ] Verify agent stops execution
- [ ] Check that appropriate message is displayed
- [ ] Verify UI returns to normal state

---

## Common Issues and Solutions

### Issue 1: File Preview Not Working
**Solution**: Ensure `currentThreadId` and `currentProjectId` are not null when calling `getFile()`.

### Issue 2: Stop Button Not Appearing
**Solution**: Check that `isStreaming` flag is properly set to `true` during streaming and `false` when complete.

### Issue 3: Topics Not Saving
**Solution**: Verify Hive box is initialized and the `_extractTopic` method is being called before saving.

### Issue 4: File Type Filter Not Working
**Solution**: Ensure `allowedExtensions` parameter is correctly passed to `FilePicker.platform.pickFiles()`.

---

## Additional Enhancements (Optional)

### 1. Search Conversations
Add search functionality to filter conversations by topic in the sidebar.

### 2. Export Conversations
Allow users to export conversation history as JSON or Markdown.

### 3. File Download
Add download button alongside preview for generated files.

### 4. Batch File Operations
Allow selecting multiple files for preview or download.

### 5. File Type Icons in Preview
Show appropriate icons based on file type in the preview dialog.

---

## Conclusion

This implementation guide provides all the necessary code and steps to add the requested features. Follow each section carefully, test thoroughly, and refer to the troubleshooting section if you encounter issues.

For questions or issues, refer to:
- Flutter documentation: https://flutter.dev/docs
- Helium API documentation: `HELIUM_PUBLIC_API_DOCUMENTATION.md`
- File picker package: https://pub.dev/packages/file_picker

Good luck with the implementation!
