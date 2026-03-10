# App Quality Standards

Production readiness standards for Apple platform apps. Use this reference when reviewing code headed for App Store submission or assessing release readiness. Every section represents a category of risk — gaps in any category are review findings that can result in App Store rejection, poor user ratings, or real-world failures on customer devices.

## Table of Contents
1. [Performance Budgets](#performance-budgets)
2. [Device Matrix Testing](#device-matrix-testing)
3. [App Store Review Risks](#app-store-review-risks)
4. [Testing Requirements](#testing-requirements)
5. [Localization Readiness](#localization-readiness)
6. [Error Handling UX](#error-handling-ux)
7. [Privacy and Permissions](#privacy-and-permissions)

---

## Performance Budgets

### Launch time
- **Cold launch target: under 2 seconds** on the oldest supported device. Under 400ms warm launch. These are measured from tap to interactive content visible — not just the first frame
- **Pre-main time:** Excessive dynamic libraries, +load methods, and static initializers inflate pre-main time. Keep under 400ms. Profile with Instruments > App Launch template
- **Lazy initialization:** Don't initialize everything in `init()` or `App.init()`. Defer heavy setup (database, network, analytics) until actually needed. `@State` initialization in views is fine — it's lazy by default
- **Launch screen:** A static launch screen (storyboard or Info.plist configuration) must match the app's initial state to avoid visible "pop" on transition. Test in both Light and Dark mode

### Scroll and animation performance
- **60fps scroll is mandatory.** Any dropped frames during normal scrolling of a `List` or `ScrollView` is a HIGH finding. On ProMotion devices, target 120fps for animations
- **Hitch budget:** Zero hitches during standard interactions (scroll, navigate, present sheet). Use the Animation Hitches instrument to measure. A hitch is a frame that takes longer than the frame deadline
- **Off-screen preparation:** For complex list cells, prepare content before the cell scrolls into view. Use `.task` for pre-fetching. Don't load images synchronously during scroll

### Memory
- **Memory ceiling by device class:**
  - iPhone SE / 3GB devices: keep under 200MB total footprint
  - iPhone standard / 6GB devices: keep under 400MB
  - iPad / Mac: more headroom but still budget-conscious
- **Memory warnings:** Handle `UIApplication.didReceiveMemoryWarningNotification`. Clear caches, release non-essential resources. Test by simulating memory pressure in Xcode
- **Image memory:** A single 12MP photo decoded to bitmap consumes ~48MB. Thumbnail and cache at display resolution, not source resolution. Flag code that loads full-resolution images for thumbnail display as HIGH
- **Leak detection:** Run the Leaks instrument regularly. Any leak is a finding. SwiftUI closure captures and Task lifecycle are the most common sources

### Disk and network
- **App bundle size:** Review for unnecessary assets, duplicate resources, unused code. Each MB of app size reduces install rate — users on cellular or limited storage skip large apps
- **Network request budget:** Batch API calls. Cache aggressively. Don't fetch data the user hasn't asked for. Profile with the Network instrument for redundant or excessive requests
- **Background data:** Minimize background network activity. Excessive background usage drains battery and triggers iOS throttling

### Battery
- **No unnecessary background activity:** Timers, location updates, and network polling drain battery. Use system mechanisms: `BackgroundTasks` framework, push notifications for updates, significant-change location monitoring instead of continuous
- **Efficient updates:** Prefer push-based updates (WebSocket, push notification) over polling. If polling is necessary, use the minimum viable frequency and respect low-power mode

## Device Matrix Testing

### Screen sizes
- **iPhone SE (4.7", 375pt width):** The smallest actively sold iPhone. Every layout must work here. Text that fits on a 6.7" Pro Max may overflow on SE. Flag layouts not tested at 375pt width as HIGH
- **iPhone standard (6.1", 390pt width):** The most common screen size. Primary design target
- **iPhone Pro Max (6.7", 430pt width):** Largest iPhone. Check that layouts don't have excessive whitespace or undersized content
- **iPad (various sizes):** If the app targets iPad, test in portrait, landscape, Split View (1/3, 1/2, 2/3 split), and Slide Over. Test with pointer/trackpad connected
- **Mac (if applicable):** Test at various window sizes including minimum and maximum. Test with menu bar, keyboard shortcuts, and multiple windows

### Dynamic Type extremes
- **Extra Small:** Verify content doesn't become too small to read or interact with
- **Default:** Primary design target
- **Accessibility XXXL:** The largest system size. Verify no text clipping, no overlapping, no buttons pushed off-screen, and all functionality remains accessible [CRITICAL if broken]
- **Intermediate sizes:** Spot-check at Large and AX1 to ensure smooth scaling

### Appearance modes
- [ ] Light Mode: fully functional, no invisible elements, correct contrast
- [ ] Dark Mode: fully functional, no white flashes, no invisible elements, custom colors adapted [HIGH if broken]
- [ ] Increase Contrast: text and borders more visible, not broken
- [ ] Reduce Transparency: glass and blur effects replaced with solid backgrounds
- [ ] Bold Text: font weights increased, layout still correct

### Orientation
- [ ] Portrait: primary design target
- [ ] Landscape: layout adapts or app explicitly opts out (must be intentional, not accidental)
- [ ] Rotation transitions: smooth, no layout jumps, no state loss

## App Store Review Risks

### Common rejection reasons
- **Crashes:** Any crash during normal usage flow is an automatic rejection. Test the full flow on the minimum supported OS version and device. Pay extra attention to forced unwrap (`!`), unhandled optionals, and missing nil checks [CRITICAL]
- **Broken links and dead buttons:** Every button must do something. Every link must work. Every menu item must be functional. Placeholder "coming soon" features are rejected
- **Incomplete functionality:** The app must provide value as submitted. "Sign up for beta" or "more features coming" is not sufficient
- **Login walls:** Requiring login to browse content (when browsing doesn't need login) may be rejected. "Sign in with Apple" must be offered alongside other third-party login options
- **Privacy:** Missing privacy policy link. Data collection not disclosed in App Privacy section. Missing purpose string for system permissions. Flag any missing permission description as CRITICAL

### Privacy manifest (required)
- **Privacy manifest file (PrivacyInfo.xcprivacy) required** for all apps and SDKs that use Required Reason APIs
- **Required Reason APIs:** UserDefaults, file timestamp access, system boot time, disk space, active keyboards — each requires a declared reason. Flag undeclared usage as CRITICAL
- **Tracking domains:** All tracking domains must be declared in the privacy manifest
- **Third-party SDK compliance:** Every third-party SDK must include its own privacy manifest. Check that all dependencies have updated manifests

### App Tracking Transparency
- **ATT prompt required before any tracking.** Tracking includes advertising identifiers, cross-app tracking, and sharing data with data brokers. The prompt must appear before any tracking code executes [CRITICAL]
- **Graceful handling of denial:** If the user denies tracking, the app must function fully. No degraded experience, no repeated prompts, no "you must enable tracking" messages
- **Pre-prompt explanation:** Consider showing a custom screen explaining why tracking helps before showing the system prompt. The system prompt itself is not customizable beyond the purpose string

### Entitlements and capabilities
- **Only request entitlements you use.** Unused entitlements (push notifications enabled but never configured, HealthKit enabled but never accessed) cause review delays and possible rejection
- **Background modes:** Each background mode must be justified by actual usage. Background fetch without a refresh handler, or background audio without audio playback, will be flagged
- **Associated domains:** Universal Links and App Clips require proper `apple-app-site-association` file on the web server. Test that the association works

### Review notes
- **Provide demo accounts** if the app requires login. App Store reviewers will reject if they can't test core functionality
- **Explain non-obvious features** in review notes (AR features that need a flat surface, features that need a second device, location-dependent features)
- **Respond promptly** to reviewer questions. A delayed response can result in rejection

## Testing Requirements

### SwiftUI previews
- **Every view should have at least one preview.** Previews catch layout issues early and serve as documentation. Flag views with no previews as MEDIUM
- **Multi-state previews:** Each view previewed in multiple states: populated data, empty state, loading state, error state, large Dynamic Type, Dark Mode. Flag views with only a single happy-path preview as LOW
- **Preview containers for SwiftData:** Use `ModelContainer` with `isStoredInMemoryOnly: true` for previews. Don't rely on disk data for previews — they must work from a clean state

### UI test automation
- **Critical user flows must have UI tests.** Onboarding, sign in, primary feature usage, purchase flow. These are the flows App Store reviewers test — they must not crash [HIGH]
- **Accessibility identifiers:** Interactive elements need `.accessibilityIdentifier()` for UI test targeting. These are separate from VoiceOver labels and don't affect accessibility
- **State setup:** UI tests must set up their own state (launch arguments, mock data). Don't depend on simulator state or previous test runs

### Accessibility audit
- **Xcode Accessibility Inspector audit:** Run against every primary screen. Fix all errors, review all warnings. This catches missing labels, contrast violations, and touch target issues that manual review misses
- **VoiceOver walkthrough:** Manually navigate the entire app with VoiceOver enabled. Every screen, every interaction. Flag if VoiceOver walkthrough has never been performed as HIGH
- **Voice Control test:** Enable Voice Control and verify all buttons can be activated by speaking their label

### Instruments profiling
- **Time Profiler:** Run against cold launch and primary user flows. Identify main thread blocking > 16ms. Flag if no profiling has been done as HIGH
- **Allocations:** Check for memory growth during repeated actions (scroll list, navigate forward/back, open/close sheet). Steady growth indicates leaks or cache without bounds
- **SwiftUI view body instrument:** Identify views with excessive body evaluations. Views recomputing > 10x/second during idle state are suspect
- **Animation Hitches instrument:** Run during scroll and navigation. Any hitch in standard interactions is a finding

### Snapshot testing
- **Visual regression detection:** For apps with complex custom UI, snapshot tests catch unintended visual changes. Compare screenshots across commits
- **Multi-configuration snapshots:** Light/Dark mode, iPhone SE/Pro Max, Default/AX XXXL Dynamic Type. Each configuration is a separate snapshot

## Localization Readiness

### String management
- **All user-facing strings must be localizable.** Use `String(localized:)` or `LocalizedStringKey`. Hardcoded English strings in SwiftUI views are a MEDIUM finding — even if the app is English-only, localization readiness prevents tech debt
- **No string concatenation for sentences.** `"Hello " + name + ", you have " + count + " items"` cannot be localized because word order varies by language. Use `String(localized:)` with interpolation or `AttributedString` for formatting
- **Plural rules:** Use `.stringsdict` or `String(localized:)` with `grammar agreement` for plurals. "You have \(count) item(s)" is not localizable — many languages have more than two plural forms

### Layout for localization
- **Text expansion:** German and Finnish text can be 2-3x longer than English. Layouts must accommodate this expansion without truncation or overlap [HIGH]
- **Right-to-left (RTL):** If the app will ever support Arabic or Hebrew, layouts must use `.leading`/`.trailing` instead of `.left`/`.right`. SwiftUI uses leading/trailing by default — flag any explicit `.left`/`.right` alignment as MEDIUM
- **Mirroring:** In RTL languages, the entire layout mirrors. Navigation flows right-to-left. Verify layout mirroring with Xcode's RTL pseudolanguage

### Date, number, and currency formatting
- **Use `Formatters` or `formatted()`.** Never manually format dates ("MM/dd/yyyy" — ambiguous internationally), numbers ("1,000.00" — uses period for decimal in some locales), or currencies. Flag manual formatting as HIGH
- **Relative dates:** Use `Text(date, style: .relative)` or `RelativeDateTimeFormatter`. "3 minutes ago" varies by language
- **Calendar awareness:** Not all calendars are Gregorian. Use `Calendar.current` not `Calendar(identifier: .gregorian)`

### Testing localization
- **Pseudolanguage testing:** Run with Xcode's "Double-Length Pseudolanguage" to catch truncation and overflow at expanded text lengths
- **RTL testing:** Run with "Right-to-Left Pseudolanguage" to verify layout mirroring
- **Review string files:** `.strings` and `.stringsdict` files must have all keys present for all supported languages. Missing keys fall back to the development language silently

## Error Handling UX

### Empty states
- **First-run empty state:** When the app has no data (first launch), show a clear explanation and a call to action — not a blank screen. "No items yet. Tap + to add your first item." [HIGH if missing]
- **No results:** Search, filter, or fetch that returns nothing should show a specific message, not a blank list. "No results for 'xyz'. Try a different search term"
- **No network:** If the app needs network but has none, show offline state with a clear message and a retry affordance. Don't show an empty screen or an error alert with no action [HIGH]

### Error states
- **Actionable error messages:** "Something went wrong" is not acceptable. Tell the user what happened and what they can do: "Couldn't save your changes. Check your connection and try again" [HIGH]
- **Retry affordance:** For transient errors (network, server), provide a retry button. Don't make the user navigate away and back to try again
- **Non-blocking errors:** Errors that don't prevent core functionality should be non-modal (banner, inline message), not blocking alerts. Reserve alerts for errors that require user decision
- **Error recovery:** After an error, the app should be in a recoverable state. No half-saved data, no inconsistent UI, no stuck loading indicators

### Loading states
- **Indicate progress:** Every operation that takes more than ~200ms should show loading feedback. Immediate operations don't need indicators — but anything that hits network, disk, or a heavy computation does
- **Skeleton screens:** For content loading, skeleton views (placeholder shapes matching the content layout) are preferred over spinners. They feel faster and set expectations for what content will appear
- **Progress indication:** For long operations (file upload, export, sync), show determinate progress (progress bar with percentage), not indeterminate spinners. Users need to know how long to wait
- **Cancellation:** Long operations should be cancellable. The user should be able to tap "Cancel" and have the operation stop within a few seconds

### State restoration
- **Crash recovery:** If the app crashes, it should resume to a reasonable state — not lose all user work. Use `@SceneStorage` for lightweight state, `SwiftData` autosave for model data
- **Background termination:** iOS may terminate backgrounded apps at any time. All important state must be persisted before entering background. Don't rely on `applicationWillTerminate` — it's not always called
- **Mid-operation state:** If the user leaves the app during a multi-step flow (form filling, checkout), their progress should be preserved when they return

## Privacy and Permissions

### Permission request timing
- **Just-in-time requests:** Request permissions when the user initiates the action that needs them — not at launch, not in onboarding [HIGH if requested at launch without context]
- **Pre-prompt context:** Before showing the system permission dialog, explain why the permission is needed with a custom screen. "We need camera access to scan QR codes" — then show the system dialog. The system dialog's purpose string is limited and can't fully explain the value
- **Purpose strings:** Every permission must have a clear, specific purpose string in Info.plist. "This app needs access to your location" is too vague. "We use your location to show nearby restaurants" is specific [CRITICAL if missing]

### Graceful degradation
- **Denied permissions must not break the app.** If camera access is denied, the QR scanning feature is unavailable — but the rest of the app must work perfectly. Flag apps that require permissions for basic functionality as HIGH
- **Permission status checking:** Check permission status before requesting. If already denied, show an explanation with a button to open Settings — don't show the system prompt (it won't appear for already-denied permissions)
- **Status monitoring:** Permissions can change while the app is running (user goes to Settings and revokes). Use the appropriate status monitoring API (CLLocationManager delegate, PHPhotoLibrary changes, etc.) to react to changes

### Background capabilities
- **Background App Refresh:** If used, register a `BGAppRefreshTaskRequest` with appropriate interval. Don't schedule too frequently — iOS throttles and the battery impact is real
- **Location updates:** Use the minimum accuracy needed. `desiredAccuracy: kCLLocationAccuracyKilometer` for city-level, not `kCLLocationAccuracyBest` for everything. Background location is heavily scrutinized by App Store review
- **Push notifications:** Request permission judiciously. Don't request at first launch. Provide clear value proposition. Handle denied state gracefully
- **Background audio:** Only if the app actually plays audio in the background. Claiming background audio for non-audio features is grounds for rejection

### Data handling
- **Minimum data collection:** Collect only what you need. Every data point must have a justified purpose. App Store privacy labels must accurately reflect collection
- **Data at rest:** Sensitive data (tokens, user credentials, personal information) stored in Keychain, not UserDefaults or plain files. Flag sensitive data in UserDefaults as CRITICAL
- **Data in transit:** All network requests over HTTPS. No HTTP exceptions in ATS (App Transport Security) without documented justification. Flag ATS exceptions as HIGH
- **Data deletion:** If you collect user data, provide a way to delete it. Account deletion must be available if account creation is offered (App Store requirement)
