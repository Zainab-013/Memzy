# Implementation Plan - Memzy: Personal Memory Assistant

Memzy is a Flutter-based personal memory assistant that stores messages, links, images, and documents in a chat-based interface. It automatically parses reminders from user messages, schedules local notifications, and provides a centralized "Reminders" page. Additionally, we will implement a "Forward to Memzy" feature so that users can share files and links from other apps (like Chrome, YouTube, or file managers) directly into Memzy.

## User Review Required

> [!IMPORTANT]
> **Forward to Memzy Native Setup**: The sharing functionality requires modifying native configuration files (like `AndroidManifest.xml` for Android). Since you will run the terminal commands, I will need you to verify that these native configs build correctly on your target device/emulator.

> [!NOTE]
> **Local Storage choice**: We propose using **Hive** for local storage as it is fast, lightweight, and supports key-value database models in pure Dart without heavy SQL setup.

---

## Proposed Changes

We will build the application in the workspace directory `c:\Users\Zainab\OneDrive\Documents\Desktop\ZDesktop\Memzy`.

### 1. Project Initialization & Dependencies

We will instruct the user to run the Flutter creation command.
The dependencies to be added in `pubspec.yaml` include:
*   `provider`: For state management.
*   `hive` & `hive_flutter`: For local database.
*   `flutter_local_notifications`: For scheduling reminders.
*   `timezone`: Required by `flutter_local_notifications` for scheduled timezone-aware notifications.
*   `image_picker`: For selecting photos/videos.
*   `file_picker`: For picking PDFs and documents.
*   `receive_sharing_intent`: For receiving shared links, text, and files from other apps.
*   `intl`: For date and time formatting.
*   `uuid`: For unique identifiers for chats, messages, and reminders.
*   `path_provider`: For fetching local directories.

### 2. State & Storage Architecture

*   **Models**:
    *   `Chat`: Contains `id`, `name`, `createdAt`, `isPinned`, `isArchived`, `lastMessage`.
    *   `Message`: Contains `id`, `chatId`, `text`, `mediaPath`, `type` (text, image, pdf, doc, link), `timestamp`, `isStarred`, `isAutoReply`, `reminderId`.
    *   `Reminder`: Contains `id`, `messageId`, `chatId`, `content`, `dateTime`, `isCompleted`.
*   **Services**:
    *   `StorageService`: Handles Hive boxes for Chats, Messages, and Reminders.
    *   `NotificationService`: Initializes `flutter_local_notifications`, requests permissions, schedules notifications, and cancels notifications.
    *   `ReminderParser`: A utility class using Regular Expressions and Date/Time arithmetic to parse expressions like:
        *   `remind me at 10:00 PM`
        *   `remind me tomorrow at 8 AM`
        *   `remind me on 25 June at 5 PM`
*   **State Providers**:
    *   `MainProvider`: Manages loading, creation of chats, sending messages, parsing messages for reminders, deleting/pinning/archiving, and handling received sharing intents.

### 3. Share Receiver Setup ("Forward to Memzy")

*   **Android configuration**: Modify [AndroidManifest.xml](file:///c:/Users/Zainab/OneDrive/Documents/Desktop/ZDesktop/Memzy/android/app/src/main/AndroidManifest.xml) (once initialized) to add an `<intent-filter>` to `MainActivity` that catches shared text, links, and media.
*   **Flutter handling**: On app startup or resume, check for shared items. If present, open a bottom sheet or modal dialog allowing the user to select which chat they want to save the shared item into.

### 4. UI Theme & Screens (Stitch Design Specification)

We will build the exact high-fidelity visual design specified in the downloaded Stitch assets (`c:\Users\Zainab\Downloads\stitch_memzy_personal_memory_assistant\stitch_memzy_personal_memory_assistant`):
*   **Colors**: 
    *   Primary: Deep Amethyst/Indigo-Violet (`#4648d4`)
    *   Secondary: Amethyst/Magenta-Purple (`#883ca6`)
    *   Background/Surface: Soft Lavender/Off-White (`#f8f9ff` for Light mode)
    *   Dark Mode Surface: Charcoal dark theme with slate tones
    *   Alerts/Errors: Soft pink/red (`#ba1a1a`)
*   **Typography**: Clean sans-serif styling matching the *Geist* specifications.
*   **Screens to Implement**:
    1.  **Splash Screen**: Centered glowing memory logo with deep purple background.
    2.  **Home Screen (Chats Tab)**: Header with "Memzy" title, search button, and top-right light/dark mode switch. Chats are represented as cards (e.g., Placement Prep, College Notes, Shopping) with avatars, status tags, last message, time, and indicators. Floating "+" action button.
    3.  **Chat Screen (Conversation View)**: Top bar with back button, user avatar, active status. User messages are styled in a gradient bubble (`#4648d4` to `#883ca6`), and auto-replies are styled in a soft-mint/lavender outline container. Bottom pill-shaped input with a "+" menu for picking files/images and a round send button.
    4.  **Chat Info Screen**: Centered large avatar and details. Bento-style media grid (collates images, PDFs, docs, links), saved links list, and active reminders specific to the chat.
    5.  **Reminders Screen (Reminders Tab)**: Segregated lists for "Today", "Upcoming", and "Completed" reminders, featuring custom checklist buttons to toggle completion.

---

## Verification Plan

### Manual Verification
1. Run `flutter build apk` or run on an Android emulator/device to verify compile-time errors.
2. Create chats and send reminder messages to verify parsing and auto-response.
3. Test picking images and PDF files to ensure they save and render.
4. Verify notifications show up at the scheduled time.
5. Use the "Share" feature from Chrome or another app, select Memzy, pick a chat, and check if it imports the link/document properly.
