# Quick Reference: Implementation Checklist

## 📋 Overview
This is a quick reference for implementing the 4 major features. See `IMPLEMENTATION_GUIDE.md` for detailed code.

---

## ✅ Feature 1: Enhanced Conversation History

**Goal**: Save conversations with auto-generated topics

**Files to Edit**:
1. `lib/state/chat_controller.dart` - Add `_extractTopic()` method
2. `lib/state/chat_controller.dart` - Update `_createNewConversation()` to save topic
3. `lib/widgets/sidebar.dart` - Display topics instead of full prompts

**Key Changes**:
- Extract first 50 chars or first sentence as topic
- Save topic in Hive: `"topic": _extractTopic(prompt)`
- Display topic in sidebar with 2-line max

---

## ✅ Feature 2: Folder Icon with File Type Filters

**Goal**: Add folder icon that opens file type selector modal

**Files to Create**:
1. `lib/widgets/file_type_selector.dart` - New modal widget

**Files to Edit**:
1. `lib/widgets/chat_input.dart` - Add folder button and filter logic
2. `lib/widgets/landing_page.dart` - Add folder button and filter logic

**Key Components**:
- Folder icon button (top-right or before attach button)
- Modal with 6 file type options:
  - All Files
  - Images (png, jpg, jpeg, gif, svg, webp)
  - Documents (pdf, docx, xlsx, pptx, csv)
  - Text (txt, json, xml, md)
  - Audio (mp3, wav, flac, aac)
  - Archives (zip, rar, 7z)
- Filter file picker based on selection

---

## ✅ Feature 3: File Preview System

**Goal**: Preview generated files using Get File Content API

**Files to Create**:
1. `lib/widgets/file_preview_dialog.dart` - Preview modal

**Files to Edit**:
1. `lib/widgets/message_bubble.dart` - Add preview button to file chips
2. `lib/widgets/message_bubble.dart` - Add `_previewFile()` method

**Key Features**:
- Click file chip to preview
- Fetch content via `api.getFile()`
- Show in modal with copy button
- Support text-based files (HTML, JSON, TXT, etc.)

**API Call**:
```dart
final result = await chat.api.getFile(
  fileId,
  chat.currentThreadId!,
  chat.currentProjectId!,
);
```

---

## ✅ Feature 4: Stop Agent Button

**Goal**: Add stop button during streaming to halt execution

**Files to Edit**:
1. `lib/screens/chat_screen.dart` - Add stop button in header
2. `lib/state/chat_controller.dart` - Enhance `stopCurrentAgent()` method

**Key Features**:
- Show stop button only when `isStreaming == true`
- Red button with stop icon
- Call `chat.stopCurrentAgent()`
- Display "Agent stopped" message
- Hide button when not streaming

**Button Location**: Header, next to "Helium" title

---

## 🎯 Implementation Order (Recommended)

1. **Start with Feature 1** (Easiest)
   - Simple text extraction and storage
   - No new UI components

2. **Then Feature 4** (Medium)
   - Uses existing API method
   - Simple button addition

3. **Then Feature 2** (Medium-Hard)
   - Requires new modal widget
   - File picker integration

4. **Finally Feature 3** (Hardest)
   - Requires API integration
   - Complex preview dialog
   - Error handling

---

## 🔧 Key API Methods Already Implemented

These methods are already in `lib/services/helium_api.dart`:

```dart
// For Feature 3
Future<Map<String, dynamic>> getFile(
  String fileId,
  String threadId,
  String projectId,
  {bool download = false}
)

// For Feature 4
Future<Map<String, dynamic>> stopAgent(
  String threadId,
  String projectId,
)
```

---

## 📦 Required Packages

All packages are already installed:
- ✅ `file_picker` - For file selection
- ✅ `hive` - For local storage
- ✅ `provider` - For state management
- ✅ `http` - For API calls

---

## 🧪 Testing Commands

```bash
# Run on Chrome
flutter run -d chrome --web-port=8888

# Hot reload after changes
r

# Hot restart
R

# Check for errors
flutter analyze
```

---

## 📝 Important Notes

1. **Conversation Topics**: Extracted from first user message, max 50 chars
2. **File Types**: Must match API documentation exactly
3. **File Preview**: Only works for text-based files (HTML, JSON, TXT, etc.)
4. **Stop Agent**: Only visible during streaming (`isStreaming == true`)
5. **Error Handling**: Always check for null values before API calls

---

## 🚀 Quick Start

1. Read `IMPLEMENTATION_GUIDE.md` for detailed code
2. Implement features in recommended order
3. Test each feature before moving to next
4. Use hot reload (`r`) to see changes quickly
5. Check console for errors

---

## 📞 Need Help?

- **Detailed Code**: See `IMPLEMENTATION_GUIDE.md`
- **API Reference**: See `HELIUM_PUBLIC_API_DOCUMENTATION.md`
- **Current Code**: Check existing files for patterns
- **Flutter Docs**: https://flutter.dev/docs

---

## ✨ Expected Results

After implementation:

1. **Sidebar**: Shows conversation topics (not full prompts)
2. **Folder Icon**: Opens file type selector modal
3. **File Chips**: Clickable to preview content
4. **Stop Button**: Appears during streaming, stops agent

---

Good luck! 🎉
