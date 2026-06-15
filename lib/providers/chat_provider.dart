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

  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  List<Chat> get chats {
    // Pinned chats first, then sorted by last message time (or creation time if no messages)
    final list = List<Chat>.from(_chats);
    list.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      
      final aMsgs = getMessagesForChat(a.id);
      final bMsgs = getMessagesForChat(b.id);
      
      final aTime = aMsgs.isNotEmpty ? aMsgs.last.timestamp : a.createdAt;
      final bTime = bMsgs.isNotEmpty ? bMsgs.last.timestamp : b.createdAt;
      
      return bTime.compareTo(aTime);
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

  Future<void> _loadFromDatabase() async {
    _chats = DatabaseService.chatsBox.values.toList();
    _messages = DatabaseService.messagesBox.values.toList();
    _reminders = DatabaseService.remindersBox.values.toList();
    
    if (_chats.isEmpty) {
      await _createDefaultChats();
    } else {
      notifyListeners();
    }
  }

  Future<void> _createDefaultChats() async {
    final c1 = await createChat("Placement Prep", iconCode: Icons.work.codePoint);
    final c2 = await createChat("College Notes", iconCode: Icons.description.codePoint);
    final c3 = await createChat("Shopping", iconCode: Icons.shopping_cart.codePoint);
    
    // We already do notifyListeners inside createChat, but let's make sure the state is clean
    _chats = [c1, c2, c3];
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

    // Schedule Alarm (exact time) and Warning (10 minutes before)
    final notificationId = reminderId.hashCode;
    final warningTime = time.subtract(const Duration(minutes: 10));
    final payloadString = "$reminderId|$chatId";

    await NotificationService.scheduleNotification(
      id: notificationId,
      title: "Memzy Alarm",
      body: content,
      scheduledTime: time,
      payload: payloadString,
      isAlarm: true,
    );

    await NotificationService.scheduleNotification(
      id: notificationId + 1,
      title: "Upcoming Reminder (in 10m)",
      body: content,
      scheduledTime: warningTime,
      payload: payloadString,
      isAlarm: false,
    );

    notifyListeners();
    return reminder;
  }

  // Update an existing reminder (content and time)
  Future<void> updateReminder({
    required String reminderId,
    required String content,
    required DateTime time,
  }) async {
    final reminderIndex = _reminders.indexWhere((r) => r.id == reminderId);
    if (reminderIndex != -1) {
      final r = _reminders[reminderIndex];
      // 1. Cancel previous notification (both alarm and warning)
      await NotificationService.cancelNotification(r.id.hashCode);

      // 2. Mutate reminder fields and save
      r.content = content;
      r.time = time;
      await r.save();

      // 3. Re-schedule notifications if not completed
      if (!r.isCompleted) {
        final notificationId = r.id.hashCode;
        final warningTime = time.subtract(const Duration(minutes: 10));
        final payloadString = "${r.id}|${r.chatId}";

        await NotificationService.scheduleNotification(
          id: notificationId,
          title: "Memzy Alarm",
          body: content,
          scheduledTime: time,
          payload: payloadString,
          isAlarm: true,
        );

        await NotificationService.scheduleNotification(
          id: notificationId + 1,
          title: "Upcoming Reminder (in 10m)",
          body: content,
          scheduledTime: warningTime,
          payload: payloadString,
          isAlarm: false,
        );
      }
      notifyListeners();
    }
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

    bool reminderCreated = false;

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
        reminderCreated = true;
        notifyListeners();
      }
    }

    if (!reminderCreated) {
      // Auto-reply for any other message
      final systemMsg = Message(
        id: _uuid.v4(),
        chatId: chatId,
        text: "✓ Noted.",
        sender: 'system',
        timestamp: DateTime.now().add(const Duration(milliseconds: 100)),
        type: 'text',
      );

      await DatabaseService.messagesBox.put(systemMsg.id, systemMsg);
      _messages.add(systemMsg);
      notifyListeners();
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
      // Re-schedule notifications
      final notificationId = reminder.id.hashCode;
      final warningTime = reminder.time.subtract(const Duration(minutes: 10));
      final payloadString = "${reminder.id}|${reminder.chatId}";

      await NotificationService.scheduleNotification(
        id: notificationId,
        title: "Memzy Alarm",
        body: reminder.content,
        scheduledTime: reminder.time,
        payload: payloadString,
        isAlarm: true,
      );

      await NotificationService.scheduleNotification(
        id: notificationId + 1,
        title: "Upcoming Reminder (in 10m)",
        body: reminder.content,
        scheduledTime: warningTime,
        payload: payloadString,
        isAlarm: false,
      );
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

  // Delete reminder directly by reminder ID
  Future<void> deleteReminder(String reminderId) async {
    await NotificationService.cancelNotification(reminderId.hashCode);
    await DatabaseService.remindersBox.delete(reminderId);
    _reminders.removeWhere((r) => r.id == reminderId);
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
}
