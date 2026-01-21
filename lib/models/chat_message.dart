class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool hasFiles;
  final bool hasCode;
  final List<dynamic>? files;
  final List<dynamic>? codeBlocks;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.hasFiles = false,
    this.hasCode = false,
    this.files,
    this.codeBlocks,
  });

  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.assistant(String content, {
    bool hasFiles = false,
    bool hasCode = false,
    List<dynamic>? files,
    List<dynamic>? codeBlocks,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      hasFiles: hasFiles,
      hasCode: hasCode,
      files: files,
      codeBlocks: codeBlocks,
    );
  }
}
