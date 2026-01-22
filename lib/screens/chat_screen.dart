import 'package:flutter/material.dart';
import 'package:helium/state/chat_controller.dart';
import 'package:helium/widgets/chat_input.dart';
import 'package:helium/widgets/sidebar.dart';
import 'package:helium/widgets/message_bubble.dart';
import 'package:helium/widgets/landing_page.dart';
import 'package:helium/widgets/files_list_dialog.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _userScrolledUp = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Listen to scroll events to detect if user scrolled up
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        // If user is more than 100 pixels from bottom, they've scrolled up
        setState(() {
          _userScrolledUp = (maxScroll - currentScroll) > 100;
        });
      }
    });
  }

  void _scrollToBottom({bool force = false}) {
    if (_scrollController.hasClients) {
      // Only auto-scroll if user hasn't scrolled up or if forced
      if (force || !_userScrolledUp) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();

    // Auto-scroll when streaming new content
    if (chat.isStreaming && chat.messages.isNotEmpty) {
      _scrollToBottom(force: false);
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: const Color(0xFF1A1A1A),
        child: SafeArea(
          child: Column(
            children: [
              // Drawer header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: chat.startNewConversation,
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      label: const Text('New Chat', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search chat history...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const Divider(color: Colors.white24),
              // Chat history list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    if (chat.currentThreadId != null)
                      ListTile(
                        leading: const Icon(Icons.chat_bubble_outline, color: Colors.white70),
                        title: const Text(
                          'Current Chat',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          chat.messages.isNotEmpty 
                              ? () {
                                  // Find first user message
                                  final firstUserMsg = chat.messages.firstWhere(
                                    (msg) => msg.isUser,
                                    orElse: () => chat.messages.first,
                                  );
                                  final content = firstUserMsg.content;
                                  return content.length > 50
                                      ? '${content.substring(0, 50)}...'
                                      : content;
                                }()
                              : 'Active conversation',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        selected: true,
                        selectedTileColor: Colors.white.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    // Add more chat history items here
                  ],
                ),
              ),
              // Settings/Files at bottom
              const Divider(color: Colors.white24),
              if (chat.currentThreadId != null)
                ListTile(
                  leading: const Icon(Icons.folder_outlined, color: Colors.white70),
                  title: const Text('Files', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => const FilesListDialog(),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      body: chat.messages.isEmpty && !chat.loading
          ? LandingPage(onSend: (prompt, {files}) => chat.sendPrompt(prompt, files: files))
          : Column(
                    children: [
                      // Header with menu button and title
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: SafeArea(
                          bottom: false,
                          child: Row(
                            children: [
                              // Menu button
                              IconButton(
                                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                                icon: const Icon(Icons.menu, color: Colors.white),
                                tooltip: 'Menu',
                              ),
                              // Title
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Helium',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              ),
                              // Action buttons
                              if (chat.currentThreadId != null && !chat.isStreaming)
                                IconButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => const FilesListDialog(),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.folder_outlined,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  tooltip: 'Files',
                                ),
                              if (chat.isStreaming)
                                const SizedBox(width: 48)
                              else
                                const SizedBox(width: 48), // Spacer to keep title centered
                            ],
                          ),
                        ),
                      ),
                      // Messages area
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(24),
                          itemCount: chat.messages.length,
                          itemBuilder: (context, index) {
                            // Check if this is the last message and streaming
                            final isLastMessage = index == chat.messages.length - 1;
                            final isStreamingMessage = isLastMessage && chat.isStreaming;
                            
                            return MessageBubble(
                              message: chat.messages[index],
                              isStreaming: isStreamingMessage,
                            );
                          },
                        ),
                      ),
                      // Input area
                      ChatInput(
                        onSend: chat.sendPrompt,
                        isStreaming: chat.isStreaming,
                        onStop: () async {
                          await chat.stopCurrentAgent();
                        },
                      ),
                    ],
                  ),
    );
  }
}
