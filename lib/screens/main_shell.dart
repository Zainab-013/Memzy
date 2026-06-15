import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/stitch_theme.dart';
import 'chats_home_screen.dart';
import 'all_reminders_screen.dart';
import 'share_target_dialog.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  StreamSubscription? _intentSub;

  final List<Widget> _screens = const [
    ChatsHomeScreen(),
    AllRemindersScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initSharingIntent();
    // Request notification permissions once on app startup
    NotificationService.requestPermissions();
    // Check if app was launched via notification click
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (NotificationService.initialPayload != null) {
        final payload = NotificationService.initialPayload;
        NotificationService.initialPayload = null; // Clear it
        NotificationService.handleNotificationClick(payload);
      }
    });
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
  }

  void _initSharingIntent() {
    // Listen to media/text sharing coming from outside the app while the app is in memory
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      _handleSharedFiles(value);
    }, onError: (err) {
      debugPrint("getMediaStream error: $err");
    });

    // Get the media/text sharing that brought the app to life from a closed state
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty && mounted) {
        _handleSharedFiles(value);
      }
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    if (files.isEmpty || !mounted) return;
    final file = files.first;
    
    if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
      showDialog(
        context: context,
        builder: (context) => ShareTargetDialog(
          sharedText: file.path,
          sharedType: 'text',
        ),
      );
    } else {
      final path = file.path;
      final extension = path.split('.').last.toLowerCase();
      
      String type = 'document';
      if (extension == 'jpg' || extension == 'jpeg' || extension == 'png' || extension == 'gif') {
        type = 'image';
      } else if (extension == 'pdf') {
        type = 'pdf';
      }

      final name = path.split(Platform.isWindows ? '\\' : '/').last;

      showDialog(
        context: context,
        builder: (context) => ShareTargetDialog(
          sharedFilePath: path,
          sharedFileName: name,
          sharedType: type,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final chatProvider = Provider.of<ChatProvider>(context);
    final selectedIndex = chatProvider.currentTabIndex;

    return Scaffold(
      // Extend body so we can see list content behind the transparent blur navigation bar
      extendBody: true,
      body: IndexedStack(
        index: selectedIndex,
        children: _screens,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72.0), // elevate above nav bar
        child: FloatingActionButton(
          backgroundColor: StitchTheme.primary,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          elevation: 4,
          onPressed: selectedIndex == 0
              ? () => _showCreateChatDialog(context)
              : () => _showCreateReminderDialog(context),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              color: (isDark ? StitchTheme.darkSurface : Colors.white).withValues(alpha: 0.7),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.chat,
                    label: 'Chats',
                    isDark: isDark,
                    selectedIndex: selectedIndex,
                    onTap: () => chatProvider.setTabIndex(0),
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.notifications,
                    label: 'Reminders',
                    isDark: isDark,
                    selectedIndex: selectedIndex,
                    onTap: () => chatProvider.setTabIndex(1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
    required int selectedIndex,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedIndex == index;
    final activeColor = isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary;
    final inactiveColor = isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  // Create Dialog for adding custom chats
  void _showCreateChatDialog(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    final nameController = TextEditingController();
    IconData selectedIcon = Icons.chat;

    final List<IconData> selectableIcons = [
      Icons.chat,
      Icons.work,
      Icons.description,
      Icons.shopping_cart,
      Icons.home,
      Icons.event,
      Icons.school,
      Icons.star,
      Icons.person,
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: isDark ? StitchTheme.darkSurfaceContainerLow : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'New Memory Thread',
                style: TextStyle(
                  color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Thread Title',
                        labelStyle: TextStyle(
                          color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary,
                          ),
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
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose Category Icon',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectableIcons.map((icon) {
                        final isIconSelected = selectedIcon == icon;
                        final highlightColor = isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isIconSelected
                                  ? highlightColor.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isIconSelected
                                    ? highlightColor
                                    : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: isIconSelected
                                  ? highlightColor
                                  : (isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface),
                              size: 24,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StitchTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  ),
                  onPressed: () async {
                    final title = nameController.text.trim();
                    if (title.isNotEmpty) {
                      await chatProvider.createChat(title, iconCode: selectedIcon.codePoint);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Create Dialog for adding custom reminders manually
  void _showCreateReminderDialog(BuildContext context) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    final activeChats = chatProvider.chats.where((c) => !c.isArchived).toList();
    String selectedChatId = 'none';

    final contentController = TextEditingController();
    DateTime selectedDateTime = DateTime.now().add(const Duration(minutes: 1));
    int selectedOption = 0;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final highlightColor = isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary;
            return AlertDialog(
              backgroundColor: isDark ? StitchTheme.darkSurfaceContainerLow : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'New Reminder Task',
                style: TextStyle(
                  color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: contentController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'What to remember?',
                        labelStyle: TextStyle(
                          color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline,
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
                    const SizedBox(height: 20),
                    const Text(
                      'Schedule Time:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTimeChip(
                          label: 'In 1 Min',
                          isSelected: selectedOption == 0,
                          onTap: () {
                            setModalState(() {
                              selectedOption = 0;
                              selectedDateTime = DateTime.now().add(const Duration(minutes: 1));
                            });
                          },
                          isDark: isDark,
                        ),
                        _buildTimeChip(
                          label: 'In 1 Hr',
                          isSelected: selectedOption == 1,
                          onTap: () {
                            setModalState(() {
                              selectedOption = 1;
                              selectedDateTime = DateTime.now().add(const Duration(hours: 1));
                            });
                          },
                          isDark: isDark,
                        ),
                        _buildTimeChip(
                          label: 'In 3 Hrs',
                          isSelected: selectedOption == 2,
                          onTap: () {
                            setModalState(() {
                              selectedOption = 2;
                              selectedDateTime = DateTime.now().add(const Duration(hours: 3));
                            });
                          },
                          isDark: isDark,
                        ),
                        _buildTimeChip(
                          label: 'Tomorrow 8 AM',
                          isSelected: selectedOption == 3,
                          onTap: () {
                            setModalState(() {
                              selectedOption = 3;
                              final tomorrow = DateTime.now().add(const Duration(days: 1));
                              selectedDateTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0);
                            });
                          },
                          isDark: isDark,
                        ),
                        _buildTimeChip(
                          label: 'Tomorrow 10 PM',
                          isSelected: selectedOption == 4,
                          onTap: () {
                            setModalState(() {
                              selectedOption = 4;
                              final tomorrow = DateTime.now().add(const Duration(days: 1));
                              selectedDateTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 22, 0);
                            });
                          },
                          isDark: isDark,
                        ),
                        _buildTimeChip(
                          label: 'Custom...',
                          isSelected: selectedOption == 5,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDateTime,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null && context.mounted) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                              );
                              if (time != null) {
                                setModalState(() {
                                  selectedOption = 5;
                                  selectedDateTime = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            }
                          },
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_filled,
                            size: 16,
                            color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Will remind on: ${DateFormat('MMM d, yyyy - h:mm a').format(selectedDateTime)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Associate with Thread:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      dropdownColor: isDark ? StitchTheme.darkSurfaceContainerLow : Colors.white,
                      initialValue: selectedChatId,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: highlightColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: TextStyle(
                        color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: 'none',
                          child: Row(
                            children: [
                              Icon(
                                Icons.label_off_outlined,
                                size: 18,
                                color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'None (Standalone)',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...activeChats.map((chat) => DropdownMenuItem<String>(
                          value: chat.id,
                          child: Row(
                            children: [
                              Icon(
                                IconData(chat.iconCode, fontFamily: 'MaterialIcons'),
                                size: 18,
                                color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  chat.title,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          selectedChatId = val ?? 'none';
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StitchTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  ),
                  onPressed: () async {
                    final text = contentController.text.trim();
                    if (text.isNotEmpty) {
                      if (selectedChatId == 'none') {
                        await chatProvider.createReminder(
                          chatId: 'none',
                          messageId: 'none',
                          content: text,
                          time: selectedDateTime,
                        );
                      } else {
                        final formattedText = "$text. Remind me on ${DateFormat('d MMMM').format(selectedDateTime)} at ${DateFormat('h:mm a').format(selectedDateTime)}";
                        await chatProvider.sendMessage(
                          chatId: selectedChatId,
                          text: formattedText,
                        );
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTimeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeColor = isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary;
    final activeTextColor = isDark ? Colors.black : Colors.white;
    final inactiveBgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100;
    final inactiveBorderColor = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade300;
    final inactiveTextColor = isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: isSelected ? activeTextColor : inactiveTextColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      selectedColor: activeColor,
      backgroundColor: inactiveBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? Colors.transparent : inactiveBorderColor,
        ),
      ),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
    );
  }
}
