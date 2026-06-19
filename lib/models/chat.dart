import 'package:hive/hive.dart';

part 'chat-g.dart';

@HiveType(typeId: 0)
class Chat extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  int iconCode;

  @HiveField(3)
  bool isPinned;

  @HiveField(4)
  bool isArchived;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  bool isLocked;

  Chat({
    required this.id,
    required this.title,
    required this.iconCode,
    this.isPinned = false,
    this.isArchived = false,
    this.isLocked = false,
    required this.createdAt,
  });
}
