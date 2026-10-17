# Accessibility (a11y) & WCAG Audit: ChatScreen

**Target Scope**: `lib/screens/home/friends/chat_screen.dart` (`ChatScreen`)  
**File Path**: `d:\Feditok\lib\screens\home\friends\chat_screen.dart`  
**WCAG Standard**: WCAG 2.1 / 2.2 Level AA  
**Platform Guidelines**: Android (48x48 dp), iOS (44x44 dp)

---

## Executive Summary

`ChatScreen` provides ephemeral direct messaging between friends, featuring automatic 3-day deletion notices, a scrolling message history, and a message composition field. The most critical defect identified is that chat bubbles rely exclusively on spatial alignment (left vs. right) and background color to convey message authorship. Screen reader users hear only the message text without any indication of who sent each message.

---

## Findings by Severity

### 1. High Severity

#### [HIGH-01] Message Bubbles Rely Purely on Alignment and Color to Convey Authorship
- **File**: `d:\Feditok\lib\screens\home\friends\chat_screen.dart`
- **Line(s)**: 84–98
- **WCAG Guideline**: WCAG 1.3.1 Info and Relationships (Level A), WCAG 1.4.1 Use of Color (Level A), WCAG 4.1.2 Name, Role, Value (Level A)
- **Defect**: The message item is constructed using an `Align` (left or right) and a colored `Container`:
  ```dart
  Align(
    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      decoration: BoxDecoration(
        color: isMe ? Theme.of(context).colorScheme.primary : Colors.grey[800],
      ),
      child: Text(msg.content),
    ),
  )
  ```
  Assistive technologies read only the string `msg.content`. There is zero verbal attribution of whether a message was sent by "Tu" or the conversation partner (`friend.username`). This makes conversations incomprehensible to blind and visually impaired users.
- **Code Fix**:
```dart
// Wrap the bubble in an explicit Semantics widget declaring sender and content:
Align(
  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
  child: Semantics(
    container: true,
    label: '${isMe ? "Tu" : widget.friend.fullName ?? widget.friend.username}: ${msg.content}',
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? Theme.of(context).colorScheme.primary : Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExcludeSemantics(
        child: Text(
          msg.content,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  ),
)
```

---

### 2. Medium Severity

#### [MED-01] Missing Tooltip / Semantic Label on Message Send IconButton
- **File**: `d:\Feditok\lib\screens\home\friends\chat_screen.dart`
- **Line(s)**: 117–121
- **WCAG Guideline**: WCAG 1.1.1 Non-text Content (Level A), WCAG 4.1.2 Name, Role, Value (Level A)
- **Defect**: The message send button is an `IconButton(icon: Icon(Icons.send))` without a `tooltip`. Screen reader users focusing on the send icon hear only "Pulsante".
- **Code Fix**:
```dart
IconButton(
  icon: const Icon(Icons.send),
  tooltip: 'Invia messaggio',
  color: Theme.of(context).colorScheme.primary,
  onPressed: _send,
)
```

#### [MED-02] Ephemeral Message Policy Banner Semantics
- **File**: `d:\Feditok\lib\screens\home\friends\chat_screen.dart`
- **Line(s)**: 61–75
- **WCAG Guideline**: WCAG 1.3.1 Info and Relationships (Level A)
- **Defect**: The top amber banner communicating the 3-day deletion policy lacks semantic container grouping, causing the timer icon and text to be read as isolated disjoint elements.
- **Code Fix**:
```dart
MergeSemantics(
  child: Container(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
    color: Colors.amber.withValues(alpha: 0.15),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: Icon(Icons.timer_outlined, size: 16, color: Colors.amber),
        ),
        SizedBox(width: 6),
        Text(
          'I messaggi vengono eliminati automaticamente dopo 3 giorni',
          style: TextStyle(color: Colors.amber, fontSize: 12),
        ),
      ],
    ),
  ),
)
```

---

### 3. Low Severity

#### [LOW-01] Decorative Avatar in Chat AppBar
- **File**: `d:\Feditok\lib\screens\home\friends\chat_screen.dart`
- **Line(s)**: 48–56
- **WCAG Guideline**: WCAG 1.1.1 Non-text Content (Level A)
- **Defect**: The `CircleAvatar` inside the `AppBar` title is placed right next to `Text(widget.friend.username)`. It should be excluded from semantics to prevent redundant announcements.
- **Code Fix**:
```dart
title: Row(
  children: [
    ExcludeSemantics(
      child: CircleAvatar(
        radius: 16,
        backgroundImage: widget.friend.avatarUrl != null ? NetworkImage(widget.friend.avatarUrl!) : null,
        child: widget.friend.avatarUrl == null ? Text(widget.friend.username[0].toUpperCase()) : null,
      ),
    ),
    const SizedBox(width: 10),
    Text(widget.friend.fullName ?? widget.friend.username),
  ],
)
```

---

## Automated Accessibility Testing Checklist

```dart
testWidgets('ChatScreen meets accessibility guidelines', (WidgetTester tester) async {
  final testFriend = UserProfile(id: 'friend1', username: 'niko', fullName: 'Niko Bellic');

  await tester.pumpWidget(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => FriendsProvider())],
      child: MaterialApp(home: ChatScreen(friend: testFriend)),
    ),
  );

  await expectLater(tester, meetsGuideline(textContrastGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
});
```
