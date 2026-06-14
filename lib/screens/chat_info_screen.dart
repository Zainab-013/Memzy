import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/message.dart';
import '../models/reminder.dart';
import '../theme/stitch_theme.dart';
import 'chat_attachments_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final chat = chatProvider.chats.firstWhere((c) => c.id == widget.chatId);
    final messages = chatProvider.getMessagesForChat(widget.chatId);
    final chatReminders = chatProvider.reminders
        .where((r) => r.chatId == widget.chatId && !r.isCompleted)
        .toList();

    // Group media files
    final mediaMessages = messages.where((m) => m.type == 'image').toList();
    final documentMessages = messages.where((m) => m.type == 'pdf' || m.type == 'document').toList();
    final allAttachments = [...mediaMessages, ...documentMessages];

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
          savedLinks.add({'title': title, 'url': url});
        }
      }
    }

    final avatarBgColor = chat.title == "Placement Prep"
        ? StitchTheme.primaryFixed
        : (chat.title == "College Notes"
            ? StitchTheme.secondaryFixed
            : StitchTheme.tertiaryFixedDim);

    final avatarIconColor = chat.title == "Placement Prep"
        ? StitchTheme.onPrimaryFixed
        : (chat.title == "College Notes"
            ? StitchTheme.onSecondaryFixed
            : StitchTheme.onTertiaryFixedVariant);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chat Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
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
                            color: StitchTheme.primary.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          IconData(chat.iconCode, fontFamily: 'MaterialIcons'),
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: StitchTheme.outline,
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
                          color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline,
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
                        // Find starred messages in this chat
                        final starred = messages.where((m) => m.isStarred).toList();
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: isDark ? StitchTheme.darkSurfaceContainerLow : Colors.white,
                            title: const Text('Starred Messages'),
                            content: starred.isEmpty
                                ? const Text('No starred messages in this chat.')
                                : SizedBox(
                                    width: double.maxFinite,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: starred.length,
                                      itemBuilder: (context, idx) => ListTile(
                                        title: Text(starred[idx].text),
                                        subtitle: Text(
                                          DateFormat('MMM d, h:mm a').format(starred[idx].timestamp),
                                        ),
                                      ),
                                    ),
                                  ),
                            actions: [
                              TextButton(
                                child: const Text('Close'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
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
                          if (mounted) {
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
            color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline,
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
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? StitchTheme.darkSurfaceContainerLow : StitchTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.insert_drive_file, color: StitchTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // More Indicator card
                      Expanded(
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? StitchTheme.darkSurfaceContainerLow : StitchTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: isImg && msg.fileLocalPath != null
          ? Image.file(
              File(msg.fileLocalPath!),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          : Center(
              child: Icon(
                msg.type == 'pdf' ? Icons.picture_as_pdf : Icons.insert_drive_file,
                color: msg.type == 'pdf' ? Colors.red : StitchTheme.primary,
                size: 32,
              ),
            ),
    );
  }

  Widget _buildLinkCard(String title, String url, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? StitchTheme.darkSurfaceContainerLowest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: StitchTheme.primary.withOpacity(0.1),
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
                  style: const TextStyle(
                    fontSize: 11,
                    color: StitchTheme.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: StitchTheme.outline),
        ],
      ),
    );
  }

  Widget _buildReminderItem(Reminder reminder, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? StitchTheme.primary.withOpacity(0.05)
            : StitchTheme.secondaryFixed.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StitchTheme.secondary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: StitchTheme.secondary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active, color: StitchTheme.secondary, size: 18),
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
                    const Icon(Icons.schedule, size: 12, color: StitchTheme.secondary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, h:mm a').format(reminder.time),
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
        ],
      ),
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
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: isDark ? StitchTheme.darkSurfaceContainerLow : Colors.white,
              title: const Text('Add Reminder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Reminder details'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Schedule:'),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDateTime,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null && context.mounted) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                            );
                            if (time != null) {
                              setModalState(() {
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
                        child: Text(
                          DateFormat('MMM d, h:mm a').format(selectedDateTime),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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
}
