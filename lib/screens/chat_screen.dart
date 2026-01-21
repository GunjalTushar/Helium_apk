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
        _userScrolledUp = (maxScroll - currentScroll) > 100;
      }
    });
  }

  void _scrollToBottom({bool force = false}) {
    if (_scrollController.hasClients && (force || !_userScrolledUp)) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();

    // Auto-scroll when new messages arrive (but not if user scrolled up)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chat.messages.isNotEmpty) {
        // Force scroll on new message, but respect user scroll during streaming
        final forceScroll = !chat.isStreaming;
        _scrollToBottom(force: forceScroll);
      }
    });

    return Scaffold(
      body: Row(
        children: [
          const SlidingSidebar(),
          Expanded(
            child: chat.messages.isEmpty && !chat.loading
                ? LandingPage(onSend: (prompt, {files}) => chat.sendPrompt(prompt, files: files))
                : Column(
                    children: [
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
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: TextButton.icon(
                                  onPressed: chat.startNewConversation,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('New Chat'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            
                            // Files button (top-right) with folder icon
                            if (chat.currentThreadId != null && !chat.isStreaming)
                              Container(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => const FilesListDialog(),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(20),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.folder,
                                                  size: 16,
                                                  color: Colors.white.withValues(alpha: 0.8),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Files',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white.withValues(alpha: 0.8),
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
                          ],
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
                      ChatInput(onSend: chat.sendPrompt),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
