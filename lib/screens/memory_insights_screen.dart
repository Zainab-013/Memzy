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

    // Dynamic Time of Day Activity Analysis from messages
    int morningCount = 0; // 6 AM - 12 PM
    int afternoonCount = 0; // 12 PM - 6 PM
    int eveningCount = 0; // 6 PM - 10 PM
    int nightCount = 0; // 10 PM - 6 AM

    for (var chat in chatProvider.chats) {
      final messages = chatProvider.getMessagesForChat(chat.id);
      for (var m in messages) {
        final hour = m.timestamp.hour;
        if (hour >= 6 && hour < 12) {
          morningCount++;
        } else if (hour >= 12 && hour < 18) {
          afternoonCount++;
        } else if (hour >= 18 && hour < 22) {
          eveningCount++;
        } else {
          nightCount++;
        }
      }
    }

    final int maxActivity = [morningCount, afternoonCount, eveningCount, nightCount]
        .reduce((curr, next) => curr > next ? curr : next);

    // Dynamic Top Keywords Extraction
    final Map<String, int> wordCounts = {};
    final stopWords = {
      'the', 'a', 'to', 'in', 'on', 'at', 'for', 'and', 'me', 'remind', 'buy', 
      'do', 'review', 'my', 'is', 'with', 'from', 'tomorrow', 'today', 'this',
      'that', 'these', 'those', 'have', 'has', 'had', 'will', 'would', 'shall', 'should'
    };

    for (var r in allReminders) {
      final words = r.content.toLowerCase().split(RegExp(r'\s+'));
      for (var w in words) {
        final cleanWord = w.replaceAll(RegExp(r'[^a-zA-Z]'), '');
        if (cleanWord.length > 2 && !stopWords.contains(cleanWord)) {
          wordCounts[cleanWord] = (wordCounts[cleanWord] ?? 0) + 1;
        }
      }
    }

    final sortedWords = wordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final List<String> topTags = sortedWords.take(6).map((e) => e.key).toList();
    
    // Fallbacks if no words are parsed yet
    if (topTags.isEmpty) {
      topTags.addAll(['placement', 'internship', 'groceries', 'lecture', 'revision', 'shopping']);
    }

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

              // Activity Trend Chart
              Text(
                'Memory Capture Activity',
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Creation Density (by Time of Day)',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Visual Bars representation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildChartBar(
                          label: "Morning",
                          value: morningCount,
                          maxValue: maxActivity,
                          color: StitchTheme.secondary,
                          isDark: isDark,
                        ),
                        _buildChartBar(
                          label: "Afternoon",
                          value: afternoonCount,
                          maxValue: maxActivity,
                          color: StitchTheme.primary,
                          isDark: isDark,
                        ),
                        _buildChartBar(
                          label: "Evening",
                          value: eveningCount,
                          maxValue: maxActivity,
                          color: const Color(0xFF8B5CF6),
                          isDark: isDark,
                        ),
                        _buildChartBar(
                          label: "Night",
                          value: nightCount,
                          maxValue: maxActivity,
                          color: const Color(0xFFC084FC),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Keyword Tag Cloud
              Text(
                'Top Memory Keywords',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: topTags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? StitchTheme.darkSurfaceContainerLow : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.label, size: 12, color: StitchTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          tag,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 100),
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
}
