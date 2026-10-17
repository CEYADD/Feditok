# Feditok Flutter Codebase - Master Accessibility (a11y) & WCAG Audit Report

**Audit Target**: `d:\Feditok` (`lib/screens/` and UI components)  
**Evaluator**: Flutter Accessibility Reviewer  
**Standard**: WCAG 2.1 & 2.2 Level AA / Section 508  
**Platform Compliance**: Android (48x48 dp), iOS (44x44 dp), Web (44x44 dp)  
**Date**: October 17, 2026  

---

## 1. Executive Summary

A comprehensive accessibility (a11y) and WCAG compliance audit was conducted across the entire **Feditok** Flutter codebase, specifically inspecting all 11 screens under `lib/screens/`.

Feditok is designed with anti-doomscrolling principles, chronological feeds, and ActivityPub federation. While its dark theme aesthetics (`#121212` scaffold, `#1E1E1E` surface) are modern, several systemic accessibility gaps were identified across six major WCAG audit categories:
1. **Semantics & Screen Readers**: Several key interactive controls (camera shutter, speed-dial FABs, chat bubbles, avatar pickers, unread notification badges) rely on raw `GestureDetector` or lack `Semantics.label` / `tooltip`, leaving screen reader users without names, roles, or states.
2. **Dynamic Live Regions**: Validation errors, OAuth connection states, and destructive action countdowns appear silently without `Semantics(liveRegion: true)`.
3. **Color Contrast (WCAG 1.4.3 / 1.4.11)**: The primary navigation bar's active tab color (`#6C5CE7` on `#1E1E1E`) yields only **3.47:1** contrast (failing the 4.5:1 minimum for small text labels). Button loading subtext (`Colors.white70` on `#6C5CE7`) yields **3.4:1**.
4. **Touch Target Sizing**: Floating action buttons using `FloatingActionButton.small` have a default size of **40x40 dp**, failing the Android 48x48 dp requirement. Inline license links have hit areas as small as 14dp vertically.
5. **Text Scaling & Layout Responsiveness**: Non-scrollable columns with `Spacer()` on the welcome screen can trigger `RenderFlex overflow` when system text scale factor is increased.
6. **Timing & Animation Controls**: The motivational quote timer on `_EndFeedScreen` auto-advances every 10 seconds without pause or freeze controls (violating WCAG 2.2.1 / 2.2.2).

---

## 2. Reviewed Pages & Individual Reports

All 11 discovered screens across `lib/screens/` were selected and audited. Click on any report link to review detailed findings and line-level code fixes:

