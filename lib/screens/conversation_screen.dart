import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/message.dart';
import '../models/reminder.dart';
import '../theme/stitch_theme.dart';
import 'chat_info_screen.dart';
import 'starred_messages_screen.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../widgets/passcode_view.dart';

class SelectedAttachment {
  final File file;
  final String type; // 'image', 'pdf', 'document'
  final String name;
  final int size;

  SelectedAttachment({
    required this.file,
    required this.type,
    required this.name,
    required this.size,
  });
}

class ConversationScreen extends StatefulWidget {
  final String chatId;
  const ConversationScreen({super.key, required this.chatId});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = {};
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  bool _isUnlocked = false;

  final List<SelectedAttachment> _selectedAttachments = [];

  @override
  void initState() {
    super.initState();
    // Scroll to bottom on initial build
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(isAnimated: false));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool isAnimated = true}) {
    if (_scrollController.hasClients) {
      if (isAnimated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedAttachments.isEmpty) return;

    _textController.clear();
    final provider = Provider.of<ChatProvider>(context, listen: false);

    if (_selectedAttachments.isNotEmpty) {
      final attachmentsToSend = List<SelectedAttachment>.from(_selectedAttachments);
      setState(() {
        _selectedAttachments.clear();
      });

      for (int i = 0; i < attachmentsToSend.length; i++) {
        final item = attachmentsToSend[i];
        final captionText = (i == 0 && text.isNotEmpty)
            ? text
            : (item.type == 'image'
                ? 'Sent an image'
                : (item.type == 'pdf' ? 'Sent a PDF' : 'Sent a document'));

        await provider.sendMessage(
          chatId: widget.chatId,
          text: captionText,
          type: item.type,
          fileLocalPath: item.file.path,
          fileName: item.name,
          fileSize: item.size,
        );
      }
    } else {
      await provider.sendMessage(chatId: widget.chatId, text: text);
    }
    
    // Animate to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _pickImage() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty && mounted) {
        final List<SelectedAttachment> newAttachments = [];
        for (final image in images) {
          final file = File(image.path);
          final fileName = image.name;
          final fileSize = await file.length();
          newAttachments.add(SelectedAttachment(
            file: file,
            type: 'image',
            name: fileName,
            size: fileSize,
          ));
        }
        setState(() {
          _selectedAttachments.addAll(newAttachments);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty && mounted) {
        final List<SelectedAttachment> newAttachments = [];
        for (final file in result.files) {
          if (file.path != null) {
            final extension = file.extension?.toLowerCase() ?? 'document';
            newAttachments.add(SelectedAttachment(
              file: File(file.path!),
              type: extension == 'pdf' ? 'pdf' : 'document',
              name: file.name,
              size: file.size,
            ));
          }
        }
        setState(() {
          _selectedAttachments.addAll(newAttachments);
        });
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Attach Memory File',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentOption(
                      icon: Icons.image,
                      label: 'Gallery',
                      color: StitchTheme.secondary,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage();
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.picture_as_pdf,
                      label: 'PDF Document',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        _pickFile();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
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

    if (chat.isLocked && !_isUnlocked) {
      return PasscodeView(
        mode: 'verify',
        title: "Unlock Chat",
        onSuccess: (passcode) {
          setState(() {
            _isUnlocked = true;
          });
        },
        onCancel: () {
          Navigator.pop(context);
        },
      );
    }
    final messages = chatProvider.getMessagesForChat(widget.chatId);
    final displayedMessages = _searchQuery.isEmpty
        ? messages
        : messages
            .where((m) => m.text.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    final allStarred = _selectedMessageIds.isNotEmpty &&
        messages.where((m) => _selectedMessageIds.contains(m.id)).every((m) => m.isStarred);

    final allPinned = _selectedMessageIds.isNotEmpty &&
        messages.where((m) => _selectedMessageIds.contains(m.id)).every((m) => m.isPinned == true);

    final pinnedMessages = messages.where((m) => m.isPinned == true).toList();

    final isSingleUserTextSelected = _selectedMessageIds.length == 1 && () {
      final selectedList = messages.where((m) => _selectedMessageIds.contains(m.id)).toList();
      if (selectedList.isEmpty) return false;
      final msg = selectedList.first;
      return msg.sender == 'user' && msg.type == 'text';
    }();

    // Suggestion chips matching HTML prototypes
    final suggestionChips = chat.title == "Placement Prep"
        ? ["Add to Calendar", "Draft Email", "Search Roles"]
        : ["Mark Done", "Save PDF Link", "Set Reminder"];

    final avatarBgColor = StitchTheme.getAvatarBgColor(chat.title, isDark);
    final avatarIconColor = StitchTheme.getAvatarIconColor(chat.title, isDark);

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedMessageIds.clear();
                  });
                },
              ),
              title: Text('${_selectedMessageIds.length} Selected'),
              actions: [
                if (isSingleUserTextSelected)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editSelectedMessage(chatProvider),
                  ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copySelectedMessages(chatProvider),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareSelectedMessages(chatProvider),
                ),
                IconButton(
                  icon: Icon(allStarred ? Icons.star : Icons.star_border, color: Colors.amber),
                  onPressed: () => _starSelectedMessages(chatProvider),
                ),
                IconButton(
                  icon: Icon(allPinned ? Icons.push_pin : Icons.push_pin_outlined, color: Colors.blueAccent),
                  onPressed: () => _pinSelectedMessages(chatProvider),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSelectedMessages(chatProvider),
                ),
              ],
            )
          : AppBar(
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
                        hintText: 'Search messages...',
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
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatInfoScreen(chatId: chat.id),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          // Chat icon avatar with active indicator
                          Stack(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: StitchTheme.getAvatarGradient(chat.title, isDark),
                                ),
                                child: Icon(
                                  StitchTheme.getChatIcon(chat.iconCode),
                                  color: avatarIconColor,
                                  size: 20,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? StitchTheme.darkBackground : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Header titles
                          Expanded(
                            child: Text(
                              chat.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'clear') {
                      await chatProvider.clearChatLogs(widget.chatId);
                    } else if (value == 'info') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatInfoScreen(chatId: widget.chatId),
                        ),
                      );
                    } else if (value == 'starred') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StarredMessagesScreen(chatId: widget.chatId),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'info',
                      child: Text('Chat Info'),
                    ),
                    const PopupMenuItem(
                      value: 'starred',
                      child: Text('Starred Messages'),
                    ),
                    const PopupMenuItem(
                      value: 'clear',
                      child: Text('Clear Chat Logs', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
      body: SafeArea(
        child: Column(
          children: [
            if (pinnedMessages.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? StitchTheme.darkSurfaceContainerLow : Colors.grey.shade100,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.push_pin, size: 16, color: StitchTheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final index = displayedMessages.indexWhere((m) => m.id == pinnedMessages.last.id);
                          if (index != -1 && _scrollController.hasClients) {
                            _scrollController.animateTo(
                              (index + 1) * 90.0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Pinned Message',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: StitchTheme.primary,
                              ),
                            ),
                            Text(
                              pinnedMessages.last.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        await chatProvider.togglePinMessage(pinnedMessages.last.id);
                      },
                    ),
                  ],
                ),
              ),
            // Chat messages canvas
            Expanded(
              child: displayedMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? "Start your memory chain.\nSend files or set reminders directly."
                                : "No matching messages found.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      itemCount: displayedMessages.length + 1, // extra item for Date Separator
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // Date separator bubble
                          return Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? StitchTheme.darkSurfaceContainer : StitchTheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Today',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }

                        final msg = displayedMessages[index - 1];
                        return _buildMessageBubble(msg, isDark, chatProvider);
                      },
                    ),
            ),

            // Suggestion chips
            if (suggestionChips.isNotEmpty)
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: suggestionChips.length,
                  itemBuilder: (context, index) {
                    final chip = suggestionChips[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        backgroundColor: isDark ? StitchTheme.darkSurfaceContainerLow : StitchTheme.surfaceContainerLow,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: BorderSide(
                          color: isDark ? StitchTheme.darkSurfaceContainerHigh : StitchTheme.outline,
                          width: 0.5,
                        ),
                        label: Text(
                          chip,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary,
                          ),
                        ),
                        onPressed: () {
                          _textController.text = chip;
                          _handleSend();
                        },
                      ),
                    );
                  },
                ),
              ),

            // Attachment Preview Card
            if (_selectedAttachments.isNotEmpty)
              Container(
                height: 90,
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedAttachments.length,
                  itemBuilder: (context, index) {
                    final item = _selectedAttachments[index];
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 80,
                          margin: const EdgeInsets.only(right: 12, top: 8),
                          decoration: BoxDecoration(
                            color: isDark ? StitchTheme.darkSurfaceContainerLow : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: item.type == 'image'
                                ? Image.file(
                                    item.file,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        item.type == 'pdf'
                                            ? Icons.picture_as_pdf
                                            : Icons.description,
                                        color: item.type == 'pdf'
                                            ? Colors.red
                                            : Colors.blue,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                        child: Text(
                                          item.name,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedAttachments.removeAt(index);
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.grey,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            // Bottom Input footer bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? StitchTheme.darkSurfaceContainerLow : StitchTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: StitchTheme.primary),
                            onPressed: _showAttachmentMenu,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: _selectedAttachments.isNotEmpty
                                    ? 'Add caption...'
                                    : 'Recall something...',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              style: TextStyle(
                                color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _handleSend,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: StitchTheme.primary,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, bool isDark, ChatProvider provider) {
    final isMe = msg.sender == 'user';
    final formattedTime = DateFormat('h:mm a').format(msg.timestamp);
    final isSelected = _selectedMessageIds.contains(msg.id);

    Reminder? reminder;
    for (final r in provider.reminders) {
      if (r.messageId == msg.id) {
        reminder = r;
        break;
      }
    }

    final reminderWidget = reminder == null ? const SizedBox.shrink() : Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.notifications_active,
          size: 11,
          color: isMe
              ? StitchTheme.userBubbleText.withValues(alpha: 0.7)
              : StitchTheme.systemBubbleText.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 3),
        Text(
          reminder.time != null
              ? provider.formatReminderTime(reminder.time!)
              : "Reminder",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isMe
                ? StitchTheme.userBubbleText.withValues(alpha: 0.7)
                : StitchTheme.systemBubbleText.withValues(alpha: 0.7),
          ),
        ),
      ],
    );

    final timestampWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (msg.isStarred) ...[
          Icon(
            Icons.star,
            size: 11,
            color: isMe
                ? StitchTheme.userBubbleText.withValues(alpha: 0.6)
                : StitchTheme.systemBubbleText.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 3),
        ],
        Text(
          formattedTime,
          style: TextStyle(
            fontSize: 10,
            color: isMe
                ? StitchTheme.userBubbleText.withValues(alpha: 0.6)
                : StitchTheme.systemBubbleText.withValues(alpha: 0.6),
          ),
        ),
        if (msg.isEdited) ...[
          const SizedBox(width: 4),
          Text(
            '• Edited',
            style: TextStyle(
              fontSize: 8,
              color: isMe
                  ? StitchTheme.userBubbleText.withValues(alpha: 0.6)
                  : StitchTheme.systemBubbleText.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );

    final bubbleBody = Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMe) ...[
                if (msg.isPinned == true) ...[
                  const Icon(Icons.push_pin, size: 14, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                ],
              ],
              GestureDetector(
                onTap: () async {
                  if (_isSelectionMode) {
                    setState(() {
                      if (isSelected) {
                        _selectedMessageIds.remove(msg.id);
                      } else {
                        _selectedMessageIds.add(msg.id);
                      }
                    });
                  } else if (msg.type == 'image') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImageViewer(
                          imagePath: msg.fileLocalPath,
                          fileName: msg.fileName ?? "image.jpg",
                          heroTag: msg.fileLocalPath ?? (msg.fileName ?? msg.id),
                        ),
                      ),
                    );
                  } else if ((msg.type == 'pdf' || msg.type == 'document') && msg.fileLocalPath != null) {
                    try {
                      final file = File(msg.fileLocalPath!);
                      if (!await file.exists()) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("File not found on this device.")),
                          );
                        }
                        return;
                      }
                      await OpenFilex.open(msg.fileLocalPath!);
                    } catch (e) {
                      debugPrint("Error opening file: $e");
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Could not open this file type")),
                        );
                      }
                    }
                  }
                },
                onLongPress: () {
                  if (!_isSelectionMode) {
                    setState(() {
                      _isSelectionMode = true;
                      _selectedMessageIds.add(msg.id);
                    });
                  }
                },
                child: IntrinsicWidth(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe
                          ? (isDark ? StitchTheme.userBubbleDarkBg : StitchTheme.userBubbleLightBg)
                          : (isDark ? StitchTheme.systemBubbleDarkBg : StitchTheme.systemBubbleLightBg),
                      borderRadius: isMe ? StitchTheme.userBubbleRadius : StitchTheme.systemBubbleRadius,
                      border: Border.all(
                        color: isMe
                            ? (isDark ? StitchTheme.userBubbleDarkBorder : StitchTheme.userBubbleLightBorder)
                            : (isDark ? StitchTheme.systemBubbleDarkBorder : StitchTheme.systemBubbleLightBorder),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBubbleContent(msg, isDark),
                        const SizedBox(height: 6),
                        reminder != null
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  reminderWidget,
                                  timestampWidget,
                                ],
                              )
                            : Align(
                                alignment: Alignment.bottomRight,
                                child: timestampWidget,
                              ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isMe) ...[
                if (msg.isPinned == true) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.push_pin, size: 14, color: Colors.blueAccent),
                ],
              ],
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );

    if (_isSelectionMode) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedMessageIds.remove(msg.id);
            } else {
              _selectedMessageIds.add(msg.id);
            }
          });
        },
        child: Container(
          width: double.infinity,
          color: isSelected
              ? StitchTheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: bubbleBody,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: bubbleBody,
    );
  }

  Widget _buildBubbleContent(Message msg, bool isDark) {
    if (msg.type == 'image') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Hero(
              tag: msg.fileLocalPath ?? (msg.fileName ?? msg.id),
              child: msg.fileLocalPath != null
                  ? Image.file(
                      File(msg.fileLocalPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          color: isDark ? Colors.grey.shade900 : Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image, size: 48),
                        );
                      },
                    )
                  : Container(
                      height: 150,
                      color: Colors.grey.shade300,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image, size: 48),
                    ),
            ),
          ),
          if (msg.text != "Sent an image") ...[
            const SizedBox(height: 8),
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 15,
                color: msg.sender == 'user'
                    ? StitchTheme.userBubbleText
                    : StitchTheme.systemBubbleText,
              ),
            ),
          ],
        ],
      );
    } else if (msg.type == 'pdf' || msg.type == 'document') {
      final isPdf = msg.type == 'pdf';
      final showCaption = msg.text != "Sent a document" && msg.text != "Sent a PDF";
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPdf ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPdf ? Icons.picture_as_pdf : Icons.description,
                  color: isPdf ? Colors.red : Colors.blue,
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
                        color: msg.sender == 'user'
                            ? StitchTheme.userBubbleText
                            : StitchTheme.systemBubbleText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      msg.fileSize != null
                          ? "${(msg.fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB • ${msg.type.toUpperCase()}"
                          : msg.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        color: msg.sender == 'user'
                            ? StitchTheme.userBubbleText.withValues(alpha: 0.7)
                            : (isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showCaption) ...[
            const SizedBox(height: 8),
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 15,
                color: msg.sender == 'user'
                    ? StitchTheme.userBubbleText
                    : StitchTheme.systemBubbleText,
              ),
            ),
          ],
        ],
      );
    } else {
      // Standard text bubble content
      return Text(
        msg.text,
        style: TextStyle(
          fontSize: 15,
          color: msg.sender == 'user'
              ? StitchTheme.userBubbleText
              : StitchTheme.systemBubbleText,
        ),
      );
    }
  }




  Future<void> _copySelectedMessages(ChatProvider provider) async {
    final messages = provider.getMessagesForChat(widget.chatId);
    final selectedMsgs = messages.where((m) => _selectedMessageIds.contains(m.id)).toList();
    if (selectedMsgs.isEmpty) return;

    selectedMsgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final textToCopy = selectedMsgs.map((m) => m.text).join('\n');

    await Clipboard.setData(ClipboardData(text: textToCopy));

    setState(() {
      _isSelectionMode = false;
      _selectedMessageIds.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Messages copied to clipboard"),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _editSelectedMessage(ChatProvider provider) {
    final messages = provider.getMessagesForChat(widget.chatId);
    final selectedList = messages.where((m) => _selectedMessageIds.contains(m.id)).toList();
    if (selectedList.isEmpty) return;
    final selectedMsg = selectedList.first;
    final controller = TextEditingController(text: selectedMsg.text);

    setState(() {
      _isSelectionMode = false;
      _selectedMessageIds.clear();
    });

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final highlightColor = isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary;

        return AlertDialog(
          scrollable: true,
          backgroundColor: isDark ? StitchTheme.darkSurfaceContainerLow : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Edit Message',
            style: TextStyle(
              color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLines: null,
            autofocus: true,
            decoration: InputDecoration(
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
                final newText = controller.text.trim();
                if (newText.isNotEmpty && newText != selectedMsg.text) {
                  await provider.editMessageText(selectedMsg.id, newText);
                }
                if (context.mounted) {
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

  Future<void> _shareSelectedMessages(ChatProvider provider) async {
    final messages = provider.getMessagesForChat(widget.chatId);
    final selectedMsgs = messages.where((m) => _selectedMessageIds.contains(m.id)).toList();
    if (selectedMsgs.isEmpty) return;

    setState(() {
      _isSelectionMode = false;
      _selectedMessageIds.clear();
    });

    try {
      if (selectedMsgs.length == 1) {
        final msg = selectedMsgs.first;
        if (msg.fileLocalPath != null) {
          final file = File(msg.fileLocalPath!);
          if (await file.exists()) {
            await Share.shareXFiles(
              [XFile(msg.fileLocalPath!)],
              text: msg.text != "Sent a document" && msg.text != "Sent an image" ? msg.text : null,
            );
            return;
          }
        }
        await Share.share(msg.text);
      } else {
        final buffer = StringBuffer();
        for (var msg in selectedMsgs) {
          final sender = msg.sender == 'user' ? 'Me' : 'Memzy';
          final time = DateFormat('h:mm a').format(msg.timestamp);
          buffer.writeln('[$time] $sender: ${msg.text}');
          if (msg.fileName != null) {
            buffer.writeln('Attachment: ${msg.fileName}');
          }
          buffer.writeln();
        }
        await Share.share(buffer.toString().trim());
      }
    } catch (e) {
      debugPrint("Error sharing messages: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sharing failed")),
        );
      }
    }
  }

  Future<void> _starSelectedMessages(ChatProvider provider) async {
    final messages = provider.getMessagesForChat(widget.chatId);
    final selectedMsgs = messages.where((m) => _selectedMessageIds.contains(m.id)).toList();
    final allStarred = selectedMsgs.isNotEmpty && selectedMsgs.every((m) => m.isStarred);

    for (var msg in selectedMsgs) {
      if (allStarred) {
        if (msg.isStarred) {
          await provider.toggleStarMessage(msg.id);
        }
      } else {
        if (!msg.isStarred) {
          await provider.toggleStarMessage(msg.id);
        }
      }
    }
    setState(() {
      _isSelectionMode = false;
      _selectedMessageIds.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(allStarred ? 'Selected messages unstarred' : 'Selected messages starred'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _pinSelectedMessages(ChatProvider provider) async {
    final messages = provider.getMessagesForChat(widget.chatId);
    final selectedMsgs = messages.where((m) => _selectedMessageIds.contains(m.id)).toList();
    final allPinned = selectedMsgs.isNotEmpty && selectedMsgs.every((m) => m.isPinned == true);

    for (var msg in selectedMsgs) {
      if (allPinned) {
        if (msg.isPinned == true) {
          await provider.togglePinMessage(msg.id);
        }
      } else {
        if (msg.isPinned != true) {
          await provider.togglePinMessage(msg.id);
        }
      }
    }
    setState(() {
      _isSelectionMode = false;
      _selectedMessageIds.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(allPinned ? 'Selected messages unpinned' : 'Selected messages pinned'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _deleteSelectedMessages(ChatProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Messages?'),
        content: Text('Are you sure you want to delete these ${_selectedMessageIds.length} messages permanently?'),
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
      for (var id in _selectedMessageIds) {
        await provider.deleteMessage(id);
      }
      setState(() {
        _isSelectionMode = false;
        _selectedMessageIds.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected messages deleted'), duration: Duration(seconds: 1)),
        );
      }
    }
  }


}
