# Accessibility (a11y) & WCAG Audit: FeedTab

**Target Scope**: `lib/screens/home/feed/feed_tab.dart` (`FeedTab`, `_VideoFeedItem`, `_EndFeedScreen`)  
**File Path**: `d:\Feditok\lib\screens\home\feed\feed_tab.dart`  
**WCAG Standard**: WCAG 2.1 / 2.2 Level AA  
**Platform Guidelines**: Android (48x48 dp), iOS (44x44 dp)

---

## Executive Summary

`FeedTab` implements the chronological video feed with vertical swipe navigation, an expandable speed-dial Floating Action Button (FAB) menu for camera and gallery uploads, video interaction actions (like, comments, offline download), and an `_EndFeedScreen` delivering anti-doomscrolling motivational quotes. Significant accessibility issues were identified across tap target sizes of mini-FABs, missing semantic labels on video action buttons, lack of pause/timing controls on the auto-advancing quote timer (WCAG 2.2.1/2.2.2), and focus ordering for floating controls overlaid on scrollable views.

---

## Findings by Severity

### 1. High Severity

#### [HIGH-01] Undersized Tap Targets and Missing Labels on Floating Action Buttons
- **File**: `d:\Feditok\lib\screens\home\feed\feed_tab.dart`
- **Line(s)**: 152–160, 189–198, 204–213
- **WCAG Guideline**: WCAG 2.5.5 / 2.5.8 Target Size (Level AA), WCAG 4.1.2 Name, Role, Value (Level A)
- **Defect**:
  1. `FloatingActionButton.small` default diameter is **40x40 dp**, which fails Android's 48x48 dp and iOS's 44x44 dp minimum hit target requirements unless padded.
  2. The gallery and camera small FABs do not define `tooltip` or `Semantics.label`. Although visual text chips ("Galleria", "Fotocamera") are positioned next to them, they are separate unmerged widgets, leaving the buttons nameless to TalkBack/VoiceOver.
  3. The main FAB (`main_plus_btn`) has no tooltip or announcement regarding whether the speed dial is expanded or collapsed.
- **Code Fix**:
```dart
// 1. Main FAB with dynamic state announcement:
FloatingActionButton(
  heroTag: 'main_plus_btn',
  tooltip: _isFabOpen ? 'Chiudi opzioni creazione' : 'Crea nuovo post',
  backgroundColor: Theme.of(context).colorScheme.primary,
  onPressed: _toggleFab,
  child: AnimatedRotation(
    turns: _isFabOpen ? 0.125 : 0.0,
    duration: const Duration(milliseconds: 250),
    child: const Icon(Icons.add, size: 28, color: Colors.white),
  ),
),

// 2. Secondary FABs with minimum 48x48 hit target and tooltips:
Semantics(
  button: true,
  label: 'Apri galleria per caricare video',
  child: SizedBox(
    width: 48,
    height: 48,
    child: FloatingActionButton.small(
      heroTag: 'gallery_btn',
      tooltip: 'Apri Galleria',
      backgroundColor: Colors.purpleAccent,
      onPressed: _pickFileFromGallery,
      child: const Icon(Icons.photo_library, color: Colors.white),
    ),
  ),
),
```

#### [HIGH-02] Focus Traversal Order for Overlaid Floating Action Buttons
- **File**: `d:\Feditok\lib\screens\home\feed\feed_tab.dart`
- **Line(s)**: 105–217
- **WCAG Guideline**: WCAG 2.4.3 Focus Order (Level A)
- **Defect**: The FAB menu is placed in a `Stack` over the `PageView.builder`. For keyboard and switch users navigating the feed, focus either gets trapped or does not follow a predictable, ordered path outside the scrollable sequence.
- **Code Fix**:
```dart
// Wrap the FAB container in a FocusTraversalGroup with explicit priority:
Positioned(
  right: 20,
  bottom: 30,
  child: FocusTraversalGroup(
    policy: OrderedTraversalPolicy(),
    child: FocusTraversalOrder(
      order: const NumericFocusOrder(1.0),
      child: Column(
        // ... FAB hierarchy
      ),
    ),
  ),
),
```