| Screen / Component | Source File Path | Detailed Audit Report |
| :--- | :--- | :--- |
| **WelcomeScreen** | [`lib/screens/auth/welcome_screen.dart`](file:///d:/Feditok/lib/screens/auth/welcome_screen.dart) | [Welcome Screen Report](file:///d:/Feditok/tmp/a11y_reports/welcome_screen.md) |
| **EmailAuthScreen** | [`lib/screens/auth/email_auth_screen.dart`](file:///d:/Feditok/lib/screens/auth/email_auth_screen.dart) | [Email Auth Screen Report](file:///d:/Feditok/tmp/a11y_reports/email_auth_screen.md) |
| **FediverseAuthScreen** | [`lib/screens/auth/fediverse_auth_screen.dart`](file:///d:/Feditok/lib/screens/auth/fediverse_auth_screen.dart) | [Fediverse Auth Screen Report](file:///d:/Feditok/tmp/a11y_reports/fediverse_auth_screen.md) |
| **OnboardingScreen** | [`lib/screens/onboarding/onboarding_screen.dart`](file:///d:/Feditok/lib/screens/onboarding/onboarding_screen.dart) | [Onboarding Screen Report](file:///d:/Feditok/tmp/a11y_reports/onboarding_screen.md) |
| **HomeScreen** | [`lib/screens/home/home_screen.dart`](file:///d:/Feditok/lib/screens/home/home_screen.dart) | [Home Screen Report](file:///d:/Feditok/tmp/a11y_reports/home_screen.md) |
| **FeedTab** | [`lib/screens/home/feed/feed_tab.dart`](file:///d:/Feditok/lib/screens/home/feed/feed_tab.dart) | [Feed Tab Report](file:///d:/Feditok/tmp/a11y_reports/feed_tab.md) |
| **CameraScreen** | [`lib/screens/home/feed/camera_screen.dart`](file:///d:/Feditok/lib/screens/home/feed/camera_screen.dart) | [Camera Screen Report](file:///d:/Feditok/tmp/a11y_reports/camera_screen.md) |
| **FriendsTab** | [`lib/screens/home/friends/friends_tab.dart`](file:///d:/Feditok/lib/screens/home/friends/friends_tab.dart) | [Friends Tab Report](file:///d:/Feditok/tmp/a11y_reports/friends_tab.md) |
| **ChatScreen** | [`lib/screens/home/friends/chat_screen.dart`](file:///d:/Feditok/lib/screens/home/friends/chat_screen.dart) | [Chat Screen Report](file:///d:/Feditok/tmp/a11y_reports/chat_screen.md) |
| **ProfileTab** | [`lib/screens/home/profile/profile_tab.dart`](file:///d:/Feditok/lib/screens/home/profile/profile_tab.dart) | [Profile Tab Report](file:///d:/Feditok/tmp/a11y_reports/profile_tab.md) |
| **SettingsScreen** | [`lib/screens/home/profile/settings_screen.dart`](file:///d:/Feditok/lib/screens/home/profile/settings_screen.dart) | [Settings Screen Report](file:///d:/Feditok/tmp/a11y_reports/settings_screen.md) |

*(Note: There are zero unreviewed screens; 100% of discovered application screens were included in the audit).*

---

## 3. Aggregated Findings Grouped by Severity

### Critical & High Severity Issues

1. **[ChatScreen] Message Bubbles Rely Purely on Spatial Alignment and Color for Authorship (WCAG 1.3.1, 1.4.1, 4.1.2)**
   - **File & Lines**: [`lib/screens/home/friends/chat_screen.dart#L84-L98`](file:///d:/Feditok/lib/screens/home/friends/chat_screen.dart#L84-L98)
   - Screen reader users only hear the raw text of each message with zero indication of whether the message was sent by themselves ("Tu") or their friend (`friend.username`).
   - **Fix**: Wrap chat bubbles in `Semantics(container: true, label: '${isMe ? "Tu" : friend.username}: ${msg.content}')`.

2. **[CameraScreen] Camera Shutter Button Built with Unlabelled, Non-Focusable GestureDetector (WCAG 4.1.2, 2.1.1, 2.4.7)**
   - **File & Lines**: [`lib/screens/home/feed/camera_screen.dart#L95-L106`](file:///d:/Feditok/lib/screens/home/feed/camera_screen.dart#L95-L106)
   - The central recording button has no `Semantics(button: true)`, no toggle state announcement (record vs. stop), and cannot be focused or activated via keyboard / switch devices.
   - **Fix**: Replace with `InkWell` / `Semantics(button: true, label: _isRecording ? 'Interrompi registrazione' : 'Avvia registrazione')`.

3. **[HomeScreen] Insufficient Color Contrast on Selected BottomNavigationBar Items (WCAG 1.4.3, 1.4.11)**
   - **File & Lines**: [`lib/screens/home/home_screen.dart#L51-L58`](file:///d:/Feditok/lib/screens/home/home_screen.dart#L51-L58)
   - The active navigation tab color (`#6C5CE7`) on dark grey background (`#1E1E1E`) yields a contrast ratio of only **3.47:1**, violating the 4.5:1 minimum requirement for small text labels (12sp).
   - **Fix**: Lighten `selectedItemColor` to `#A29BFE` (6.9:1 ratio) or use `#00CEC9` (8.8:1 ratio).

4. **[FeedTab] Speed-Dial FloatingActionButtons Have Sub-48dp Hit Targets and Missing Labels (WCAG 2.5.5, 2.5.8, 4.1.2)**
   - **File & Lines**: [`lib/screens/home/feed/feed_tab.dart#L152-L213`](file:///d:/Feditok/lib/screens/home/feed/feed_tab.dart#L152-L213)
   - `FloatingActionButton.small` is 40x40 dp (below 48x48 Android threshold) and lacks `tooltip` / `Semantics.label`. The main plus button lacks expand/collapse state announcements.
   - **Fix**: Pad small FABs to minimum 48x48 dp and assign explicit `tooltip` and state descriptions.

5. **[FeedTab] Auto-Advancing Content Without Pause or Stop Controls (WCAG 2.2.1, 2.2.2)**
   - **File & Lines**: [`lib/screens/home/feed/feed_tab.dart#L509-L523`](file:///d:/Feditok/lib/screens/home/feed/feed_tab.dart#L509-L523)
   - Quotes in `_EndFeedScreen` switch every 10 seconds automatically without any pause, stop, or extend control.
   - **Fix**: Provide a prominent pause/play button to control the progress timer.

6. **[EmailAuthScreen] Missing Live Region for Dynamic Authentication and Validation Errors (WCAG 4.1.3)**
   - **File & Lines**: [`lib/screens/auth/email_auth_screen.dart#L188-L202`](file:///d:/Feditok/lib/screens/auth/email_auth_screen.dart#L188-L202)
   - Error messages are rendered conditionally without `Semantics(liveRegion: true)`. Screen reader users receive no spoken feedback when login, registration, or validation fails.
   - **Fix**: Wrap error containers in `Semantics(container: true, liveRegion: true)`.

7. **[EmailAuthScreen] Unlabeled License Checkbox & Undersized Target on GitHub Link (WCAG 1.3.1, 4.1.2, 2.5.5)**
   - **File & Lines**: [`lib/screens/auth/email_auth_screen.dart#L277-L303`](file:///d:/Feditok/lib/screens/auth/email_auth_screen.dart#L277-L303)
   - The `Checkbox` has no `semanticLabel`. The inline link `repo di GitHub` has an undersized touch area (~14dp).
   - **Fix**: Migrate to `CheckboxListTile` with expanded hit padding on the link.

8. **[FediverseAuthScreen] Missing Live Region for OAuth Dynamic Status and Handshake Steps (WCAG 4.1.3)**
   - **File & Lines**: [`lib/screens/auth/fediverse_auth_screen.dart#L209-L228, L270-L279`](file:///d:/Feditok/lib/screens/auth/fediverse_auth_screen.dart#L209-L228)
   - Dynamic OAuth status transitions and network error alerts are silent to screen readers.
   - **Fix**: Wrap status texts in `Semantics(liveRegion: true)`.

9. **[OnboardingScreen] Keyboard Focus Trapping & Unannounced Step Progression in PageView (WCAG 2.4.3, 4.1.2)**
   - **File & Lines**: [`lib/screens/onboarding/onboarding_screen.dart#L72-L80, L162-L165`](file:///d:/Feditok/lib/screens/onboarding/onboarding_screen.dart#L72-L80)
   - Advancing the wizard via `_pageController.nextPage()` leaves keyboard focus trapped on the bottom "Avanti" button instead of shifting focus to the new step inputs.
   - **Fix**: Request focus programmatically on the newly revealed step content.

10. **[ProfileTab] Unannounced Unread Notification Status on Notification Icon (WCAG 4.1.2, 1.3.1)**
    - **File & Lines**: [`lib/screens/home/profile/profile_tab.dart#L288-L314`](file:///d:/Feditok/lib/screens/home/profile/profile_tab.dart#L288-L314)
    - The red exclamation badge over the notification icon is invisible to screen readers, which only announce "Notifiche".
    - **Fix**: Set dynamic `tooltip: _hasUnreadNotifications ? 'Notifiche (hai notifiche non lette)' : 'Notifiche'`.

11. **[ProfileTab] Non-Focusable GestureDetector Selectors in Profile Editor Dialog (WCAG 4.1.2, 2.1.1)**
    - **File & Lines**: [`lib/screens/home/profile/profile_tab.dart#L60-L114`](file:///d:/Feditok/lib/screens/home/profile/profile_tab.dart#L60-L114)
    - Banner and avatar selectors use raw `GestureDetector` lacking `Semantics(button: true)` and keyboard focus.
    - **Fix**: Convert to `InkWell` with semantic button labels and focus rings.

12. **[SettingsScreen] Missing Live Region on Safety Countdown Lockout in Delete Confirmation Dialog (WCAG 4.1.3, 2.2.1)**
    - **File & Lines**: [`lib/screens/home/profile/settings_screen.dart#L326-L341, L378-L392`](file:///d:/Feditok/lib/screens/home/profile/settings_screen.dart#L326-L341)
    - The 5-second countdown timer and transition to enabled state occur silently. Blind users cannot tell when the deletion button becomes clickable.
    - **Fix**: Wrap button label in `Semantics(liveRegion: true)`.

13. **[WelcomeScreen] RenderFlex Overflow Risk on High Text Scale Factors (WCAG 1.4.4, 1.4.10)**
    - **File & Lines**: [`lib/screens/auth/welcome_screen.dart#L14-L18, L56`](file:///d:/Feditok/lib/screens/auth/welcome_screen.dart#L14-L18)
    - Rigid `Column` with multiple `Spacer()` widgets causes visual overflow and unscrollable clipping at 1.5x–2.0x text scaling.
    - **Fix**: Wrap in `SingleChildScrollView` with `ConstrainedBox` / `IntrinsicHeight`.

---

### Medium Severity Issues

1. **[WelcomeScreen] Missing Header Semantics on Primary Screen Title**: [`lib/screens/auth/welcome_screen.dart#L35-L42`](file:///d:/Feditok/lib/screens/auth/welcome_screen.dart#L35-L42). Add `Semantics(header: true)`.
2. **[WelcomeScreen] Decorative Icons Announced Redundantly**: [`lib/screens/auth/welcome_screen.dart#L28-L32, L78, L108`](file:///d:/Feditok/lib/screens/auth/welcome_screen.dart#L28-L32). Wrap in `ExcludeSemantics`.
3. **[EmailAuthScreen] Missing Accessible Label on Suffix IconButton in Email Field**: [`lib/screens/auth/email_auth_screen.dart#L213-L223`](file:///d:/Feditok/lib/screens/auth/email_auth_screen.dart#L213-L223). Add `tooltip: 'Modifica indirizzo email'`.
4. **[EmailAuthScreen] Reliance on Color Alone for Error Container**: [`lib/screens/auth/email_auth_screen.dart#L189-L200`](file:///d:/Feditok/lib/screens/auth/email_auth_screen.dart#L189-L200). Add warning icon alongside red text.
5. **[FediverseAuthScreen] Low Color Contrast on Button Status Subtitle (`Colors.white70` on `#6C5CE7`)**: [`lib/screens/auth/fediverse_auth_screen.dart#L271-L278`](file:///d:/Feditok/lib/screens/auth/fediverse_auth_screen.dart#L271-L278). Contrast ratio is **3.4:1** (fails 4.5:1). Change to solid `Colors.white`.
6. **[FediverseAuthScreen] Missing Semantics on CircularProgressIndicator**: [`lib/screens/auth/fediverse_auth_screen.dart#L261-L268`](file:///d:/Feditok/lib/screens/auth/fediverse_auth_screen.dart#L261-L268). Add `semanticsLabel`.
7. **[OnboardingScreen] Missing Semantics on Step Progress Indicator**: [`lib/screens/onboarding/onboarding_screen.dart#L134-L138`](file:///d:/Feditok/lib/screens/onboarding/onboarding_screen.dart#L134-L138). Add `semanticsLabel` and `semanticsValue`.
8. **[OnboardingScreen] Fragmented Announcements on Rule Cards**: [`lib/screens/onboarding/onboarding_screen.dart#L340-L364`](file:///d:/Feditok/lib/screens/onboarding/onboarding_screen.dart#L340-L364). Wrap each `_RuleTile` in `MergeSemantics`.
9. **[FeedTab] Missing Tooltips on Video Interaction IconButtons**: [`lib/screens/home/feed/feed_tab.dart#L303-L334`](file:///d:/Feditok/lib/screens/home/feed/feed_tab.dart#L303-L334). Add tooltips for like, comments, and download.
10. **[FeedTab] Focus Order on Floating Action Buttons**: [`lib/screens/home/feed/feed_tab.dart#L105-L217`](file:///d:/Feditok/lib/screens/home/feed/feed_tab.dart#L105-L217). Add `FocusTraversalGroup` with explicit priority order.
11. **[CameraScreen] Missing Tooltips on Modal Add Tag Button & Tag Chips**: [`lib/screens/home/feed/camera_screen.dart#L227-L245`](file:///d:/Feditok/lib/screens/home/feed/camera_screen.dart#L227-L245). Add `tooltip` and `deleteButtonTooltipMessage`.
12. **[FriendsTab] Missing Semantic Hints and Trailing Icon Redundancy on Friend ListTiles**: [`lib/screens/home/friends/friends_tab.dart#L108-L129`](file:///d:/Feditok/lib/screens/home/friends/friends_tab.dart#L108-L129). Exclude trailing chat icon from semantics.
13. **[ChatScreen] Missing Tooltip on Message Send IconButton**: [`lib/screens/home/friends/chat_screen.dart#L117-L121`](file:///d:/Feditok/lib/screens/home/friends/chat_screen.dart#L117-L121). Add `tooltip: 'Invia messaggio'`.
14. **[ProfileTab] Missing Tooltip on Settings Gear IconButton**: [`lib/screens/home/profile/profile_tab.dart#L317-L325`](file:///d:/Feditok/lib/screens/home/profile/profile_tab.dart#L317-L325). Add `tooltip: 'Impostazioni profilo'`.
15. **[ProfileTab] Missing Tooltip on Local Video Delete Buttons**: [`lib/screens/home/profile/profile_tab.dart#L450-L455`](file:///d:/Feditok/lib/screens/home/profile/profile_tab.dart#L450-L455). Add `tooltip: 'Elimina video locale'`.
16. **[SettingsScreen] Missing Header Semantics on Settings Section Titles**: [`lib/screens/home/profile/settings_screen.dart#L116-L128`](file:///d:/Feditok/lib/screens/home/profile/settings_screen.dart#L116-L128). Add `Semantics(header: true)`.

---

### Low Severity Issues

1. **[WelcomeScreen] Button Internal Semantics Grouping**: [`lib/screens/auth/welcome_screen.dart#L59-L86`](file:///d:/Feditok/lib/screens/auth/welcome_screen.dart#L59-L86). Add `MergeSemantics`.
2. **[EmailAuthScreen] Decorative Input Prefix Icons**: [`lib/screens/auth/email_auth_screen.dart#L211, L250, L271`](file:///d:/Feditok/lib/screens/auth/email_auth_screen.dart#L211). Add `ExcludeSemantics`.
3. **[HomeScreen] Dead Code BottomNavigationBarThemeData Stub**: [`lib/screens/home/home_screen.dart#L81-L83`](file:///d:/Feditok/lib/screens/home/home_screen.dart#L81-L83). Remove dead stub.
4. **[FriendsTab] Decorative Empty State Icon**: [`lib/screens/home/friends/friends_tab.dart#L89`](file:///d:/Feditok/lib/screens/home/friends/friends_tab.dart#L89). Add `ExcludeSemantics`.
5. **[ChatScreen] Decorative Avatar in Chat AppBar**: [`lib/screens/home/friends/chat_screen.dart#L48-L56`](file:///d:/Feditok/lib/screens/home/friends/chat_screen.dart#L48-L56). Add `ExcludeSemantics`.
6. **[CameraScreen] Modal Heading Semantics**: [`lib/screens/home/feed/camera_screen.dart#L190-L193`](file:///d:/Feditok/lib/screens/home/feed/camera_screen.dart#L190-L193). Add `Semantics(header: true)`.

---

## 4. Automated Accessibility Testing Strategy

To guard against a11y regressions in future pull requests, add widget tests asserting Flutter's built-in accessibility guidelines for every screen:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Screen passes accessibility guidelines', (WidgetTester tester) async {
    // 1. Pump the target screen
    await tester.pumpWidget(const TestableScreenWrapper());

    // 2. Validate WCAG 2.1 Contrast
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    // 3. Validate Tap Target Boundaries (48x48 Android / 44x44 iOS)
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

    // 4. Validate All Interactive Elements Are Labeled
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}
```
