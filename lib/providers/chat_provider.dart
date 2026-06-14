import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/reminder.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/reminder_parser.dart';

class ChatProvider extends ChangeNotifier {
  final Uuid _uuid = const Uuid();

  List<Chat> _chats = [];
  List<Message> _messages = [];
  List<Reminder> _reminders = [];

  List<Chat> get chats {
    // Pinned chats first, then sorted by creation time descending (or last message time)
    final list = List<Chat>.from(_chats);
    list.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  List<Reminder> get reminders => _reminders;

  List<Reminder> get todayReminders {
    final now = DateTime.now();
    return _reminders.where((r) {
      final isSameDay = r.time.year == now.year &&
          r.time.month == now.month &&
          r.time.day == now.day;
      return isSameDay && !r.isCompleted;
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  List<Reminder> get upcomingReminders {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return _reminders.where((r) {
      return r.time.isAfter(todayEnd) && !r.isCompleted;
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  List<Reminder> get completedReminders {
    return _reminders.where((r) => r.isCompleted).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
  }

  ChatProvider() {
    _loadFromDatabase();
  }

  void _loadFromDatabase() {
    _chats = DatabaseService.chatsBox.values.toList();
    _messages = DatabaseService.messagesBox.values.toList();
    _reminders = DatabaseService.remindersBox.values.toList();
    notifyListeners();
  }

  // Get messages for a specific chat
  List<Message> getMessagesForChat(String chatId) {
    return _messages.where((m) => m.chatId == chatId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // Create a chat thread
  Future<Chat> createChat(String title, {int? iconCode}) async {
    final newChat = Chat(
      id: _uuid.v4(),
      title: title,
      iconCode: iconCode ?? Icons.chat.codePoint,
      createdAt: DateTime.now(),
    );
    await DatabaseService.chatsBox.put(newChat.id, newChat);
    _chats.add(newChat);
    notifyListeners();
    return newChat;
  }

  // Pin / Unpin chat
  Future<void> togglePinChat(String chatId) async {
    final chat = _chats.firstWhere((c) => c.id == chatId);
    chat.isPinned = !chat.isPinned;
    await chat.save();
    notifyListeners();
  }

  // Archive / Unarchive chat
  Future<void> toggleArchiveChat(String chatId) async {
    final chat = _chats.firstWhere((c) => c.id == chatId);
    chat.isArchived = !chat.isArchived;
    await chat.save();
    notifyListeners();
  }

  // Delete chat and its associated messages/reminders
  Future<void> deleteChat(String chatId) async {
    // Delete chat from box
    await DatabaseService.chatsBox.delete(chatId);
    _chats.removeWhere((c) => c.id == chatId);

    // Delete messages
    final chatMessages = _messages.where((m) => m.chatId == chatId).toList();
    for (var m in chatMessages) {
      await DatabaseService.messagesBox.delete(m.id);
    }
    _messages.removeWhere((m) => m.chatId == chatId);

    // Delete reminders & cancel notifications
    final chatReminders = _reminders.where((r) => r.chatId == chatId).toList();
    for (var r in chatReminders) {
      await NotificationService.cancelNotification(r.id.hashCode);
      await DatabaseService.remindersBox.delete(r.id);
    }
    _reminders.removeWhere((r) => r.chatId == chatId);

    notifyListeners();
  }

  // Create a reminder directly (can be standalone or linked to a chat)
  Future<Reminder> createReminder({
    required String chatId,
    required String messageId,
    required String content,
    required DateTime time,
  }) async {
    final reminderId = _uuid.v4();
    final reminder = Reminder(
      id: reminderId,
      chatId: chatId,
      messageId: messageId,
      content: content,
      time: time,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    await DatabaseService.remindersBox.put(reminder.id, reminder);
    _reminders.add(reminder);

    // Schedule Notification (Hash code of UUID for unique int id)
    final notificationId = reminderId.hashCode;
    await NotificationService.scheduleNotification(
      id: notificationId,
      title: "Memzy Reminder",
      body: content,
      scheduledTime: time,
    );

    notifyListeners();
    return reminder;
  }

  // Send message
  Future<void> sendMessage({
    required String chatId,
    required String text,
    String type = 'text',
    String? fileLocalPath,
    String? fileName,
    int? fileSize,
  }) async {
    final messageId = _uuid.v4();
    final userMsg = Message(
      id: messageId,
      chatId: chatId,
      text: text,
      sender: 'user',
      timestamp: DateTime.now(),
      type: type,
      fileLocalPath: fileLocalPath,
      fileName: fileName,
      fileSize: fileSize,
    );

    await DatabaseService.messagesBox.put(userMsg.id, userMsg);
    _messages.add(userMsg);
    notifyListeners();

    // Check if the message contains a reminder
    if (type == 'text') {
      final parseResult = ReminderParser.parse(text);
      if (parseResult != null) {
        await createReminder(
          chatId: chatId,
          messageId: messageId,
          content: parseResult.content,
          time: parseResult.time,
        );

        // Format and add system response message
        final formattedTime = _formatReminderTime(parseResult.time);
        final systemMsg = Message(
          id: _uuid.v4(),
          chatId: chatId,
          text: "✓ Noted. Reminder created for $formattedTime.",
          sender: 'system',
          timestamp: DateTime.now().add(const Duration(milliseconds: 100)),
          type: 'text',
        );

        await DatabaseService.messagesBox.put(systemMsg.id, systemMsg);
        _messages.add(systemMsg);
        notifyListeners();
      }
    }
  }

  // Toggle Message Star status
  Future<void> toggleStarMessage(String messageId) async {
    final msg = _messages.firstWhere((m) => m.id == messageId);
    msg.isStarred = !msg.isStarred;
    await msg.save();
    notifyListeners();
  }

  // Toggle Reminder completion
  Future<void> toggleReminderCompletion(String reminderId) async {
    final reminder = _reminders.firstWhere((r) => r.id == reminderId);
    reminder.isCompleted = !reminder.isCompleted;
    await reminder.save();

    if (reminder.isCompleted) {
      await NotificationService.cancelNotification(reminder.id.hashCode);
    } else {
      // Re-schedule reminder if it's in the future
      if (reminder.time.isAfter(DateTime.now())) {
        await NotificationService.scheduleNotification(
          id: reminder.id.hashCode,
          title: "Memzy Reminder",
          body: reminder.content,
          scheduledTime: reminder.time,
        );
      }
    }
    notifyListeners();
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    await DatabaseService.messagesBox.delete(messageId);
    _messages.removeWhere((m) => m.id == messageId);

    // Cancel related reminder if any
    final reminderIndex = _reminders.indexWhere((r) => r.messageId == messageId);
    if (reminderIndex != -1) {
      final r = _reminders[reminderIndex];
      await NotificationService.cancelNotification(r.id.hashCode);
      await DatabaseService.remindersBox.delete(r.id);
      _reminders.remove(r);
    }
    notifyListeners();
  }

  // Clear chat logs
  Future<void> clearChatLogs(String chatId) async {
    final chatMessages = _messages.where((m) => m.chatId == chatId).toList();
    for (var m in chatMessages) {
      await DatabaseService.messagesBox.delete(m.id);
    }
    _messages.removeWhere((m) => m.chatId == chatId);

    final chatReminders = _reminders.where((r) => r.chatId == chatId).toList();
    for (var r in chatReminders) {
      await NotificationService.cancelNotification(r.id.hashCode);
      await DatabaseService.remindersBox.delete(r.id);
    }
    _reminders.removeWhere((r) => r.chatId == chatId);

    notifyListeners();
  }

  // Search function returning matches for chats, messages, and reminders
  Map<String, dynamic> searchAll(String query) {
    if (query.isEmpty) {
      return {'chats': <Chat>[], 'messages': <Message>[], 'reminders': <Reminder>[]};
    }
    final lowercaseQuery = query.toLowerCase();

    final matchedChats = _chats.where((c) => c.title.toLowerCase().contains(lowercaseQuery)).toList();
    final matchedMessages = _messages.where((m) => m.text.toLowerCase().contains(lowercaseQuery)).toList();
    final matchedReminders = _reminders.where((r) => r.content.toLowerCase().contains(lowercaseQuery)).toList();

    return {
      'chats': matchedChats,
      'messages': matchedMessages,
      'reminders': matchedReminders,
    };
  }

  String _formatReminderTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (target == today) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (target == tomorrow) {
      return "tomorrow at ${DateFormat('h:mm a').format(dateTime)}";
    } else {
      return "${DateFormat('d MMMM').format(dateTime)} at ${DateFormat('h:mm a').format(dateTime)}";
    }
  }

  // Seed default data for prototype demonstration on first launch
  Future<void> seedDemoData() async {
    if (_chats.isNotEmpty) return; // Only seed if empty
    final now = DateTime.now();

    final c1 = await createChat("Placement Prep", iconCode: Icons.work.codePoint);
    final c2 = await createChat("College Notes", iconCode: Icons.description.codePoint);
    final c3 = await createChat("Shopping", iconCode: Icons.shopping_cart.codePoint);

    // Seeding messages for Placement Prep
    await sendMessage(chatId: c1.id, text: "Apply for internship. Remind me at 10:00 PM.");
    // This triggers the automatic system reply and scheduled reminder inside sendMessage

    // Seeding College Notes files
    final time2 = DateTime.now().subtract(const Duration(hours: 3));
    final userMsg2 = Message(
      id: _uuid.v4(),
      chatId: c2.id,
      text: "Saved Lecture 3 PDF",
      sender: 'user',
      timestamp: time2,
      type: 'pdf',
      fileName: 'Lecture_3.pdf',
      fileSize: 1258291, // 1.2 MB
    );
    await DatabaseService.messagesBox.put(userMsg2.id, userMsg2);
    _messages.add(userMsg2);

    // Seeding Shopping list
    final time3 = DateTime.now().subtract(const Duration(days: 1));
    final userMsg3 = Message(
      id: _uuid.v4(),
      chatId: c3.id,
      text: "Groceries list",
      sender: 'user',
      timestamp: time3,
      type: 'text',
    );
    await DatabaseService.messagesBox.put(userMsg3.id, userMsg3);
    _messages.add(userMsg3);

    // Add some completed/upcoming reminders manually to match prototypes
    final tomorrow9AM = DateTime(now.year, now.month, now.day).add(const Duration(days: 1, hours: 9));
    final rUpcoming = Reminder(
      id: _uuid.v4(),
      chatId: c3.id,
      messageId: userMsg3.id,
      content: "Buy groceries",
      time: tomorrow9AM,
      isCompleted: false,
      createdAt: time3,
    );
    await DatabaseService.remindersBox.put(rUpcoming.id, rUpcoming);
    _reminders.add(rUpcoming);

    final rCompleted = Reminder(
      id: _uuid.v4(),
      chatId: c2.id,
      messageId: userMsg2.id,
      content: "Review Lecture 3",
      time: DateTime.now().subtract(const Duration(hours: 1)),
      isCompleted: true,
      createdAt: time2,
    );
    await DatabaseService.remindersBox.put(rCompleted.id, rCompleted);
    _reminders.add(rCompleted);

    // Pin College Notes to match UI screenshots
    c2.isPinned = true;
    await c2.save();

    _loadFromDatabase();
  }
}
