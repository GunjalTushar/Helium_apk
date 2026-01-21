//HELIUM API - Complete Implementation

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HeliumApi {
  static const baseUrl = "https://api.he2.ai";
  static const int defaultTimeout = 300;
  static const int maxRetries = 3;

  // Use a getter to ensure the API key is loaded when accessed
  Map<String, String> get headers => {
    "X-API-Key": dotenv.env['HELIUM_API_KEY'] ?? '',
  };

  /// 1. Create Task (Quick Action)
  /// Creates and executes a task immediately using FormData
  Future<Map<String, dynamic>> createTask(
    String prompt, {
    String? agentId,
    String? modelName,
    bool enableThinking = false,
    String reasoningEffort = "low",
    bool enableContextManager = false,
    String source = "mobile",
    Map<String, dynamic>? metadata,
    bool showInRecentTasks = true,
    List<PlatformFile>? files, // Changed to PlatformFile for web support
  }) async {
    try {
      final req = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/api/v1/public/quick-action"),
      );

      req.headers.addAll(headers);
      
      // Add form fields
      if (prompt.isNotEmpty) {
        req.fields["prompt"] = prompt;
      }
      req.fields["source"] = source;
      req.fields["enable_thinking"] = enableThinking.toString();
      req.fields["reasoning_effort"] = reasoningEffort;
      req.fields["enable_context_manager"] = enableContextManager.toString();
      req.fields["show_in_recent_tasks"] = showInRecentTasks.toString();

      if (agentId != null) req.fields["agent_id"] = agentId;
      if (modelName != null) req.fields["model_name"] = modelName;
      if (metadata != null) req.fields["metadata"] = json.encode(metadata);

      // Add file uploads if provided
      if (files != null && files.isNotEmpty) {
        for (final file in files) {
          try {
            if (kIsWeb) {
              // On web, use bytes from PlatformFile
              if (file.bytes != null) {
                final multipartFile = http.MultipartFile.fromBytes(
                  'files',
                  file.bytes!,
                  filename: file.name,
                );
                req.files.add(multipartFile);
              }
            } else {
              // On mobile/desktop, use file path
              if (file.path != null) {
                final multipartFile = await http.MultipartFile.fromPath(
                  'files',
                  file.path!,
                  filename: file.name,
                );
                req.files.add(multipartFile);
              }
            }
          } catch (e) {
            print("Error adding file ${file.name}: $e");
          }
        }
      }

      final res = await req.send();
      final responseBody = await res.stream.bytesToString();
      
      if (res.statusCode != 200) {
        try {
          final responseData = json.decode(responseBody);
          return {
            "success": false,
            "detail": responseData["detail"] ?? "API Error: ${res.statusCode}"
          };
        } catch (e) {
          return {
            "success": false,
            "detail": "API Error: ${res.statusCode} - $responseBody"
          };
        }
      }

      final responseData = json.decode(responseBody);
      return responseData;
    } catch (e) {
      return {
        "success": false,
        "detail": "Network error: $e"
      };
    }
  }

  /// 2. Get Task Results (Polling)
  /// Fetches results from a completed or running task
  Future<Map<String, dynamic>> getResponse(
    String threadId,
    String projectId, {
    int timeout = defaultTimeout,
    bool includeFileContent = false,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final uri = Uri.parse(
        "$baseUrl/api/v1/public/threads/$threadId/response"
      ).replace(queryParameters: {
        "project_id": projectId,
        "timeout": timeout.toString(),
        "include_file_content": includeFileContent.toString(),
        "page": page.toString(),
        "page_size": pageSize.toString(),
      });

      final response = await http.get(uri, headers: headers);
      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        return {
          "success": false,
          "detail": responseData["detail"] ?? "API Error: ${response.statusCode}"
        };
      }

      return responseData;
    } catch (e) {
      return {
        "success": false,
        "detail": "Network error: $e"
      };
    }
  }

  /// 3. Stream Response (Real-time)
  /// Get live updates as the AI works
  Stream<Map<String, dynamic>> streamResponse(
    String threadId,
    String projectId,
  ) async* {
    try {
      final uri = Uri.parse(
        "$baseUrl/api/v1/public/threads/$threadId/response"
      ).replace(queryParameters: {
        "project_id": projectId,
        "realtime": "true",
        "timeout": "300",
      });

      print("🔴 Starting stream: $uri");

      final request = http.Request("GET", uri)..headers.addAll(headers);
      final response = await request.send();

      print("🔴 Stream response status: ${response.statusCode}");

      // Check if response is successful
      if (response.statusCode != 200) {
        yield {
          "type": "error",
          "detail": "HTTP ${response.statusCode}"
        };
        return;
      }

      int eventCount = 0;
      // Process the stream line by line
      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        
        // Skip empty lines
        if (line.trim().isEmpty) continue;
        
        // Parse SSE format: "data: {...}" or just the event type
        if (line.startsWith('data: ')) {
          try {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isEmpty) continue;
            
            final data = json.decode(jsonStr);
            eventCount++;
            
            // Handle different response formats
            if (data.containsKey('role') && data['role'] == 'assistant') {
              // This is a content chunk
              final content = data['content'];
              if (content != null && content.toString().isNotEmpty) {
                print("🔴 Stream event #$eventCount: content chunk (${content.toString().length} chars)");
                yield {
                  "type": "content",
                  "content": content,
                };
              }
            } else if (data.containsKey('status_type')) {
              // This is a status update
              final statusType = data['status_type'];
              print("🔴 Stream event #$eventCount: status - $statusType");
              
              if (statusType == 'finish' || statusType == 'thread_run_end') {
                yield {
                  "type": "status",
                  "status": "completed",
                };
              } else {
                yield {
                  "type": "status",
                  "status": statusType ?? "running",
                };
              }
            } else if (data.containsKey('type')) {
              // Standard format with type field
              print("🔴 Stream event #$eventCount: ${data['type']}");
              yield data;
            }
            
          } catch (e) {
            print("🔴 Failed to parse line: $line - Error: $e");
            // Skip malformed JSON lines
            continue;
          }
        } else if (line.startsWith('event:')) {
          // Handle event type lines
          continue;
        }
      }
      
      print("🔴 Stream ended. Total events: $eventCount");
    } catch (e) {
      print("🔴 Stream error: $e");
      yield {
        "type": "error",
        "detail": "Stream error: $e"
      };
    }
  }

  /// 4. Continue Conversation (Follow-up)
  /// Add a follow-up message to an existing conversation using FormData
  Future<Map<String, dynamic>> continueConversation(
    String threadId,
    String projectId,
    String prompt, {
    List<PlatformFile>? files, // Changed to PlatformFile for web support
  }) async {
    try {
      final req = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/api/v1/public/threads/$threadId/response")
            .replace(queryParameters: {"project_id": projectId}),
      );

      req.headers.addAll(headers);
      
      // Add prompt if provided
      if (prompt.isNotEmpty) {
        req.fields["prompt"] = prompt;
      }

      // Add file uploads if provided
      if (files != null && files.isNotEmpty) {
        for (final file in files) {
          try {
            if (kIsWeb) {
              // On web, use bytes from PlatformFile
              if (file.bytes != null) {
                final multipartFile = http.MultipartFile.fromBytes(
                  'files',
                  file.bytes!,
                  filename: file.name,
                );
                req.files.add(multipartFile);
              }
            } else {
              // On mobile/desktop, use file path
              if (file.path != null) {
                final multipartFile = await http.MultipartFile.fromPath(
                  'files',
                  file.path!,
                  filename: file.name,
                );
                req.files.add(multipartFile);
              }
            }
          } catch (e) {
            print("Error adding file ${file.name}: $e");
          }
        }
      }

      final res = await req.send();
      final responseBody = await res.stream.bytesToString();
      
      if (res.statusCode != 200) {
        try {
          final responseData = json.decode(responseBody);
          return {
            "success": false,
            "detail": responseData["detail"] ?? "API Error: ${res.statusCode}"
          };
        } catch (e) {
          return {
            "success": false,
            "detail": "API Error: ${res.statusCode} - $responseBody"
          };
        }
      }

      final responseData = json.decode(responseBody);
      return responseData;
    } catch (e) {
      return {
        "success": false,
        "detail": "Network error: $e"
      };
    }
  }

  /// 5. Stop Agent
  /// Stop a running task
  Future<Map<String, dynamic>> stopAgent(
    String threadId,
    String projectId,
  ) async {
    try {
      final uri = Uri.parse(
        "$baseUrl/api/v1/public/threads/$threadId/agent/stop"
      ).replace(queryParameters: {
        "project_id": projectId,
      });

      final response = await http.post(uri, headers: headers);
      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        return {
          "success": false,
          "detail": responseData["detail"] ?? "API Error: ${response.statusCode}"
        };
      }

      return responseData;
    } catch (e) {
      return {
        "success": false,
        "detail": "Network error: $e"
      };
    }
  }

  /// 6. Get Conversation History
  /// Retrieve the complete conversation history
  Future<Map<String, dynamic>> getHistory(
    String threadId,
    String projectId, {
    int page = 1,
    int pageSize = 100,
    bool includeFileContent = false,
    bool includeStatusMessages = false,
    bool compact = false,
  }) async {
    try {
      final uri = Uri.parse(
        "$baseUrl/api/v1/public/threads/$threadId/history"
      ).replace(queryParameters: {
        "project_id": projectId,
        "page": page.toString(),
        "page_size": pageSize.toString(),
        "include_file_content": includeFileContent.toString(),
        "include_status_messages": includeStatusMessages.toString(),
        "compact": compact.toString(),
      });

      final response = await http.get(uri, headers: headers);
      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        return {
          "success": false,
          "detail": responseData["detail"] ?? "API Error: ${response.statusCode}"
        };
      }

      return responseData;
    } catch (e) {
      return {
        "success": false,
        "detail": "Network error: $e"
      };
    }
  }

  /// 7. List Thread Files
  /// Get a list of all files generated in a thread
  Future<Map<String, dynamic>> listFiles(
    String threadId,
    String projectId, {
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final uri = Uri.parse(
        "$baseUrl/api/v1/public/threads/$threadId/files"
      ).replace(queryParameters: {
        "project_id": projectId,
        "page": page.toString(),
        "page_size": pageSize.toString(),
      });

      final response = await http.get(uri, headers: headers);
      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        return {
          "success": false,
          "detail": responseData["detail"] ?? "API Error: ${response.statusCode}"
        };
      }

      return responseData;
    } catch (e) {
      return {
        "success": false,
        "detail": "Network error: $e"
      };
    }
  }

  /// 8. Get File Content
  /// Download a specific file
  Future<Map<String, dynamic>> getFile(
    String fileId,
    String threadId,
    String projectId, {
    bool download = false,
  }) async {
    try {
      final uri = Uri.parse(
        "$baseUrl/api/v1/public/files/$fileId"
      ).replace(queryParameters: {
        "project_id": projectId,
        "thread_id": threadId,
        "download": download.toString(),
      });

      final response = await http.get(uri, headers: headers);

      if (response.statusCode != 200) {
        final responseData = json.decode(response.body);
        return {
          "success": false,
          "detail": responseData["detail"] ?? "API Error: ${response.statusCode}"
        };
      }

      if (download) {
        // Return raw bytes for download
        return {
          "success": true,
          "bytes": response.bodyBytes,
        };
      } else {
        // Return JSON with metadata
        final responseData = json.decode(response.body);
        return responseData;
      }
    } catch (e) {
      return {
        "success": false,
        "detail": "Network error: $e"
      };
    }
  }

  /// Retry mechanism for critical operations
  Future<Map<String, dynamic>> _retryOperation(
    Future<Map<String, dynamic>> Function() operation, {
    int maxRetries = maxRetries,
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        final result = await operation();
        if (result['success'] != false) {
          return result;
        }
        attempts++;
        if (attempts < maxRetries) {
          await Future.delayed(Duration(seconds: attempts * 2));
        }
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          return {
            "success": false,
            "detail": "Max retries exceeded: $e"
          };
        }
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    return {
      "success": false,
      "detail": "Operation failed after $maxRetries attempts"
    };
  }

  /// Create task with retry
  Future<Map<String, dynamic>> createTaskWithRetry(String prompt) async {
    return _retryOperation(() => createTask(prompt));
  }

  /// Get response with retry
  Future<Map<String, dynamic>> getResponseWithRetry(
    String threadId,
    String projectId,
  ) async {
    return _retryOperation(() => getResponse(threadId, projectId));
  }
}
