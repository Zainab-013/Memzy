import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/stitch_theme.dart';
import 'chats_home_screen.dart';
import 'all_reminders_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    ChatsHomeScreen(),
    AllRemindersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      // Extend body so we can see list content behind the transparent blur navigation bar
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: _selectedIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 72.0), // elevate above nav bar
              child: FloatingActionButton(
                backgroundColor: StitchTheme.primary,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                elevation: 4,
                onPressed: () => _showCreateChatDialog(context),
                child: const Icon(Icons.add, size: 28),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              color: (isDark ? StitchTheme.darkSurface : Colors.white).withOpacity(0.7),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.chat,
                    label: 'Chats',
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.notifications,
                    label: 'Reminders',
                    isDark: isDark,
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
  }) {
    final isSelected = _selectedIndex == index;
    final activeColor = isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary;
    final inactiveColor = isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withOpacity(0.12)
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
                                  ? highlightColor.withOpacity(0.2)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isIconSelected
                                    ? highlightColor
                                    : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300),
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
}
