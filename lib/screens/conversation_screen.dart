import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/message.dart';
import '../theme/stitch_theme.dart';
import 'chat_info_screen.dart';
import '../widgets/full_screen_image_viewer.dart';

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
    if (text.isEmpty) return;

    _textController.clear();
    final provider = Provider.of<ChatProvider>(context, listen: false);
    await provider.sendMessage(chatId: widget.chatId, text: text);
    
    // Animate to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        final provider = Provider.of<ChatProvider>(context, listen: false);
        final file = File(image.path);
        final fileName = image.name;
        final fileSize = await file.length();

        await provider.sendMessage(
          chatId: widget.chatId,
          text: "Sent an image",
          type: 'image',
          fileLocalPath: image.path,
          fileName: fileName,
          fileSize: fileSize,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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
      );

      if (result != null && result.files.single.path != null && mounted) {
        final provider = Provider.of<ChatProvider>(context, listen: false);
        final path = result.files.single.path!;
        final name = result.files.single.name;
        final size = result.files.single.size;
        final extension = result.files.single.extension?.toLowerCase() ?? 'document';

        await provider.sendMessage(
          chatId: widget.chatId,
          text: "Sent a document",
          type: extension == 'pdf' ? 'pdf' : 'document',
          fileLocalPath: path,
          fileName: name,
          fileSize: size,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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

    final chat = chatProvider.chats.firstWhere((c) => c.id == widget.chatId);
    final messages = chatProvider.getMessagesForChat(widget.chatId);
    final displayedMessages = _searchQuery.isEmpty
        ? messages
        : messages
            .where((m) => m.text.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    final allStarred = _selectedMessageIds.isNotEmpty &&
        messages.where((m) => _selectedMessageIds.contains(m.id)).every((m) => m.isStarred);

    // Suggestion chips matching HTML prototypes
    final suggestionChips = chat.title == "Placement Prep"
        ? ["Add to Calendar", "Draft Email", "Search Roles"]
        : ["Mark Done", "Save PDF Link", "Set Reminder"];

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
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareSelectedMessages(chatProvider),
                ),
                IconButton(
                  icon: Icon(allStarred ? Icons.star_border : Icons.star, color: Colors.amber),
                  onPressed: () => _starSelectedMessages(chatProvider),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSelectedMessages(chatProvider),
                ),
              ],
            )
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
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
                  : Row(
                      children: [
                        // Chat icon avatar with active indicator
                        Stack(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: avatarBgColor,
                              ),
                              child: Icon(
                                IconData(chat.iconCode, fontFamily: 'MaterialIcons'),
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
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'info',
                      child: Text('Chat Info'),
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
                            color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? "Start your memory chain.\nSend files or set reminders directly."
                                : "No matching messages found.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
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
                                  color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline,
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
                        backgroundColor: isDark ? StitchTheme.darkSurfaceContainer : StitchTheme.surfaceContainerHigh,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: const BorderSide(color: Colors.transparent),
                        label: Text(
                          chip,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: StitchTheme.primary,
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
                              decoration: const InputDecoration(
                                hintText: 'Recall something...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
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

    final bubbleWidget = Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMe) ...[
                // Star option on hover/longpress (we show star icon if starred)
                if (msg.isStarred)
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
              ],
              GestureDetector(
                onTap: () {
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
                      await OpenFilex.open(msg.fileLocalPath);
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
                onLongPress: () {
                  if (!_isSelectionMode) {
                    setState(() {
                      _isSelectionMode = true;
                      _selectedMessageIds.add(msg.id);
                    });
                  }
                },
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                            colors: [StitchTheme.primary, StitchTheme.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMe
                        ? null
                        : (isDark ? StitchTheme.darkSurfaceContainer : StitchTheme.surfaceContainerHighest),
                    borderRadius: isMe ? StitchTheme.userBubbleRadius : StitchTheme.systemBubbleRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: _buildBubbleContent(msg, isDark),
                ),
              ),
              if (!isMe) ...[
                const SizedBox(width: 4),
                if (msg.isStarred)
                  const Icon(Icons.star, size: 14, color: Colors.amber),
              ],
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isMe ? 0 : 8.0,
              right: isMe ? 8.0 : 0,
              bottom: 12.0,
            ),
            child: Text(
              formattedTime,
              style: const TextStyle(
                fontSize: 10,
                color: StitchTheme.outline,
              ),
            ),
          ),
        ],
      ),
    );

    if (_isSelectionMode) {
      final checkbox = GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedMessageIds.remove(msg.id);
            } else {
              _selectedMessageIds.add(msg.id);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 20.0),
          child: Icon(
            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: StitchTheme.primary,
            size: 24,
          ),
        ),
      );

      return Row(
        children: isMe
            ? [
                Expanded(child: bubbleWidget),
                checkbox,
              ]
            : [
                checkbox,
                Expanded(child: bubbleWidget),
              ],
      );
    }

    return bubbleWidget;
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
                    )
                  : Container(
                      height: 150,
                      color: Colors.grey.shade300,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image, size: 48),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            msg.fileName ?? "image.jpg",
            style: TextStyle(
              fontSize: 12,
              color: msg.sender == 'user' ? Colors.white : (isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface),
            ),
          ),
        ],
      );
    } else if (msg.type == 'pdf' || msg.type == 'document') {
      final isPdf = msg.type == 'pdf';
      return Row(
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
                    color: msg.sender == 'user' ? Colors.white : (isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  msg.fileSize != null
                      ? "${(msg.fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB • ${msg.type.toUpperCase()}"
                      : msg.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: msg.sender == 'user' ? Colors.white.withValues(alpha: 0.7) : StitchTheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Standard text bubble content
      return Text(
        msg.text,
        style: TextStyle(
          fontSize: 15,
          color: msg.sender == 'user'
              ? Colors.white
              : (isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface),
        ),
      );
    }
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
