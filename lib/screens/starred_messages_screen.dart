import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/message.dart';
import '../theme/stitch_theme.dart';
import '../widgets/full_screen_image_viewer.dart';

class StarredMessagesScreen extends StatefulWidget {
  final String chatId;
  const StarredMessagesScreen({super.key, required this.chatId});

  @override
  State<StarredMessagesScreen> createState() => _StarredMessagesScreenState();
}

class _StarredMessagesScreenState extends State<StarredMessagesScreen> {
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final messages = chatProvider.getMessagesForChat(widget.chatId);
    final starredMessages = messages.where((m) => m.isStarred).toList();

    final filteredMessages = _searchQuery.isEmpty
        ? starredMessages
        : starredMessages
            .where((m) => m.text.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                          (m.fileName ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 48,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search starred messages...',
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text(
                'Starred Messages',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = "";
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          if (starredMessages.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'unstar_all') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: isDark ? StitchTheme.darkSurfaceContainerLow : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: const Text('Unstar all messages?'),
                      content: const Text('Are you sure you want to unstar all messages in this chat?'),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                        TextButton(
                          child: const Text('Unstar All', style: TextStyle(color: Colors.red)),
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && mounted) {
                    await chatProvider.unstarAllMessages(widget.chatId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All messages unstarred'), duration: Duration(seconds: 1)),
                      );
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'unstar_all',
                  child: Text('Unstar All', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: filteredMessages.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star_outline,
                      size: 64,
                      color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty
                          ? "No starred messages yet."
                          : "No matching starred messages.",
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: filteredMessages.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final msg = filteredMessages[index];
                  return _buildStarredMessageCard(context, msg, isDark, chatProvider);
                },
              ),
      ),
    );
  }

  Widget _buildStarredMessageCard(BuildContext context, Message msg, bool isDark, ChatProvider provider) {
    final isMe = msg.sender == 'user';
    final dateString = DateFormat('MMM d, yyyy').format(msg.timestamp);
    final timeString = DateFormat('h:mm a').format(msg.timestamp);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        if (msg.type == 'image') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenImageViewer(
                imagePath: msg.fileLocalPath,
                fileName: msg.fileName ?? "image.jpg",
                heroTag: "starred_screen_${msg.fileLocalPath ?? msg.id}",
              ),
            ),
          );
        } else if ((msg.type == 'pdf' || msg.type == 'document') && msg.fileLocalPath != null) {
          try {
            final file = File(msg.fileLocalPath!);
            if (!await file.exists()) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("File not found on this device.")),
                );
              }
              return;
            }
            await OpenFilex.open(msg.fileLocalPath!);
          } catch (e) {
            debugPrint("Error opening file: $e");
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Could not open this file type")),
              );
            }
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.only(top: 6, bottom: 8, left: 16, right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? StitchTheme.darkSurfaceContainerLowest : Colors.white,
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender pill and Unstar button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMe 
                        ? (isDark ? StitchTheme.primary.withValues(alpha: 0.2) : StitchTheme.primaryFixed)
                        : (isDark ? StitchTheme.secondary.withValues(alpha: 0.2) : StitchTheme.secondaryFixed),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isMe ? 'Me' : 'Memzy',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isMe 
                          ? (isDark ? StitchTheme.primaryFixedDim : StitchTheme.onPrimaryFixed)
                          : (isDark ? StitchTheme.secondaryFixedDim : StitchTheme.onSecondaryFixed),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.star, color: Colors.amber),
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    await provider.toggleStarMessage(msg.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message unstarred'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Message Content
            if (msg.type == 'image') ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: msg.fileLocalPath != null
                    ? Image.file(
                        File(msg.fileLocalPath!),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image, size: 32),
                          );
                        },
                      )
                    : Container(
                        height: 120,
                        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image, size: 32),
                      ),
              ),
              if (msg.text != "Sent an image") ...[
                const SizedBox(height: 8),
                Text(
                  msg.text,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ] else if (msg.type == 'pdf' || msg.type == 'document') ...[
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: msg.type == 'pdf' ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      msg.type == 'pdf' ? Icons.picture_as_pdf : Icons.description,
                      color: msg.type == 'pdf' ? Colors.red : Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.fileName ?? "Document",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          msg.fileSize != null
                              ? "${(msg.fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB • ${msg.type.toUpperCase()}"
                              : msg.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (msg.text != "Sent a document" && msg.text != "Sent a PDF") ...[
                const SizedBox(height: 8),
                Text(
                  msg.text,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ] else ...[
              Text(
                msg.text,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 8),

            // Date and Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateString,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  timeString,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
