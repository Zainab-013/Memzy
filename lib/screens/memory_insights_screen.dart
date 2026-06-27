import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/stitch_theme.dart';

class MemoryInsightsScreen extends StatelessWidget {
  const MemoryInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final allReminders = chatProvider.reminders;
    final activeReminders = allReminders.where((r) => !r.isCompleted).toList();
    final completedReminders = allReminders.where((r) => r.isCompleted).toList();
    
    final int totalCount = allReminders.length;
    final int activeCount = activeReminders.length;
    final int completedCount = completedReminders.length;
    
    final double completionRate = totalCount > 0 ? (completedCount / totalCount) : 0.0;
    final String completionPercent = "${(completionRate * 100).toStringAsFixed(0)}%";

    // Calculate daily completion streak from reminders
    final completionDates = completedReminders
        .map((r) => r.time ?? r.createdAt)
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList();

    completionDates.sort((a, b) => b.compareTo(a));

    int currentStreak = 0;
    int bestStreak = 0;

    if (completionDates.isNotEmpty) {
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final yesterday = today.subtract(const Duration(days: 1));

      bool isStreakActive = completionDates.first == today || completionDates.first == yesterday;

      if (isStreakActive) {
        currentStreak = 1;
        for (int i = 0; i < completionDates.length - 1; i++) {
          final current = completionDates[i];
          final previous = completionDates[i + 1];
          final expectedPrevious = DateTime(current.year, current.month, current.day - 1);
          if (previous == expectedPrevious) {
            currentStreak++;
          } else {
            break;
          }
        }
      }

      // Historical Best Streak
      int tempStreak = 1;
      bestStreak = 1;
      for (int i = 0; i < completionDates.length - 1; i++) {
        final current = completionDates[i];
        final previous = completionDates[i + 1];
        final expectedPrevious = DateTime(current.year, current.month, current.day - 1);
        if (previous == expectedPrevious) {
          tempStreak++;
          if (tempStreak > bestStreak) {
            bestStreak = tempStreak;
          }
        } else {
          tempStreak = 1;
        }
      }
      if (tempStreak > bestStreak) {
        bestStreak = tempStreak;
      }
    }

    // Generate last 7 days trailing from today
    final todayDate = DateTime.now();
    final List<DateTime> last7Days = List.generate(7, (index) {
      return DateTime(todayDate.year, todayDate.month, todayDate.day).subtract(Duration(days: 6 - index));
    });

    // Initialize daywise counts for completed and missed reminders
    int monCompleted = 0; int monMissed = 0;
    int tueCompleted = 0; int tueMissed = 0;
    int wedCompleted = 0; int wedMissed = 0;
    int thuCompleted = 0; int thuMissed = 0;
    int friCompleted = 0; int friMissed = 0;
    int satCompleted = 0; int satMissed = 0;
    int sunCompleted = 0; int sunMissed = 0;

    for (var r in allReminders) {
      final date = r.time ?? r.createdAt;
      final weekday = date.weekday;

      if (r.isCompleted) {
        switch (weekday) {
          case DateTime.monday: monCompleted++; break;
          case DateTime.tuesday: tueCompleted++; break;
          case DateTime.wednesday: wedCompleted++; break;
          case DateTime.thursday: thuCompleted++; break;
          case DateTime.friday: friCompleted++; break;
          case DateTime.saturday: satCompleted++; break;
          case DateTime.sunday: sunCompleted++; break;
        }
      } else {
        switch (weekday) {
          case DateTime.monday: monMissed++; break;
          case DateTime.tuesday: tueMissed++; break;
          case DateTime.wednesday: wedMissed++; break;
          case DateTime.thursday: thuMissed++; break;
          case DateTime.friday: friMissed++; break;
          case DateTime.saturday: satMissed++; break;
          case DateTime.sunday: sunMissed++; break;
        }
      }
    }

    final int maxDayReminderValue = [
      monCompleted, monMissed,
      tueCompleted, tueMissed,
      wedCompleted, wedMissed,
      thuCompleted, thuMissed,
      friCompleted, friMissed,
      satCompleted, satMissed,
      sunCompleted, sunMissed
    ].reduce((curr, next) => curr > next ? curr : next);



    // Cognitive load recommendation
    String cognitiveLoadTitle;
    String cognitiveLoadDesc;
    Color cognitiveColor;

