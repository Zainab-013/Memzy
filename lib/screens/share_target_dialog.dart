import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/stitch_theme.dart';

class ShareTargetDialog extends StatelessWidget {
  final String? sharedText;
  final String? sharedFilePath;
  final String? sharedFileName;
  final int? sharedFileSize;
  final String sharedType; // 'text', 'image', 'pdf', 'document'

  const ShareTargetDialog({
    super.key,
    this.sharedText,
    this.sharedFilePath,
    this.sharedFileName,
    this.sharedFileSize,
    required this.sharedType,
  });

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final activeChats = chatProvider.chats.where((c) => !c.isArchived).toList();

    return AlertDialog(
      backgroundColor: isDark ? StitchTheme.darkSurfaceContainerLow : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.forward, color: StitchTheme.primary),
          const SizedBox(width: 8),
          Text(
            'Forward to Memzy',
            style: TextStyle(
              color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview of shared item
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? StitchTheme.darkSurfaceContainer : StitchTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    sharedType == 'text'
                        ? Icons.text_snippet
                        : (sharedType == 'image'
                            ? Icons.image
                            : (sharedType == 'pdf' ? Icons.picture_as_pdf : Icons.insert_drive_file)),
                    color: StitchTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sharedType == 'text'
                          ? (sharedText ?? '')
                          : (sharedFileName ?? 'Shared file'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select target thread:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            activeChats.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Text('No active threads. Please create a thread first.'),
                  )
                : Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: activeChats.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final chat = activeChats[index];
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

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: avatarBgColor,
                            radius: 18,
                            child: Icon(
                              IconData(chat.iconCode, fontFamily: 'MaterialIcons'),
                              color: avatarIconColor,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            chat.title,
                            style: TextStyle(
                              color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                            ),
                          ),
                          onTap: () async {
                            if (sharedType == 'text') {
                              await chatProvider.sendMessage(
                                chatId: chat.id,
                                text: sharedText!,
                              );
                            } else {
                              await chatProvider.sendMessage(
                                chatId: chat.id,
                                text: "Imported attachment",
                                type: sharedType,
                                fileLocalPath: sharedFilePath,
                                fileName: sharedFileName,
                                fileSize: sharedFileSize,
                              );
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Successfully forwarded to ${chat.title}!'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
