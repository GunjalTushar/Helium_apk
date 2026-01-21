# Real-Time Streaming Implementation

## Overview
The Helium API integration now supports real-time streaming with ChatGPT-like sequential response loading, plus file upload capabilities.

## What Was Implemented

### 1. API Service (`lib/services/helium_api.dart`)
- ✅ Passing `realtime=true` parameter for streaming
- ✅ Properly parsing SSE (Server-Sent Events) format
- ✅ Added debug logging to track stream events
- ✅ Handling multiple event formats:
  - `{"role": "assistant", "content": "..."}` - Content chunks
  - `{"status_type": "finish"}` - Status updates
  - `{"type": "content", "content": "..."}` - Standard format
  - `{"type": "status", "status": "..."}` - Standard status
- ✅ **File Upload Support**: Added `filePaths` parameter to `createTask()` and `continueConversation()`

### 2. Chat Controller (`lib/state/chat_controller.dart`)
**Optimizations Made:**
- ✅ Pre-create empty assistant message placeholder before streaming starts
- ✅ Update message in-place (by index) instead of checking last message
- ✅ Call `notifyListeners()` after each content chunk for immediate UI update
- ✅ Added `isStreaming` state flag for UI feedback
- ✅ Added chunk counter for debugging
- ✅ Improved fallback logic when streaming fails
- ✅ Better error handling with specific error messages

### 3. Message Bubble Widget (`lib/widgets/message_bubble.dart`)
**New Features:**
- ✅ Animated typing cursor that blinks when streaming
- ✅ Better text formatting with improved line height (1.6) and letter spacing
- ✅ Enhanced file and code block indicators with borders
- ✅ Proper pluralization for file/code counts
- ✅ Fixed deprecated `withOpacity` calls (now using `withValues`)

### 4. How It Works

**Flow:**
1. User sends prompt → Quick Action API creates task
2. Get thread_id and project_id from response
3. Call GET API with `realtime=true` parameter
4. Server responds with SSE stream in multiple formats:
   ```
   data: {"role": "assistant", "content": "First chunk..."}
   data: {"role": "assistant", "content": "Second chunk..."}
   data: {"status_type": "finish", "finish_reason": "stop"}
   ```
5. Each content chunk immediately updates the UI
6. User sees text appearing with animated cursor (like ChatGPT)

### 5. File Upload Feature

**API Methods Updated:**

#### Create Task with Files
```dart
await api.createTask(
  "Analyze this image and create a website",
  filePaths: ['/path/to/image.png', '/path/to/document.pdf'],
);
```

#### Continue Conversation with Files
```dart
await api.continueConversation(
  threadId,
  projectId,
  "Analyze this additional file",
  filePaths: ['/path/to/document.pdf'],
);
```

**Supported File Types:**
- Images: .png, .jpg, .jpeg, .gif, .svg, .webp
- Documents: .pdf, .docx, .xlsx, .pptx, .csv
- Text: .txt, .json, .xml, .md
- Audio: .mp3, .wav, .flac, .aac
- Archives: .zip, .rar, .7z

**Limits:**
- Max 10 files per request
- Max 50MB per file
- Max 200MB total

**Response Format:**
```json
{
  "success": true,
  "project_id": "proj_123",
  "thread_id": "thread_456",
  "agent_run_id": "run_789",
  "message": "Task created and execution started"
}
```

## Testing

To verify streaming is working:
1. Open browser console (F12)
2. Send a prompt
3. Look for debug logs:
   ```
   🔴 Starting stream: https://api.he2.ai/...
   🔴 Stream response status: 200
   🔴 Stream event #1: content chunk (50 chars)
   🔴 Stream event #2: content chunk (45 chars)
   🔴 Stream event #3: status - finish
   🔴 Stream ended. Total events: 3
   ```

## Fallback Mechanism

If streaming fails (network issues, API changes, etc.):
- Automatically falls back to polling
- Fetches complete response using GET API without realtime
- Displays full response at once
- User still gets their result, just not in real-time

## Performance

- Each content chunk triggers a UI rebuild via `notifyListeners()`
- Message is updated in-place (no list manipulation)
- Efficient for long responses with many chunks
- Smooth scrolling maintained via auto-scroll in ChatScreen
- Animated cursor provides visual feedback during streaming

## UI Enhancements

### Typing Animation
- Blinking cursor appears at the end of streaming text
- Cursor fades in/out smoothly (530ms cycle)
- Automatically disappears when streaming completes

### Message Formatting
- Improved line height (1.6) for better readability
- Letter spacing (0.2) for cleaner text appearance
- Better padding and margins
- Enhanced glassmorphism effect

### File Indicators
- Shows file count with proper pluralization
- Shows code block count
- Bordered badges for better visibility
- Icons for visual clarity

## API Documentation Reference

From `HELIUM_PUBLIC_API_DOCUMENTATION.md`:

**Endpoint:** `GET /api/v1/public/threads/{thread_id}/response`

**Parameters:**
- `project_id` (required)
- `realtime=true` (enables streaming)
- `timeout=300` (max wait time)

**Response Formats:**
```
data: {"role": "assistant", "content": "chunk..."}
data: {"status_type": "finish", "finish_reason": "stop"}
```

**File Upload Endpoint:** `POST /api/v1/public/quick-action`

**Parameters:**
- `prompt` (optional): Task description
- `files` (optional): File uploads via multipart/form-data
- `source` (optional): Platform identifier

## Next Steps

To add file upload UI:
1. Add file picker button to chat input
2. Store selected files in chat controller
3. Pass file paths when calling `sendPrompt()`
4. Display file previews before sending
5. Show upload progress indicator

## Local Storage Features

### Conversation History Storage
The app now stores conversation history locally using Hive database:

**Features:**
- ✅ Automatic storage of all conversations
- ✅ Load past conversations from sidebar
- ✅ Message count tracking
- ✅ Timestamp with relative time display (e.g., "2h ago")
- ✅ Active conversation highlighting
- ✅ Clear all history option
- ✅ Sync with API using Get Conversation History endpoint

**API Integration:**
```dart
// Load conversation from API and store locally
await chat.loadConversationHistory(threadId, projectId);

// Get locally stored conversations
final conversations = chat.getLocalConversations();

// Delete specific conversation
await chat.deleteConversation(threadId);

// Clear all history
await chat.clearAllHistory();
```

**Storage Format:**
```dart
{
  "thread_id": "thread_456",
  "project_id": "proj_123",
  "prompt": "Create a website",
  "timestamp": "2024-01-01T10:00:00Z",
  "message_count": 5,
  "last_updated": "2024-01-01T10:05:00Z"
}
```

**Sidebar Features:**
- Click on any conversation to load it
- Shows message count and time ago
- Highlights currently active conversation
- Delete all history with confirmation dialog
- Smooth animations and hover effects
