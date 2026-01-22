import 'package:flutter/material.dart';
import 'package:helium/services/helium_api.dart';
import 'package:helium/models/chat_message.dart';
import 'package:hive/hive.dart';
import 'package:file_picker/file_picker.dart';

class ChatController extends ChangeNotifier {
  final HeliumApi api = HeliumApi();
  final Box threadsBox = Hive.box('threads');

  List<ChatMessage> messages = [];
  bool loading = false;
  bool isStreaming = false;
  String? currentThreadId;
  String? currentProjectId;
  String? currentAgentRunId;
  String status = "";
  String streamingContent = "";

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

  Future<void> sendPrompt(String prompt, {List<PlatformFile>? files}) async {
    if (prompt.trim().isEmpty && (files == null || files.isEmpty)) return;

    // Add user message
    final displayPrompt = prompt.trim().isEmpty ? "[Files attached]" : prompt;
    messages.add(ChatMessage.user(displayPrompt));
    loading = true;
    streamingContent = "";
    status = "Sending...";
    notifyListeners();

    try {
      // Check if we're in an existing conversation
      if (currentThreadId != null && currentProjectId != null) {
        // Use follow-up API
        await _sendFollowUp(prompt, files: files);
      } else {
        // Create new conversation
        await _createNewConversation(prompt, files: files);
      }
    } catch (e) {
      messages.add(ChatMessage.assistant("❌ Error: $e"));
      status = "Failed";
    }

    loading = false;
    notifyListeners();
  }

  Future<void> _createNewConversation(String prompt, {List<PlatformFile>? files}) async {
    status = "Creating conversation...";
    notifyListeners();

    final task = await api.createTask(prompt, files: files);

    if (task['success'] == false || task.containsKey('detail')) {
      messages.add(ChatMessage.assistant("❌ Error: ${task['detail']}"));
      status = "";
      loading = false;
      notifyListeners();
      return;
    }

    final threadId = task["thread_id"];
    final projectId = task["project_id"];
    final agentRunId = task["agent_run_id"];

    if (threadId == null || projectId == null) {
      messages.add(ChatMessage.assistant("❌ Error: Invalid API response - missing thread or project ID"));
      status = "";
      loading = false;
      notifyListeners();
      return;
    }

    currentThreadId = threadId;
    currentProjectId = projectId;
    currentAgentRunId = agentRunId;

    // Save to history with extracted topic
    final topic = _extractTopic(prompt.isEmpty ? "[Files attached]" : prompt);
    threadsBox.add({
      "prompt": prompt.isEmpty ? "[Files attached]" : prompt,
      "topic": topic,
      "thread_id": threadId,
      "project_id": projectId,
      "agent_run_id": agentRunId,
      "timestamp": DateTime.now().toIso8601String(),
      "message_count": messages.length,
    });

    // Stream the response
    await _streamResponse(threadId, projectId);
  }

  Future<void> _sendFollowUp(String prompt, {List<PlatformFile>? files}) async {
    status = "Sending follow-up...";
    notifyListeners();

    final result = await api.continueConversation(
      currentThreadId!,
      currentProjectId!,
      prompt,
      files: files,
    );

    if (result['success'] == false || result.containsKey('detail')) {
      final errorDetail = result['detail'] ?? 'Unknown error';
      
      // Check if it's a thread error
      if (errorDetail.toString().toLowerCase().contains('thread')) {
        messages.add(ChatMessage.assistant(
          "❌ Error: This conversation is no longer valid.\n\n"
          "The thread may have been deleted or expired. Please start a new conversation."
        ));
        
        // Clean up invalid thread
        if (currentThreadId != null) {
          await deleteConversation(currentThreadId!);
        }
        
        // Reset state
        currentThreadId = null;
        currentProjectId = null;
        currentAgentRunId = null;
      } else {
        messages.add(ChatMessage.assistant("❌ Error: $errorDetail"));
      }
      
      status = "";
      loading = false;
      notifyListeners();
      return;
    }

    // Stream the new response
    await _streamResponse(currentThreadId!, currentProjectId!);
  }

