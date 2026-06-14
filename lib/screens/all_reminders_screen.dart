import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/reminder.dart';
import '../theme/stitch_theme.dart';

class AllRemindersScreen extends StatefulWidget {
  const AllRemindersScreen({super.key});

  @override
  State<AllRemindersScreen> createState() => _AllRemindersScreenState();
}

class _AllRemindersScreenState extends State<AllRemindersScreen> {
  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final today = chatProvider.todayReminders;
    final upcoming = chatProvider.upcomingReminders;
    final completed = chatProvider.completedReminders;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? StitchTheme.darkBackground : StitchTheme.background,
        elevation: 0,
        title: Row(
          children: [
            Icon(
              Icons.memory,
              color: isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Memzy',
              style: TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.bold,
                color: isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Title
                Text(
                  'Reminders',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontFamily: 'Geist',
                        color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stay on track with your cognitive assistant.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Geist',
                        color: isDark
                            ? StitchTheme.darkOnSurfaceVariant
                            : StitchTheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),

                // Today Section
                if (today.isNotEmpty) ...[
                  _buildSectionHeader('Today', today.length.toString(), StitchTheme.primary, isDark),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: today.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildReminderCard(context, today[index], isDark, chatProvider, false),
                  ),
                  const SizedBox(height: 24),
                ],

                // Upcoming Section
                if (upcoming.isNotEmpty) ...[
                  _buildSectionHeader('Upcoming', null, StitchTheme.secondary, isDark),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: upcoming.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildReminderCard(context, upcoming[index], isDark, chatProvider, false),
                  ),
                  const SizedBox(height: 24),
                ],

                // Completed Section
                if (completed.isNotEmpty) ...[
                  _buildSectionHeader('Completed', null, isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.outline, isDark),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: 0.6,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: completed.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _buildReminderCard(context, completed[index], isDark, chatProvider, true),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Fallback empty view
                if (today.isEmpty && upcoming.isEmpty && completed.isEmpty) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Text(
                        "No reminders created yet.\nReminders are auto-extracted when you type messages containing times (e.g. 'Remind me at 10 PM')",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? StitchTheme.darkOnSurfaceVariant
                              : StitchTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Tip of the day card
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: isDark ? StitchTheme.darkSurfaceContainerLowest : Colors.grey.shade200,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Amethyst Aesthetic Gradient
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF883CA6),
                              Color(0xFF4648D4),
                            ],
                            begin: Alignment.bottomRight,
                            end: Alignment.topLeft,
                          ),
                        ),
                      ),
                      // Decorative Circle
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      // Text Contents overlay
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tip of the day'.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Focus on one task at a time.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? badgeText, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        if (badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? StitchTheme.darkSurfaceContainer : StitchTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$badgeText Task${int.parse(badgeText) > 1 ? "s" : ""}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReminderCard(
      BuildContext context, Reminder reminder, bool isDark, ChatProvider provider, bool isDone) {
    final formattedTime = isDone
        ? "Completed"
        : _formatDateTime(reminder.time);

    final icon = isDone
        ? Icons.done_all
        : (reminder.time.day == DateTime.now().day ? Icons.schedule : Icons.event);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? StitchTheme.darkSurfaceContainerLowest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular custom check box
          GestureDetector(
            onTap: () => provider.toggleReminderCompletion(reminder.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? StitchTheme.primary : Colors.transparent,
                border: Border.all(
                  color: isDone ? StitchTheme.primary : (isDark ? StitchTheme.outlineVariant : StitchTheme.outline),
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),

          // Reminder Information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.content,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (target == today) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (target == tomorrow) {
      return "Tomorrow ${DateFormat('h:mm a').format(dateTime)}";
    } else {
      return "${DateFormat('MMM d').format(dateTime)} ${DateFormat('h:mm a').format(dateTime)}";
    }
  }
}
