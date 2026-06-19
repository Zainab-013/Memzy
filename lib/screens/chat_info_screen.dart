import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/reminder.dart';
import '../theme/stitch_theme.dart';
import '../widgets/full_screen_image_viewer.dart';
import 'chat_attachments_screen.dart';
import 'starred_messages_screen.dart';
import '../widgets/passcode_view.dart';

class ChatInfoScreen extends StatefulWidget {
  final String chatId;
  const ChatInfoScreen({super.key, required this.chatId});

  @override
  State<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends State<ChatInfoScreen> {
  // Regex to detect links in messages
  final RegExp _urlRegex = RegExp(
    r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
    caseSensitive: false,
  );

  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleChatLock(BuildContext context, Chat chat, ChatProvider provider) {
    if (chat.isLocked) {
      // Unlock flow
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PasscodeView(
            mode: 'verify',
            title: "Unlock Chat",
            onSuccess: (passcode) async {
              Navigator.pop(context);
              await provider.toggleLockChat(chat.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat unlocked successfully')),
                );
              }
            },
            onCancel: () => Navigator.pop(context),
          ),
        ),
      );
    } else {
      // Lock flow
      if (!provider.isPasscodeSet) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PasscodeView(
              mode: 'create',
              title: "Set Passcode",
              onSuccess: (passcode) async {
                await provider.setPasscode(passcode);
                await provider.toggleLockChat(chat.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passcode set and chat locked')),
                  );
                }
              },
              onCancel: () => Navigator.pop(context),
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PasscodeView(
              mode: 'verify',
              title: "Lock Chat",
              onSuccess: (passcode) async {
                Navigator.pop(context);
                await provider.toggleLockChat(chat.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat locked successfully')),
                  );
                }
              },
              onCancel: () => Navigator.pop(context),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final chatList = chatProvider.chats.where((c) => c.id == widget.chatId).toList();
    if (chatList.isEmpty) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final chat = chatList.first;
    final messages = chatProvider.getMessagesForChat(widget.chatId);
    final chatReminders = chatProvider.reminders
        .where((r) => r.chatId == widget.chatId && !r.isCompleted)
        .where((r) {
          if (_searchQuery.isEmpty) return true;
          return r.content.toLowerCase().contains(_searchQuery.toLowerCase());
        })
        .toList();

    // Group media files
    final mediaMessages = messages.where((m) => m.type == 'image').toList();
    final documentMessages = messages.where((m) => m.type == 'pdf' || m.type == 'document').toList();
    final allAttachments = [...mediaMessages, ...documentMessages].where((m) {
      if (_searchQuery.isEmpty) return true;
      return (m.fileName ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Extract links from text messages
    final List<Map<String, String>> savedLinks = [];
    for (var m in messages) {
      if (m.type == 'text' && _urlRegex.hasMatch(m.text)) {
        final matches = _urlRegex.allMatches(m.text);
        for (var match in matches) {
          final url = match.group(0)!;
          // Create a neat title by stripping URL or taking preceding text
          String title = m.text.replaceFirst(url, '').trim();
          if (title.isEmpty) {
            title = "Shared Link";
          }
          if (_searchQuery.isEmpty || 
              title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
              url.toLowerCase().contains(_searchQuery.toLowerCase())) {
            savedLinks.add({'title': title, 'url': url});
          }
        }
      }
    }

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
                  hintText: 'Search chat info...',
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
            : const Text('Chat Info'),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'clear') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Chat Logs?'),
                    content: const Text(
                        'Are you sure you want to delete all messages and reminders inside this chat?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      TextButton(
                        child: const Text('Clear', style: TextStyle(color: Colors.red)),
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await chatProvider.clearChatLogs(widget.chatId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chat logs cleared'), duration: Duration(seconds: 1)),
                    );
                  }
                }
              } else if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Memory Thread?'),
                    content: const Text(
                        'This will permanently delete this chat thread and all its reminders.'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      TextButton(
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await chatProvider.deleteChat(widget.chatId);
                  if (context.mounted) {
                    Navigator.pop(context); // pop ChatInfoScreen
                    Navigator.pop(context); // pop ConversationScreen (back to home)
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear Chat Logs', style: TextStyle(color: Colors.red)),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Chat Thread', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Chat Identity
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Large circular logo avatar
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [StitchTheme.primary, StitchTheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: StitchTheme.primary.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          StitchTheme.getChatIcon(chat.iconCode),
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      chat.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Created: ${DateFormat('MMM d, yyyy').format(chat.createdAt)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Media Bento Grid Section
              _buildSectionHeader('Media, Links and Docs', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatAttachmentsScreen(chatId: widget.chatId),
                  ),
                );
              }, isDark),
              const SizedBox(height: 12),
              _buildBentoGrid(allAttachments, isDark),
              const SizedBox(height: 28),

              // Saved Links Section
              if (savedLinks.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Saved Links',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: savedLinks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final link = savedLinks[index];
                    return _buildLinkCard(link['title']!, link['url']!, isDark);
                  },
                ),
                const SizedBox(height: 28),
              ],

              // Reminders Section
              _buildSectionHeader('Reminders', () {
                // Add quick reminder option inside chat info
                _showAddReminderDialog(context, chatProvider, isDark);
              }, isDark, actionLabel: 'New', actionIcon: Icons.add),
              const SizedBox(height: 12),
              chatReminders.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? StitchTheme.darkSurfaceContainer : StitchTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'No active reminders for this thread.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: chatReminders.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final r = chatReminders[index];
                        return _buildReminderItem(r, isDark);
                      },
                    ),
              const SizedBox(height: 32),

              // Lock Chat Setting Card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isDark ? StitchTheme.darkSurfaceContainerLowest : Colors.white,
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: StitchTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_outline, color: StitchTheme.primary),
                  ),
                  title: Text(
                    'Lock Chat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Obscure messages with a passcode',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Switch.adaptive(
                    value: chat.isLocked,
                    activeColor: StitchTheme.primary,
                    onChanged: (bool value) {
                      _toggleChatLock(context, chat, chatProvider);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Action buttons (Bento styles)
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.star,
                      label: 'Starred Messages',
                      color: StitchTheme.primary,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StarredMessagesScreen(chatId: widget.chatId),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.delete,
                      label: 'Clear Chat',
                      color: StitchTheme.error,
                      isDark: isDark,
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear Chat Logs?'),
                            content: const Text(
                                'Are you sure you want to delete all messages and reminders inside this chat?'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.pop(context, false),
                              ),
                              TextButton(
                                child: const Text('Clear', style: TextStyle(color: Colors.red)),
                                onPressed: () => Navigator.pop(context, true),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await chatProvider.clearChatLogs(widget.chatId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chat logs cleared'), duration: Duration(seconds: 1)),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap, bool isDark,
      {String actionLabel = 'See all', IconData? actionIcon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Row(
            children: [
              if (actionIcon != null) ...[
                Icon(actionIcon, size: 14, color: StitchTheme.primary),
                const SizedBox(width: 4),
              ],
              Text(
                actionLabel,
                style: const TextStyle(
                  color: StitchTheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Bento style grid helper
  Widget _buildBentoGrid(List<Message> attachments, bool isDark) {
    if (attachments.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? StitchTheme.darkSurfaceContainer : StitchTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'No documents or images yet',
          style: TextStyle(
            color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Display up to 3 previews, plus an indicator card
    final totalCount = attachments.length;
    final item1 = attachments[0];
    final item2 = totalCount > 1 ? attachments[1] : null;

    return SizedBox(
      height: 180,
      child: Row(
        children: [
          // Left panel: 2x2 double height block
          Expanded(
            flex: 2,
            child: _buildBentoItem(item1, isDark),
          ),
          const SizedBox(width: 8),

          // Right panel: 2 rows stack
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: item2 != null
                      ? _buildBentoItem(item2, isDark)
                      : Container(
                          decoration: BoxDecoration(
                            color: isDark ? StitchTheme.darkSurfaceContainerLow : StitchTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.image, color: StitchTheme.outline),
                        ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatAttachmentsScreen(
                                  chatId: widget.chatId,
                                  initialTabIndex: 1,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? StitchTheme.darkSurfaceContainerLow : StitchTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.insert_drive_file, color: StitchTheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // More Indicator card
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatAttachmentsScreen(
                                  chatId: widget.chatId,
                                  initialTabIndex: 0,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: StitchTheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '+$totalCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoItem(Message msg, bool isDark) {
    final isImg = msg.type == 'image';

    return GestureDetector(
      onTap: () {
        if (isImg) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenImageViewer(
                imagePath: msg.fileLocalPath,
                fileName: msg.fileName ?? "image.jpg",
                heroTag: "bento_${msg.fileLocalPath ?? msg.id}",
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatAttachmentsScreen(
                chatId: widget.chatId,
                initialTabIndex: 1,
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? StitchTheme.darkSurfaceContainerLow : StitchTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: isImg && msg.fileLocalPath != null
            ? Hero(
                tag: "bento_${msg.fileLocalPath ?? msg.id}",
                child: Image.file(
                  File(msg.fileLocalPath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isDark ? Colors.grey.shade900 : Colors.grey.shade300,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image, size: 32),
                    );
                  },
                ),
              )
            : Center(
                child: Icon(
                  msg.type == 'pdf' ? Icons.picture_as_pdf : Icons.insert_drive_file,
                  color: msg.type == 'pdf' ? Colors.red : StitchTheme.primary,
                  size: 32,
                ),
              ),
      ),
    );
  }

  Widget _buildLinkCard(String title, String url, bool isDark) {
    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not launch link: $url')),
              );
            }
          }
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? StitchTheme.darkSurfaceContainerLowest : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: StitchTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.link, color: StitchTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    url,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderItem(Reminder reminder, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? StitchTheme.primary.withValues(alpha: 0.05)
            : StitchTheme.secondaryFixed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StitchTheme.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: StitchTheme.secondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              reminder.time == null ? Icons.notifications_off : Icons.notifications_active,
              color: StitchTheme.secondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.content,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      reminder.time == null ? Icons.notifications_off : Icons.schedule,
                      size: 12,
                      color: StitchTheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      reminder.time == null
                          ? "No set time"
                          : DateFormat('MMM d, h:mm a').format(reminder.time!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: StitchTheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: StitchTheme.primary),
            onPressed: () => _showEditReminderDialog(context, reminder, isDark),
          ),
        ],
      ),
    );
  }

  void _showEditReminderDialog(BuildContext context, Reminder reminder, bool isDark) {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final titleController = TextEditingController(text: reminder.content);
    DateTime selectedDateTime = reminder.time ?? DateTime.now().add(const Duration(hours: 1));
    int selectedOption = 5;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              scrollable: true,
              backgroundColor: isDark ? StitchTheme.darkSurfaceContainerLow : Colors.white,
              title: const Text('Edit Reminder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Reminder details'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Schedule:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTimeChip(
                        label: 'In 1 Hr',
                        isSelected: selectedOption == 1,
                        onTap: () {
                          setModalState(() {
                            selectedOption = 1;
                            selectedDateTime = DateTime.now().add(const Duration(hours: 1));
                          });
                        },
                        isDark: isDark,
                      ),
                      _buildTimeChip(
                        label: 'In 3 Hrs',
                        isSelected: selectedOption == 2,
                        onTap: () {
                          setModalState(() {
                            selectedOption = 2;
                            selectedDateTime = DateTime.now().add(const Duration(hours: 3));
                          });
                        },
                        isDark: isDark,
                      ),
                      _buildTimeChip(
                        label: 'Tomorrow 8 AM',
                        isSelected: selectedOption == 3,
                        onTap: () {
                          setModalState(() {
                            selectedOption = 3;
                            final tomorrow = DateTime.now().add(const Duration(days: 1));
                            selectedDateTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0);
                          });
                        },
                        isDark: isDark,
                      ),
                      _buildTimeChip(
                        label: 'Tomorrow 10 PM',
                        isSelected: selectedOption == 4,
                        onTap: () {
                          setModalState(() {
                            selectedOption = 4;
                            final tomorrow = DateTime.now().add(const Duration(days: 1));
                            selectedDateTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 22, 0);
                          });
                        },
                        isDark: isDark,
                      ),
                      _buildTimeChip(
                        label: 'Custom...',
                        isSelected: selectedOption == 5,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDateTime,
                            firstDate: DateTime.now().isBefore(selectedDateTime) ? DateTime.now() : selectedDateTime,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null && context.mounted) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                            );
                            if (time != null) {
                              setModalState(() {
                                selectedOption = 5;
                                selectedDateTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_filled,
                          size: 16,
                          color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Will remind on: ${DateFormat('MMM d, yyyy - h:mm a').format(selectedDateTime)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final text = titleController.text.trim();
                    if (text.isNotEmpty) {
                      await provider.updateReminder(
                        reminderId: reminder.id,
                        content: text,
                        time: selectedDateTime,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reminder updated successfully')),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? StitchTheme.darkSurfaceContainerLow : StitchTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context, ChatProvider provider, bool isDark) {
    final titleController = TextEditingController();
    DateTime selectedDateTime = DateTime.now().add(const Duration(hours: 1));
    int selectedOption = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              scrollable: true,
              backgroundColor: isDark ? StitchTheme.darkSurfaceContainerLow : Colors.white,
              title: const Text('Add Reminder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Reminder details'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Schedule:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTimeChip(
                        label: 'In 1 Hr',
                        isSelected: selectedOption == 1,
                        onTap: () {
                          setModalState(() {
                            selectedOption = 1;
                            selectedDateTime = DateTime.now().add(const Duration(hours: 1));
                          });
                        },
                        isDark: isDark,
                      ),
                      _buildTimeChip(
                        label: 'In 3 Hrs',
                        isSelected: selectedOption == 2,
                        onTap: () {
                          setModalState(() {
                            selectedOption = 2;
                            selectedDateTime = DateTime.now().add(const Duration(hours: 3));
                          });
                        },
                        isDark: isDark,
                      ),
                      _buildTimeChip(
                        label: 'Tomorrow 8 AM',
                        isSelected: selectedOption == 3,
                        onTap: () {
                          setModalState(() {
                            selectedOption = 3;
                            final tomorrow = DateTime.now().add(const Duration(days: 1));
                            selectedDateTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0);
                          });
                        },
                        isDark: isDark,
                      ),
                      _buildTimeChip(
                        label: 'Tomorrow 10 PM',
                        isSelected: selectedOption == 4,
                        onTap: () {
                          setModalState(() {
                            selectedOption = 4;
                            final tomorrow = DateTime.now().add(const Duration(days: 1));
                            selectedDateTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 22, 0);
                          });
                        },
                        isDark: isDark,
                      ),
                      _buildTimeChip(
                        label: 'Custom...',
                        isSelected: selectedOption == 5,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDateTime,
                            firstDate: DateTime.now().isBefore(selectedDateTime) ? DateTime.now() : selectedDateTime,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null && context.mounted) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                            );
                            if (time != null) {
                              setModalState(() {
                                selectedOption = 5;
                                selectedDateTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_filled,
                          size: 16,
                          color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Will remind on: ${DateFormat('MMM d, yyyy - h:mm a').format(selectedDateTime)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final text = titleController.text.trim();
                    if (text.isNotEmpty) {
                      // Schedule via provider directly by sending parsed helper or manually adding
                      await provider.sendMessage(
                        chatId: widget.chatId,
                        text: "$text. Remind me on ${DateFormat('d MMMM').format(selectedDateTime)} at ${DateFormat('h:mm a').format(selectedDateTime)}",
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTimeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeColor = isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary;
    final activeTextColor = isDark ? Colors.black : Colors.white;
    final inactiveBgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100;
    final inactiveBorderColor = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade300;
    final inactiveTextColor = isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: isSelected ? activeTextColor : inactiveTextColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      selectedColor: activeColor,
      backgroundColor: inactiveBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? Colors.transparent : inactiveBorderColor,
        ),
      ),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
    );
  }
}