  /// Clean markdown symbols from text before streaming
  String _cleanMarkdownSymbols(String text) {
    if (text.isEmpty) return text;
    
    String cleaned = text;
    
    // Remove bold markers (**text** or __text__)
    cleaned = cleaned.replaceAll(RegExp(r'\*\*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'__'), '');
    
    // Remove italic markers (*text* or _text_) - but be careful with single asterisks
    // Only remove if they're paired
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<!\*)\*(?!\*)([^\*]+)\*(?!\*)'),
      (match) => match.group(1) ?? '',
    );
    
    // Remove heading markers (# ## ###) at the start of lines
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'^#{1,6}\s+', multiLine: true),
      (match) => '',
    );
    
    // Also handle hashtags that might appear mid-line after newline
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\n#{1,6}\s+'),
      (match) => '\n',
    );
    
    return cleaned;
  }

  Future<void> _streamResponse(String threadId, String projectId) async {
    status = "Generating response...";
    streamingContent = "";
    isStreaming = true;
    
    // Add empty assistant message placeholder for streaming
    messages.add(ChatMessage.assistant(""));
    final messageIndex = messages.length - 1;
    notifyListeners();

    bool hasContent = false;
    bool hasFiles = false;
    bool hasCode = false;
    List<dynamic>? files;
    List<dynamic>? codeBlocks;
    String currentStatus = "running";
    String fullResponse = ""; // Store complete response

    try {
      // Collect the full response first
      await for (final event in api.streamResponse(threadId, projectId)) {
        if (event['type'] == 'content') {
          final content = event['content'];
          if (content != null && content.toString().isNotEmpty) {
            fullResponse += content.toString();
            hasContent = true;
          }
        } else if (event['type'] == 'status') {
          currentStatus = event['status'] ?? 'running';
          status = currentStatus.replaceAll('_', ' ').toUpperCase();
          
          if (currentStatus == 'completed') {
            break;
          }
        } else if (event['type'] == 'error') {
          final errorDetail = event['detail']?.toString() ?? 'Stream error';
          
          // Check if it's a thread error
          if (errorDetail.toLowerCase().contains('thread')) {
            messages[messageIndex] = ChatMessage.assistant(
              "❌ Error: This conversation is no longer valid.\n\n"
              "The thread may have been deleted or expired. Please start a new conversation."
            );
            
            // Clean up invalid thread
            await deleteConversation(threadId);
            currentThreadId = null;
            currentProjectId = null;
            currentAgentRunId = null;
          } else {
            messages[messageIndex] = ChatMessage.assistant("❌ Stream error: $errorDetail");
          }
          
          notifyListeners();
          hasContent = true;
          isStreaming = false;
          loading = false;
          return;
        }
      }
      
      print("Stream completed. Full response length: ${fullResponse.length} chars");
    } catch (e) {
      print("Streaming error: $e");
      
      final errorMsg = e.toString();
      if (errorMsg.toLowerCase().contains('thread')) {
        messages[messageIndex] = ChatMessage.assistant(
          "❌ Error: This conversation is no longer valid.\n\n"
          "The thread may have been deleted or expired. Please start a new conversation."
        );
        
        // Clean up invalid thread
        await deleteConversation(threadId);
        currentThreadId = null;
        currentProjectId = null;
        currentAgentRunId = null;
      } else {
        messages[messageIndex] = ChatMessage.assistant("❌ Streaming failed: $e");
      }
      
      notifyListeners();
      isStreaming = false;
      loading = false;
      return;
    }

    // Fallback to polling if streaming didn't work or no content received
    if (!hasContent || fullResponse.isEmpty) {
      print("Falling back to polling...");
      status = "Fetching response...";
      notifyListeners();

      final response = await api.getResponseWithRetry(threadId, projectId);

      if (response['success'] == false || response.containsKey('detail')) {
        final errorDetail = response['detail']?.toString() ?? 'Failed to get response';
        
        if (errorDetail.toLowerCase().contains('thread')) {
          messages[messageIndex] = ChatMessage.assistant(
            "❌ Error: This conversation is no longer valid.\n\n"
            "The thread may have been deleted or expired. Please start a new conversation."
          );
          
          // Clean up invalid thread
          await deleteConversation(threadId);
          currentThreadId = null;
          currentProjectId = null;
          currentAgentRunId = null;
        } else {
          messages[messageIndex] = ChatMessage.assistant("❌ Error: $errorDetail");
        }
        
        notifyListeners();
        isStreaming = false;
        loading = false;
        return;
      }

      if (response['response'] != null) {
        fullResponse = response['response']['content'] ?? '✅ Task completed!';
        hasFiles = response['has_files'] == true;
        hasCode = response['has_code'] == true;
        files = response['files'];
        codeBlocks = response['code_blocks'];
        hasContent = true;
      } else {
        messages[messageIndex] = ChatMessage.assistant("❌ Error: No response received");
        notifyListeners();
        isStreaming = false;
        loading = false;
        return;
      }
    }

    // Now animate the typing effect character by character
    if (hasContent && fullResponse.isNotEmpty) {
      status = "Typing...";
      streamingContent = "";
      
      // Clean markdown symbols before streaming
      final cleanedResponse = _cleanMarkdownSymbols(fullResponse);
      
      // Much faster typing animation - show chunks instead of single characters
      const int chunkSize = 5; // Show 5 characters at a time
      const int delayMs = 15; // Faster delay
      
      for (int i = 0; i < cleanedResponse.length; i += chunkSize) {
        final end = (i + chunkSize < cleanedResponse.length) 
            ? i + chunkSize 
            : cleanedResponse.length;
        streamingContent += cleanedResponse.substring(i, end);
        
        messages[messageIndex] = ChatMessage.assistant(
          streamingContent,
          hasFiles: hasFiles,
          hasCode: hasCode,
          files: files,
          codeBlocks: codeBlocks,
        );
        
        notifyListeners();
        
        // Add small delay for typing effect
        await Future.delayed(const Duration(milliseconds: delayMs));
      }
      
      // Add file count message if files were generated
      if (hasFiles && files != null && files.isNotEmpty) {
        final fileCount = files.length;
        messages.add(ChatMessage.assistant("📁 Generated $fileCount file(s)"));
        notifyListeners();
      }
    }

    status = "Completed";
    streamingContent = "";
    isStreaming = false;
    loading = false;
    notifyListeners();
  }

  /// Start a new conversation
  void startNewConversation() {
    messages.clear();
    currentThreadId = null;
    currentProjectId = null;
    currentAgentRunId = null;
    status = "";
    streamingContent = "";
    isStreaming = false;
    notifyListeners();
  }

  /// Load conversation history from API and store locally
  Future<void> loadConversationHistory(String threadId, String projectId) async {
    try {
      loading = true;
      status = "Loading conversation...";
      notifyListeners();

      final history = await api.getHistory(threadId, projectId);
      
      // Check for errors
      if (history['success'] == false || history.containsKey('detail')) {
        // Thread doesn't exist or was deleted
        messages.clear();
        messages.add(ChatMessage.assistant(
          "❌ Error: ${history['detail'] ?? 'Could not load conversation'}\n\n"
          "This conversation may have been deleted or is no longer available."
        ));
        
        // Remove from local storage
        await deleteConversation(threadId);
        
        // Reset state
        currentThreadId = null;
        currentProjectId = null;
        currentAgentRunId = null;
        loading = false;
        status = "";
        notifyListeners();
        return;
      }
      
      if (history['messages'] != null) {
        // Clear current messages
        messages.clear();
        
        // Convert API messages to ChatMessage objects
        for (final msg in history['messages']) {
          final role = msg['role'];
          final content = msg['content'] ?? '';
          
          if (role == 'user') {
            messages.add(ChatMessage.user(content));
          } else if (role == 'assistant') {
            messages.add(ChatMessage.assistant(
              content,
              hasFiles: msg['has_files'] == true,
              hasCode: msg['has_code'] == true,
            ));
          }
        }
        
        // Update current thread info
        currentThreadId = threadId;
        currentProjectId = projectId;
        
        // Update in local Hive database
        final existingIndex = threadsBox.values.toList().indexWhere(
          (item) {
            final map = Map<String, dynamic>.from(item as Map);
            return map['thread_id'] == threadId;
          }
        );
        
        if (existingIndex != -1) {
          // Update existing entry
          final key = threadsBox.keyAt(existingIndex);
          final existing = Map<String, dynamic>.from(threadsBox.get(key) as Map);
          existing['message_count'] = messages.length;
          existing['last_updated'] = DateTime.now().toIso8601String();
          threadsBox.put(key, existing);
        }
        
        loading = false;
        status = "";
        notifyListeners();
      } else {
        // No messages found
        messages.clear();
        messages.add(ChatMessage.assistant(
          "This conversation appears to be empty or could not be loaded."
        ));
        loading = false;
        status = "";
        notifyListeners();
      }
    } catch (e) {
      print("Failed to load conversation history: $e");
      messages.clear();
      messages.add(ChatMessage.assistant(
        "❌ Error loading conversation: $e\n\n"
        "Please try starting a new conversation."
      ));
      
      // Clean up invalid thread
      await deleteConversation(threadId);
      
      currentThreadId = null;
      currentProjectId = null;
      currentAgentRunId = null;
      loading = false;
      status = "";
      notifyListeners();
    }
  }

  /// Get locally stored conversation summaries
  List<Map<String, dynamic>> getLocalConversations() {
    return threadsBox.values
        .toList()
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Delete a conversation from local storage
  Future<void> deleteConversation(String threadId) async {
    final index = threadsBox.values.toList().indexWhere(
      (item) {
        final map = Map<String, dynamic>.from(item as Map);
        return map['thread_id'] == threadId;
      }
    );
    
    if (index != -1) {
      final key = threadsBox.keyAt(index);
      await threadsBox.delete(key);
      notifyListeners();
    }
  }

  /// Clear all local conversation history
  Future<void> clearAllHistory() async {
    await threadsBox.clear();
    notifyListeners();
  }

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

  List<Map<String, dynamic>> get history {
    return threadsBox.values
        .toList()
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
