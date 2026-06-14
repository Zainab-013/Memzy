import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/chat.dart';
import '../theme/stitch_theme.dart';
import 'conversation_screen.dart';

class ArchivedChatsScreen extends StatelessWidget {
  const ArchivedChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Filter archived chats
    final archivedChats = chatProvider.chats.where((c) => c.isArchived).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Chats'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: archivedChats.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 48,
                        color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No archived chats.",
                        style: TextStyle(
                          color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: archivedChats.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final chat = archivedChats[index];
                  return _buildArchivedChatCard(context, chat, isDark, chatProvider);
                },
              ),
      ),
    );
  }

  Widget _buildArchivedChatCard(
      BuildContext context, Chat chat, bool isDark, ChatProvider provider) {
    final messages = provider.getMessagesForChat(chat.id);
    final hasMessages = messages.isNotEmpty;
    final lastMsg = hasMessages ? messages.last : null;
    final lastMsgText = lastMsg != null
        ? (lastMsg.type == 'text' ? lastMsg.text : '📎 Attachment: ${lastMsg.fileName ?? "File"}')
        : "No messages yet";

    final lastMsgTime = lastMsg != null
        ? DateFormat('h:mm a').format(lastMsg.timestamp)
        : DateFormat('h:mm a').format(chat.createdAt);

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

    return Dismissible(
      key: Key(chat.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20.0),
        decoration: BoxDecoration(
          color: StitchTheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.unarchive, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Unarchive Chat
          await provider.toggleArchiveChat(chat.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chat Unarchived'),
                duration: Duration(seconds: 1),
              ),
            );
          }
          return true;
        } else {
          // Confirm Delete
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Memory Thread?'),
              content: const Text(
                  'This will permanently delete this chat thread and all its reminders.'),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          );
        }
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await provider.deleteChat(chat.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? StitchTheme.darkSurfaceContainerLowest : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConversationScreen(chatId: chat.id),
                ),
              );
            },
            onLongPress: () {
              _showArchivedChatOptionsSheet(context, chat, provider, isDark);
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: avatarBgColor,
                    ),
                    child: Icon(
                      IconData(chat.iconCode, fontFamily: 'MaterialIcons'),
                      color: avatarIconColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                chat.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lastMsgTime,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastMsgText,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? StitchTheme.darkOnSurfaceVariant
                                : StitchTheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showArchivedChatOptionsSheet(BuildContext context, Chat chat, ChatProvider provider, bool isDark) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                chat.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.unarchive, color: StitchTheme.primary),
                title: const Text('Unarchive Chat'),
                onTap: () async {
                  Navigator.pop(context);
                  await provider.toggleArchiveChat(chat.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat Unarchived'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Chat', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Memory Thread?'),
                      content: const Text(
                          'This will permanently delete this chat thread and all its reminders.'),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        TextButton(
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await provider.deleteChat(chat.id);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
