# Accessibility (a11y) & WCAG Audit: ProfileTab

**Target Scope**: `lib/screens/home/profile/profile_tab.dart` (`ProfileTab`, `EditProfileDialog`, `RankInfoDialog`, `NotificationsDialog`)  
**File Path**: `d:\Feditok\lib\screens\home\profile\profile_tab.dart`  
**WCAG Standard**: WCAG 2.1 / 2.2 Level AA  
**Platform Guidelines**: Android (48x48 dp), iOS (44x44 dp)

---

## Executive Summary

`ProfileTab` displays user identity details (avatar, banner, username, bio, supporter rank), an account actions toolbar (profile editing, rank information, notification center, and settings navigation), and locally saved offline video backups. Key accessibility issues identified include unannounced unread notification badges, unlabelled non-keyboard-accessible `GestureDetector` buttons in the profile editor dialog, unlabelled action buttons in the app bar and video list, and small font sizing on the rank badge.

---

## Findings by Severity

### 1. High Severity

#### [HIGH-01] Unannounced Unread Notifications Status on Notification Button
- **File**: `d:\Feditok\lib\screens\home\profile\profile_tab.dart`
- **Line(s)**: 288–314
- **WCAG Guideline**: WCAG 4.1.2 Name, Role, Value (Level A), WCAG 1.3.1 Info and Relationships (Level A)
- **Defect**: When `_hasUnreadNotifications` is true, a red badge containing `'!'` is rendered in a `Positioned` overlay above the notification icon button. However, the `IconButton` maintains a static `tooltip: 'Notifiche'`. Blind and low-vision screen reader users receive no auditory indication that unread alerts or friend requests are waiting.
- **Code Fix**:
```dart
Stack(
  children: [
    IconButton(
      icon: const Icon(Icons.notifications_none),
      tooltip: _hasUnreadNotifications ? 'Notifiche (hai notifiche non lette)' : 'Notifiche',
      onPressed: () => _openNotificationsDialog(context),
    ),
    if (_hasUnreadNotifications)
      Positioned(
        right: 8,
        top: 8,
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: const Text(
              '!',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
  ],
)
```

#### [HIGH-02] Non-Focusable GestureDetector Image Selectors in EditProfileDialog
- **File**: `d:\Feditok\lib\screens\home\profile\profile_tab.dart`
- **Line(s)**: 60–93, 97–114
- **WCAG Guideline**: WCAG 4.1.2 Name, Role, Value (Level A), WCAG 2.1.1 Keyboard (Level A)
- **Defect**: In `_openEditProfileDialog`, the banner and avatar image selectors are built using `GestureDetector`.
  1. Neither widget declares `Semantics(button: true)`.
  2. Assistive navigation skips or misidentifies them as static containers.
  3. Hardware keyboard users cannot focus on them or trigger gallery selection via `Enter` or `Space`.
- **Code Fix**:
```dart
// Wrap with InkWell, focus management, and explicit button semantics:
Semantics(
  button: true,
  label: 'Cambia banner del profilo',
  child: InkWell(
    onTap: () async {
      final img = await picker.pickImage(source: ImageSource.gallery);
      if (img != null) setDialogState(() => bannerPath = img.path);
    },
    borderRadius: BorderRadius.circular(8),
    child: Container(
      // ... banner UI
    ),
  ),
),

Semantics(
  button: true,
  label: 'Cambia foto profilo avatar',
  child: InkWell(
    onTap: () async {
      final img = await picker.pickImage(source: ImageSource.gallery);
      if (img != null) setDialogState(() => avatarPath = img.path);
    },
    customBorder: const CircleBorder(),
    child: CircleAvatar(
      // ... avatar UI
    ),
  ),
),
```

---

### 2. Medium Severity

#### [MED-01] Missing Tooltip on Settings IconButton
- **File**: `d:\Feditok\lib\screens\home\profile\profile_tab.dart`
- **Line(s)**: 317–325
- **WCAG Guideline**: WCAG 1.1.1 Non-text Content (Level A), WCAG 4.1.2 Name, Role, Value (Level A)
- **Defect**: The gear icon button opening `SettingsScreen` omits a `tooltip`. Screen readers announce only "Pulsante".
- **Code Fix**:
```dart
IconButton(
  icon: const Icon(Icons.settings),
  tooltip: 'Impostazioni profilo e account',
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  },
)
```

#### [MED-02] Missing Tooltip / Label on Local Video Delete Buttons
- **File**: `d:\Feditok\lib\screens\home\profile\profile_tab.dart`
- **Line(s)**: 450–455
- **WCAG Guideline**: WCAG 1.1.1 Non-text Content (Level A), WCAG 4.1.2 Name, Role, Value (Level A)
- **Defect**: In the saved video list, each item has an `IconButton(icon: Icon(Icons.delete))`. It lacks a `tooltip` identifying which video is targeted for deletion.
- **Code Fix**:
```dart
IconButton(
  icon: const Icon(Icons.delete, color: Colors.redAccent),
  tooltip: 'Elimina video #${index + 1} dalla memoria locale',
  onPressed: () {
    feedProvider.deleteLocalVideo(item);
  },
)
```

#### [MED-03] Rank Badge Semantic Description
- **File**: `d:\Feditok\lib\screens\home\profile\profile_tab.dart`
- **Line(s)**: 368–390
- **WCAG Guideline**: WCAG 1.3.1 Info and Relationships (Level A)
- **Defect**: The supporter rank badge is rendered as a small visual chip with 10sp text and a star icon. Screen readers read the star icon code and raw word without clarifying that it represents the user's community rank.
- **Code Fix**:
```dart
Semantics(
  label: 'Grado utente: ${user?.rank ?? "Supporter"}',
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.amber,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ExcludeSemantics(child: Icon(Icons.star, size: 12, color: Colors.black)),
        const SizedBox(width: 2),
        Text(
          user?.rank ?? 'Supporter',
          style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  ),
)
```

---

### 3. Low Severity

#### [LOW-01] Missing Header Semantics on Saved Videos Section Title
- **File**: `d:\Feditok\lib\screens\home\profile\profile_tab.dart`
- **Line(s)**: 424–428
- **WCAG Guideline**: WCAG 1.3.1 Info and Relationships (Level A)
- **Defect**: `'I Tuoi Video Salvati Localmente'` acts as a section heading but lacks `Semantics(header: true)`.
- **Code Fix**:
```dart
Semantics(
  header: true,
  child: const Text(
    'I Tuoi Video Salvati Localmente',
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  ),
),
```

---

## Automated Accessibility Testing Checklist

```dart
testWidgets('ProfileTab meets accessibility guidelines', (WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
      ],
      child: const MaterialApp(home: ProfileTab()),
    ),
  );

  await expectLater(tester, meetsGuideline(textContrastGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
});
```
