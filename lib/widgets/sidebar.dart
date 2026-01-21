import 'package:flutter/material.dart';
import 'package:helium/state/chat_controller.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class SlidingSidebar extends StatefulWidget {
  const SlidingSidebar({super.key});

  @override
  State<SlidingSidebar> createState() => _SlidingSidebarState();
}

class _SlidingSidebarState extends State<SlidingSidebar> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _expandSidebar() {
    if (!_isExpanded) {
      setState(() {
        _isExpanded = true;
        _animationController.forward();
      });
    }
  }

  void _collapseSidebar() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _animationController.reverse();
      });
    }
  }

  String _generateSummary(String prompt) {
    // Generate a one-line summary from the prompt
    if (prompt.length <= 50) {
      return prompt;
    }
    return '${prompt.substring(0, 47)}...';
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final history = chat.getLocalConversations();

    return MouseRegion(
      onEnter: (_) => _expandSidebar(),
      onExit: (_) => _collapseSidebar(),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final width = 60 + (220 * _animation.value);
          
          return Container(
            width: width,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
            ),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Menu button
                    Container(
                      height: 60,
                      padding: const EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: _toggleSidebar,
                        child: Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.menu,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    
                    // Content
                    if (_animation.value > 0.3)
                      Expanded(
                        child: Opacity(
                          opacity: _animation.value,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Recent Chats",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ),
                                    if (history.isNotEmpty)
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.white.withValues(alpha: 0.6),
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Clear History'),
                                              content: const Text('Delete all conversation history?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          
                                          if (confirm == true) {
                                            await chat.clearAllHistory();
                                          }
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: history.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No conversations yet',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: history.length,
                                          itemBuilder: (context, index) {
                                            final item = history[history.length - 1 - index];
                                            final topic = item["topic"] ?? item["prompt"] ?? "Untitled";
                                            final threadId = item["thread_id"];
                                            final projectId = item["project_id"];
                                            final timestamp = _formatTimestamp(item["timestamp"]);
                                            final messageCount = item["message_count"] ?? 0;
                                            
                                            return GestureDetector(
                                              onTap: () async {
                                                if (threadId != null && projectId != null) {
                                                  await chat.loadConversationHistory(threadId, projectId);
                                                }
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: chat.currentThreadId == threadId
                                                      ? Colors.white.withValues(alpha: 0.15)
                                                      : Colors.white.withValues(alpha: 0.05),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      topic,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.white.withValues(alpha: 0.8),
                                                        fontWeight: chat.currentThreadId == threadId
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                    if (timestamp.isNotEmpty || messageCount > 0)
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 4),
                                                        child: Row(
                                                          children: [
                                                            if (messageCount > 0) ...[
                                                              Icon(
                                                                Icons.chat_bubble_outline,
                                                                size: 10,
                                                                color: Colors.white.withValues(alpha: 0.5),
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                '$messageCount',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors.white.withValues(alpha: 0.5),
                                                                ),
                                                              ),
                                                              const SizedBox(width: 8),
                                                            ],
                                                            if (timestamp.isNotEmpty)
                                                              Text(
                                                                timestamp,
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors.white.withValues(alpha: 0.5),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
