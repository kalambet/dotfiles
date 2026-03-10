# HIG Compliance Checklist

Systematic checklist for reviewing compliance with Apple Human Interface Guidelines. Every checkbox is a review item with an implicit severity. Items marked [CRITICAL] or [HIGH] are called out explicitly — all others are MEDIUM unless the context elevates them.

## Table of Contents
1. [Typography](#typography)
2. [Color](#color)
3. [Touch Targets and Hit Areas](#touch-targets-and-hit-areas)
4. [Accessibility](#accessibility)
5. [Navigation Patterns](#navigation-patterns)
6. [Platform Conventions](#platform-conventions)
7. [Iconography](#iconography)
8. [Liquid Glass](#liquid-glass)

---

## Typography

### Text styles
- [ ] All user-facing text uses semantic text styles (`.headline`, `.body`, `.caption`, `.title`, `.footnote`, etc.) — not hardcoded sizes [CRITICAL if missing]
- [ ] Custom fonts registered via `UIFontMetrics` or `@ScaledMetric` for Dynamic Type scaling
- [ ] No more than two font families in the app (system + one custom, or two custom maximum)
- [ ] Font weight used for emphasis hierarchy — not font size alone. Bold for important, regular for body, light avoided (poor readability)
- [ ] Minimum body text size: 17pt equivalent (SF Pro default). Text below 11pt is unreadable for many users

### Dynamic Type
- [ ] All text scales from Extra Small to Accessibility Extra Extra Extra Large (full range) [CRITICAL]
- [ ] Layout adapts at large sizes: horizontal arrangements reflow to vertical, truncation has expand affordance
- [ ] No text truncation at default size — only at accessibility sizes, and only with an affordance to see full text
- [ ] Images and icons adjacent to text scale proportionally (use `@ScaledMetric` for icon dimensions)
- [ ] Fixed-height containers don't clip text at large Dynamic Type sizes [HIGH]

### Line length and readability
- [ ] Body text line length between 50-75 characters on the primary device. Longer lines hurt readability
- [ ] Sufficient line spacing — system defaults are usually correct. Custom `lineSpacing()` only when justified
- [ ] Text alignment: left-aligned for body text (right-aligned for RTL). Center alignment only for short labels, titles, or empty states
- [ ] Long-form text in a `ScrollView` — never clipped without scroll affordance

## Color

### Semantic colors
- [ ] Uses system semantic colors (`Color.primary`, `.secondary`, `.accentColor`, system backgrounds) for automatic Dark Mode support
- [ ] Custom colors defined in Asset Catalog with Light and Dark variants [HIGH if missing Dark variant]
- [ ] No hardcoded `Color.white` or `Color.black` in UI — these don't adapt to Dark Mode. Use `Color(.systemBackground)` and `Color.primary` [HIGH]
- [ ] `Color(.label)` or `Color.primary` for text — not `Color.black`

### Dark Mode
- [ ] App fully functional and visually correct in Dark Mode [HIGH]
- [ ] Custom images and illustrations have Dark Mode variants (or adapt via template rendering)
- [ ] Shadows, borders, and separators visible in both modes — shadows invisible on dark backgrounds, light borders invisible on light backgrounds
- [ ] No white flash during launch in Dark Mode (launch screen configured for both modes)

### Contrast and visibility
- [ ] Body text contrast ratio 4.5:1 minimum against background [CRITICAL — WCAG AA requirement]
- [ ] Large text (18pt+ or 14pt+ bold) contrast ratio 3:1 minimum
- [ ] Interactive element contrast 3:1 minimum against adjacent colors
- [ ] Support for Increase Contrast accessibility setting — check with `@Environment(\.colorSchemeContrast)`
- [ ] Color never used as the only indicator of meaning (status, errors, required fields) [HIGH]. Always pair with icon, text, or shape

### Accent color
- [ ] Single accent/tint color for the app — consistency across all interactive elements
- [ ] Accent color has sufficient contrast in both Light and Dark modes
- [ ] Accent color doesn't conflict with system red (destructive actions) or system green (success)

## Touch Targets and Hit Areas

### Size requirements
- [ ] All interactive elements have a minimum touch target of 44×44 points [CRITICAL — App Store rejection risk]
- [ ] Buttons with small visual content (icon buttons, close buttons) use `.frame(minWidth: 44, minHeight: 44)` or `.contentShape(Rectangle())` to expand the hit area without expanding the visual
- [ ] Text buttons have sufficient padding to reach 44pt hit area — a naked `Text("Done")` at 17pt is only ~20pt tall

### Placement
- [ ] No interactive elements within 8pt of screen edges — system gestures (swipe from edge) take priority
- [ ] No overlapping touch targets — adjacent buttons have sufficient spacing (minimum 8pt) to avoid accidental taps
- [ ] Destructive actions not placed adjacent to common actions without confirmation (e.g., Delete button next to Save button)
- [ ] Primary action is the most visually prominent and easily reachable (thumb zone on iPhone: bottom center)

### Gesture conflicts
- [ ] Custom gestures don't conflict with system gestures (swipe-back from left edge, swipe-down to dismiss sheet, pull to refresh)
- [ ] Long-press gestures don't block context menus if context menus are also present
- [ ] Scroll views inside scroll views (nested scrolling) have clear directional separation (horizontal inside vertical)

## Accessibility

### VoiceOver
- [ ] Every interactive element has a descriptive `.accessibilityLabel()` [CRITICAL]
- [ ] Icon-only buttons have `.accessibilityLabel("descriptive action name")` [CRITICAL]
- [ ] Decorative images marked `.accessibilityHidden(true)` — content images have descriptive labels
- [ ] Custom controls have appropriate `.accessibilityAddTraits()` (`.isButton`, `.isLink`, `.isHeader`, `.isSelected`)
- [ ] Adjustable controls (sliders, steppers) implement `.accessibilityAdjustableAction()` [HIGH]
- [ ] Element reading order is logical (top-to-bottom, left-to-right for LTR languages). Use `.accessibilityElement(children: .contain)` to override if needed
- [ ] Related elements grouped with `.accessibilityElement(children: .combine)` to reduce verbosity (e.g., label + value combined into one element)
- [ ] Dynamic content changes announced with `AccessibilityNotification.Announcement` when appropriate (error messages, content updates not caused by user action)
- [ ] `.accessibilityHint()` provided for non-obvious interactions (swipe actions, long press, custom gestures)

### Dynamic Type (accessibility sizes)
- [ ] All text scales to Accessibility sizes (AX1 through AX5 / XXXL) without clipping, overlapping, or becoming inaccessible [CRITICAL]
- [ ] Layouts adapt: horizontal arrangements switch to vertical at large sizes. Use `@Environment(\.dynamicTypeSize)` or `ViewThatFits`
- [ ] Scroll views accommodate expanded content — fixed-height containers don't clip
- [ ] Interactive elements remain tappable at all type sizes (labels don't push buttons off screen)

### Motion and visual effects
- [ ] Animations respect `@Environment(\.accessibilityReduceMotion)` — substitute instant transitions or cross-fades [HIGH]
- [ ] Transparency effects respect `@Environment(\.accessibilityReduceTransparency)`
- [ ] Bold text preference respected where applicable — system fonts handle this automatically, custom fonts may not
- [ ] No auto-playing video or animation without user control (play/pause affordance)

### Other assistive technologies
- [ ] Switch Control: all interactive elements reachable via scanning (no custom gesture-only interactions)
- [ ] Voice Control: all buttons have visible or accessibility labels that Voice Control can target
- [ ] Full Keyboard Access: all interactive elements reachable via Tab key (focus management with `.focusable()`)
- [ ] Smart Invert: custom images and media marked `.accessibilityIgnoresInvertColors(true)` to prevent double-inversion

## Navigation Patterns

### Platform-correct navigation
- [ ] iOS: Tab bar for 3-5 primary sections. Navigation stack for hierarchical content. Sheets for focused tasks [HIGH if wrong pattern]
- [ ] iPadOS: Sidebar for primary navigation (regular width). Tab bar acceptable for compact. Popovers instead of full-screen sheets
- [ ] macOS: Sidebar, toolbar, menu bar. No tab bars (use sidebar sections). Settings via `Settings` scene, not a navigation destination
- [ ] watchOS: Vertical scroll for primary content. NavigationStack for hierarchy. Minimal interaction depth (2-3 levels max)
- [ ] visionOS: Spatial layout with ornaments. Tab bar at side. Volumes and immersive spaces for 3D content

### Back navigation
- [ ] System back button/swipe-back gesture works throughout the app [HIGH]
- [ ] Custom back buttons include `.accessibilityLabel("Back")` and preserve swipe-back gesture
- [ ] No dead ends — every screen has a path back to the root navigation

### State and deep linking
- [ ] Tab selection preserved when switching tabs (each tab has independent navigation state)
- [ ] Navigation state restorable after app termination (using `@SceneStorage` or custom persistence)
- [ ] Universal Links / deep links navigate to the correct content within the app

## Platform Conventions

### iOS conventions
- [ ] Large title in top-level views (`navigationBarTitleDisplayMode(.large)`)
- [ ] Pull-to-refresh for updatable content (`.refreshable()`)
- [ ] Swipe actions on list rows for quick actions (`.swipeActions()`)
- [ ] Haptic feedback for significant interactions (`UIImpactFeedbackGenerator`)
- [ ] System share sheet for sharing content (`ShareLink`)

### macOS conventions
- [ ] Menu bar items for all primary actions (`Commands`)
- [ ] Keyboard shortcuts for common actions (`.keyboardShortcut()`) [HIGH]
- [ ] Toolbar for frequently used actions
- [ ] Multiple window support or documented single-window rationale
- [ ] Settings accessible via Cmd+, (`.Settings` scene)
- [ ] Right-click context menus (`.contextMenu()`)

### iPadOS conventions
- [ ] Pointer/trackpad support with hover effects (`.hoverEffect()`)
- [ ] Drag and drop for applicable content (`.draggable()`, `.dropDestination()`)
- [ ] Keyboard shortcuts discoverable via Cmd key hold
- [ ] Multitasking support: Slide Over, Split View (or documented opt-out reason)
- [ ] Stage Manager window sizing handled gracefully

### watchOS conventions
- [ ] Glanceable information — primary data visible without scrolling
- [ ] Minimal interaction depth (2-3 taps to any content)
- [ ] Digital Crown integration where appropriate
- [ ] Complications for at-a-glance data

## Iconography

### SF Symbols
- [ ] SF Symbols used instead of custom icons wherever a suitable symbol exists (~5000+ symbols available) [HIGH if custom icon duplicates SF Symbol]
- [ ] Correct rendering mode for context: `.monochrome` for action buttons, `.hierarchical` for informational, `.palette` or `.multicolor` for decorative
- [ ] Symbol variants used appropriately: `.fill` for selected states, `.circle` for emphasis, `.slash` for disabled/off
- [ ] Symbols scale with Dynamic Type when adjacent to text (use `imageScale` or let system handle)

### App icon
- [ ] Single 1024×1024 source provided (no text in icon — illegible at small sizes)
- [ ] App icon is simple, recognizable, and unique. Avoids generic shapes (globe, gear)
- [ ] No photographs or screenshots in the app icon
- [ ] Dark and tinted variants provided for iOS 18+ (dark mode and tinted home screen) [MEDIUM]

## Liquid Glass

### Adoption (iOS 26+)
- [ ] System navigation bars, tab bars, and toolbars automatically adopt Liquid Glass — verify they display correctly
- [ ] Custom navigation bars or tab bars replaced with system equivalents for automatic Glass adoption [HIGH if custom bars override system appearance]
- [ ] Floating elements and sheets use appropriate material (`.ultraThinMaterial`, `.regularMaterial`, `.thickMaterial`)

### Readability
- [ ] Text over glass surfaces remains legible — use vibrancy labels (`Color.primary` already adapts)
- [ ] Test with multiple wallpapers/backgrounds — glass effect varies with underlying content
- [ ] Interactive elements on glass surfaces maintain sufficient contrast
- [ ] Reduced Transparency accessibility setting respected — glass falls back to opaque when enabled
