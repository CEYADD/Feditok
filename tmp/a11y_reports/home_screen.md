# Accessibility (a11y) & WCAG Audit: HomeScreen

**Target Scope**: `lib/screens/home/home_screen.dart` (`HomeScreen`)  
**File Path**: `d:\Feditok\lib\screens\home\home_screen.dart`  
**WCAG Standard**: WCAG 2.1 / 2.2 Level AA  
**Platform Guidelines**: Android (48x48 dp), iOS (44x44 dp)

---

## Executive Summary

`HomeScreen` serves as the primary navigation shell of the application, managing a `PageView` across three core sections (`FeedTab`, `FriendsTab`, and `ProfileTab`) via a fixed `BottomNavigationBar`. The audit discovered a **critical color contrast violation** on the selected item labels and icons in the navigation bar, along with focus traversal considerations for hardware keyboard users.

---

## Findings by Severity

### 1. High Severity

#### [HIGH-01] Insufficient Color Contrast on Selected BottomNavigationBar Items
- **File**: `d:\Feditok\lib\screens\home\home_screen.dart`
- **Line(s)**: 51–58
- **WCAG Guideline**: WCAG 1.4.3 Contrast (Minimum) (Level AA), WCAG 1.4.11 Non-text Contrast (Level AA)
- **Defect**: The `BottomNavigationBar` has `backgroundColor: Color(0xFF1E1E1E)` and `selectedItemColor: Theme.of(context).colorScheme.primary` (`#6C5CE7`).
  - Relative luminance of `#6C5CE7`: `0.165`
  - Relative luminance of `#1E1E1E`: `0.012`
  - Calculated Contrast Ratio: `(0.165 + 0.05) / (0.012 + 0.05) = 0.215 / 0.062 =` **3.47:1**
  For normal text (< 18pt or < 14pt bold, such as navigation bar 12sp labels), WCAG 1.4.3 requires a minimum contrast of **4.5:1**. The active tab label and icon blend into the dark grey bar, impairing readability for low-vision users and under bright ambient lighting.
- **Code Fix**:
```dart
// Option A: Use the app's secondary accent (#00CEC9, luminance ~0.50, contrast 8.8:1)
// Option B: Lighten the selected primary purple to #A29BFE (luminance ~0.38, contrast 6.9:1)

bottomNavigationBar: BottomNavigationBar(
  currentIndex: _currentIndex,
  onTap: _onBottomNavTapped,
  backgroundColor: const Color(0xFF1E1E1E),
  selectedItemColor: const Color(0xFFA29BFE), // Lightened purple passes 4.5:1 with 6.9:1 ratio
  unselectedItemColor: Colors.grey[400],      // 10.0:1 contrast ratio against #1E1E1E
  showUnselectedLabels: true,
  type: BottomNavigationBarType.fixed,
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.style_outlined),
      activeIcon: Icon(Icons.style),
      label: 'Feed',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.people_outline),
      activeIcon: Icon(Icons.people),
      label: 'Amici',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Tu',
    ),
  ],
),
```

---

### 2. Medium Severity

#### [MED-01] Focus Order & Keyboard Navigation Across Navigation Bar and Tabs
- **File**: `d:\Feditok\lib\screens\home\home_screen.dart`
- **Line(s)**: 45–58
- **WCAG Guideline**: WCAG 2.4.3 Focus Order (Level A)
- **Defect**: When users navigate with hardware keyboards (e.g. Chromebooks, desktop, switch devices), the focus order between the `PageView` items and the bottom navigation bar can become ambiguous without explicit traversal grouping.
- **Code Fix**:
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _tabs,
      ),
    ),
    bottomNavigationBar: FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: BottomNavigationBar(
        // ...
      ),
    ),
  );
}
```

---

### 3. Low Severity

#### [LOW-01] Unused BottomNavigationBarThemeData Stub
- **File**: `d:\Feditok\lib\screens\home\home_screen.dart`
- **Line(s)**: 81–83
- **WCAG Guideline**: Code Quality / Maintainability
- **Defect**: An empty class declaration `class BottomNavigationBarThemeData` exists at the bottom of the file, which shadows Flutter's framework class `BottomNavigationBarThemeData` and can cause configuration confusion.
- **Code Fix**: Remove the dead class declaration from lines 81–83.

---

## Automated Accessibility Testing Checklist

```dart
testWidgets('HomeScreen meets accessibility guidelines', (WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => FriendsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );

  await expectLater(tester, meetsGuideline(textContrastGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
});
```
