import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/message.dart';
import '../theme/stitch_theme.dart';
import '../widgets/full_screen_image_viewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';


class ChatAttachmentsScreen extends StatefulWidget {
  final String chatId;
  final int initialTabIndex; // 0: Photos, 1: PDFs, 2: Links, 3: Messages, 4: Starred

  const ChatAttachmentsScreen({
    super.key,
    required this.chatId,
    this.initialTabIndex = 0,
  });

  @override
  State<ChatAttachmentsScreen> createState() => _ChatAttachmentsScreenState();
}

class _ChatAttachmentsScreenState extends State<ChatAttachmentsScreen> {
  late int _activeTab;
  bool _isSelectionMode = false;
  final Set<String> _selectedItemIds = {};

  final RegExp _urlRegex = RegExp(
    r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
    caseSensitive: false,
  );

  Future<void> _downloadFile(Message msg) async {
    if (msg.fileLocalPath == null) return;
    final sourceFile = File(msg.fileLocalPath!);
    if (!await sourceFile.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Source file does not exist locally.')),
        );
      }
      return;
    }

    try {
      String targetPath = '';
      bool success = false;

      // Try public Download folder on Android first
      if (Platform.isAndroid) {
        try {
          final publicDir = Directory('/storage/emulated/0/Download');
          if (await publicDir.exists()) {
            targetPath = '${publicDir.path}/${msg.fileName ?? "downloaded_file"}';
            await sourceFile.copy(targetPath);
            success = true;
          }
        } catch (_) {
          // Suppress public download copy failure and proceed to fallback
        }
      }

      // Fallback if public download failed or on iOS/Desktop
      if (!success) {
        Directory? fallbackDir;
        if (Platform.isAndroid) {
          fallbackDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        } else {
          fallbackDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        }
        targetPath = '${fallbackDir.path}/${msg.fileName ?? "downloaded_file"}';
        await sourceFile.copy(targetPath);
        success = true;
      }

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to: $targetPath'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading file: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTabIndex;
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
    final allStarred = _selectedItemIds.isNotEmpty &&
        messages.where((m) => _selectedItemIds.contains(m.id)).every((m) => m.isStarred);

    // Photos & Images
    final photos = messages.where((m) => m.type == 'image').toList();

    // PDFs & Docs
    final docs = messages.where((m) => m.type == 'pdf' || m.type == 'document').toList();

    // Text messages
    final textMsgs = messages.where((m) => m.type == 'text').toList();

    // Starred Messages
    final starred = messages.where((m) => m.isStarred).toList();

    // Links extracted from text messages
    final List<Map<String, String>> links = [];
    for (var m in messages) {
      if (m.type == 'text' && _urlRegex.hasMatch(m.text)) {
        final matches = _urlRegex.allMatches(m.text);
        for (var match in matches) {
          final url = match.group(0)!;
          String title = m.text.replaceFirst(url, '').trim();
          if (title.isEmpty) {
            title = "Shared Link";
          }
          links.add({
            'id': m.id,
            'title': title,
            'url': url,
            'time': DateFormat('MMM d, h:mm a').format(m.timestamp),
          });
        }
      }
    }

    final List<String> tabLabels = ['Photos & Images', 'PDFs & Docs', 'Links', 'Messages', 'Starred'];

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 48,
        titleSpacing: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedItemIds.clear();
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.chevron_left),
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(_isSelectionMode ? '${_selectedItemIds.length} Selected' : '${chat.title} Attachments'),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareSelectedItems(chatProvider),
                ),
                IconButton(
                  icon: Icon(allStarred ? Icons.star : Icons.star_border, color: Colors.amber),
                  onPressed: () => _starSelectedItems(chatProvider),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSelectedItems(chatProvider),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Pill filter chips section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              height: 64,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: tabLabels.length,
                itemBuilder: (context, index) {
                  final isSelected = _activeTab == index;
                  final inactiveColor = isDark ? StitchTheme.darkSurfaceContainer : StitchTheme.surfaceContainerHigh;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(tabLabels[index]),
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant),
                      ),
                      selectedColor: StitchTheme.primary,
                      backgroundColor: inactiveColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: const BorderSide(color: Colors.transparent),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _activeTab = index;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),

            // Content body list/grid
            Expanded(
              child: _buildTabContent(photos, docs, links, textMsgs, starred, isDark, chatProvider),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _shareSelectedItems(ChatProvider provider) async {
    final messages = provider.getMessagesForChat(widget.chatId);
    final selectedMsgs = messages.where((m) => _selectedItemIds.contains(m.id)).toList();
    if (selectedMsgs.isEmpty) return;

    setState(() {
      _isSelectionMode = false;
      _selectedItemIds.clear();
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
        final filePaths = selectedMsgs
            .where((m) => m.fileLocalPath != null)
            .map((m) => m.fileLocalPath!)
            .toList();

        if (filePaths.isNotEmpty) {
          final xFiles = <XFile>[];
          for (var path in filePaths) {
            if (await File(path).exists()) {
              xFiles.add(XFile(path));
            }
          }
          if (xFiles.isNotEmpty) {
            await Share.shareXFiles(xFiles);
            return;
          }
        }

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
      debugPrint("Error sharing items: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sharing failed")),
        );
      }
    }
  }

  Future<void> _starSelectedItems(ChatProvider provider) async {
    final messages = provider.getMessagesForChat(widget.chatId);
    final selectedMsgs = messages.where((m) => _selectedItemIds.contains(m.id)).toList();
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
      _selectedItemIds.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(allStarred ? 'Selected items unstarred' : 'Selected items starred'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _deleteSelectedItems(ChatProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Items?'),
        content: Text('Are you sure you want to delete these ${_selectedItemIds.length} items permanently?'),
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
      for (var id in _selectedItemIds) {
        await provider.deleteMessage(id);
      }
      setState(() {
        _isSelectionMode = false;
        _selectedItemIds.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected items deleted'), duration: Duration(seconds: 2)),
        );
      }
    }
  }

  Widget _buildTabContent(
    List<Message> photos,
    List<Message> docs,
    List<Map<String, String>> links,
    List<Message> textMsgs,
    List<Message> starred,
    bool isDark,
    ChatProvider provider,
  ) {
    switch (_activeTab) {
      case 0: // Photos
        if (photos.isEmpty) return _buildEmptyState("No photos or images in this thread.", Icons.image, isDark);
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final msg = photos[index];
            final isSelected = _selectedItemIds.contains(msg.id);
            return GestureDetector(
              onTap: () {
                if (_isSelectionMode) {
                  setState(() {
                    if (isSelected) {
                      _selectedItemIds.remove(msg.id);
                    } else {
                      _selectedItemIds.add(msg.id);
                    }
                  });
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageViewer(
                        imagePath: msg.fileLocalPath,
                        fileName: msg.fileName ?? "image.jpg",
                        heroTag: "attachment_${msg.fileLocalPath ?? msg.id}",
                      ),
                    ),
                  );
                }
              },
              onLongPress: () {
                if (!_isSelectionMode) {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedItemIds.add(msg.id);
                  });
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? StitchTheme.darkSurfaceContainer : StitchTheme.surfaceContainerLow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: msg.fileLocalPath != null
                        ? Hero(
                            tag: "attachment_${msg.fileLocalPath ?? msg.id}",
                            child: Image.file(
                              File(msg.fileLocalPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade300,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.broken_image, size: 32),
                                );
                              },
                            ),
                          )
                        : const Center(child: Icon(Icons.image, color: StitchTheme.outline)),
                  ),
                  if (_isSelectionMode)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        child: Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: StitchTheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      case 1: // PDFs
        if (docs.isEmpty) return _buildEmptyState("No documents or PDFs in this thread.", Icons.insert_drive_file, isDark);
        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final msg = docs[index];
            final isPdf = msg.type == 'pdf';
            final isSelected = _selectedItemIds.contains(msg.id);
            return GestureDetector(
              onTap: () async {
                if (_isSelectionMode) {
                  setState(() {
                    if (isSelected) {
                      _selectedItemIds.remove(msg.id);
                    } else {
                      _selectedItemIds.add(msg.id);
                    }
                  });
                } else if (msg.fileLocalPath != null) {
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
                    debugPrint("Error opening document: $e");
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
                    _selectedItemIds.add(msg.id);
                  });
                }
              },
              child: Row(
                children: [
                  if (_isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: StitchTheme.primary,
                        size: 24,
                      ),
                    ),
                  Expanded(
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
                              color: isPdf ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPdf ? Icons.picture_as_pdf : Icons.description,
                              color: isPdf ? Colors.red : Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.fileName ?? "Document",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
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
                          if (!_isSelectionMode)
                            IconButton(
                              icon: const Icon(Icons.download, color: StitchTheme.primary),
                              onPressed: () => _downloadFile(msg),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      case 2: // Links
        if (links.isEmpty) return _buildEmptyState("No extracted links in this thread.", Icons.link, isDark);
        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: links.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final link = links[index];
            final linkId = link['id']!;
            final isSelected = _selectedItemIds.contains(linkId);
            return GestureDetector(
              onTap: () async {
                if (_isSelectionMode) {
                  setState(() {
                    if (isSelected) {
                      _selectedItemIds.remove(linkId);
                    } else {
                      _selectedItemIds.add(linkId);
                    }
                  });
                } else {
                  final url = link['url']!;
                  final uri = Uri.tryParse(url);
                  if (uri != null) {
                    try {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not launch link: $url')),
                        );
                      }
                    }
                  }
                }
              },
              onLongPress: () {
                if (!_isSelectionMode) {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedItemIds.add(linkId);
                  });
                }
              },
              child: Row(
                children: [
                  if (_isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: StitchTheme.primary,
                        size: 24,
                      ),
                    ),
                  Expanded(
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
                                  link['title']!,
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
                                  link['url']!,
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
                          if (!_isSelectionMode)
                            Icon(Icons.chevron_right, color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      case 3: // Messages
        if (textMsgs.isEmpty) return _buildEmptyState("No text messages in this thread.", Icons.chat_bubble_outline, isDark);
        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: textMsgs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final msg = textMsgs[index];
            final isMe = msg.sender == 'user';
            final isSelected = _selectedItemIds.contains(msg.id);
            return GestureDetector(
              onTap: () {
                if (_isSelectionMode) {
                  setState(() {
                    if (isSelected) {
                      _selectedItemIds.remove(msg.id);
                    } else {
                      _selectedItemIds.add(msg.id);
                    }
                  });
                }
              },
              onLongPress: () {
                if (!_isSelectionMode) {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedItemIds.add(msg.id);
                  });
                }
              },
              child: Row(
                children: [
                  if (_isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: StitchTheme.primary,
                        size: 24,
                      ),
                    ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? StitchTheme.darkSurfaceContainerLowest : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isMe ? 'You' : 'System',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isMe ? StitchTheme.primary : StitchTheme.secondary,
                                ),
                              ),
                              Text(
                                DateFormat('MMM d, h:mm a').format(msg.timestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            msg.text,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      case 4: // Starred
        if (starred.isEmpty) return _buildEmptyState("No starred messages in this thread.", Icons.star_border, isDark);
        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: starred.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final msg = starred[index];
            final isMe = msg.sender == 'user';
            final isSelected = _selectedItemIds.contains(msg.id);
            return GestureDetector(
              onTap: () async {
                if (_isSelectionMode) {
                  setState(() {
                    if (isSelected) {
                      _selectedItemIds.remove(msg.id);
                    } else {
                      _selectedItemIds.add(msg.id);
                    }
                  });
                } else {
                  if (msg.type == 'image') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImageViewer(
                          imagePath: msg.fileLocalPath,
                          fileName: msg.fileName ?? "image.jpg",
                          heroTag: "starred_attachment_${msg.fileLocalPath ?? msg.id}",
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
                  } else if (msg.type == 'text' && _urlRegex.hasMatch(msg.text)) {
                    final matches = _urlRegex.allMatches(msg.text);
                    if (matches.isNotEmpty) {
                      final url = matches.first.group(0)!;
                      final uri = Uri.tryParse(url);
                      if (uri != null) {
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not launch link: $url')),
                            );
                          }
                        }
                      }
                    }
                  }
                }
              },
              onLongPress: () {
                if (!_isSelectionMode) {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedItemIds.add(msg.id);
                  });
                }
              },
              child: Row(
                children: [
                  if (_isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: StitchTheme.primary,
                        size: 24,
                      ),
                    ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? StitchTheme.darkSurfaceContainerLowest : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isMe ? 'You' : 'System',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isMe ? StitchTheme.primary : StitchTheme.secondary,
                                ),
                              ),
                              Text(
                                DateFormat('MMM d, h:mm a').format(msg.timestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
                                  fontSize: 14,
                                  color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
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
                                  fontSize: 14,
                                  color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                                ),
                              ),
                            ],
                          ] else ...[
                            Text(
                              msg.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      default:
        return Container();
    }
  }

  Widget _buildEmptyState(String text, IconData icon, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
