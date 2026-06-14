import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/reminder.dart';

class DatabaseService {
  static const String _chatsBoxName = 'chats';
  static const String _messagesBoxName = 'messages';
  static const String _remindersBoxName = 'reminders';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Hive Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ChatAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MessageAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ReminderAdapter());
    }

    // Open boxes
    await Hive.openBox<Chat>(_chatsBoxName);
    await Hive.openBox<Message>(_messagesBoxName);
    await Hive.openBox<Reminder>(_remindersBoxName);
  }

  static Box<Chat> get chatsBox => Hive.box<Chat>(_chatsBoxName);
  static Box<Message> get messagesBox => Hive.box<Message>(_messagesBoxName);
  static Box<Reminder> get remindersBox => Hive.box<Reminder>(_remindersBoxName);

  static Future<void> clearAll() async {
    await chatsBox.clear();
    await messagesBox.clear();
    await remindersBox.clear();
  }
}
