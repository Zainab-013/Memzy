import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../theme/stitch_theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  void _showDetailDialog({
    required BuildContext context,
    required String title,
    required String content,
    required bool isDark,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        final cardBgColor = isDark ? StitchTheme.darkSurfaceContainer : Colors.white;
        final onSurfaceColor = isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface;
        final outlineColor = isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.description_outlined,
                      color: isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary,
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: onSurfaceColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      color: outlineColor,
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Dialog Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Dialog Action
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: StitchTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSupportDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        final cardBgColor = isDark ? StitchTheme.darkSurfaceContainer : Colors.white;
        final onSurfaceColor = isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface;
        final outlineColor = isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.support_agent_rounded,
                    color: isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary,
                  ),
                  title: Text(
                    'Customer Support',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: onSurfaceColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: outlineColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Need assistance? Our support team is here to help with any questions, feedback, or suggestions about Memzy.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                // Contact Details card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mail_outline_rounded, size: 20, color: StitchTheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email Address',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: outlineColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'shaikhyasmeen78600@gmail.com',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: onSurfaceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: outlineColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: StitchTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final Uri emailLaunchUri = Uri(
                            scheme: 'mailto',
                            path: 'shaikhyasmeen78600@gmail.com',
                            queryParameters: {
                              'subject': 'Memzy Support & Feedback',
                            },
                          );
                          try {
                            if (await canLaunchUrl(emailLaunchUri)) {
                              await launchUrl(emailLaunchUri);
                            } else {
                              throw 'Could not launch email client';
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not open email app. Please write to shaikhyasmeen78600@gmail.com'),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Send Email',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final titleColor = isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface;
    final subtitleColor = isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant;
    final cardBgColor = isDark ? StitchTheme.darkSurfaceContainerLowest : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? StitchTheme.darkBackground : StitchTheme.background,
      appBar: AppBar(
        backgroundColor: isDark ? StitchTheme.darkBackground : StitchTheme.background,
        elevation: 0,
        title: Text(
          'About Us',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Learn about Memzy, local data terms, and guidelines.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? StitchTheme.darkOnSurfaceVariant
                          : StitchTheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),

              // App Brand Info Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? StitchTheme.darkSurfaceContainerLow : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                  ),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Memzy',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0 ',
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // About Us Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Memzy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Memzy is a personal memory thread companion designed to help you capture, organize, and recall important information from your everyday life. Similar to the layout of chat apps you already use, Memzy allows you to open standalone categories or themed chats where you can type notes, save links, store images, and keep documents.\n\nOur smart system automatically scans your messages for reminder prompts and sets calendar actions, creating a seamless, natural workflow to keep you on schedule.',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quote Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Your mind is for having ideas, not holding them.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: titleColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '— David Allen',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bottom Links Section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomTextLink(
                      label: 'Terms',
                      isDark: isDark,
                      onPressed: () => _showDetailDialog(
                        context: context,
                        title: 'Terms of Service',
                        content: _fullTermsContent,
                        isDark: isDark,
                      ),
                    ),
                    _buildDivider(isDark),
                    _buildBottomTextLink(
                      label: 'Privacy Policy',
                      isDark: isDark,
                      onPressed: () => _showDetailDialog(
                        context: context,
                        title: 'Privacy Policy',
                        content: _fullPrivacyContent,
                        isDark: isDark,
                      ),
                    ),
                    _buildDivider(isDark),
                    _buildBottomTextLink(
                      label: 'Support',
                      isDark: isDark,
                      onPressed: () => _showSupportDialog(context, isDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100), // bottom bar spacer
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomTextLink({
    required String label,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 14,
      color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.15),
    );
  }

  static const String _fullTermsContent = '''
Welcome to Memzy!

By using our mobile application ("Memzy"), you agree to abide by and be bound by the following Terms and Conditions of Service. Please read these terms carefully before accessing or using any aspect of the application.

1. ACCEPTANCE OF TERMS
By creating threads, logging messages, or otherwise interacting with Memzy, you acknowledge that you have read, understood, and agreed to these terms. If you do not accept these terms, you are not authorized to use the app.

2. OFFLINE-FIRST & DEVICE LOCAL STORAGE
Memzy is designed to operate completely offline on your device. All databases, index profiles, chat histories, links, images, files, and notification schedules are created and stored locally using Hive technology on your own hardware. 
- We do not operate server infrastructure to hold your data.
- We do not synchronize your conversations or files to external cloud environments.
- You are solely responsible for protecting, archiving, backing up, or exporting your local databases. Deleting the application or clearing storage will permanently erase all local records.

3. REMINDER NOTIFICATIONS
Memzy relies on local system-level scheduling libraries (flutter_local_notifications) to trigger reminders. 
- You must grant appropriate operating system permissions for notifications to show at scheduled times.
- System optimization features (such as battery saving profiles, RAM cleaners, or app hibernation settings) may prevent local notifications from firing. Memzy is not liable for missed reminders or tasks resulting from OS battery constraints.

4. USER CONDUCT & FILE STORAGE
You agree that you will not use Memzy to save, capture, or display content that violates local, national, or international laws. 
- You retain full and exclusive ownership of all text and media stored.
- Memzy has no access to verify, moderate, or delete any content stored in your local application database.

5. DISCLAIMER OF WARRANTIES
Memzy is provided on an "AS IS" and "AS AVAILABLE" basis. We make no warranties, express or implied, regarding the reliability, security, accuracy, or uninterrupted function of the application or its automatic reminder parsing algorithm.

6. LIMITATION OF LIABILITY
To the maximum extent permitted by law, the developers of Memzy shall not be liable for any direct, indirect, incidental, special, or consequential damages (including, but not limited to, loss of data, missed events, or device failure) arising out of the use or inability to use the application.

7. CHANGES TO TERMS
We reserve the right to revise these Terms and Conditions at any time. Any changes will be updated inside this screen within the application. Continued use of the application following updates constitutes your acceptance of the revised terms.
''';

  static const String _fullPrivacyContent = '''
Last Updated: June 2026

At Memzy, we believe in complete, absolute user privacy. Our design philosophy centers on a simple principle: your private memories and information should remain exclusively yours.

1. INFORMATION WE DO NOT COLLECT
Because Memzy is built as a local-only mobile tool, we do not collect, capture, transmit, or monitor your personal data.
- No Text Logging: The messages you write and reminders you parse are saved purely in local files on your device. We cannot read them.
- No File Access: Any screenshots, images, PDFs, or documents you share into Memzy remain in your device's protected local directory. No external uploads occur.
- No Accounts: You do not need to register, create an account, or log in with third-party credentials to use Memzy. There are no tracking profiles linked to your usage.
- No Analytics: We do not use third-party behavioral analytics, crash reporting platforms that gather user-specific identifiers, or marketing trackers.

2. DEVICE PERMISSIONS
To enable key functionalities of Memzy, we request access to certain system tools. Here is why we need them and how they are handled:
- Notifications: Required to dispatch local audio/visual alerts when your reminder schedule is due. The alert content is constructed offline.
- Storage & Files: Required if you choose to attach images, screenshots, PDFs, or documents to your memory threads. Files are read locally and saved under the app's local sandbox directory.
- Sharing Stream: Required to allow you to select Memzy in your device's native "Share Sheet" while browsing other apps. The shared text or file is only processed locally when you approve saving it.

3. DATA RETENTION
All information is saved using Hive database instances, which reside within the private application directory allocated by the mobile Operating System.
- Your data remains stored for as long as Memzy is installed.
- You can instantly delete all messages, chats, and reminders inside the app settings or by clearing the application cache/data in your device settings.
- Uninstalling Memzy will wipe all associated databases and files immediately. These cannot be recovered.

4. SECURITY
While we do not transmit your data over the internet, the physical security of your data depends on your device. We recommend securing your smartphone with pin/biometric locks to prevent unauthorized physical access to your local Memzy database.

5. CONTACT US
If you have any questions, feedback, or concerns regarding our privacy policies, feel free to contact our customer support team directly at shaikhyasmeen78600@gmail.com.
''';
}
