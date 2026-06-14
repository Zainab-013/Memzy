import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/message.dart';
import '../theme/stitch_theme.dart';
import '../widgets/full_screen_image_viewer.dart';

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

    final chat = chatProvider.chats.firstWhere((c) => c.id == widget.chatId);
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
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedItemIds.clear();
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(_isSelectionMode ? '${_selectedItemIds.length} Selected' : '${chat.title} Attachments'),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: Icon(allStarred ? Icons.star_border : Icons.star, color: Colors.amber),
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
                            : (isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline),
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
        if (photos.isEmpty) return _buildEmptyState("No photos or images in this thread.", Icons.image);
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
        if (docs.isEmpty) return _buildEmptyState("No documents or PDFs in this thread.", Icons.insert_drive_file);
        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final msg = docs[index];
            final isPdf = msg.type == 'pdf';
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
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: StitchTheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_isSelectionMode)
                            IconButton(
                              icon: const Icon(Icons.download, color: StitchTheme.primary),
                              onPressed: () {},
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
        if (links.isEmpty) return _buildEmptyState("No extracted links in this thread.", Icons.link);
        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: links.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final link = links[index];
            final linkId = link['id']!;
            final isSelected = _selectedItemIds.contains(linkId);
            return GestureDetector(
              onTap: () {
                if (_isSelectionMode) {
                  setState(() {
                    if (isSelected) {
                      _selectedItemIds.remove(linkId);
                    } else {
                      _selectedItemIds.add(linkId);
                    }
                  });
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
                          if (!_isSelectionMode)
                            const Icon(Icons.chevron_right, color: StitchTheme.outline),
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
        if (textMsgs.isEmpty) return _buildEmptyState("No text messages in this thread.", Icons.chat_bubble_outline);
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
                                style: const TextStyle(fontSize: 11, color: StitchTheme.outline),
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
        if (starred.isEmpty) return _buildEmptyState("No starred messages in this thread.", Icons.star_border);
        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: starred.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final msg = starred[index];
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
                                style: const TextStyle(fontSize: 11, color: StitchTheme.outline),
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
      default:
        return Container();
    }
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: StitchTheme.outline),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(color: StitchTheme.outline)),
        ],
      ),
    );
  }
}
