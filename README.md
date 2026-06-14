# Memzy - Intelligent Personal Memory Assistant

Memzy is a high-fidelity mobile personal memory assistant built in Flutter, porting the premium **Stitch UI** visual design system. It allows users to manage chats, automatically extract natural language reminders, browse shared files/attachments in a bento-grid layout, view images interactively, and capture intents from other apps.

---

## 🎨 Premium Stitch UI & Design System

- **Amethyst Color Palette**: Sleek dark and light modes styled with dynamic theme configurations using primary colors `#4648d4` and `#883ca6`.
- **Custom Bubble Tails**: Conversation bubbles use asymmetrical rounded borders, with user messages featuring a top-right tail and system replies featuring a top-left tail.
- **Glassmorphism & Blurs**: A blur bottom navigation bar with a transparent frosted glass style overlaying the content.
- **Bento Attachment Layout**: Media, links, and documents are presented in a high-fidelity bento-grid preview inside the Chat Info screen.

---

## ✨ Features Implemented

1. **Natural Language Reminder Extraction**:
   - Parses typed text messages recursively for time clauses (e.g. `"Remind me tomorrow at 8 AM"`, `"Remind me on June 25 at 5 PM"`).
   - Automatically schedules local notifications via exact alarms.
   - Cleans and strips clauses so that the reminder title contains only relevant text.

2. **Full-Screen Interactive Image Viewer**:
   - Tapping any image/photo bubble in the chat view or grid in the attachments view opens the image in full screen.
   - Supports pinch-to-zoom (up to `4.0x`) and panning across the full mobile size.
   - Leverages `Hero` animations for transitions.

3. **Multi-Selection Mode**:
   - Long-pressing any message bubble or attachment immediately starts selection mode.
   - Checkboxes are dynamically aligned based on the message sender (left side for incoming/system, right side for outgoing/user).
   - Allows batch actions (Delete and Star/Unstar).

4. **"Forward to Memzy" Share Target**:
   - Registers intent-filters in the Android Manifest targeting text, images, and other document formats shared from external apps.
   - Displays a custom Share Target selection dialog prompting the user to forward the shared content to an existing chat thread.

---

## 🛠️ Tech Stack & Packages

- **State Management**: `provider`
- **Local Database**: `hive` and `hive_flutter` for offline persistence of Chats, Messages, and Reminders.
- **Notifications**: `flutter_local_notifications` with exact alarms.
- **Files/Media**: `image_picker` and `file_picker`.
- **System Sharing**: `receive_sharing_intent` for incoming share targets.
- **Theme & Typography**: `google_fonts` (using Outfit, Geist, and Inter style profiles).

---

## 🚀 How to Run the Project

1. Ensure a device or emulator is connected:
   ```bash
   adb devices
   ```

2. Get project dependencies:
   ```bash
   flutter pub get
   ```

3. Run the project:
   ```bash
   flutter run
   ```

---

## 🧪 Verification & Testing

Verify that all NLP parse test cases compile and pass:
```bash
flutter test
```
