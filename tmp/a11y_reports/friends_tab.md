# Accessibility (a11y) & WCAG Audit: FriendsTab

**Target Scope**: `lib/screens/home/friends/friends_tab.dart` (`FriendsTab`)  
**File Path**: `d:\Feditok\lib\screens\home\friends\friends_tab.dart`  
**WCAG Standard**: WCAG 2.1 / 2.2 Level AA  
**Platform Guidelines**: Android (48x48 dp), iOS (44x44 dp)

---

## Executive Summary

`FriendsTab` displays the user's friend list with navigation into private temporary 1-on-1 chats and an `AddFriendDialog`. The screen generally implements good accessibility hygiene (e.g., `IconButton` has a `tooltip`), but improvements are needed in list tile semantics, avatar alternative text, decorative icon exclusion, and dialog focus order.

---

## Findings by Severity

### 1. Medium Severity

#### [MED-01] Missing Semantic Hints and Trailing Icon Redundancy on Friend ListTiles
- **File**: `d:\Feditok\lib\screens\home\friends\friends_tab.dart`
- **Line(s)**: 108–129
- **WCAG Guideline**: WCAG 4.1.2 Name, Role, Value (Level A), WCAG 1.1.1 Non-text Content (Level A)
- **Defect**: Each friend item in `ListView.builder` has a trailing `Icon(Icons.chat_bubble_outline)`. Because it is not excluded from semantics, screen readers read "chat bubble outline icon" as part of the tile content without conveying that tapping the tile opens the chat with that friend.
- **Code Fix**:
```dart
ListTile(
  leading: CircleAvatar(
    backgroundImage: friend.avatarUrl != null ? NetworkImage(friend.avatarUrl!) : null,
    child: friend.avatarUrl == null
        ? Text(friend.username[0].toUpperCase())
        : null,
  ),
  title: Text(friend.fullName ?? friend.username),
  subtitle: Text('@${friend.username}'),
  trailing: const ExcludeSemantics(
    child: Icon(Icons.chat_bubble_outline),
  ),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(friend: friend)),
    );
  },
)
```

#### [MED-02] Missing Alternative Text for Initial Avatar Fallback
- **File**: `d:\Feditok\lib\screens\home\friends\friends_tab.dart`
- **Line(s)**: 109–116
- **WCAG Guideline**: WCAG 1.1.1 Non-text Content (Level A)
- **Defect**: When `friend.avatarUrl` is null, the avatar displays a single letter (the first character of the username). Assistive readers may pronounce this isolated capital letter before the user's full name, confusing the user.
- **Code Fix**:
```dart
Semantics(
  image: true,
  label: 'Avatar di ${friend.fullName ?? friend.username}',
  child: CircleAvatar(
    backgroundImage: friend.avatarUrl != null ? NetworkImage(friend.avatarUrl!) : null,
    child: friend.avatarUrl == null
        ? Text(friend.username[0].toUpperCase())
        : null,
  ),
),
```

---

### 2. Low Severity

#### [LOW-01] Empty State Decorative Icon Screen Reader Leakage
- **File**: `d:\Feditok\lib\screens\home\friends\friends_tab.dart`
- **Line(s)**: 89
- **WCAG Guideline**: WCAG 1.1.1 Non-text Content (Level A)
- **Defect**: The empty state icon `Icons.people_outline` is purely decorative accompanying `'Nessun amico presente.'`. It should be hidden from screen readers.
- **Code Fix**:
```dart
const ExcludeSemantics(
  child: Icon(Icons.people_outline, size: 64, color: Colors.grey[600]),
),
```

#### [LOW-02] Dialog Input Prefix Icon Exclusion
- **File**: `d:\Feditok\lib\screens\home\friends\friends_tab.dart`
- **Line(s)**: 38
- **WCAG Guideline**: WCAG 1.1.1 Non-text Content (Level A)
- **Defect**: The prefix `@` icon in the add friend search field is decorative.
- **Code Fix**:
```dart
prefixIcon: const ExcludeSemantics(child: Icon(Icons.alternate_email)),
```

---

## Automated Accessibility Testing Checklist

```dart
testWidgets('FriendsTab meets accessibility guidelines', (WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => FriendsProvider())],
      child: const MaterialApp(home: FriendsTab()),
    ),
  );

  await expectLater(tester, meetsGuideline(textContrastGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
});
```
