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
  });
}
