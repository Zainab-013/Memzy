import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/stitch_theme.dart';
import '../widgets/passcode_view.dart';

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
      scrollable: true,
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
      content: Column(
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
              : Column(
                  children: activeChats.map((chat) {
                    final avatarIconColor = StitchTheme.getAvatarIconColor(chat.title, isDark);

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: StitchTheme.getAvatarGradient(chat.title, isDark),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              StitchTheme.getChatIcon(chat.iconCode),
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
                            if (chat.isLocked) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (routeContext) => PasscodeView(
                                    mode: 'verify',
                                    title: "Unlock ${chat.title}",
                                    onSuccess: (passcode) async {
                                      Navigator.pop(routeContext); // pop passcode view
                                      
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
                                        Navigator.pop(context); // pop ShareTargetDialog
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Successfully forwarded to ${chat.title}!'),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    onCancel: () => Navigator.pop(routeContext),
                                  ),
                                ),
                              );
                            } else {
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
                            }
                          },
                        ),
                        const Divider(height: 1),
                      ],
                    );
                  }).toList(),
                ),
        ],
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
