import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../theme/stitch_theme.dart';
import '../widgets/passcode_view.dart';
import 'conversation_screen.dart';
import 'archived_chats_screen.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBatteryOptimization();
    });
  }

  Future<void> _checkBatteryOptimization() async {
    if (!Platform.isAndroid) return;

    // Do not show the prompt if user has already seen and dismissed/configured it
    final bool alreadyWarned = DatabaseService.settingsBox.get('has_dismissed_battery_warning', defaultValue: false) as bool;
    if (alreadyWarned) return;
    
    final bool isIgnoring = await NotificationService.isIgnoringBatteryOptimizations();
    if (!isIgnoring && mounted) {
      _showBatteryOptimizationDialog();
    }
  }

  void _showBatteryOptimizationDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? StitchTheme.darkSurfaceContainerLow : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(
                Icons.alarm_on_rounded,
                color: isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Timely Reminders',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To make sure your reminders deliver exactly on time, Memzy needs battery optimization to be turned off.',
                style: TextStyle(
                  color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'On the next screen, change the setting to "Don\'t optimize" or "Unrestricted".',
                        style: TextStyle(fontSize: 13, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await DatabaseService.settingsBox.put('has_dismissed_battery_warning', true);
              },
              child: Text(
                'Later',
                style: TextStyle(
                  color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: StitchTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 2,
              ),
              onPressed: () async {
                Navigator.pop(context);
                await DatabaseService.settingsBox.put('has_dismissed_battery_warning', true);
                await NotificationService.requestIgnoreBatteryOptimizations();
              },
              child: const Text('Configure Now', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

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

    // Filter active (non-archived) chats
    final activeChats = chatProvider.chats.where((c) => !c.isArchived).toList();

    // Global search lists
    final List<Chat> matchingChats = [];
    final List<Map<String, dynamic>> matchingMessages = [];
    final List<Map<String, dynamic>> matchingFiles = [];

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      for (final chat in activeChats) {
        if (chat.title.toLowerCase().contains(query)) {
          matchingChats.add(chat);
        }

        if (!chat.isLocked) {
          final messages = chatProvider.getMessagesForChat(chat.id);
          for (final msg in messages) {
            final isFile = msg.type == 'image' || msg.type == 'pdf' || msg.type == 'document';
            final fileName = msg.fileName ?? '';
            final text = msg.text;

            if (isFile) {
              if (fileName.toLowerCase().contains(query) || text.toLowerCase().contains(query)) {
                matchingFiles.add({
                  'chat': chat,
                  'message': msg,
                });
              }
            } else if (msg.type == 'text') {
              if (text.toLowerCase().contains(query)) {
                matchingMessages.add({
                  'chat': chat,
                  'message': msg,
                });
              }
            }
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? StitchTheme.darkBackground : StitchTheme.background,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search chats, messages, files...',
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

                // Chat List or Search Results
                if (_searchQuery.isEmpty) ...[
                  activeChats.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              "No memory threads yet. Tap '+' to create one.",
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
                          itemCount: activeChats.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final chat = activeChats[index];
                            return _buildChatCard(context, chat, isDark, chatProvider);
                          },
                        ),
                ] else ...[
                  if (matchingChats.isEmpty && matchingMessages.isEmpty && matchingFiles.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          "No matching chats, messages, or files found.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? StitchTheme.darkOnSurfaceVariant
                                : StitchTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    // Matching Chats Section
                    if (matchingChats.isNotEmpty) ...[
                      Text(
                        'Chats (${matchingChats.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: matchingChats.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final chat = matchingChats[index];
                          return _buildChatCard(context, chat, isDark, chatProvider);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Matching Messages Section
                    if (matchingMessages.isNotEmpty) ...[
                      Text(
                        'Messages (${matchingMessages.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: matchingMessages.length,
                        itemBuilder: (context, index) {
                          final item = matchingMessages[index];
                          return _buildMessageResultCard(
                            context,
                            item['chat'] as Chat,
                            item['message'] as Message,
                            isDark,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Matching Files Section
                    if (matchingFiles.isNotEmpty) ...[
                      Text(
                        'Files & Documents (${matchingFiles.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: matchingFiles.length,
                        itemBuilder: (context, index) {
                          final item = matchingFiles[index];
                          return _buildFileResultCard(
                            context,
                            item['chat'] as Chat,
                            item['message'] as Message,
                            isDark,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ],
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
              color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0x0C45346A),
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
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Rename Chat'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameChatDialog(context, chat, provider);
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

  void _showRenameChatDialog(BuildContext context, Chat chat, ChatProvider provider) {
    final controller = TextEditingController(text: chat.title);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        final highlightColor = isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary;
        return AlertDialog(
          backgroundColor: isDark ? StitchTheme.darkSurfaceContainerLow : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Rename Memory Thread', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Thread Title',
              labelStyle: TextStyle(
                color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: highlightColor),
                borderRadius: BorderRadius.circular(12),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            style: TextStyle(
              color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: StitchTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              ),
              onPressed: () async {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty && newTitle != chat.title) {
                  await provider.renameChat(chat.id, newTitle);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat renamed successfully'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageResultCard(BuildContext context, Chat chat, Message msg, bool isDark) {
    final timeStr = DateFormat('MMM d, h:mm a').format(msg.timestamp);
    final isMe = msg.sender == 'user';
    final senderPrefix = isMe ? 'Me: ' : 'System: ';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? StitchTheme.darkSurfaceContainerLowest : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF28243E) : const Color(0xFFECE9FC),
          width: 1.0,
        ),
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: StitchTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_bubble_outline, color: StitchTheme.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            chat.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary,
                            ),
                          ),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                          ),
                          children: [
                            TextSpan(
                              text: senderPrefix,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: msg.text,
                            ),
                          ],
                        ),
                        maxLines: 2,
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
    );
  }

  Widget _buildFileResultCard(BuildContext context, Chat chat, Message msg, bool isDark) {
    final timeStr = DateFormat('MMM d, h:mm a').format(msg.timestamp);
    final isPdf = msg.type == 'pdf';
    final isImage = msg.type == 'image';
    final icon = isImage
        ? Icons.image
        : (isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file);
    final iconColor = isImage
        ? StitchTheme.secondary
        : (isPdf ? Colors.red : Colors.blue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? StitchTheme.darkSurfaceContainerLowest : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF28243E) : const Color(0xFFECE9FC),
          width: 1.0,
        ),
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            chat.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary,
                            ),
                          ),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        msg.fileName ?? (isImage ? 'image.jpg' : 'Document'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (msg.fileSize != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          "${(msg.fileSize! / (1024 * 1024)).toStringAsFixed(2)} MB",
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
