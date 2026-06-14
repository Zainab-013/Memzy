class ReminderParseResult {
  final String content;
  final DateTime time;

  ReminderParseResult({required this.content, required this.time});
}

class ReminderParser {
  static ReminderParseResult? parse(String text) {
    final now = DateTime.now();

    // 1. "remind me on [day] [month] at [time]"
    // e.g. "remind me on 25 June at 5 PM" or "remind me on 25 June at 5:30 PM"
    final datePattern1 = RegExp(
      r'remind\s+me\s+on\s+(\d{1,2})\s+([a-zA-Z]+)\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );

    // 2. "remind me on [month] [day] at [time]"
    // e.g. "remind me on June 25 at 5 PM"
    final datePattern2 = RegExp(
      r'remind\s+me\s+on\s+([a-zA-Z]+)\s+(\d{1,2})\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );

    // 3. "remind me tomorrow at [time]"
    // e.g. "remind me tomorrow at 8 AM"
    final tomorrowPattern = RegExp(
      r'remind\s+me\s+tomorrow\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );

    // 4. "remind me at [time]"
    // e.g. "remind me at 10 PM"
    final atPattern = RegExp(
      r'remind\s+me\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );

    Match? match;
    DateTime? reminderTime;
    String matchedString = '';

    if (datePattern1.hasMatch(text)) {
      match = datePattern1.firstMatch(text);
      matchedString = match!.group(0)!;
      final day = int.parse(match.group(1)!);
      final monthStr = match.group(2)!.toLowerCase();
      final hourStr = match.group(3)!;
      final minStr = match.group(4);
      final amPm = match.group(5)?.toLowerCase();

      final month = _monthNumber(monthStr);
      final hour = _parseHour(hourStr, amPm);
      final minute = minStr != null ? int.parse(minStr) : 0;

      int year = now.year;
      if (month < now.month || (month == now.month && day < now.day)) {
        year += 1;
      }
      reminderTime = DateTime(year, month, day, hour, minute);
    } else if (datePattern2.hasMatch(text)) {
      match = datePattern2.firstMatch(text);
      matchedString = match!.group(0)!;
      final monthStr = match.group(1)!.toLowerCase();
      final day = int.parse(match.group(2)!);
      final hourStr = match.group(3)!;
      final minStr = match.group(4);
      final amPm = match.group(5)?.toLowerCase();

      final month = _monthNumber(monthStr);
      final hour = _parseHour(hourStr, amPm);
      final minute = minStr != null ? int.parse(minStr) : 0;

      int year = now.year;
      if (month < now.month || (month == now.month && day < now.day)) {
        year += 1;
      }
      reminderTime = DateTime(year, month, day, hour, minute);
    } else if (tomorrowPattern.hasMatch(text)) {
      match = tomorrowPattern.firstMatch(text);
      matchedString = match!.group(0)!;
      final hourStr = match.group(1)!;
      final minStr = match.group(2);
      final amPm = match.group(3)?.toLowerCase();

      final hour = _parseHour(hourStr, amPm);
      final minute = minStr != null ? int.parse(minStr) : 0;

      final tomorrow = now.add(const Duration(days: 1));
      reminderTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
    } else if (atPattern.hasMatch(text)) {
      match = atPattern.firstMatch(text);
      matchedString = match!.group(0)!;
      final hourStr = match.group(1)!;
      final minStr = match.group(2);
      final amPm = match.group(3)?.toLowerCase();

      final hour = _parseHour(hourStr, amPm);
      final minute = minStr != null ? int.parse(minStr) : 0;

      reminderTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (reminderTime.isBefore(now)) {
        reminderTime = reminderTime.add(const Duration(days: 1));
      }
    }

    if (reminderTime != null && match != null) {
      // Remove reminder clause
      String content = text.replaceFirst(matchedString, '');
      content = content.trim();

      // Clean up any trailing punctuation or whitespace recursively
      while (content.endsWith('.') || content.endsWith(',') || content.endsWith('!')) {
        content = content.substring(0, content.length - 1).trim();
      }

      if (content.isEmpty) {
        content = "Reminder";
      }

      return ReminderParseResult(content: content, time: reminderTime);
    }

    return null;
  }

  static int _monthNumber(String monthStr) {
    if (monthStr.startsWith("jan")) return 1;
    if (monthStr.startsWith("feb")) return 2;
    if (monthStr.startsWith("mar")) return 3;
    if (monthStr.startsWith("apr")) return 4;
    if (monthStr.startsWith("may")) return 5;
    if (monthStr.startsWith("jun")) return 6;
    if (monthStr.startsWith("jul")) return 7;
    if (monthStr.startsWith("aug")) return 8;
    if (monthStr.startsWith("sep")) return 9;
    if (monthStr.startsWith("oct")) return 10;
    if (monthStr.startsWith("nov")) return 11;
    if (monthStr.startsWith("dec")) return 12;
    return 1;
  }

  static int _parseHour(String hourStr, String? amPm) {
    int hour = int.parse(hourStr);
    if (amPm != null) {
      if (amPm == 'pm' && hour < 12) {
        hour += 12;
      } else if (amPm == 'am' && hour == 12) {
        hour = 0;
      }
    }
    return hour;
  }
}