    if (activeCount > 5) {
      cognitiveLoadTitle = "Elevated Focus Demand";
      cognitiveLoadDesc = "You have $activeCount pending reminders. Prioritize key items to free up mental bandwidth.";
      cognitiveColor = StitchTheme.secondary;
    } else if (activeCount > 0) {
      cognitiveLoadTitle = "Balanced Focus Load";
      cognitiveLoadDesc = "You have $activeCount active reminders. Your cognitive assistant is keeping load moderate.";
      cognitiveColor = StitchTheme.primary;
    } else {
      cognitiveLoadTitle = "Clear Cognitive State";
      cognitiveLoadDesc = "No pending reminders! Your digital brain is completely clear and organized.";
      cognitiveColor = Colors.green;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? StitchTheme.darkBackground : StitchTheme.background,
        elevation: 0,
        title: Text(
          'Analytic',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Insights, trends, and focus metrics for your cognitive assistant.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),

              // Row of Metric Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: "Completed",
                      value: completedCount.toString(),
                      subtitle: "reminders met",
                      color: isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      title: "Completion",
                      value: completionPercent,
                      subtitle: "efficiency rate",
                      color: isDark ? StitchTheme.secondaryFixedDim : StitchTheme.secondary,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Cognitive Load Card (Stitch Amethyst Gradient style)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: isDark ? StitchTheme.darkSurfaceContainer : StitchTheme.primaryFixedDim.withValues(alpha: 0.5),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cognitiveColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.psychology, color: cognitiveColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cognitiveLoadTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cognitiveLoadDesc,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Productivity Streak Card
              Text(
                'Productivity Streak',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? StitchTheme.darkSurfaceContainerLowest : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFFF59E0B), const Color(0xFFEF4444)]
                                  : [const Color(0xFFFBBF24), const Color(0xFFF59E0B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_fire_department,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentStreak == 1 ? "1 Day Streak" : "$currentStreak Days Streak",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Best: $bestStreak days",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Divider(
                      height: 1,
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Last 7 Days Tracker",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: last7Days.map((day) {
                        final isCompletedOnDay = completionDates.contains(day);
                        final dayLabel = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1];
                        final isToday = day.day == todayDate.day && day.month == todayDate.month && day.year == todayDate.year;

                        return Column(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isCompletedOnDay
                                    ? const LinearGradient(
                                        colors: [Color(0xFF34D399), Color(0xFF10B981)],
                                      )
                                    : null,
                                color: !isCompletedOnDay
                                    ? (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade100)
                                    : null,
                                border: Border.all(
                                  color: isToday
                                      ? (isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: isCompletedOnDay
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : Text(
                                        dayLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                          color: isToday
                                              ? (isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary)
                                              : (isDark ? StitchTheme.darkOnSurfaceVariant.withValues(alpha: 0.5) : StitchTheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isToday ? "Today" : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isToday
                                    ? (isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary)
                                    : (isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? StitchTheme.darkSurfaceContainerLowest : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Weekly Performance (Completed vs Missed)',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF059669),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Completed",
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE11D48),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Missed/Incomplete",
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildDoubleChartBar(
                          label: "Mon",
                          completedValue: monCompleted,
                          missedValue: monMissed,
                          maxValue: maxDayReminderValue,
                          isDark: isDark,
                        ),
                        _buildDoubleChartBar(
                          label: "Tue",
                          completedValue: tueCompleted,
                          missedValue: tueMissed,
                          maxValue: maxDayReminderValue,
                          isDark: isDark,
                        ),
                        _buildDoubleChartBar(
                          label: "Wed",
                          completedValue: wedCompleted,
                          missedValue: wedMissed,
                          maxValue: maxDayReminderValue,
                          isDark: isDark,
                        ),
                        _buildDoubleChartBar(
                          label: "Thu",
                          completedValue: thuCompleted,
                          missedValue: thuMissed,
                          maxValue: maxDayReminderValue,
                          isDark: isDark,
                        ),
                        _buildDoubleChartBar(
                          label: "Fri",
                          completedValue: friCompleted,
                          missedValue: friMissed,
                          maxValue: maxDayReminderValue,
                          isDark: isDark,
                        ),
                        _buildDoubleChartBar(
                          label: "Sat",
                          completedValue: satCompleted,
                          missedValue: satMissed,
                          maxValue: maxDayReminderValue,
                          isDark: isDark,
                        ),
                        _buildDoubleChartBar(
                          label: "Sun",
                          completedValue: sunCompleted,
                          missedValue: sunMissed,
                          maxValue: maxDayReminderValue,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? StitchTheme.darkSurfaceContainerLowest : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar({
    required String label,
    required int value,
    required int maxValue,
    required Color color,
    required bool isDark,
  }) {
    // Determine visual scale height (max value represents 100px)
    final double barHeight = maxValue > 0 ? (value / maxValue) * 100 : 0.0;

    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: 24,
          height: barHeight > 4 ? barHeight : 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                color.withValues(alpha: 0.3),
                color,
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDoubleChartBar({
    required String label,
    required int completedValue,
    required int missedValue,
    required int maxValue,
    required bool isDark,
  }) {
    // Determine visual scale height (max value represents 100px)
    final double completedHeight = maxValue > 0 ? (completedValue / maxValue) * 100 : 0.0;
    final double missedHeight = maxValue > 0 ? (missedValue / maxValue) * 100 : 0.0;

    return Column(
      children: [
        // Completed/Missed numbers
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              completedValue.toString(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
              ),
            ),
            Text(
              "/",
              style: TextStyle(
                fontSize: 9,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
            ),
            Text(
              missedValue.toString(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Completed Bar (Emerald Green)
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 10,
              height: completedHeight > 4 ? completedHeight : 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF059669).withValues(alpha: 0.3),
                    const Color(0xFF059669),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Missed Bar (Rose Red)
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 10,
              height: missedHeight > 4 ? missedHeight : 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFFE11D48).withValues(alpha: 0.3),
                    const Color(0xFFE11D48),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
