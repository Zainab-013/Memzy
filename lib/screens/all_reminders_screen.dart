import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/reminder.dart';
import '../theme/stitch_theme.dart';
import 'conversation_screen.dart';
import 'dart:math' as math;

class AllRemindersScreen extends StatefulWidget {
  const AllRemindersScreen({super.key});

  @override
  State<AllRemindersScreen> createState() => _AllRemindersScreenState();
}

class _AllRemindersScreenState extends State<AllRemindersScreen> {
  String? _selectedFilter = 'All';
  final Set<String> _selectedReminderIds = {};
  final Set<String> _completingReminderIds = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final today = chatProvider.todayReminders;
    final upcoming = chatProvider.upcomingReminders;
    final anytime = chatProvider.anytimeReminders;
    final completed = chatProvider.completedReminders;

    // Calculate Overdue Reminders
    final overdue = chatProvider.reminders.where((r) {
      return r.time != null && r.time!.isBefore(DateTime.now()) && !r.isCompleted;
    }).toList();

    final hasAnyReminders = today.isNotEmpty || upcoming.isNotEmpty || anytime.isNotEmpty || completed.isNotEmpty || overdue.isNotEmpty;

    final selectedReminder = _selectedReminderIds.length == 1
        ? chatProvider.reminders.firstWhere((r) => r.id == _selectedReminderIds.first)
        : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? StitchTheme.darkBackground : StitchTheme.background,
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, size: 22),
                color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedReminderIds.clear();
                  });
                },
              )
            : null,
        title: Text(
          _isSelectionMode
              ? '${_selectedReminderIds.length} Selected'
              : 'Reminders',
          style: _isSelectionMode
              ? TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                  fontSize: 18,
                  height: 1.0,
                )
              : TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                ),
        ),
        actions: _isSelectionMode
            ? [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 48),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_areAllSelected(chatProvider)) {
                        _selectedReminderIds.clear();
                      } else {
                        final visible = _getFilteredRemindersList(chatProvider);
                        _selectedReminderIds.addAll(visible.map((r) => r.id));
                      }
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'All',
                        style: TextStyle(
                          color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _areAllSelected(chatProvider)
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                        size: 22,
                      ),
                    ],
                  ),
                ),
                if (_selectedReminderIds.isNotEmpty) ...[
                  if (selectedReminder != null && !selectedReminder.isCompleted)
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.edit_outlined, size: 22),
                      color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                      tooltip: 'Edit Reminder',
                      onPressed: () {
                        _showEditReminderDialog(
                          context,
                          selectedReminder,
                          chatProvider,
                          isDark,
                        );
                        setState(() {
                          _selectedReminderIds.clear();
                          _isSelectionMode = false;
                        });
                      },
                    ),
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                    tooltip: 'Delete Reminders',
                    onPressed: () {
                      _confirmDeleteReminders(
                        context,
                        _selectedReminderIds.toList(),
                        chatProvider,
                      );
                    },
                  ),
                ],
              ]
            : [
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                  ),
                  onSelected: (value) {
                    if (value == 'select') {
                      setState(() {
                        _isSelectionMode = true;
                      });
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'select',
                      child: Row(
                        children: [
                          Icon(Icons.checklist, size: 20),
                          SizedBox(width: 8),
                          Text('Select Tasks'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Stay on track with your cognitive assistant.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? StitchTheme.darkOnSurfaceVariant
                            : StitchTheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),

                // Stats Dashboard Grid
                if (hasAnyReminders) ...[
                  _buildStatsDashboard(
                    allCount: chatProvider.reminders.length,
                    todayCount: today.length,
                    upcomingCount: upcoming.length,
                    anytimeCount: anytime.length,
                    overdueCount: overdue.length,
                    completedCount: completed.length,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.grey.withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: 20),
                ],



                // Today Section
                if ((_selectedFilter == null || _selectedFilter == 'All' || _selectedFilter == 'Today') && today.isNotEmpty) ...[
                  _buildSectionHeader('Today', today.length.toString(), StitchTheme.primary, isDark),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: today.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildReminderCard(context, today[index], isDark, chatProvider, false),
                  ),
                  const SizedBox(height: 24),
                ],
                if (_selectedFilter == 'Today' && today.isEmpty) ...[
                  _buildSectionHeader('Today', '0', StitchTheme.primary, isDark),
                  _buildNoFilteredRemindersState('Today', isDark),
                  const SizedBox(height: 24),
                ],

                // Upcoming Section
                if ((_selectedFilter == null || _selectedFilter == 'All' || _selectedFilter == 'Upcoming') && upcoming.isNotEmpty) ...[
                  _buildSectionHeader('Upcoming', upcoming.length.toString(), StitchTheme.secondary, isDark),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: upcoming.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildReminderCard(context, upcoming[index], isDark, chatProvider, false),
                  ),
                  const SizedBox(height: 24),
                ],
                if (_selectedFilter == 'Upcoming' && upcoming.isEmpty) ...[
                  _buildSectionHeader('Upcoming', '0', StitchTheme.secondary, isDark),
                  _buildNoFilteredRemindersState('Upcoming', isDark),
                  const SizedBox(height: 24),
                ],

                // Anytime Section
                if ((_selectedFilter == null || _selectedFilter == 'All' || _selectedFilter == 'Anytime') && anytime.isNotEmpty) ...[
                  _buildSectionHeader('Anytime', anytime.length.toString(), Colors.teal, isDark),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: anytime.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildReminderCard(context, anytime[index], isDark, chatProvider, false),
                  ),
                  const SizedBox(height: 24),
                ],
                if (_selectedFilter == 'Anytime' && anytime.isEmpty) ...[
                  _buildSectionHeader('Anytime', '0', Colors.teal, isDark),
                  _buildNoFilteredRemindersState('Anytime', isDark),
                  const SizedBox(height: 24),
                ],

                // Completed Section
                if ((_selectedFilter == null || _selectedFilter == 'All' || _selectedFilter == 'Completed') && completed.isNotEmpty) ...[
                  _buildSectionHeader('Completed', completed.length.toString(), isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant, isDark),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: 0.65,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: completed.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _buildReminderCard(context, completed[index], isDark, chatProvider, true),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (_selectedFilter == 'Completed' && completed.isEmpty) ...[
                  _buildSectionHeader('Completed', '0', isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant, isDark),
                  _buildNoFilteredRemindersState('Completed', isDark),
                  const SizedBox(height: 24),
                ],

                // Overdue Section (only shown when selectedFilter is 'Overdue' or 'All' if overdue tasks exist)
                if (_selectedFilter == 'Overdue' || (_selectedFilter == 'All' && overdue.isNotEmpty)) ...[
                  _buildSectionHeader('Overdue', overdue.length.toString(), Colors.red, isDark),
                  const SizedBox(height: 8),
                  if (overdue.isNotEmpty) ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: overdue.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _buildReminderCard(context, overdue[index], isDark, chatProvider, false),
                    ),
                  ] else ...[
                    _buildNoFilteredRemindersState('Overdue', isDark),
                  ],
                  const SizedBox(height: 24),
                ],

                // Fallback empty view
                if (!hasAnyReminders) ...[
                  _buildEmptyState(isDark),
                  const SizedBox(height: 24),
                ],


                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? badgeText, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                ),
              ),
            ],
          ),
          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B1838) : const Color(0xFFEEF2F6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF28243E) : const Color(0xFFE2E8F0),
                  width: 0.5,
                ),
              ),
              child: Text(
                '$badgeText Task${int.parse(badgeText) != 1 ? "s" : ""}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsDashboard({
    required int allCount,
    required int todayCount,
    required int upcomingCount,
    required int anytimeCount,
    required int overdueCount,
    required int completedCount,
    required bool isDark,
  }) {
    final List<Map<String, dynamic>> stats = [
      {
        'title': 'All',
        'value': allCount.toString(),
        'icon': Icons.grid_view_rounded,
        'gradient': isDark
            ? [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)] // Royal blue
            : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)], // Soft blue
        'textColor': isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
        'iconColor': isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
      },
      {
        'title': 'Today',
        'value': todayCount.toString(),
        'icon': Icons.today,
        'gradient': isDark
            ? [const Color(0xFF2E1065), const Color(0xFF5B21B6)] // Dark purple
            : [const Color(0xFFF3E8FF), const Color(0xFFE9D5FF)], // Light lavender
        'textColor': isDark ? const Color(0xFFD8B4FE) : const Color(0xFF6B21A8),
        'iconColor': isDark ? const Color(0xFFD8B4FE) : const Color(0xFF7C3AED),
      },
      {
        'title': 'Upcoming',
        'value': upcomingCount.toString(),
        'icon': Icons.upcoming,
        'gradient': isDark
            ? [const Color(0xFF500724), const Color(0xFF881337)] // Rose
            : [const Color(0xFFFCE7F3), const Color(0xFFFBCFE8)],
        'textColor': isDark ? const Color(0xFFF9A8D4) : const Color(0xFF9D174D),
        'iconColor': isDark ? const Color(0xFFF9A8D4) : const Color(0xFFC2185B),
      },
      {
        'title': 'Overdue',
        'value': overdueCount.toString(),
        'icon': Icons.warning_amber_rounded,
        'gradient': isDark
            ? [const Color(0xFF5F071D), const Color(0xFF9F1239)] // Deep crimson glow
            : [const Color(0xFFFFE4E6), const Color(0xFFFECDD3)], // soft pastel rose/red
        'textColor': isDark ? const Color(0xFFFDA4AF) : const Color(0xFFBE123C),
        'iconColor': isDark ? const Color(0xFFFDA4AF) : const Color(0xFFE11D48),
      },
      {
        'title': 'Anytime',
        'value': anytimeCount.toString(),
        'icon': Icons.all_inclusive,
        'gradient': isDark
            ? [const Color(0xFF0F172A), const Color(0xFF334155)] // Dark slate
            : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
        'textColor': isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
        'iconColor': isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
      },
      {
        'title': 'Completed',
        'value': completedCount.toString(),
        'icon': Icons.check_circle_outline,
        'gradient': isDark
            ? [const Color(0xFF064E3B), const Color(0xFF065F46)] // Emerald
            : [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)],
        'textColor': isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
        'iconColor': isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
      },
    ];

    Widget buildStatCard(Map<String, dynamic> stat) {
      final gradientColors = stat['gradient'] as List<Color>;
      final isSelected = _selectedFilter == stat['title'];
      return GestureDetector(
        onTap: () {
          setState(() {
            if (_selectedFilter == stat['title']) {
              _selectedFilter = 'All';
            } else {
              _selectedFilter = stat['title'];
            }
          });
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isSelected ? 1.0 : 0.55,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? (isDark ? Colors.white : StitchTheme.primary)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.5)),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.15)
                      : (stat['title'] == 'Overdue'
                          ? const Color(0x1AFE1D48)
                          : const Color(0x0C45346A)),
                  blurRadius: isSelected ? 10 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        stat['icon'] as IconData,
                        size: 16,
                        color: stat['iconColor'] as Color,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stat['title'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: stat['textColor'] as Color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  stat['value'] as String,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: stat['textColor'] as Color,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: buildStatCard(stats[0])),
            const SizedBox(width: 8),
            Expanded(child: buildStatCard(stats[1])),
            const SizedBox(width: 8),
            Expanded(child: buildStatCard(stats[2])),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: buildStatCard(stats[3])),
            const SizedBox(width: 8),
            Expanded(child: buildStatCard(stats[4])),
            const SizedBox(width: 8),
            Expanded(child: buildStatCard(stats[5])),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gorgeous gradient icon
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: isDark
                    ? [const Color(0xFF818CF8), const Color(0xFFFBCFE8)]
                    : [StitchTheme.primary, StitchTheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "No Reminders Yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Reminders are automatically extracted when you mention dates or times in your chats (e.g., 'remind me tomorrow at 8 AM') or you can create one manually below.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark
                    ? StitchTheme.darkOnSurfaceVariant
                    : StitchTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            // Suggestion chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip("Try: 'Remind me in 5 mins'", isDark),
                _buildSuggestionChip("Try: 'Meeting tomorrow at 2 PM'", isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFilteredRemindersState(String category, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
        child: Column(
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 48,
              color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              "No $category Tasks",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontStyle: FontStyle.italic,
          color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildReminderCard(
      BuildContext context, Reminder reminder, bool isDark, ChatProvider provider, bool isDone) {
    final isCompleting = _completingReminderIds.contains(reminder.id);
    final showAsCompleted = isDone ? !isCompleting : isCompleting;

    final formattedTime = showAsCompleted
        ? "Completed"
        : (reminder.time == null ? "No set time" : _formatDateTime(reminder.time!));

    final icon = showAsCompleted
        ? Icons.done_all
        : (reminder.time == null
            ? Icons.notifications_off
            : (reminder.time!.day == DateTime.now().day ? Icons.schedule : Icons.event));

    final chatList = provider.chats.where((c) => c.id == reminder.chatId).toList();
    final chat = chatList.isNotEmpty ? chatList.first : null;
    final isOverdue = reminder.time != null && reminder.time!.isBefore(DateTime.now()) && !isDone;

    final leftIndicatorColor = isDone
        ? (isDark ? const Color(0xFF059669) : const Color(0xFF10B981))
        : (isOverdue
            ? (isDark ? const Color(0xFFE11D48) : const Color(0xFFF43F5E))
            : (reminder.time == null
                ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                : (reminder.time!.year == DateTime.now().year &&
                        reminder.time!.month == DateTime.now().month &&
                        reminder.time!.day == DateTime.now().day
                    ? (isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary)
                    : (isDark ? StitchTheme.secondaryFixedDim : StitchTheme.secondary))));

    final isSelectedForActions = _selectedReminderIds.contains(reminder.id);

    return Builder(
      builder: (cardContext) {
        final cardWidget = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: () {
              if (!_isSelectionMode) {
                setState(() {
                  _isSelectionMode = true;
                  _selectedReminderIds.add(reminder.id);
                });
              }
            },
            onTap: () {
              if (_isSelectionMode) {
                setState(() {
                  if (_selectedReminderIds.contains(reminder.id)) {
                    _selectedReminderIds.remove(reminder.id);
                  } else {
                    _selectedReminderIds.add(reminder.id);
                  }
                });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelectedForActions
                    ? (isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEFF6FF))
                    : (isDark ? StitchTheme.darkSurfaceContainerLowest : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelectedForActions
                      ? (isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary)
                      : leftIndicatorColor,
                  width: isSelectedForActions ? 2.0 : (isOverdue ? 1.5 : 1.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Circular custom check box with scale animation
                    GestureDetector(
                      onTap: () {
                        if (_isSelectionMode) {
                          setState(() {
                            if (_selectedReminderIds.contains(reminder.id)) {
                              _selectedReminderIds.remove(reminder.id);
                            } else {
                              _selectedReminderIds.add(reminder.id);
                            }
                          });
                        } else if (!_completingReminderIds.contains(reminder.id)) {
                          if (!isDone) {
                            final RenderBox? box = cardContext.findRenderObject() as RenderBox?;
                            final cardSize = box?.size ?? const Size(300, 80);
                            _showScatterEffect(cardContext, leftIndicatorColor, cardSize);
                          }
                          setState(() {
                            _completingReminderIds.add(reminder.id);
                          });
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (provider.reminders.any((r) => r.id == reminder.id) && mounted) {
                              provider.toggleReminderCompletion(reminder.id);
                              setState(() {
                                _completingReminderIds.remove(reminder.id);
                              });
                            }
                          });
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _isSelectionMode
                              ? (isSelectedForActions
                                  ? LinearGradient(
                                      colors: isDark
                                          ? [StitchTheme.primaryFixedDim, StitchTheme.primaryFixedDim]
                                          : [StitchTheme.primary, StitchTheme.primary],
                                    )
                                  : null)
                              : (showAsCompleted
                                  ? LinearGradient(
                                      colors: isDark
                                          ? [const Color(0xFF818CF8), const Color(0xFFC084FC)]
                                          : [StitchTheme.primary, StitchTheme.secondary],
                                    )
                                  : null),
                          border: Border.all(
                            color: _isSelectionMode
                                ? (isSelectedForActions
                                    ? Colors.transparent
                                    : (isDark
                                        ? StitchTheme.darkOnSurfaceVariant.withValues(alpha: 0.4)
                                        : StitchTheme.outline.withValues(alpha: 0.5)))
                                : (showAsCompleted
                                    ? Colors.transparent
                                    : (isDark
                                        ? StitchTheme.darkOnSurfaceVariant.withValues(alpha: 0.4)
                                        : StitchTheme.outline.withValues(alpha: 0.5))),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: AnimatedScale(
                            scale: _isSelectionMode
                                ? (isSelectedForActions ? 1.0 : 0.0)
                                : (showAsCompleted ? 1.0 : 0.0),
                            duration: const Duration(milliseconds: 150),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Reminder Information
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.content,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                              decoration: showAsCompleted ? TextDecoration.lineThrough : null,
                              color: isDark
                                  ? (showAsCompleted ? StitchTheme.darkOnSurfaceVariant : StitchTheme.darkOnSurface)
                                  : (showAsCompleted ? StitchTheme.onSurfaceVariant : StitchTheme.onSurface),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 12,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        icon,
                                        size: 13,
                                        color: isOverdue
                                            ? StitchTheme.secondary
                                            : (isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        formattedTime,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                          color: isOverdue
                                              ? StitchTheme.secondary
                                              : (isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (chat != null)
                                    GestureDetector(
                                      onTap: () {
                                        if (_isSelectionMode) {
                                          setState(() {
                                            if (_selectedReminderIds.contains(reminder.id)) {
                                              _selectedReminderIds.remove(reminder.id);
                                            } else {
                                              _selectedReminderIds.add(reminder.id);
                                            }
                                          });
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ConversationScreen(chatId: chat.id),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1B1838) : const Color(0xFFEEF2F6),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF28243E) : const Color(0xFFE2E8F0),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              StitchTheme.getChatIcon(chat.iconCode),
                                              size: 10,
                                              color: isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              chat.title,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (isOverdue) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF4C0519) : const Color(0xFFFFE4E6),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFFBE123C) : const Color(0xFFFECDD3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 10,
                                        color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Overdue",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        );

        if (isCompleting) {
          return const SizedBox(width: double.infinity, height: 0);
        }
        return cardWidget;
      },
    );
  }

  void _showScatterEffect(BuildContext context, Color color, Size cardSize) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: position.dx,
          top: position.dy,
          width: cardSize.width,
          height: cardSize.height,
          child: IgnorePointer(
            child: ScatterParticlesWidget(
              color: color,
              cardSize: cardSize,
              onComplete: () {
                overlayEntry.remove();
              },
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(overlayEntry);
  }

  List<Reminder> _getFilteredRemindersList(ChatProvider chatProvider) {
    final today = chatProvider.todayReminders;
    final upcoming = chatProvider.upcomingReminders;
    final anytime = chatProvider.anytimeReminders;
    final completed = chatProvider.completedReminders;
    final overdue = chatProvider.reminders.where((r) {
      return r.time != null && r.time!.isBefore(DateTime.now()) && !r.isCompleted;
    }).toList();

    if (_selectedFilter == 'Today') return today;
    if (_selectedFilter == 'Upcoming') return upcoming;
    if (_selectedFilter == 'Anytime') return anytime;
    if (_selectedFilter == 'Completed') return completed;
    if (_selectedFilter == 'Overdue') return overdue;

    return chatProvider.reminders;
  }

  bool _areAllSelected(ChatProvider chatProvider) {
    final list = _getFilteredRemindersList(chatProvider);
    if (list.isEmpty) return false;
    return list.every((r) => _selectedReminderIds.contains(r.id));
  }

  void _confirmDeleteReminders(BuildContext context, List<String> reminderIds, ChatProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(reminderIds.length == 1 ? "Delete Reminder?" : "Delete Reminders?"),
          content: Text(reminderIds.length == 1
              ? "Are you sure you want to delete this reminder permanently?"
              : "Are you sure you want to delete these ${reminderIds.length} reminders permanently?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                for (final id in reminderIds) {
                  await provider.deleteReminder(id);
                }
                setState(() {
                  _selectedReminderIds.clear();
                  _isSelectionMode = false;
                });
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }



  void _showEditReminderDialog(
      BuildContext context, Reminder reminder, ChatProvider provider, bool isDark) {
    final contentController = TextEditingController(text: reminder.content);
    DateTime selectedDateTime = reminder.time ?? DateTime.now().add(const Duration(hours: 1));
    int selectedOption = 5; // Custom option initially

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final highlightColor = isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary;
            return AlertDialog(
              scrollable: true,
              backgroundColor: isDark ? StitchTheme.darkSurfaceContainerLow : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'Edit Reminder Task',
                style: TextStyle(
                  color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    TextField(
                      controller: contentController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'What to remember?',
                        labelStyle: TextStyle(
                          color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
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
                          label: 'In 10 Mins',
                          isSelected: selectedOption == 0,
                          onTap: () {
                            setModalState(() {
                              selectedOption = 0;
                              selectedDateTime = DateTime.now().add(const Duration(minutes: 10));
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
                          label: 'Custom...',
                          isSelected: selectedOption == 5,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDateTime,
                              firstDate: DateTime.now().isBefore(selectedDateTime) ? DateTime.now() : selectedDateTime,
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
                            color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Will remind on: ${DateFormat('MMM d, yyyy - h:mm a').format(selectedDateTime)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
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
                      await provider.updateReminder(
                        reminderId: reminder.id,
                        content: text,
                        time: selectedDateTime,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child: const Text('Save'),
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

class Particle {
  final Offset startOffset;
  final double angle;
  final double speed;
  final double size;
  final Color color;

  Particle({
    required this.startOffset,
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class ScatterParticlesWidget extends StatefulWidget {
  final Color color;
  final Size cardSize;
  final VoidCallback onComplete;

  const ScatterParticlesWidget({
    super.key,
    required this.color,
    required this.cardSize,
    required this.onComplete,
  });

  @override
  State<ScatterParticlesWidget> createState() => _ScatterParticlesWidgetState();
}

class _ScatterParticlesWidgetState extends State<ScatterParticlesWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _generateParticles();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  void _generateParticles() {
    final rand = math.Random();
    final colors = [
      widget.color,
      widget.color.withValues(alpha: 0.7),
      const Color(0xFF10B981),
      const Color(0xFF34D399),
      const Color(0xFF60A5FA),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      widget.color.withValues(alpha: 0.4),
    ];

    for (int i = 0; i < 80; i++) {
      // Random starting offset within the card dimensions
      final double rx = rand.nextDouble() * widget.cardSize.width;
      final double ry = rand.nextDouble() * widget.cardSize.height;

      _particles.add(Particle(
        startOffset: Offset(rx, ry),
        angle: rand.nextDouble() * 2 * math.pi,
        speed: 50.0 + rand.nextDouble() * 150.0,
        size: 2.0 + rand.nextDouble() * 5.0,
        color: colors[rand.nextInt(colors.length)],
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScatterPainter(
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _ScatterPainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  _ScatterPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      final double distance = particle.speed * progress;
      final double x = particle.startOffset.dx + math.cos(particle.angle) * distance;
      final double y = particle.startOffset.dy + math.sin(particle.angle) * distance;

      final double opacity = math.max(0.0, 1.0 - progress);
      paint.color = particle.color.withValues(alpha: opacity);

      final double currentSize = particle.size * (1.0 - progress);

      canvas.drawCircle(Offset(x, y), currentSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScatterPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
