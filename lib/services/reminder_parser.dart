class ReminderParseResult {
  final String content;
  final DateTime time;

  ReminderParseResult({required this.content, required this.time});
}

class ReminderParser {
  static ReminderParseResult? parse(String text) {
    final now = DateTime.now();

    // First check if the word "remind" exists (case-insensitive)
    final remindRegExp = RegExp(r'\bremind\b', caseSensitive: false);
    if (!remindRegExp.hasMatch(text)) {
      return null;
    }

    DateTime? reminderTime;
    String matchedString = '';

    // Define regexes to search for time expressions anywhere in the text
    // 1. Relative time: "in [X] [minutes/hours/days]"
    final relativePattern = RegExp(
      r'\bin\s+(\d+)\s+(minute|minutes|min|mins|hour|hours|hr|hrs|day|days|d)\b',
      caseSensitive: false,
    );

    // 2. Numeric date: "on dd/mm/yyyy at time" or "on dd/mm/yyyy"
    final numericDatePattern = RegExp(
      r'\bon\s+(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})(?:\s+at)?\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );

    // 3. "on [day] [month] at [time]"
    final datePattern1 = RegExp(
      r'\bon\s+(\d{1,2})(?:st|nd|rd|th)?\s+([a-zA-Z]+)(?:\s+at)?\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );

    // 4. "on [month] [day] at [time]"
    final datePattern2 = RegExp(
      r'\bon\s+([a-zA-Z]+)\s+(\d{1,2})(?:st|nd|rd|th)?(?:\s+at)?\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );

    // 5. "tomorrow at [time]"
    final tomorrowPattern = RegExp(
      r'\btomorrow(?:\s+at)?\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );

    // 6. "tomorrow" (bare)
    final tomorrowBarePattern = RegExp(
      r'\btomorrow\b',
      caseSensitive: false,
    );

    // 7. "at [time]"
    final atPattern = RegExp(
      r'\bat\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );

    // 8. Bare time: e.g. "10:30 PM", "10 PM", "5pm"
    final bareTimePattern = RegExp(
      r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
      caseSensitive: false,
    );

    if (relativePattern.hasMatch(text)) {
      final match = relativePattern.firstMatch(text)!;
      matchedString = match.group(0)!;
      final quantity = int.parse(match.group(1)!);
      final unit = match.group(2)!.toLowerCase();

      if (unit.startsWith('m')) {
        reminderTime = now.add(Duration(minutes: quantity));
      } else if (unit.startsWith('h')) {
        reminderTime = now.add(Duration(hours: quantity));
      } else if (unit.startsWith('d')) {
        reminderTime = now.add(Duration(days: quantity));
      }
    } else if (numericDatePattern.hasMatch(text)) {
      final match = numericDatePattern.firstMatch(text)!;
      matchedString = match.group(0)!;
      final num1 = int.parse(match.group(1)!);
      final num2 = int.parse(match.group(2)!);
      final yearStr = match.group(3)!;
      final hourStr = match.group(4)!;
      final minStr = match.group(5);
      final amPm = match.group(6)?.toLowerCase();

      int year = int.parse(yearStr);
      if (yearStr.length == 2) {
        year += 2000;
      }

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
      final match = datePattern1.firstMatch(text)!;
      matchedString = match.group(0)!;
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
      final match = datePattern2.firstMatch(text)!;
      matchedString = match.group(0)!;
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
      final match = tomorrowPattern.firstMatch(text)!;
      matchedString = match.group(0)!;
      final hourStr = match.group(1)!;
      final minStr = match.group(2);
      final amPm = match.group(3)?.toLowerCase();

      final hour = _parseHourSmart(int.parse(hourStr), amPm, now);
      final minute = minStr != null ? int.parse(minStr) : 0;

      final tomorrow = now.add(const Duration(days: 1));
      reminderTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
    } else if (tomorrowBarePattern.hasMatch(text)) {
      final match = tomorrowBarePattern.firstMatch(text)!;
      matchedString = match.group(0)!;
      // Default to tomorrow at 9 AM
      final tomorrow = now.add(const Duration(days: 1));
      reminderTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
    } else if (atPattern.hasMatch(text)) {
      final match = atPattern.firstMatch(text)!;
      matchedString = match.group(0)!;
      final hourStr = match.group(1)!;
      final minStr = match.group(2);
      final amPm = match.group(3)?.toLowerCase();

      final hour = _parseHourSmart(int.parse(hourStr), amPm, now);
      final minute = minStr != null ? int.parse(minStr) : 0;

      reminderTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (reminderTime.isBefore(now)) {
        reminderTime = reminderTime.add(const Duration(days: 1));
      }
    } else if (bareTimePattern.hasMatch(text)) {
      final match = bareTimePattern.firstMatch(text)!;
      matchedString = match.group(0)!;
      final hourStr = match.group(1)!;
      final minStr = match.group(2);
      final amPm = match.group(3)!.toLowerCase();

      final hour = _parseHourSmart(int.parse(hourStr), amPm, now);
      final minute = minStr != null ? int.parse(minStr) : 0;

      reminderTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (reminderTime.isBefore(now)) {
        reminderTime = reminderTime.add(const Duration(days: 1));
      }
    } else {
      // Fallback: If "remind" exists but no time expression matched, default to 1 hour from now
      reminderTime = now.add(const Duration(hours: 1));
      matchedString = '';
    }

    // Clean the text to form content
    String content = text;
    if (matchedString.isNotEmpty) {
      content = content.replaceFirst(matchedString, '');
    }

    // Remove the word "remind" and common connecting words/prepositions
    // e.g. "remind me to", "remind me about", "set reminder for", etc.
    final cleanTriggerRegExp = RegExp(
      r'\b(remind\s+me\s+(?:to|about|of|for|on)\s+|remind\s+(?:to|about|of|for|on)\s+|set\s+reminder\s+(?:to|about|of|for|on)\s+|reminder\s+(?:to|about|of|for|on)\s+|remind\s+me\s+|set\s+reminder\s+|reminder\s+|remind\s+|reminder\b|remind\b)',
      caseSensitive: false,
    );
    content = content.replaceFirst(cleanTriggerRegExp, '');

    // Double check if any isolated "remind" or "reminder" remains
    content = content.replaceAll(RegExp(r'\b(remind|reminder)\b', caseSensitive: false), '');

    content = content.trim();

    // Strip any leading prepositions that might be left over, e.g. "to ", "for ", "about ", "of ", "on "
    final leadingPrepositionRegExp = RegExp(
      r'^(?:to|for|about|of|on|set)\s+',
      caseSensitive: false,
    );
    content = content.replaceFirst(leadingPrepositionRegExp, '').trim();

    // Clean up any trailing/leading punctuation
    while (content.startsWith('.') || content.startsWith(',') || content.startsWith('!')) {
      content = content.substring(1).trim();
    }
    while (content.endsWith('.') || content.endsWith(',') || content.endsWith('!')) {
      content = content.substring(0, content.length - 1).trim();
    }

    if (content.isEmpty) {
      content = "Reminder";
    }

    return ReminderParseResult(content: content, time: reminderTime!);
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

      if (now.hour >= amHour && now.hour < pmHour) {
        return pmHour;
      }
      return amHour;
    }
    return hour;
  }
}
