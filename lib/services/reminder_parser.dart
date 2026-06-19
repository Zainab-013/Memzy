class ReminderParseResult {
  final String content;
  final DateTime time;
  final bool hasTimeExpression;

  ReminderParseResult({
    required this.content,
    required this.time,
    required this.hasTimeExpression,
  });
}

class ReminderParser {
  static ReminderParseResult? parse(String text, {bool requireRemindKeyword = true}) {
    final rawNow = DateTime.now();
    // Truncate seconds, milliseconds, and microseconds to 0 for exact minute calculations
    final now = DateTime(rawNow.year, rawNow.month, rawNow.day, rawNow.hour, rawNow.minute);

    if (requireRemindKeyword) {
      // First check if the word "remind", "reminder", or "reminders" exists (case-insensitive)
      final remindRegExp = RegExp(r'\b(remind|reminder|reminders)\b', caseSensitive: false);
      if (!remindRegExp.hasMatch(text)) {
        return null;
      }
    }

    DateTime? reminderTime;
    String matchedString = '';
    final List<String> stringsToClean = [];

    // Define regexes to search for time expressions anywhere in the text
    // 1. Relative time: "(in|after) [X] [minutes/hours/days]"
    final relativePattern = RegExp(
      r'\b(?:in|after)\s+(\d+|[a-zA-Z]+(?:\s+[a-zA-Z]+)?(?:\-[a-zA-Z]+)?)\s+(minute|minutes|min|mins|minuter|hour|hours|hr|hrs|day|days|d)\b',
      caseSensitive: false,
    );

    // 2. Numeric date: "on dd/mm/yyyy at time" or "on dd/mm/yyyy"
    final numericDatePattern = RegExp(
      r'\bon\s+(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})(?:\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?)?',
      caseSensitive: false,
    );

    // 3. "on [day] [month] at [time]" or "on [day] [month]"
    final datePattern1 = RegExp(
      r'\bon\s+(\d{1,2})(?:st|nd|rd|th)?\s+([a-zA-Z]+)(?:\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?)?',
      caseSensitive: false,
    );

    // 4. "on [month] [day] at [time]" or "on [month] [day]"
    final datePattern2 = RegExp(
      r'\bon\s+([a-zA-Z]+)\s+(\d{1,2})(?:st|nd|rd|th)?(?:\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?)?',
      caseSensitive: false,
    );

    // 5. Weekday: "on/this [weekday] at [time]" or "on/this [weekday]"
    final weekdayPattern = RegExp(
      r'\b(?:on|this)\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun)\b(?:\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?)?',
      caseSensitive: false,
    );

    // 6. "tomorrow at [time]"
    final tomorrowPattern = RegExp(
      r'\btomorrow(?:\s+at)?\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );

    // 7. "tomorrow" (bare)
    final tomorrowBarePattern = RegExp(
      r'\btomorrow\b',
      caseSensitive: false,
    );

    // 8. "at [time]"
    final atPattern = RegExp(
      r'\bat\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );

    // 9. Bare time: e.g. "10:30 PM", "10 PM", "5pm"
    final bareTimePattern = RegExp(
      r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
      caseSensitive: false,
    );

    if (relativePattern.hasMatch(text)) {
      final match = relativePattern.firstMatch(text)!;
      matchedString = match.group(0)!;
      stringsToClean.add(matchedString);
      final quantity = _parseQuantity(match.group(1)!);
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
      stringsToClean.add(matchedString);
      final num1 = int.parse(match.group(1)!);
      final num2 = int.parse(match.group(2)!);
      final yearStr = match.group(3)!;
      final hourStr = match.group(4);
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

      int hour = 9;
      int minute = 0;
      if (hourStr != null) {
        hour = _parseHourSmart(
          hour: int.parse(hourStr),
          amPm: amPm,
          targetDate: DateTime(year, month, day),
          now: now,
        );
        minute = minStr != null ? int.parse(minStr) : 0;
      } else {
        final timeRes = _extractTimeFromText(text, DateTime(year, month, day), now);
        if (timeRes != null) {
          stringsToClean.add(timeRes['matched']);
          hour = timeRes['hour'];
          minute = timeRes['minute'];
        }
      }

      reminderTime = DateTime(year, month, day, hour, minute);
    } else if (datePattern1.hasMatch(text)) {
      final match = datePattern1.firstMatch(text)!;
      matchedString = match.group(0)!;
      stringsToClean.add(matchedString);
      final day = int.parse(match.group(1)!);
      final monthStr = match.group(2)!.toLowerCase();
      final hourStr = match.group(3);
      final minStr = match.group(4);
      final amPm = match.group(5)?.toLowerCase();

      final month = _monthNumber(monthStr);
      int year = now.year;
      if (month < now.month || (month == now.month && day < now.day)) {
        year += 1;
      }

      int hour = 9;
      int minute = 0;
      if (hourStr != null) {
        hour = _parseHourSmart(
          hour: int.parse(hourStr),
          amPm: amPm,
          targetDate: DateTime(year, month, day),
          now: now,
        );
        minute = minStr != null ? int.parse(minStr) : 0;
      } else {
        final timeRes = _extractTimeFromText(text, DateTime(year, month, day), now);
        if (timeRes != null) {
          stringsToClean.add(timeRes['matched']);
          hour = timeRes['hour'];
          minute = timeRes['minute'];
        }
      }

      reminderTime = DateTime(year, month, day, hour, minute);
    } else if (datePattern2.hasMatch(text)) {
      final match = datePattern2.firstMatch(text)!;
      matchedString = match.group(0)!;
      stringsToClean.add(matchedString);
      final monthStr = match.group(1)!.toLowerCase();
      final day = int.parse(match.group(2)!);
      final hourStr = match.group(3);
      final minStr = match.group(4);
      final amPm = match.group(5)?.toLowerCase();

      final month = _monthNumber(monthStr);
      int year = now.year;
      if (month < now.month || (month == now.month && day < now.day)) {
        year += 1;
      }

      int hour = 9;
      int minute = 0;
      if (hourStr != null) {
        hour = _parseHourSmart(
          hour: int.parse(hourStr),
          amPm: amPm,
          targetDate: DateTime(year, month, day),
          now: now,
        );
        minute = minStr != null ? int.parse(minStr) : 0;
      } else {
        final timeRes = _extractTimeFromText(text, DateTime(year, month, day), now);
        if (timeRes != null) {
          stringsToClean.add(timeRes['matched']);
          hour = timeRes['hour'];
          minute = timeRes['minute'];
        }
      }

      reminderTime = DateTime(year, month, day, hour, minute);
    } else if (weekdayPattern.hasMatch(text)) {
      final match = weekdayPattern.firstMatch(text)!;
      matchedString = match.group(0)!;
      stringsToClean.add(matchedString);
      final weekdayStr = match.group(1)!;
      final hourStr = match.group(2);
      final minStr = match.group(3);
      final amPm = match.group(4)?.toLowerCase();

      final targetWeekday = _weekdayNumber(weekdayStr);
      final targetDate = _nextWeekday(targetWeekday, now);

      int hour = 9;
      int minute = 0;
      if (hourStr != null) {
        hour = _parseHourSmart(
          hour: int.parse(hourStr),
          amPm: amPm,
          targetDate: targetDate,
          now: now,
        );
        minute = minStr != null ? int.parse(minStr) : 0;
      } else {
        final timeRes = _extractTimeFromText(text, targetDate, now);
        if (timeRes != null) {
          stringsToClean.add(timeRes['matched']);
          hour = timeRes['hour'];
          minute = timeRes['minute'];
        }
      }

      reminderTime = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
      if (reminderTime.isBefore(rawNow)) {
        reminderTime = reminderTime.add(const Duration(days: 7));
      }
    } else if (tomorrowPattern.hasMatch(text)) {
      final match = tomorrowPattern.firstMatch(text)!;
      matchedString = match.group(0)!;
      stringsToClean.add(matchedString);
      final hourStr = match.group(1)!;
      final minStr = match.group(2);
      final amPm = match.group(3)?.toLowerCase();

      final tomorrow = now.add(const Duration(days: 1));
      final hour = _parseHourSmart(
        hour: int.parse(hourStr),
        amPm: amPm,
        targetDate: tomorrow,
        now: now,
      );
      final minute = minStr != null ? int.parse(minStr) : 0;

      reminderTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
    } else if (tomorrowBarePattern.hasMatch(text)) {
      final match = tomorrowBarePattern.firstMatch(text)!;
      matchedString = match.group(0)!;
      stringsToClean.add(matchedString);
      final tomorrow = now.add(const Duration(days: 1));
      int hour = 9;
      int minute = 0;
      final timeRes = _extractTimeFromText(text, tomorrow, now);
      if (timeRes != null) {
        stringsToClean.add(timeRes['matched']);
        hour = timeRes['hour'];
        minute = timeRes['minute'];
      }
      reminderTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
    } else if (atPattern.hasMatch(text)) {
      final match = atPattern.firstMatch(text)!;
      matchedString = match.group(0)!;
      stringsToClean.add(matchedString);
      final hourStr = match.group(1)!;
      final minStr = match.group(2);
      final amPm = match.group(3)?.toLowerCase();

      final hour = _parseHourSmart(
        hour: int.parse(hourStr),
        amPm: amPm,
        targetDate: now,
        now: now,
      );
      final minute = minStr != null ? int.parse(minStr) : 0;

      reminderTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (reminderTime.isBefore(rawNow)) {
        reminderTime = reminderTime.add(const Duration(days: 1));
      }
    } else if (bareTimePattern.hasMatch(text)) {
      final match = bareTimePattern.firstMatch(text)!;
      matchedString = match.group(0)!;
      stringsToClean.add(matchedString);
      final hourStr = match.group(1)!;
      final minStr = match.group(2);
      final amPm = match.group(3)!.toLowerCase();

      final hour = _parseHourSmart(
        hour: int.parse(hourStr),
        amPm: amPm,
        targetDate: now,
        now: now,
      );
      final minute = minStr != null ? int.parse(minStr) : 0;

      reminderTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (reminderTime.isBefore(rawNow)) {
        reminderTime = reminderTime.add(const Duration(days: 1));
      }
    } else {
      // Fallback: If "remind" exists but no time expression matched, default to 1 hour from now
      reminderTime = now.add(const Duration(hours: 1));
      matchedString = '';
    }

    // Clean the text to form content
    String content = text;
    for (final s in stringsToClean) {
      if (s.isNotEmpty) {
        content = content.replaceFirst(s, '');
      }
    }

    // Remove the word "remind" and common connecting words/prepositions
    // e.g. "remind me to", "remind me about", "set reminder for", etc.
    final cleanTriggerRegExp = RegExp(
      r'\b(remind\s+me\s+(?:to|about|of|for|on)\s+|remind\s+(?:to|about|of|for|on)\s+|set\s+(?:a\s+)?reminder\s+(?:to|about|of|for|on|at)\s+|reminder\s+(?:to|about|of|for|on)\s+|remind\s+me\s+|remind\s+me\b|set\s+(?:a\s+)?reminder\s+|reminder\s+|remind\s+|reminder\b|remind\b)',
      caseSensitive: false,
    );
    content = content.replaceFirst(cleanTriggerRegExp, '');

    // Double check if any isolated "remind" or "reminder" remains
    content = content.replaceAll(RegExp(r'\b(remind|reminder|reminders)\b', caseSensitive: false), '');

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

    // Strip trailing connectors like "so", "then", "and", "to", etc.
    final trailingConnectorsRegExp = RegExp(
      r'\s+(?:so|then|and|to|for|about|of|on)$',
      caseSensitive: false,
    );
    content = content.replaceFirst(trailingConnectorsRegExp, '').trim();

    // Clean up punctuation again in case trailing connector removal exposed more
    while (content.endsWith('.') || content.endsWith(',') || content.endsWith('!')) {
      content = content.substring(0, content.length - 1).trim();
    }

    if (content.isEmpty) {
      content = "Reminder";
    }

    return ReminderParseResult(
      content: content,
      time: reminderTime!,
      hasTimeExpression: matchedString.isNotEmpty,
    );
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

  static int _weekdayNumber(String dayStr) {
    dayStr = dayStr.toLowerCase();
    if (dayStr.startsWith("mon")) return DateTime.monday;
    if (dayStr.startsWith("tue")) return DateTime.tuesday;
    if (dayStr.startsWith("wed")) return DateTime.wednesday;
    if (dayStr.startsWith("thu")) return DateTime.thursday;
    if (dayStr.startsWith("fri")) return DateTime.friday;
    if (dayStr.startsWith("sat")) return DateTime.saturday;
    if (dayStr.startsWith("sun")) return DateTime.sunday;
    return DateTime.monday;
  }

  static DateTime _nextWeekday(int weekday, DateTime now) {
    int daysToAdd = weekday - now.weekday;
    if (daysToAdd < 0) {
      daysToAdd += 7;
    }
    return now.add(Duration(days: daysToAdd));
  }

  static int _parseHourSmart({
    required int hour,
    required String? amPm,
    required DateTime targetDate,
    required DateTime now,
  }) {
    if (amPm != null) {
      final normalized = amPm.toLowerCase();
      if (normalized == 'pm' && hour < 12) {
        return hour + 12;
      } else if (normalized == 'am' && hour == 12) {
        return 0;
      }
      return hour;
    }

    if (hour <= 12) {
      final isToday = targetDate.year == now.year &&
          targetDate.month == now.month &&
          targetDate.day == now.day;

      final amHour = hour == 12 ? 0 : hour;
      final pmHour = hour == 12 ? 12 : hour + 12;

      if (isToday) {
        if (now.hour < amHour) {
          return amHour;
        }
        if (now.hour < pmHour) {
          return pmHour;
        }
        if (hour >= 8 && hour <= 11) {
          return amHour;
        }
        return pmHour;
      } else {
        if (hour >= 8 && hour <= 11) {
          return amHour;
        }
        return pmHour;
      }
    }
    return hour;
  }

  static int _parseQuantity(String text) {
    final cleaned = text.toLowerCase().replaceAll('-', ' ').trim();
    final parts = cleaned.split(RegExp(r'\s+'));
    
    final numberMap = {
      'a': 1, 'an': 1, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
      'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10, 'eleven': 11,
      'twelve': 12, 'thirteen': 13, 'fourteen': 14, 'fifteen': 15, 'sixteen': 16,
      'seventeen': 17, 'eighteen': 18, 'nineteen': 19, 'twenty': 20, 'thirty': 30,
      'forty': 40, 'fifty': 50, 'sixty': 60,
    };
    
    int sum = 0;
    for (var part in parts) {
      final parsedInt = int.tryParse(part);
      if (parsedInt != null) {
        sum += parsedInt;
      } else if (numberMap.containsKey(part)) {
        sum += numberMap[part]!;
      }
    }
    
    return sum > 0 ? sum : 1;
  }

  static Map<String, dynamic>? _extractTimeFromText(String text, DateTime targetDate, DateTime now) {
    final atPattern = RegExp(
      r'\bat\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );
    final bareTimePattern = RegExp(
      r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
      caseSensitive: false,
    );

    if (atPattern.hasMatch(text)) {
      final match = atPattern.firstMatch(text)!;
      final hourStr = match.group(1)!;
      final minStr = match.group(2);
      final amPm = match.group(3)?.toLowerCase();
      final hour = _parseHourSmart(
        hour: int.parse(hourStr),
        amPm: amPm,
        targetDate: targetDate,
        now: now,
      );
      final minute = minStr != null ? int.parse(minStr) : 0;
      return {'matched': match.group(0)!, 'hour': hour, 'minute': minute};
    } else if (bareTimePattern.hasMatch(text)) {
      final match = bareTimePattern.firstMatch(text)!;
      final hourStr = match.group(1)!;
      final minStr = match.group(2);
      final amPm = match.group(3)!.toLowerCase();
      final hour = _parseHourSmart(
        hour: int.parse(hourStr),
        amPm: amPm,
        targetDate: targetDate,
        now: now,
      );
      final minute = minStr != null ? int.parse(minStr) : 0;
      return {'matched': match.group(0)!, 'hour': hour, 'minute': minute};
    }
    return null;
  }
}
