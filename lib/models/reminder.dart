import 'package:hive/hive.dart';

part 'reminder.g.dart';

@HiveType(typeId: 2)
class Reminder extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String chatId;

  @HiveField(2)
  final String messageId;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final DateTime time;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.chatId,
    required this.messageId,
    required this.content,
    required this.time,
    this.isCompleted = false,
    required this.createdAt,
  });
}
