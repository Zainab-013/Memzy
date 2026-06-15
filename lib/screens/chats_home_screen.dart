import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/chat.dart';
import '../theme/stitch_theme.dart';
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
        : activeChats
            .where((c) => c.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

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
                  Icon(
                    Icons.memory,
                    color: isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Memzy',
                    style: TextStyle(
                      fontFamily: 'Geist',
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
              color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
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
              color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
            ),
            onSelected: (value) {
              if (value == 'archived') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ArchivedChatsScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'archived',
                child: Text('Archived Chats'),
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
                        fontFamily: 'Geist',
                        color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Intelligent conversations with your past and future.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Geist',
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

                const SizedBox(height: 24),

                // Memory Insights card (Amethyst Container)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [StitchTheme.primary, StitchTheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Memory Insights',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "You've saved ${chatProvider.reminders.length} important reminders. Keep going!",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: StitchTheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(99),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MemoryInsightsScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Explore Trends',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: -16,
                        bottom: -16,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
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
          border: chat.isPinned
              ? Border.all(
                  color: isDark ? StitchTheme.secondaryFixedDim : StitchTheme.secondary,
                  width: 1.5,
                )
              : null,
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
                      shape: BoxShape.circle,
                      color: avatarBgColor,
                    ),
                    child: Icon(
                      IconData(chat.iconCode, fontFamily: 'MaterialIcons'),
                      color: avatarIconColor,
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
                                color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline,
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
                                color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline,
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
