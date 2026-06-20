import 'package:flutter_test/flutter_test.dart';
import 'package:memzy/services/reminder_parser.dart';

void main() {
  group('ReminderParser Tests', () {
    test('Parse today simple time (10:00 PM)', () {
      final msg = "Apply for internship. Remind me at 10:00 PM.";
      final result = ReminderParser.parse(msg);

      expect(result, isNotNull);
      expect(result!.content, equals("Apply for internship"));
      
      expect(result.time.hour, equals(22));
      expect(result.time.minute, equals(0));
    });

    test('Parse tomorrow time (8 AM)', () {
      final msg = "Buy groceries. Remind me tomorrow at 8 AM.";
      final result = ReminderParser.parse(msg);

      expect(result, isNotNull);
      expect(result!.content, equals("Buy groceries"));
      
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(result.time.day, equals(tomorrow.day));
      expect(result.time.hour, equals(8));
      expect(result.time.minute, equals(0));
    });

    test('Parse specific date time (25 June at 5 PM)', () {
      final msg = "Draft proposal. Remind me on 25 June at 5 PM.";
      final result = ReminderParser.parse(msg);

      expect(result, isNotNull);
      expect(result!.content, equals("Draft proposal"));
      expect(result.time.day, equals(25));
      expect(result.time.month, equals(6));
      expect(result.time.hour, equals(17));
      expect(result.time.minute, equals(0));
    });

    test('Parse specific date time inverted (June 25 at 5:30 PM)', () {
      final msg = "Read articles. Remind me on June 25 at 5:30 PM.";
      final result = ReminderParser.parse(msg);

      expect(result, isNotNull);
      expect(result!.content, equals("Read articles"));
      expect(result.time.day, equals(25));
      expect(result.time.month, equals(6));
      expect(result.time.hour, equals(17));
      expect(result.time.minute, equals(30));
    });

    test('Parse invalid message (no reminder)', () {
      final msg = "Just checking in, hope you are doing well.";
      final result = ReminderParser.parse(msg);

      expect(result, isNull);
    });

    test('Parse reminder with keyword "reminder" instead of "remind"', () {
      final msg = "Set a reminder to call Dad tomorrow at 8 AM.";
      final result = ReminderParser.parse(msg);

      expect(result, isNotNull);
      expect(result!.content, equals("call Dad"));
      expect(result.time.hour, equals(8));
    });

    test('Parse date-only expression on 25 June (defaults to 9 AM)', () {
      final msg = "Pay credit card bill. Reminder on 25 June.";
      final result = ReminderParser.parse(msg);

      expect(result, isNotNull);
      expect(result!.content, equals("Pay credit card bill"));
      expect(result.time.day, equals(25));
      expect(result.time.month, equals(6));
      expect(result.time.hour, equals(9));
      expect(result.time.minute, equals(0));
    });

    test('Parse weekday expression "on Friday at 5 PM"', () {
      final msg = "Go for a run. Remind me on Friday at 5 PM.";
      final result = ReminderParser.parse(msg);

      expect(result, isNotNull);
      expect(result!.content, equals("Go for a run"));
      expect(result.time.hour, equals(17));
      expect(result.time.minute, equals(0));
      // Weekday of result should be Friday (5)
      expect(result.time.weekday, equals(DateTime.friday));
    });

    test('Parse weekday expression without time (defaults to 9 AM)', () {
      final msg = "Submit report. Reminder on Monday.";
      final result = ReminderParser.parse(msg);

      expect(result, isNotNull);
      expect(result!.content, equals("Submit report"));
      expect(result.time.hour, equals(9));
      expect(result.time.minute, equals(0));
      expect(result.time.weekday, equals(DateTime.monday));
    });

    test('Future date time inference for 2 PM (when current time is 4 PM)', () {
      final msg = "Review document. Reminder tomorrow at 2.";
      final result = ReminderParser.parse(msg);

      expect(result, isNotNull);
      expect(result!.content, equals("Review document"));
      // 2 should be parsed as 14 (2 PM) for a future date (tomorrow)
      expect(result.time.hour, equals(14));
    });

    test('Future date time inference for 9 (when current time is 4 PM)', () {
      final msg = "Review document. Reminder tomorrow at 9.";
      final result = ReminderParser.parse(msg);

      expect(result, isNotNull);
      expect(result!.content, equals("Review document"));
      // 9 should be parsed as 9 (9 AM) for a future date (tomorrow)
      expect(result.time.hour, equals(9));
    });

    test('Parse relative time with "after", word numbers, and spelling variations', () {
      final msg = "after one minuter i ahve a meetind so remind me";
      final result = ReminderParser.parse(msg);

      expect(result, isNotNull);
      expect(result!.content, equals("i ahve a meetind"));
      
      final rawExpected = DateTime.now().add(const Duration(minutes: 1));
      final expectedTime = DateTime(rawExpected.year, rawExpected.month, rawExpected.day, rawExpected.hour, rawExpected.minute);
      expect(result.time.difference(expectedTime).inSeconds.abs() == 0, isTrue);
    });

    test('Parse relative time with "after" and digits', () {
      final msg = "after 5 minutes go to sleep. remind me";
      final result = ReminderParser.parse(msg);

      expect(result, isNotNull);
      expect(result!.content, equals("go to sleep"));
      
      final rawExpected = DateTime.now().add(const Duration(minutes: 5));
      final expectedTime = DateTime(rawExpected.year, rawExpected.month, rawExpected.day, rawExpected.hour, rawExpected.minute);
      expect(result.time.difference(expectedTime).inSeconds.abs() == 0, isTrue);
    });

    test('Parse time combined with tomorrow keyword (2 PM tomorrow)', () {
      final msg = "i have a meeting at 2 pm tomorrow";
      final result = ReminderParser.parse(msg, requireRemindKeyword: false);

      expect(result, isNotNull);
      expect(result!.content, equals("i have a meeting"));
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(result.time.day, equals(tomorrow.day));
      expect(result.time.hour, equals(14));
      expect(result.time.minute, equals(0));
    });

    test('Parse notify me simple time (10:00 PM)', () {
      final msg = "Apply for internship. Notify me at 10:00 PM.";
      final result = ReminderParser.parse(msg);

      expect(result, isNotNull);
      expect(result!.content, equals("Apply for internship"));
      
      expect(result.time.hour, equals(22));
      expect(result.time.minute, equals(0));
    });

    test('Parse notification keyword instead of remind/reminder', () {
      final msg = "Set a notification to call Dad tomorrow at 8 AM.";
      final result = ReminderParser.parse(msg);

      expect(result, isNotNull);
      expect(result!.content, equals("call Dad"));
      expect(result.time.hour, equals(8));
    });
  });
}
