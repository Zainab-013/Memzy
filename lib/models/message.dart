import 'package:hive/hive.dart';

part 'message-g.dart';

@HiveType(typeId: 1)
class Message extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String chatId;

  @HiveField(2)
  String text;

  @HiveField(3)
  final String sender; // 'user' or 'system'

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  bool isStarred;

  @HiveField(6)
  final String type; // 'text', 'image', 'pdf', 'document', 'link'

  @HiveField(7)
  final String? fileLocalPath;

  @HiveField(8)
  final String? fileName;

  @HiveField(9)
  final int? fileSize;

  @HiveField(10)
  bool isEdited;

  @HiveField(11)
  bool? isPinned;

  Message({
    required this.id,
    required this.chatId,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isStarred = false,
    this.type = 'text',
    this.fileLocalPath,
    this.fileName,
    this.fileSize,
    this.isEdited = false,
    this.isPinned = false,
  });
}