#### [HIGH-03] Auto-Advancing Content Without Pause or Stop Controls (End Feed Screen)
- **File**: `d:\Feditok\lib\screens\home\feed\feed_tab.dart`
- **Line(s)**: 509–523, 558–570
- **WCAG Guideline**: WCAG 2.2.1 Timing Adjustable (Level A), WCAG 2.2.2 Pause, Stop, Hide (Level A)
- **Defect**: The `_EndFeedScreen` features a 10-second timer (`_progressController`) that automatically rotates quotes from `stubMessages`. There is no mechanism for users with reading disabilities, low vision, or cognitive differences to pause, resume, or extend the timer.
- **Code Fix**:
```dart
// Add a pause/resume toggle button and expose it to assistive technology:
IconButton(
  icon: Icon(_progressController.isAnimating ? Icons.pause_circle_outline : Icons.play_circle_outline),
  tooltip: _progressController.isAnimating ? 'Metti in pausa i consigli' : 'Riprendi i consigli',
  onPressed: () {
    setState(() {
      if (_progressController.isAnimating) {
        _progressController.stop();
      } else {
        _progressController.forward();
      }
    });
  },
),
```

---

### 2. Medium Severity

#### [MED-01] Missing Tooltips and Labels on Video Interaction IconButtons
- **File**: `d:\Feditok\lib\screens\home\feed\feed_tab.dart`
- **Line(s)**: 303–334
- **WCAG Guideline**: WCAG 1.1.1 Non-text Content (Level A), WCAG 4.1.2 Name, Role, Value (Level A)
- **Defect**: The three side-panel icon buttons on each video feed item lack accessible descriptions:
  1. Like button (`Icons.favorite` / `Icons.favorite_border`): no tooltip or selected state indication.
  2. Comments button (`Icons.comment_outlined`): no tooltip.
  3. Offline download button (`Icons.download_for_offline_outlined`): no tooltip.
- **Code Fix**:
```dart
IconButton(
  icon: Icon(
    video.isLikedByMe ? Icons.favorite : Icons.favorite_border,
    color: video.isLikedByMe ? Colors.red : Colors.white,
    size: 32,
  ),
  tooltip: video.isLikedByMe ? 'Rimuovi Mi piace' : 'Metti Mi piace',
  onPressed: () => feedProvider.toggleLike(video.id),
),
const SizedBox(height: 16),
IconButton(
  icon: const Icon(Icons.comment_outlined, color: Colors.white, size: 32),
  tooltip: 'Mostra commenti',
  onPressed: () => _showCommentsModal(context, video.id),
),
const SizedBox(height: 16),
IconButton(
  icon: const Icon(Icons.download_for_offline_outlined, color: Colors.white, size: 32),
  tooltip: 'Salva video in locale',
  onPressed: () { ... },
),
```

#### [MED-02] Missing Tooltip on Comments Modal Send Button
- **File**: `d:\Feditok\lib\screens\home\feed\feed_tab.dart`
- **Line(s)**: 364–368
- **WCAG Guideline**: WCAG 1.1.1 Non-text Content (Level A)
- **Defect**: The send icon button in `_showCommentsModal` has no `tooltip: 'Invia commento'`.
- **Code Fix**:
```dart
IconButton(
  icon: const Icon(Icons.send),
  tooltip: 'Invia commento',
  onPressed: () => Navigator.pop(context),
),
```

#### [MED-03] Missing Live Region on Rotating Motivational Message
- **File**: `d:\Feditok\lib\screens\home\feed\feed_tab.dart`
- **Line(s)**: 574–591
- **WCAG Guideline**: WCAG 4.1.3 Status Messages (Level AA)
- **Defect**: When the quote flips every 10 seconds, screen readers are unaware unless the card is announced or wrapped in a live region.
- **Code Fix**:
```dart
Semantics(
  container: true,
  liveRegion: true,
  child: Card(
    // ...
    child: Text(stubMessages[_currentIndex], ...),
  ),
),
```

---

### 3. Low Severity

#### [LOW-01] Decorative Video Thumbnail Placeholder Icon
- **File**: `d:\Feditok\lib\screens\home\feed\feed_tab.dart`
- **Line(s)**: 240–244
- **WCAG Guideline**: WCAG 1.1.1 Non-text Content (Level A)
- **Defect**: `Icons.play_circle_outline` is purely visual inside the video stub and should be excluded from semantics.
- **Code Fix**:
```dart
const ExcludeSemantics(
  child: Icon(Icons.play_circle_outline, size: 80, color: Colors.white54),
),
```

---

## Automated Accessibility Testing Checklist

```dart
testWidgets('FeedTab meets accessibility guidelines', (WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => FeedProvider())],
      child: const MaterialApp(home: FeedTab()),
    ),
  );

  await expectLater(tester, meetsGuideline(textContrastGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
});
```
