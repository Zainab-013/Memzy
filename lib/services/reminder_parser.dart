class ReminderParseResult {
  final String content;
  final DateTime time;

  ReminderParseResult({required this.content, required this.time});
}

class ReminderParser {
  static ReminderParseResult? parse(String text) {
    final now = DateTime.now();

    // 1. Relative time: "remind me in [X] [minutes/hours/days]"
    // e.g. "remind me in 30 mins" or "remind me in 2 hours"
    final relativePattern = RegExp(
      r'remind\s+me\s+in\s+(\d+)\s+(minute|minutes|min|mins|hour|hours|hr|hrs|day|days|d)\b',
      caseSensitive: false,
    );

    // 2. Numeric date: "remind me on dd/mm/yyyy at time"
    // e.g. "remind me on 25/06/2026 at 5 PM" or "remind me on 06-25-2026 at 5 PM"
    final numericDatePattern = RegExp(
      r'remind\s+me\s+on\s+(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );

    // 3. "remind me on [day] [month] at [time]" with optional ordinal suffixes
    // e.g. "remind me on 25th June at 5 PM" or "remind me on 25 June at 5:30 PM"
    final datePattern1 = RegExp(
      r'remind\s+me\s+on\s+(\d{1,2})(?:st|nd|rd|th)?\s+([a-zA-Z]+)\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );

    // 4. "remind me on [month] [day] at [time]" with optional ordinal suffixes
    // e.g. "remind me on June 25th at 5 PM"
    final datePattern2 = RegExp(
      r'remind\s+me\s+on\s+([a-zA-Z]+)\s+(\d{1,2})(?:st|nd|rd|th)?\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );

    // 5. "remind me tomorrow at [time]"
    // e.g. "remind me tomorrow at 8 AM"
    final tomorrowPattern = RegExp(
      r'remind\s+me\s+tomorrow\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );

    // 6. "remind me at [time]"
    // e.g. "remind me at 10 PM"
    final atPattern = RegExp(
      r'remind\s+me\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );

    Match? match;
    DateTime? reminderTime;
    String matchedString = '';

    if (relativePattern.hasMatch(text)) {
      match = relativePattern.firstMatch(text);
      matchedString = match!.group(0)!;
      final quantity = int.parse(match.group(1)!);
      final unit = match.group(2)!.toLowerCase();

      if (unit.startsWith('m')) { // min, mins, minute, minutes
        reminderTime = now.add(Duration(minutes: quantity));
      } else if (unit.startsWith('h')) { // hr, hrs, hour, hours
        reminderTime = now.add(Duration(hours: quantity));
      } else if (unit.startsWith('d')) { // d, day, days
        reminderTime = now.add(Duration(days: quantity));
      }
    } else if (numericDatePattern.hasMatch(text)) {
      match = numericDatePattern.firstMatch(text);
      matchedString = match!.group(0)!;
      final num1 = int.parse(match.group(1)!);
      final num2 = int.parse(match.group(2)!);
      final yearStr = match.group(3)!;
      final hourStr = match.group(4)!;
      final minStr = match.group(5);
      final amPm = match.group(6)?.toLowerCase();

      // Parse year
      int year = int.parse(yearStr);
      if (yearStr.length == 2) {
        year += 2000;
      }

      // Determine day and month
      int day = num1;
      int month = num2;
      if (num1 > 12 && num2 <= 12) {
        day = num1;
        month = num2;
      } else if (num2 > 12 && num1 <= 12) {
        day = num2;
        month = num1;
      }

      final hour = _parseHourSmart(int.parse(hourStr), amPm, now);
      final minute = minStr != null ? int.parse(minStr) : 0;
      reminderTime = DateTime(year, month, day, hour, minute);
    } else if (datePattern1.hasMatch(text)) {
      match = datePattern1.firstMatch(text);
      matchedString = match!.group(0)!;
      final day = int.parse(match.group(1)!);
      final monthStr = match.group(2)!.toLowerCase();
      final hourStr = match.group(3)!;
      final minStr = match.group(4);
      final amPm = match.group(5)?.toLowerCase();

      final month = _monthNumber(monthStr);
      final hour = _parseHourSmart(int.parse(hourStr), amPm, now);
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
      final hour = _parseHourSmart(int.parse(hourStr), amPm, now);
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

      final hour = _parseHourSmart(int.parse(hourStr), amPm, now);
      final minute = minStr != null ? int.parse(minStr) : 0;

      final tomorrow = now.add(const Duration(days: 1));
      reminderTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
    } else if (atPattern.hasMatch(text)) {
      match = atPattern.firstMatch(text);
      matchedString = match!.group(0)!;
      final hourStr = match.group(1)!;
      final minStr = match.group(2);
      final amPm = match.group(3)?.toLowerCase();

      final hour = _parseHourSmart(int.parse(hourStr), amPm, now);
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

  static int _parseHourSmart(int hour, String? amPm, DateTime now) {
    if (amPm != null) {
      if (amPm == 'pm' && hour < 12) {
        hour += 12;
      } else if (amPm == 'am' && hour == 12) {
        hour = 0;
      }
      return hour;
    }

    if (hour <= 12) {
      final amHour = hour == 12 ? 0 : hour;
      final pmHour = hour == 12 ? 12 : hour + 12;

      // Smart inference when AM/PM is omitted:
      // If the hour as AM has already passed today, but as PM it is in the future today,
      // then the user most likely meant PM.
      if (now.hour >= amHour && now.hour < pmHour) {
        return pmHour;
      }
      return amHour;
    }
    return hour;
  }
}
