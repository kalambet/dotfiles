# Apple UI/UX Anti-Patterns Catalog

A catalog of common anti-patterns and code smells in Apple platform UI/UX code. Each entry follows a consistent format for quick reference during code reviews. State management and layout anti-patterns are the most prevalent and damaging.

## Table of Contents
1. [State Management Anti-Patterns](#state-management-anti-patterns)
2. [Layout Anti-Patterns](#layout-anti-patterns)
3. [Navigation Anti-Patterns](#navigation-anti-patterns)
4. [Performance Anti-Patterns](#performance-anti-patterns)
5. [Accessibility Anti-Patterns](#accessibility-anti-patterns)
6. [Platform Anti-Patterns](#platform-anti-patterns)

---

## State Management Anti-Patterns

### The God ViewModel
**Severity:** HIGH
**Symptom:** A single `ViewModel` class with 20+ `@Published` properties (or `@Observable` with 20+ stored properties), business logic for multiple unrelated features, and dependencies on 5+ services. Every view in the feature depends on it
**Why it's harmful:** Any property change triggers observation updates across all dependent views. Business logic is untestable because everything is coupled. Modifications risk breaking unrelated features. The object becomes a magnet for more responsibilities
**Fix:** Split by responsibility. Each view gets only the state it needs. Extract business logic into focused service types. Use composition — multiple small `@Observable` types composed by the parent view, each owned by the views that actually need them

### State Prop Drilling
**Severity:** MEDIUM
**Symptom:** A value passed through 4+ levels of view hierarchy via `@Binding` or init parameters, through intermediate views that don't use it at all. Changing the type of the prop requires modifying every view in the chain
**Why it's harmful:** Fragile: every intermediate view must be updated when the prop changes. Noisy: clutters init signatures with passthrough parameters. The intermediate views have false dependencies
**Fix:** Use `@Environment` for values that need to cross multiple levels. For `@Observable` objects, inject via `@Environment` or `@State` at the appropriate ancestor. For simple values, use custom `EnvironmentKey`

### The Published Firehose
**Severity:** HIGH
**Symptom:** `ObservableObject` with many `@Published` properties. Views that only read one property still recompute when any other property changes. Performance degrades as the object grows
**Why it's harmful:** `ObservableObject` fires `objectWillChange` on any `@Published` mutation — it's whole-object observation. A view displaying `user.name` recomputes when `user.avatarURL` changes. This causes cascading redraws across the entire view hierarchy that observes the object
**Fix:** Migrate to `@Observable` (Observation framework), which provides per-property observation. Views only recompute when properties they actually read in their body change. If stuck on `ObservableObject`, split into smaller focused objects

### Observable Object in New Code
**Severity:** MEDIUM
**Symptom:** New SwiftUI code using `ObservableObject` with `@Published`, `@StateObject`, `@ObservedObject`, or `@EnvironmentObject` — the pre-iOS 17 observation pattern
**Why it's harmful:** `ObservableObject` is the old pattern with whole-object observation. `@Observable` (iOS 17+) provides granular per-property tracking, simpler API, and better performance. New code using the old pattern accumulates tech debt
**Fix:** Use `@Observable` macro. Replace `@StateObject` with `@State`. Replace `@ObservedObject` with direct parameter passing. Replace `@EnvironmentObject` with `@Environment`. The migration is straightforward and the benefits are immediate

### State-in-ViewModel-for-View-State
**Severity:** MEDIUM
**Symptom:** View-specific UI state (is the sheet showing? which tab is selected? is the text field focused?) stored in a ViewModel/Observable object instead of `@State` on the view
**Why it's harmful:** UI state like `isShowingSheet` is view-specific — it has no business being in a shared model. It clutters the model with presentation concerns, makes the model harder to test, and creates false dependencies between the model and the view's presentation logic
**Fix:** `@State` for view-specific presentation state. The view owns its own UI state. The model owns business data. A clear boundary: if it would be meaningless in a unit test, it's view state

### The Environment Dumping Ground
**Severity:** MEDIUM
**Symptom:** Dozens of custom environment values injected at the root view. Every conceivable dependency — API clients, formatters, feature flags, theme settings — shoved into environment. Views pull from environment liberally without documentation
**Why it's harmful:** Implicit dependencies are invisible. Missing environment injections cause runtime crashes that only surface in specific navigation paths (not caught at compile time). Testing requires providing the entire environment. New developers can't see what a view depends on
**Fix:** Use environment for genuinely cross-cutting concerns (color scheme, locale, accessibility settings, shared data model). Use explicit init parameters for direct dependencies. Document required environment values with comments at injection and consumption sites

## Layout Anti-Patterns

### GeometryReader First Resort
**Severity:** MEDIUM
**Symptom:** `GeometryReader` used for basic layout tasks: making a view fill available width, centering content, or creating a responsive grid. The geometry values are used in simple ways that built-in modifiers handle
**Why it's harmful:** `GeometryReader` reads layout after the layout pass, which can cause double-layout or layout loops. It reports a size of the proposed space, not the view's actual size. It disrupts the natural flow of SwiftUI layout. It's a common source of mysterious spacing bugs
**Fix:** `.frame(maxWidth: .infinity)` for filling width. `ViewThatFits` for responsive layout. `Grid` for grid layouts. `LazyVGrid` with `.adaptive(minimum:)` for responsive grids. Reserve `GeometryReader` for truly dynamic layout that depends on actual container size (parallax, scroll-linked effects)

### Hardcoded Dimensions Everywhere
**Severity:** HIGH
**Symptom:** Views peppered with `.frame(width: 320, height: 44)`, `.padding(17)`, `.offset(x: -3, y: 2)`. Magic numbers that correspond to the developer's device screen size
**Why it's harmful:** Breaks on every other screen size. Breaks with Dynamic Type. Breaks in landscape. Breaks on iPad. Breaks when the user changes accessibility settings. The developer tested on one device and it looked fine
**Fix:** Use flexible layout: `.frame(maxWidth: .infinity)`, `.padding()` (system default), relative sizing. Use `@ScaledMetric` for values that should scale with Dynamic Type. Named constants for genuinely fixed values (minimum touch target, icon sizes). Test on iPhone SE and iPad

### The Spacer Avalanche
**Severity:** LOW
**Symptom:** Complex arrangements of `Spacer()`, `Spacer(minLength:)`, and `.frame(height:)` to achieve layouts that should use proper alignment, padding, or container views
**Why it's harmful:** Fragile — spacers compete for available space and produce different results at different sizes. Hard to understand the intended layout from the code. Minor changes cascade unpredictably
**Fix:** Use alignment parameters on stacks (`.leading`, `.trailing`, `.center`). Use `.padding()` for consistent spacing. Use `Grid` for aligned rows/columns. Spacers are appropriate for pushing content to one side, not for pixel-perfect positioning

### Frame of Lies
**Severity:** HIGH
**Symptom:** `.frame(width: UIScreen.main.bounds.width)` or similar use of screen dimensions to size views. Often combined with horizontal offsets to position elements
**Why it's harmful:** Doesn't account for safe areas, split view on iPad, slide-over, Stage Manager, or any context where the view is not full-screen. Hardcodes to one screen size on devices with different screens. Will break on future devices
**Fix:** Use `.frame(maxWidth: .infinity)` for full-width. Use `GeometryReader` only if you genuinely need the containing view's size (not the screen's). Never reference `UIScreen.main.bounds` in SwiftUI layout code

### ZStack Layer Cake
**Severity:** MEDIUM
**Symptom:** Deep `ZStack` nesting (4+ layers) to achieve overlay effects, badges, or complex visual compositions. Layers contain interactive elements without proper hit-testing
**Why it's harmful:** Z-ordered hit testing is unintuitive — the top layer receives all taps by default, blocking interaction with lower layers. Accessibility ordering doesn't match visual ordering. Complex Z-stacks are hard to maintain and debug
**Fix:** Use `.overlay()` and `.background()` modifiers for simple layering. Use `accessibilityElement(children:)` to define correct accessibility ordering. Ensure interactive elements in lower layers are reachable. Consider if the design can be simplified

### Ignoring Safe Areas
**Severity:** HIGH
**Symptom:** Content rendered under the notch, Dynamic Island, home indicator, or status bar. Interactive elements placed where system gestures take priority (bottom edge, top corners)
**Why it's harmful:** Unusable UI — buttons under the notch can't be tapped. Content behind the home indicator is obscured. System gestures (swipe from bottom, swipe from top) intercept touches near screen edges. App Store reviewers will flag this
**Fix:** Respect safe areas by default. Only ignore safe areas for decorative backgrounds and images. Interactive content must always be within safe areas. Test on devices with notch, Dynamic Island, and home indicator (not just simulator)

## Navigation Anti-Patterns

### The Sheet Stack
**Severity:** HIGH
**Symptom:** Sheets presented from within sheets, 3+ levels deep. Navigation within sheets using more sheets instead of `NavigationStack`. Dismiss buttons that only dismiss one level, leaving the user trapped in sheet layers
**Why it's harmful:** Users lose spatial context. The dismiss gesture (swipe down) only dismisses the top sheet. No way to "go back to the beginning." Accessibility navigation is confusing. The mental model breaks when stacking modals
**Fix:** Sheets should be 1 level deep maximum. If you need navigation within a sheet, embed a `NavigationStack` inside the sheet. If you need multi-step flows, use navigation push, not sheet stacking. Provide a clear path back to the starting point

### Coordinator Ceremony
**Severity:** MEDIUM
**Symptom:** A full Coordinator pattern ported from UIKit: `Coordinator` objects, delegate protocols, routing tables — all to manage navigation that SwiftUI handles declaratively. 200+ lines of coordination code wrapping simple `NavigationStack` path management
**Why it's harmful:** Fighting the framework. SwiftUI's navigation is declarative and state-driven. Imperative coordinator patterns create two sources of truth (the coordinator's state and SwiftUI's state) that can desynchronize. More code, more bugs, harder to maintain
**Fix:** Use `NavigationStack` with a path binding for programmatic navigation. Use `navigationDestination(for:)` for type-safe routing. Use `@Observable` router objects if you need shared navigation state. The framework handles the rest

### NavigationLink with isActive Spaghetti
**Severity:** MEDIUM
**Symptom:** Multiple `NavigationLink(isActive:)` or `NavigationLink(tag:selection:)` bindings managing navigation state manually. Boolean flags and enums tracking which destination is active
**Why it's harmful:** These APIs are deprecated. They create fragile state management where multiple links can fight over activation. Race conditions when multiple state changes happen simultaneously. Difficult to support deep linking
**Fix:** `NavigationStack` with path-based navigation. Push typed values onto the path. Use `navigationDestination(for:)` to map types to destination views. Single source of truth for the entire navigation state

### The Homeless Tab Bar
**Severity:** HIGH
**Symptom:** Tab bar hidden on most screens. Custom tab bar implementation that doesn't respect system conventions. Tab bar items that change based on context. Tab bar disappearing and reappearing unpredictably
**Why it's harmful:** Users expect the tab bar to be persistent — it's their primary navigation landmark. Hiding it disorients. Custom tab bars don't support VoiceOver tab switching, don't match system appearance, and don't handle safe areas correctly. Tab bars that change violate the HIG principle that tabs represent fixed categories
**Fix:** Use the system `TabView`. Keep it visible on all primary screens. Hide only for immersive content (media playback, games). Tab items are fixed — don't add or remove them based on state. Use badge counts for dynamic information, not tab bar restructuring

## Performance Anti-Patterns

### Body of Work
**Severity:** CRITICAL
**Symptom:** Network calls, file I/O, heavy computation, database queries, or image processing executed directly in a view's `body` property or triggered synchronously from within `body`
**Why it's harmful:** `body` runs on the main actor. Any blocking work freezes the UI. `body` is called frequently — every state change, every animation frame. Network calls in body fire on every recomputation, potentially hundreds of times
**Fix:** Use `.task { }` for async work. Pre-compute derived values. Move computation to model/service types. Never perform side effects in `body`. The body should only read state and return views — nothing else

### The Recomputation Cascade
**Severity:** HIGH
**Symptom:** A `@State` change in a parent triggers `body` recomputation of the parent, which passes new (but semantically identical) values to children, triggering their `body` recomputation, cascading through the entire hierarchy
**Why it's harmful:** O(n) recomputations for a single state change. On complex hierarchies (100+ views), this causes visible frame drops. The app feels sluggish on older devices even though "nothing changed"
**Fix:** Extract child views into separate structs — SwiftUI can skip their body if their inputs haven't changed. Pass only the specific properties needed, not whole objects. Use `@Observable` instead of `ObservableObject` for granular tracking. For expensive views, use `EquatableView` or custom `Equatable` conformance

### Image Loading in Body
**Severity:** HIGH
**Symptom:** `UIImage(named:)` or `UIImage(contentsOfFile:)` called inside view body for large images. Bundle images loaded at full resolution for display in small thumbnails
**Why it's harmful:** Image decoding is expensive — a 12MP photo takes ~50ms to decode. In body, this blocks the main thread. In a scrolling list, this causes visible hitches. Large images consume proportional memory even when displayed small
**Fix:** Use `AsyncImage` for remote images. For local images, use `Image("name")` (SwiftUI manages caching). For large local images, use `preparingThumbnail(of:)` to downsample. In lists, preload and cache thumbnails at display resolution

### ForEach Without Stable ID
**Severity:** HIGH
**Symptom:** `ForEach(0..<items.count, id: \.self)` or `ForEach(items, id: \.someNonUniqueProperty)`. Using array indices or non-unique properties as identity
**Why it's harmful:** When the array changes (insertion, deletion, reorder), SwiftUI uses IDs to determine which views to create, update, or remove. With index-based IDs, every item after the change point gets a new identity — SwiftUI destroys and recreates those views, losing their `@State` and causing unnecessary work. Non-unique IDs cause undefined behavior
**Fix:** Use `Identifiable` conformance with stable, unique IDs. UUIDs or database primary keys are ideal. If the model doesn't have a natural unique identifier, add one. Never use array indices as view identity

### The Eager Grid
**Severity:** HIGH
**Symptom:** `VStack { ForEach(items) { ... } }` inside a `ScrollView` for a grid of 100+ items. All items materialized immediately, even those far off-screen
**Why it's harmful:** Memory usage proportional to total item count, not visible count. Initial load time increases linearly with item count. On memory-constrained devices (older iPhones, Apple Watch), this can trigger memory warnings or jettisoning
**Fix:** `LazyVGrid` or `LazyHGrid` for grids. `List` or `LazyVStack` for vertical lists. These create views on demand as they scroll into the visible region. Only use eager containers for small, known-size collections (<20-30 items)

### Timer-Driven UI Updates
**Severity:** MEDIUM
**Symptom:** `Timer.publish(every: 1.0)` triggering state changes to update relative timestamps ("3 minutes ago"), live clocks, or countdown timers. The timer fires even when the view is off-screen or the app is backgrounded
**Why it's harmful:** Every timer fire triggers a state change, which triggers `body` recomputation, which can cascade to child views. If multiple views have their own timers, the recomputation rate multiplies. Timers running in the background waste battery
**Fix:** Use `TimelineView(.periodic(from:by:))` for time-driven updates — it's optimized for this purpose and pauses when not visible. For relative timestamps, `Text(date, style: .relative)` updates automatically with no timer. Cancel timers when the view disappears

## Accessibility Anti-Patterns

### The Decorative Lie
**Severity:** CRITICAL
**Symptom:** `.accessibilityHidden(true)` applied to interactive elements (buttons, links, form fields) to "simplify" the VoiceOver experience. Elements the developer considers "obvious" hidden from assistive technology
**Why it's harmful:** VoiceOver users cannot interact with hidden elements at all. The app is functionally broken for blind users. This violates accessibility guidelines and can be grounds for legal action. App Store reviewers may flag it
**Fix:** Never hide interactive elements from accessibility. If VoiceOver is "too verbose," use `.accessibilityElement(children: .combine)` to group elements, or improve labels to be more concise. The goal is making accessibility better, not removing it

### VoiceOver Afterthought
**Severity:** HIGH
**Symptom:** No `.accessibilityLabel()` on icon-only buttons. Images without `accessibilityLabel` or not marked as decorative. Custom controls with no accessibility traits. Views that only make sense visually (color-coded status without text alternative)
**Why it's harmful:** VoiceOver reads "button" with no label — the user has no idea what the button does. Unlabeled images are announced as their file name ("img_2847_final_v2.png"). Custom controls without traits don't tell VoiceOver they're interactive
**Fix:** Every interactive element needs a descriptive `.accessibilityLabel()`. Decorative images get `.accessibilityHidden(true)`. Informational images get descriptive labels. Custom controls get `.accessibilityAddTraits(.isButton)` or appropriate traits. Test with VoiceOver — not just in the accessibility inspector

### The Inaccessible Custom Control
**Severity:** HIGH
**Symptom:** Custom-drawn controls (sliders, toggles, segmented controls, steppers) with no accessibility implementation. Built with raw gestures on shapes/paths. No labels, no values, no traits, no actions
**Why it's harmful:** Completely invisible to VoiceOver and other assistive technologies. Users who rely on Switch Control, Voice Control, or external keyboards cannot interact with the control. It's the equivalent of displaying a bitmap and expecting the user to click pixels
**Fix:** Implement full accessibility: `.accessibilityLabel()`, `.accessibilityValue()`, `.accessibilityAddTraits()`, `.accessibilityAdjustableAction()` for sliders/steppers. Better yet — use the system control. Custom controls need extraordinary justification when system controls exist

### Dynamic Type Denial
**Severity:** CRITICAL
**Symptom:** `.font(.system(size: 14))` throughout the codebase. No semantic text styles. Fixed-height containers that clip text at large sizes. Layouts that overflow at accessibility text sizes
**Why it's harmful:** Users who need larger text (low vision, aging, preference) get tiny fixed-size text. This is an accessibility violation. In many jurisdictions, it's also a legal liability. Apple's App Store review may flag it for accessibility requirements
**Fix:** Use semantic text styles: `.font(.body)`, `.font(.headline)`, etc. For custom fonts, use `UIFontMetrics` scaling or `@ScaledMetric`. Test at AX XXXL size — if text clips or overlaps, the layout needs fixing. Use `ViewThatFits` to adapt layouts at extreme sizes

### Color-Only Meaning
**Severity:** HIGH
**Symptom:** Status indicated only by color (green = good, red = bad). Form validation errors shown only by turning the field border red. Interactive elements distinguished from static text only by color
**Why it's harmful:** ~8% of men and ~0.5% of women have color vision deficiency. Color-only indicators are invisible to them. Even for color-sighted users, meaning should be redundant — icons, labels, shapes should reinforce color coding
**Fix:** Always pair color with at least one other indicator: icon (checkmark/X), text label ("Error: ..."), shape (error triangle), position, or pattern. Test in grayscale — if meaning is lost, add a non-color indicator

## Platform Anti-Patterns

### Reinventing the Native Element
**Severity:** HIGH (CRITICAL if the custom control drops accessibility)
**Symptom:** A custom-built control or container where a native one exists and would fit — a `.window`-style panel hand-styled to look like a menu instead of `MenuBarExtra(.menu)` / `Menu`; a `VStack` of tap gestures instead of `List`; a bespoke overlay instead of `.sheet` / `.alert`; a drawn switch instead of `Toggle`. The native path wasn't tried, or was abandoned at the first modifier, and no one signed off on the deviation
**Why it's harmful:** Every native element ships the system's metrics, highlight, focus ring, keyboard navigation, VoiceOver, Dynamic Type, and Dark Mode — and keeps them correct across OS updates. A custom replacement starts at zero on all of it and re-grows the bugs the system already solved (wrong padding, no keyboard navigation, broken VoiceOver), then carries that as permanent maintenance. Most custom controls are also subtly off-convention, which users feel even if they can't name it
**Fix:** Default to the native element; reach for custom only when a native one genuinely can't express the requirement. When it can't, the deviation must be an explicit, operator-approved decision, clearly stated in the code or PR as a custom control that departs from the native path — and the custom implementation must fully restore the accessibility and keyboard behavior it gave up. Flag any silent custom reimplementation of a native element as a finding

### iOS-on-Mac
**Severity:** HIGH
**Symptom:** A Mac Catalyst or macOS native app that looks and behaves exactly like an iPhone app: full-screen single-column layout, no keyboard shortcuts, no menu bar items, no multiple windows, giant touch-sized buttons with a mouse cursor
**Why it's harmful:** Mac users expect Mac patterns: sidebars, toolbars, menu bar, keyboard shortcuts, multiple windows, right-click context menus, compact density. An iPhone app stretched to Mac size feels wrong and wastes screen space. It signals laziness to users and reviewers
**Fix:** Adapt to the platform. Add `NavigationSplitView` for sidebar on Mac. Add `.keyboardShortcut()` to common actions. Add `Commands` for menu bar. Support multiple windows with `WindowGroup` or `Window`. Reduce padding and touch target sizes for pointer interaction. Use `#if os(macOS)` for platform-specific adjustments

### The One-Size App
**Severity:** MEDIUM
**Symptom:** Same layout, same density, same navigation pattern regardless of device: iPhone SE through 12.9" iPad Pro through 27" iMac. No use of size classes, `ViewThatFits`, or `NavigationSplitView`. Horizontal size class never checked
**Why it's harmful:** Wastes screen real estate on large devices. Cramps content on small devices. iPad users get a phone app. Mac users get a phone app on a 27" screen. This is the most common reason for low App Store ratings on iPad
**Fix:** Check horizontal size class for layout adaptation. Use `NavigationSplitView` on iPad/Mac. Use `ViewThatFits` for responsive layouts. Use `Grid` with adaptive columns. Design breakpoints: compact (iPhone), regular (iPad portrait/Mac), large (iPad landscape/Mac widescreen)

### Desktop Patterns on Mobile
**Severity:** MEDIUM
**Symptom:** Hover effects as primary interaction feedback (no mobile equivalent). Tooltips for essential information. Drag-and-drop as the only way to reorder. Right-click context menus without a long-press equivalent. Tiny click targets designed for mouse precision
**Why it's harmful:** iPhone has no hover, no right-click, no precise pointer. Essential information hidden in tooltips is inaccessible. Drag-only reorder without edit mode is undiscoverable. Tiny targets are unusable on touch screens
**Fix:** Design touch-first, enhance for pointer. Long press for context menus (`.contextMenu`). Edit mode with drag handles for reordering. Touch targets 44×44pt minimum. Essential information visible by default, not on hover. Test every interaction on a physical iPhone

### Missing Keyboard Shortcuts
**Severity:** HIGH (macOS/iPadOS with keyboard)
**Symptom:** A macOS app or iPadOS app with keyboard support that has no keyboard shortcuts for common actions. No Cmd+N, Cmd+S, Cmd+Z. No arrow key navigation. The menu bar has no items
**Why it's harmful:** Mac users expect keyboard-driven workflows. iPad users with keyboards expect at least basic shortcuts. Missing shortcuts slow down power users and make the app feel unfinished. App Store reviewers check for basic keyboard support on Mac
**Fix:** Add `.keyboardShortcut()` to common actions: new (Cmd+N), save (Cmd+S), delete (Cmd+Delete), find (Cmd+F), preferences (Cmd+,). Add `Commands` for menu bar items. Support arrow key navigation in lists. Test with a keyboard — can you use the app without touching the screen?

### Touch-Only on iPad
**Severity:** MEDIUM
**Symptom:** iPad app that doesn't support pointer (trackpad/mouse). No hover effects on interactive elements. No pointer-specific interactions. Drag and drop not implemented for items that could be dragged
**Why it's harmful:** iPad with Magic Keyboard and trackpad is a primary use case. Pointer support enables hover feedback, precision interaction, and drag-and-drop between apps. Missing pointer support makes the app feel less capable than system apps
**Fix:** Add `.hoverEffect()` to interactive elements. Implement drag and drop for content items (`.draggable()`, `.dropDestination()`). Support pointer-based text selection. Test with a trackpad connected — does the app feel natural to use with a pointer?
