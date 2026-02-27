# Apple Human Interface Guidelines Reference

Distilled design guidance from Apple's HIG. Use this when making any UI/UX decision for Apple platforms.

## Table of Contents
1. [Core Design Principles](#core-design-principles)
2. [Typography](#typography)
3. [Color](#color)
4. [Layout and Spacing](#layout-and-spacing)
5. [Iconography and SF Symbols](#iconography-and-sf-symbols)
6. [Navigation Patterns](#navigation-patterns)
7. [Input and Interaction](#input-and-interaction)
8. [Accessibility Requirements](#accessibility-requirements)
9. [Platform-Specific Guidance](#platform-specific-guidance)
10. [Liquid Glass (iOS 26+)](#liquid-glass-ios-26)

---

## Core Design Principles

Apple's HIG is built on three pillars:

**Clarity.** Text is legible at every size. Icons are precise and understandable. Adornments are subtle and appropriate. Focus on functionality drives the design. Negative space, color, fonts, graphics, and interface elements highlight important content and convey interactivity.

**Deference.** Fluid motion and crisp interfaces help people understand and interact with content while never competing with it. Content typically fills the entire screen. Translucency and blurring hint at content beyond. Bezels, gradients, and drop shadows are minimal — the interface is light and airy, keeping content front and center.

**Depth.** Distinct visual layers and realistic motion convey hierarchy, impart vitality, and facilitate understanding. Touch and discoverability heighten delight, enable access to functionality, and provide context. Transitions provide a sense of depth as you navigate content.

### Practical application
- Default to system components. They embody these principles automatically
- Don't add visual chrome unless it serves a purpose
- Let content be the primary visual element
- Use animation to show spatial relationships, not for decoration

## Typography

### Use system fonts
San Francisco is the system font. Use semantic text styles, not fixed sizes:

```swift
Text("Headline").font(.headline)           // 17pt semibold
Text("Body text").font(.body)              // 17pt regular
Text("Caption").font(.caption)             // 12pt regular
Text("Large Title").font(.largeTitle)      // 34pt regular
Text("Title").font(.title)                 // 28pt regular
Text("Title 2").font(.title2)              // 22pt regular
Text("Title 3").font(.title3)              // 20pt regular
Text("Callout").font(.callout)             // 16pt regular
Text("Subheadline").font(.subheadline)     // 15pt regular
Text("Footnote").font(.footnote)           // 13pt regular
Text("Caption 2").font(.caption2)          // 11pt regular
```

**These sizes scale with Dynamic Type.** This is the entire point — using semantic styles means your typography automatically adapts to user preferences.

### Custom fonts
If using a custom font, create scaled variants:
```swift
@ScaledMetric(relativeTo: .body) var customSize = 17

Text("Custom")
    .font(.custom("MyFont", size: customSize))
```

### Typography rules
- Maximum two font families in an app (one is preferred)
- Use font weight for emphasis, not color or italics
- Line length: 50-75 characters for comfortable reading
- Don't truncate important information — let it wrap or use `ViewThatFits`

## Color

### System colors
Always use semantic system colors — they adapt to Dark Mode, accessibility settings, and platform:

```swift
Color.primary          // primary text — black in light, white in dark
Color.secondary        // secondary text — gray, adapts to mode
Color.accentColor      // your app's tint color
Color(.systemBackground)
Color(.secondarySystemBackground)
Color(.tertiarySystemBackground)
Color(.systemGroupedBackground)
Color(.secondarySystemGroupedBackground)
```

### Custom colors
Define in asset catalog with Light and Dark variants. SwiftUI resolves automatically.

### Color guidelines
- **Don't use color as the only indicator.** Always pair with shape, icon, or text (colorblind users)
- **Contrast ratios:** 4.5:1 minimum for body text, 3:1 for large text (WCAG AA)
- **Dark Mode:** Always support it. Test both modes. Never hardcode white or black
- **Tint color:** Pick one accent color for your app. Use it for interactive elements. Don't use more than 2-3 accent colors
- **Vibrancy:** On translucent backgrounds, use vibrancy effects rather than opaque colors

## Layout and Spacing

### Core spacing values
Apple uses an 8-point grid system. Common values:
- 4pt — tight spacing (within a component)
- 8pt — compact spacing
- 16pt — standard spacing (default padding)
- 20pt — comfortable spacing between sections
- 24-32pt — generous spacing between major sections

### Touch targets
**Minimum 44×44 points for all interactive elements.** This is a hard requirement. Smaller targets are an App Store rejection risk and an accessibility failure.

```swift
Button("Tap") { }
    .frame(minWidth: 44, minHeight: 44)
```

### Safe areas
Always respect safe areas. Content should never be clipped by:
- Status bar
- Home indicator
- Dynamic Island / notch
- Navigation bar / tab bar

### Margins
Use system default margins. On iPhone, standard horizontal margins are 16pt. On iPad, they increase. `padding()` with no arguments gives you system-appropriate values.

### Adaptive layouts
- Use `NavigationSplitView` for sidebar/detail on iPad, single column on iPhone
- `ViewThatFits` for responsive component layouts
- Size classes (`horizontalSizeClass`) for major layout changes
- Never assume screen size — test on smallest and largest supported devices

## Iconography and SF Symbols

### SF Symbols
Apple's icon system. 5000+ symbols, all designed to work with San Francisco. **Always prefer SF Symbols over custom icons.**

```swift
Image(systemName: "star.fill")
    .symbolRenderingMode(.hierarchical) // multi-layer rendering
    .foregroundStyle(.yellow)

Label("Favorites", systemImage: "star.fill") // text + icon together
```

### Symbol rendering modes
- `.monochrome` — single color (default)
- `.hierarchical` — primary color with opacity layers
- `.palette` — custom colors per layer
- `.multicolor` — original designed colors

### Custom icons
If you must create custom icons:
- Match SF Symbol weight and optical size
- Provide filled and outlined variants
- Export as PDF or SVG in asset catalog
- Test at all Dynamic Type sizes

### App icon
- Single 1024×1024 source in asset catalog (Xcode generates all sizes)
- No text in the icon (doesn't scale)
- Don't use photographs
- Keep it simple, recognizable, unique
- Support dark/tinted variants (iOS 18+)

## Navigation Patterns

### iOS
- **Tab bar:** 3-5 top-level sections. The primary navigation pattern for iPhone
- **Navigation stack:** Push/pop for hierarchical content
- **Modal sheets:** Focused tasks, creation flows, settings
- **Full-screen cover:** Immersive content (media playback, onboarding)

### iPadOS
- **Sidebar:** Primary navigation via `NavigationSplitView`
- **Tab bar:** Can combine with sidebar (adaptive behavior)
- **Popovers:** Secondary actions, selections

### macOS
- **Sidebar:** Standard for most apps
- **Toolbar:** Primary actions
- **Menu bar:** Standard menus (File, Edit, etc.) via `.commands`
- **Preferences:** `Settings` scene

### Navigation rules
- Back buttons should always work. Don't trap users in dead ends
- Respect the navigation back gesture (swipe from left edge on iOS)
- Deep links should restore the full navigation stack
- Don't use custom back buttons that break the standard behavior unless absolutely necessary

## Input and Interaction

### Gestures
- **Tap:** Primary action. 44pt target minimum
- **Long press:** Secondary actions, context menus
- **Swipe:** Navigation (back), list actions (delete, archive)
- **Pinch:** Zoom
- **Rotation:** Rotate content
- **Drag:** Reorder, move

Don't override system gestures (swipe from edge = back, swipe up = home).

### Context menus
```swift
Text(item.title)
    .contextMenu {
        Button("Copy", systemImage: "doc.on.doc") { copy(item) }
        Button("Share", systemImage: "square.and.arrow.up") { share(item) }
        Divider()
        Button("Delete", systemImage: "trash", role: .destructive) { delete(item) }
    }
```

### Confirmation for destructive actions
Always confirm destructive actions:
```swift
.confirmationDialog("Delete this item?", isPresented: $showDelete) {
    Button("Delete", role: .destructive) { performDelete() }
}
```

### Text input
- Use appropriate keyboard types (`.emailAddress`, `.numberPad`, `.URL`)
- Support paste, autocorrect, autocapitalization as appropriate
- Provide clear affordance for text fields (borders, placeholder text)
- Use `.submitLabel()` to customize the return key

## Accessibility Requirements

These are not optional. They affect App Store approval and legal compliance.

### Mandatory
- **VoiceOver support:** All interactive elements must be accessible. Test full flows with VoiceOver enabled
- **Dynamic Type:** All text must scale from Extra Small to Accessibility Extra Extra Extra Large (xxxLarge)
- **Color contrast:** 4.5:1 minimum for normal text, 3:1 for large text
- **Touch target size:** 44×44pt minimum
- **Motion sensitivity:** Respect `accessibilityReduceMotion`. Provide alternatives to motion-based interactions

### Strongly recommended
- **Accessibility labels** on all icons and images that convey meaning
- **Accessibility hints** on non-obvious interactive elements
- **Group related elements** with `.accessibilityElement(children: .combine)`
- **Announce dynamic changes** with `AccessibilityNotification.Announcement`
- **Support Increase Contrast** setting
- **Support Bold Text** setting
- **Support Reduce Transparency** setting

### Testing accessibility
1. Turn on VoiceOver and navigate your entire app
2. Set Dynamic Type to maximum and verify nothing breaks
3. Run Accessibility Inspector in Xcode
4. Test with Switch Control
5. Verify all Accessibility Audit results pass

## Platform-Specific Guidance

### iOS
- Tab bar at bottom for primary navigation
- Large titles in navigation bars (`.navigationBarTitleDisplayMode(.large)`)
- Swipe-to-go-back is sacred — don't interfere
- Pull-to-refresh for refreshable content
- Haptic feedback for meaningful interactions (`UIImpactFeedbackGenerator`)

### macOS
- Menu bar is the discovery mechanism for all features
- Keyboard shortcuts for all common actions
- Multiple windows support where appropriate
- Toolbar for contextual actions
- Sidebar for navigation
- Settings (not "Preferences" in new apps) via `Settings` scene
- Right-click context menus everywhere

### watchOS
- Minimal interaction — focus on glanceable information
- Digital Crown for scrolling and input
- Complications for quick access
- Notifications are a primary interaction surface
- Keep views simple and focused

### visionOS
- Spatial layouts — elements can exist at different depths
- Eye tracking + hand gestures for interaction
- Use system ornaments and window chrome
- Content should feel present in the space, not flat on a screen
- Follow volume and immersive space patterns from HIG

## Liquid Glass (iOS 26+)

Apple's new design language introduced with iOS 26. Key characteristics:

- **Translucent glass material** for navigation bars, tab bars, sidebars, and floating elements
- **Depth and layering** through blur and saturation effects
- **Frosted appearance** that adapts to content behind it
- **Seamless integration** with system UI elements

### Adoption
SwiftUI system components adopt Liquid Glass automatically when targeting iOS 26+. Custom materials:
```swift
.background(.ultraThinMaterial) // system glass effect
.background(.regularMaterial)
.background(.thickMaterial)
```

### Design considerations
- Don't fight the glass aesthetic with opaque backgrounds
- Ensure text remains readable over variable backgrounds (use vibrancy)
- Test with different wallpapers and background content
- Respect the reduced transparency accessibility setting
