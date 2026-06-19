import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/chat.dart';
import '../theme/stitch_theme.dart';
import '../widgets/passcode_view.dart';
import 'conversation_screen.dart';
import 'archived_chats_screen.dart';
import 'memory_insights_screen.dart';

class ChatsHomeScreen extends StatefulWidget {
  const ChatsHomeScreen({super.key});

  @override
  State<ChatsHomeScreen> createState() => _ChatsHomeScreenState();
}

class _ChatsHomeScreenState extends State<ChatsHomeScreen> {
  String _searchQuery = "";
  bool _isSearching = false;
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

    // Filter active (non-archived) chats by search query
    final activeChats = chatProvider.chats.where((c) => !c.isArchived).toList();
    final displayedChats = _searchQuery.isEmpty
        ? activeChats
        : activeChats.where((c) {
            final query = _searchQuery.toLowerCase();
            if (c.title.toLowerCase().contains(query)) return true;
            
            if (!c.isLocked) {
              final messages = chatProvider.getMessagesForChat(c.id);
              return messages.any((m) =>
                  m.text.toLowerCase().contains(query) ||
                  (m.fileName ?? '').toLowerCase().contains(query) ||
                  m.type.toLowerCase().contains(query));
            }
            return false;
          }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? StitchTheme.darkBackground : StitchTheme.background,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search chats...',
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
            : Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Memzy',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
            ),
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
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: GestureDetector(
                onTap: () => themeProvider.toggleTheme(),
                child: Container(
                  width: 44,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: isDark
                        ? StitchTheme.primary
                        : StitchTheme.secondaryFixedDim.withValues(alpha: 0.8),
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeIn,
                        left: isDark ? 22 : 2,
                        top: 2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(
                            isDark ? Icons.dark_mode : Icons.light_mode,
                            size: 12,
                            color: isDark ? StitchTheme.primary : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
            ),
            onSelected: (value) {
              if (value == 'archived') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ArchivedChatsScreen(),
                  ),
                );
              } else if (value == 'change_passcode') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PasscodeView(
                      mode: 'verify',
                      title: "Verify Old Passcode",
                      onSuccess: (passcode) {
                        Navigator.pop(context); // pop verify screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PasscodeView(
                              mode: 'create',
                              title: "Enter New Passcode",
                              onSuccess: (newPasscode) async {
                                await chatProvider.setPasscode(newPasscode);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Passcode changed successfully')),
                                  );
                                }
                              },
                              onCancel: () => Navigator.pop(context),
                            ),
                          ),
                        );
                      },
                      onCancel: () => Navigator.pop(context),
                    ),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'archived',
                child: Text('Archived Chats'),
              ),
              if (chatProvider.isPasscodeSet)
                const PopupMenuItem(
                  value: 'change_passcode',
                  child: Text('Change Passcode'),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Welcome header
                Text(
                  'Your Memories',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Intelligent conversations with your past and future.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? StitchTheme.darkOnSurfaceVariant
                            : StitchTheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),

                // Chat List
                displayedChats.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            _searchQuery.isEmpty
                                ? "No memory threads yet. Tap '+' to create one."
                                : "No matching chats found.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark
                                  ? StitchTheme.darkOnSurfaceVariant
                                  : StitchTheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayedChats.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final chat = displayedChats[index];
                          return _buildChatCard(context, chat, isDark, chatProvider);
                        },
                      ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatCard(
      BuildContext context, Chat chat, bool isDark, ChatProvider provider) {
    final messages = provider.getMessagesForChat(chat.id);
    final hasMessages = messages.isNotEmpty;
    final lastMsg = hasMessages ? messages.last : null;
    final lastMsgText = chat.isLocked
        ? "Locked • Tap to unlock"
        : (lastMsg != null
            ? (lastMsg.type == 'text' ? lastMsg.text : '📎 Attachment: ${lastMsg.fileName ?? "File"}')
            : "No messages yet");

    final lastMsgTime = chat.isLocked
        ? ""
        : (lastMsg != null
            ? DateFormat('h:mm a').format(lastMsg.timestamp)
            : DateFormat('h:mm a').format(chat.createdAt));

    final avatarBgColor = StitchTheme.getAvatarBgColor(chat.title, isDark);
    final avatarIconColor = StitchTheme.getAvatarIconColor(chat.title, isDark);

    return Dismissible(
      key: Key(chat.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20.0),
        decoration: BoxDecoration(
          color: Colors.green.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.push_pin, color: Colors.white),
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
          // Toggle Pin
          await provider.togglePinChat(chat.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(chat.isPinned ? 'Chat Pinned' : 'Chat Unpinned'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
          return false; // Don't remove widget from list
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
          border: Border.all(
            color: isDark
                ? (chat.isPinned ? StitchTheme.primary.withValues(alpha: 0.6) : const Color(0xFF28243E))
                : (chat.isPinned ? StitchTheme.primary.withValues(alpha: 0.4) : const Color(0xFFECE9FC)),
            width: chat.isPinned ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0x0C6366F1),
              blurRadius: 16,
              offset: const Offset(0, 8),
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
              _showChatOptionsSheet(context, chat, provider, isDark);
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Icon Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: StitchTheme.getAvatarGradient(chat.title, isDark),
                    ),
                    child: Icon(
                      StitchTheme.getChatIcon(chat.iconCode),
                      color: avatarIconColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Title and Snippet
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
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
                                  if (chat.isLocked) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.lock,
                                      size: 14,
                                      color: StitchTheme.primary,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (lastMsgTime.isNotEmpty)
                              Text(
                                lastMsgTime,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (chat.isPinned) ...[
                              Icon(
                                Icons.push_pin,
                                size: 12,
                                color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
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
                            ),
                          ],
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

  void _showChatOptionsSheet(BuildContext context, Chat chat, ChatProvider provider, bool isDark) {
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
                leading: Icon(chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin, color: StitchTheme.primary),
                title: Text(chat.isPinned ? 'Unpin Chat' : 'Pin Chat'),
                onTap: () async {
                  Navigator.pop(context);
                  await provider.togglePinChat(chat.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(chat.isPinned ? 'Chat Unpinned' : 'Chat Pinned'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive, color: StitchTheme.secondary),
                title: const Text('Archive Chat'),
                onTap: () async {
                  Navigator.pop(context);
                  await provider.toggleArchiveChat(chat.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat Archived'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(chat.isLocked ? Icons.lock_open : Icons.lock, color: StitchTheme.primary),
                title: Text(chat.isLocked ? 'Unlock Chat' : 'Lock Chat'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleChatLock(context, chat, provider);
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
