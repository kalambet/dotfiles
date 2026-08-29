# SwiftUI Review Standards

Review standards for SwiftUI code. This is the primary reference for the apple-reviewer skill — SwiftUI state management, layout, and performance are where the most subtle bugs hide and where the most user-visible regressions originate.

## Table of Contents
1. [State Management Correctness](#state-management-correctness)
2. [Navigation Robustness](#navigation-robustness)
3. [Layout Correctness](#layout-correctness)
4. [Animation Quality](#animation-quality)
5. [View Performance](#view-performance)
6. [Memory Safety](#memory-safety)
7. [Concurrency Correctness](#concurrency-correctness)
8. [Data Flow](#data-flow)

---

## State Management Correctness

State management errors are the #1 source of subtle SwiftUI bugs. A wrong property wrapper doesn't crash — it silently causes stale UI, unnecessary redraws, or lost user input.

### Property wrapper selection
- **`@State` must own the data.** If the data comes from a parent, `@State` is wrong — it creates a disconnected copy that won't update. Flag `@State` on data received via init parameters as CRITICAL
- **`@State` on reference types:** In modern SwiftUI with `@Observable`, `@State` holds a reference to an `@Observable` object. This is correct. But `@State` on a plain class (not `@Observable`) is a bug — it won't trigger view updates. Flag as CRITICAL
- **`@Binding` for child mutation only.** If a child view reads but never writes, pass the value directly. `@Binding` implies mutation — unnecessary `@Binding` adds complexity and potential for unintended side effects
- **`@Observable` vs `ObservableObject`:** New code must use `@Observable` (Observation framework). `ObservableObject` with `@Published` causes whole-object observation — any published property change triggers updates in every view that observes the object, even views that don't read the changed property. Flag `ObservableObject` in new code as MEDIUM
- **`@Environment` for shared dependencies.** Check that environment values are injected at the right level in the view hierarchy. Missing environment injection causes runtime crashes that only surface in specific navigation paths. Flag environment dependencies without documented injection points as HIGH

### State ownership
- **State must live at the lowest common ancestor** of all views that need it. State hoisted too high causes unnecessary recomputations in unrelated siblings. State too low causes data duplication and sync issues
- **Derived state must be computed, not stored.** If a value can be derived from existing state, it must be a computed property, not a separate `@State`. Separate storage creates opportunities for inconsistency — the derived value can get out of sync with its source
- **Single source of truth violations:** If the same data exists in two `@State` properties (or a `@State` and a model), flag as HIGH. Exactly one location must own each piece of data. Everything else is derived or bound

### Recomputation triggers
- **Unused `@Observable` properties:** If a view accesses properties of an `@Observable` object in its body that it doesn't display, those properties still trigger recomputation when they change. Flag views that import entire model objects but only use one field — extract the field as a parameter instead
- **Collection observation traps:** A view observing an array of `@Observable` objects recomputes when any property of any object in the array changes. For large collections, this is a performance disaster. Flag and recommend per-item extraction into child views that observe individual objects

### View identity and lifetime
- **Explicit `id()` modifiers change view identity.** When the id value changes, SwiftUI destroys and recreates the view, including all its `@State`. If `id()` changes on user interaction, `@State` is lost. Flag `id()` modifiers that use volatile values (array indices, timestamps) as HIGH
- **`@State` initialization:** `@State` initial values are only applied when the view is first created, not on subsequent body evaluations. If you set `@State var text = someParameter`, changing `someParameter` later won't update `text`. Flag as CRITICAL if the code expects init-time `@State` to track external changes

## Navigation Robustness

### Pattern correctness
- **NavigationView is deprecated.** All new code must use `NavigationStack` (single column) or `NavigationSplitView` (multi-column). Flag `NavigationView` as MEDIUM in new code, LOW in existing code
- **NavigationStack path management:** For programmatic navigation, verify the path binding is correctly typed and that `navigationDestination(for:)` is registered for each type in the path. Missing destination registrations cause silent failures — the push simply doesn't happen. Flag as HIGH
- **Nested NavigationStacks:** A `NavigationStack` inside another `NavigationStack` creates confusing double navigation bars and broken back behavior. Flag as CRITICAL

### Gesture and interaction preservation
- **Swipe-back gesture:** Verify that custom gestures, overlays, or edge-positioned elements don't block the system swipe-back gesture. A broken back gesture is a guaranteed poor review from users and a possible App Store rejection
- **Tab bar visibility:** Tab bars should remain visible during most navigation. Hiding the tab bar (`toolbar(.hidden, for: .tabBar)`) should be rare and intentional (media playback, immersive content). Flag unnecessary tab bar hiding as HIGH
- **Sheet and modal lifecycle:** Verify `.onAppear`/`.onDisappear` behavior in sheets — they behave differently from navigation pushes. State must be reset appropriately when sheets are dismissed and re-presented. Check that sheets don't stack unintentionally (presenting a sheet from within a sheet)

### Deep linking and state restoration
- **Deep link support:** If the app uses `NavigationStack` with a path, deep links must be able to construct the path programmatically. Flag apps with navigation but no deep link consideration as MEDIUM
- **State restoration:** On app termination and relaunch, navigation state should be restorable. `@SceneStorage` for lightweight state, custom persistence for complex state. Flag complete absence of state restoration as MEDIUM

## Layout Correctness

### Hardcoded values
- **Hardcoded widths and heights are almost always wrong.** They break on different screen sizes, Dynamic Type sizes, and localized text lengths. Use `.frame(maxWidth: .infinity)`, `ViewThatFits`, or flexible containers instead. Flag hardcoded dimensions as HIGH unless there's a specific design requirement (icon sizes, fixed-ratio images)
- **Hardcoded font sizes bypass Dynamic Type.** Use `.font(.body)`, `.font(.headline)`, etc. Custom fonts must use `UIFontMetrics` or `@ScaledMetric` to scale with Dynamic Type. Flag `.font(.system(size: N))` without scaling as CRITICAL — this is an accessibility failure
- **Hardcoded padding/spacing:** Use system spacing where possible. Hardcoded values should be `@ScaledMetric` if they need to scale with Dynamic Type, or at minimum be named constants, not magic numbers

### Dynamic Type support
- **Every user-facing text must scale.** Test mentally at Accessibility Extra Extra Extra Large (AX XXXL) — the largest Dynamic Type size. Text must not truncate without an affordance to see the full content. Layouts must not overlap or clip
- **Horizontal layouts must adapt.** Two labels side-by-side at default size may overlap at AX XXXL. Use `ViewThatFits` to switch from horizontal to vertical layout at large type sizes, or ensure truncation with a reasonable `lineLimit` and accessibility affordance
- **Fixed-height containers break Dynamic Type.** A `.frame(height: 44)` cell will clip large text. Use `.frame(minHeight: 44)` or remove the height constraint entirely. Flag fixed heights on text-containing views as HIGH

### Safe areas and device variation
- **`ignoresSafeArea()` must be intentional.** Background colors and images may ignore safe areas; interactive content must not. A button hidden under the notch or home indicator is inaccessible. Flag blanket `.ignoresSafeArea()` without justification as HIGH
- **Landscape support:** Unless the app explicitly opts out of landscape (documented and justified), all layouts must work in landscape. Check that horizontal layouts don't overflow and that scroll views handle orientation changes
- **iPad and Mac:** If the deployment target includes iPad or Mac, layouts must be tested at multiple window sizes. A single-column phone layout filling a 12.9" iPad screen is a poor experience. Use `NavigationSplitView`, `ViewThatFits`, or horizontal size class checks

### GeometryReader discipline
- **GeometryReader is a last resort.** It reads layout information after the layout pass, which can cause layout loops if misused. For simple "fill available width" — use `.frame(maxWidth: .infinity)`. For responsive layouts — use `ViewThatFits` or size classes. Flag GeometryReader when a simpler solution exists as MEDIUM
- **GeometryReader inside ScrollView:** This is a common source of layout bugs. The geometry may report incorrect sizes, and changes to geometry can cause infinite layout loops. Flag with extra scrutiny as HIGH

### Text handling
- **Truncation policy:** Every `Text` view that could exceed its container must have an explicit truncation strategy: `lineLimit`, `minimumScaleFactor`, or `truncationMode`. Default truncation can produce unreadable text. Flag unbounded `Text` in constrained containers as MEDIUM
- **Localization impact:** Localized strings can be 2-3x longer than English (German, Finnish). Layouts must accommodate expansion without breaking. Flag layouts that are tight at English text lengths as MEDIUM

## Animation Quality

### Smoothness
- **Animation work must happen off the main thread.** If the animation triggers a state change that causes expensive computation in `body`, the animation will hitch. Complex state changes during animation should be deferred or pre-computed
- **`withAnimation` scope:** `withAnimation` should wrap only the state change, not expensive work that happens to precede or follow it. Oversized `withAnimation` blocks cause unnecessary interpolation of unrelated properties

### Reduce motion support
- **All motion must respect `accessibilityReduceMotion`.** Use `@Environment(\.accessibilityReduceMotion)` or the `.animation(.default, value:)` modifier which automatically respects this setting. Custom `withAnimation` calls must check the environment and substitute a static state change. Flag animations without reduce-motion support as HIGH — this is an accessibility requirement
- **Transaction-based animation:** Prefer `.animation(_:value:)` over `withAnimation` when possible — it's scoped to specific values, easier to reason about, and automatically respects reduce-motion when using system animations

### Transition correctness
- **Transitions must be paired.** An `.insertion` transition without a `.removal` (or vice versa) creates asymmetric animation that looks buggy. Use `.transition(.asymmetric(insertion:removal:))` intentionally or `.transition(.opacity)` for symmetric
- **`matchedGeometryEffect` pitfalls:** Both the source and destination must be in the view hierarchy simultaneously during the transition. If one is conditionally removed, the matched geometry breaks silently. Flag matched geometry without explicit lifecycle management as HIGH

### Duration and curve
- **System default durations (0.25-0.35s) are almost always correct.** Custom durations need justification. Animations over 0.5s feel sluggish. Animations under 0.15s are invisible
- **Spring animations should specify parameters.** `.spring()` without parameters uses sensible defaults but can overshoot for UI elements. Use `.spring(response:dampingFraction:)` for control. `.spring(response: 0.3, dampingFraction: 0.8)` is a safe starting point
- **Never use `.linear` for UI element animation.** Linear animation looks mechanical and unnatural. Use `.easeInOut`, `.spring`, or `.snappy` for UI elements. `.linear` is only appropriate for continuous looping animations (spinners, progress)

## View Performance

### Body complexity
- **The `body` property must be fast.** It is called frequently — on every state change, every animation frame, every parent recomputation. Expensive work in body (network calls, heavy computation, file I/O) is a CRITICAL finding
- **View extraction:** Bodies exceeding ~30 lines should be broken into extracted subviews. Long bodies are hard to review, hard to optimize, and often contain unnecessary recomputation triggers
- **Conditional complexity:** Deeply nested `if/else` chains in body create complex view hierarchies that are expensive to diff. Consider extracting branches into separate views or using `Group` with `switch`

### Unnecessary redraws
- **`Self._printChanges()` during development:** If the reviewer suspects unnecessary redraws, recommend adding `Self._printChanges()` to the view's body (debug only) to identify what's triggering recomputation
- **Parent-child coupling:** A child view that accepts an entire model object will recompute whenever any property of that model changes, even properties the child doesn't use. Pass only the specific properties needed. Flag "whole model" passing as HIGH when the model is large or frequently updated
- **ForEach identification:** `ForEach` must use stable, unique identifiers. Using array indices (`ForEach(0..<items.count)`) means every item is "new" when the array changes — SwiftUI recreates every view instead of updating the changed ones. Flag index-based ForEach as HIGH

### Lazy container usage
- **Large collections must use lazy containers.** `VStack` inside `ScrollView` materializes every child view immediately. For more than ~20-30 items, use `List` or `LazyVStack`. Flag eager containers with dynamic collections as HIGH
- **Lazy containers load on demand.** Don't use `.onAppear` on the first item of a lazy container to trigger data loading — use `.task` on the container itself. Also, don't assume all items have appeared just because the container appeared

### Image loading
- **Images must not load synchronously in body.** Network images use `AsyncImage` or a caching library. Local images are fine with `Image(_:)` but large images should be downsampled to display size using `preparingThumbnail(of:)` or equivalent
- **Image caching:** `AsyncImage` does not cache across view lifecycle. For repeated image loading (scrolling lists, tab switches), use a caching image loader. Flag `AsyncImage` in performance-critical lists as MEDIUM

## Memory Safety

### Retain cycles
- **Closures capturing `self`:** In `@Observable` objects, closures stored as properties (completion handlers, timer callbacks, notification observers) that capture `self` create retain cycles. Use `[weak self]` for stored closures. Flag strong self-capture in stored closures as HIGH
- **Task cancellation:** `Task { }` created in view body or `.onAppear` captures the enclosing scope. If the view is dismissed before the task completes, the task continues running and retaining its captures. Use `.task { }` modifier (auto-cancels on disappear) instead of manual `Task` in `.onAppear`. Flag `onAppear { Task { } }` as MEDIUM — use `.task { }` instead
- **Combine subscribers:** `AnyCancellable` stored in a `Set<AnyCancellable>` on an object that is also retained by the publisher creates a retain cycle. Verify cancellable cleanup on `deinit`

### Timer and notification cleanup
- **Timer.publish must be cancelled.** A timer that outlives its view keeps firing and retaining its closure. Use `.onReceive` modifier (auto-cleanup) or ensure manual cancellation in `.onDisappear`
- **NotificationCenter observers:** Observers registered with closure-based API must be removed. Use `.onReceive(NotificationCenter.default.publisher(for:))` for automatic cleanup. Flag manual `addObserver` without corresponding `removeObserver` as HIGH

### View lifecycle awareness
- **`onDisappear` is not `deinit`.** In navigation stacks, popped views may call `onDisappear` but the view struct itself has no deinit. Cleanup logic for expensive resources must account for this — use `.task` for automatic cancellation or explicit cancellation in `onDisappear`

## Concurrency Correctness

### Main actor discipline
- **All UI state mutations must happen on `@MainActor`.** SwiftUI views are `@MainActor`-isolated. If a background task updates `@State` or an `@Observable` property that drives UI, the update must be dispatched to the main actor. In Swift 6, the compiler enforces this. Flag cross-actor state mutation without explicit main actor dispatch as CRITICAL
- **`@MainActor` on Observable types:** Types marked `@Observable` that are used by SwiftUI views should typically be `@MainActor`-isolated. This ensures all property access from views is safe. Flag `@Observable` types without `@MainActor` that are used in views as HIGH

### Blocking the UI thread
- **Synchronous work on main actor:** Any operation that takes more than ~16ms (one frame at 60fps) blocks the UI. File I/O, JSON parsing of large payloads, image processing, network calls — all must be on a background actor or task. Flag synchronous heavy work in view body, `onAppear`, or `@MainActor` methods as CRITICAL
- **`await` in view context:** `await` in `.task { }` suspends the task, not the UI thread — this is safe. But `await` in a `@MainActor` method does block the main actor until the awaited work returns to the main actor. Long `await` chains on `@MainActor` can cause perceptible UI freezes

### Task lifecycle
- **`.task { }` is the correct way to launch async work from views.** It auto-cancels when the view disappears and respects the view's lifecycle. Flag `Task { }` in `init()` or `onAppear` as MEDIUM — use `.task` modifier instead
- **Task cancellation checking:** Long-running tasks must check `Task.isCancelled` or use `try Task.checkCancellation()` at appropriate points. A task that ignores cancellation continues consuming resources after the view is gone
- **Structured concurrency preference:** Prefer `TaskGroup` over spawning multiple unstructured `Task { }` instances. Unstructured tasks are harder to cancel, harder to track, and easier to leak

### Sendable compliance
- **Data crossing actor boundaries must be Sendable.** In Swift 6 strict concurrency, passing non-Sendable types across actor boundaries is a compile error. Review for types that cross boundaries (model objects passed to background tasks) and verify Sendable conformance. Flag non-Sendable types used across actor boundaries as HIGH

## Data Flow

### SwiftData usage
- **`@Query` is the primary data access pattern in views.** Direct `ModelContext` queries in view body are usually wrong — they don't auto-update when data changes. Flag manual fetch in body when `@Query` would work as MEDIUM
- **ModelContext threading:** `ModelContext` is not thread-safe. Access from a background task requires `@ModelActor`. Flag `ModelContext` usage outside the main actor without `@ModelActor` as CRITICAL
- **Relationship access:** SwiftData relationships are lazy-loaded. Accessing a relationship in a `ForEach` that iterates hundreds of items triggers hundreds of individual fetches. Flag and recommend prefetching or restructuring the query

### CloudKit sync considerations
- **All SwiftData properties must have defaults or be optional** when using CloudKit sync. Non-optional properties without defaults will crash when CloudKit delivers a partial record. Flag non-optional, no-default properties in CloudKit-synced models as CRITICAL
- **Conflict resolution:** CloudKit sync can create duplicates. The app must handle merge conflicts gracefully. Flag absence of duplicate detection/resolution in CloudKit-synced apps as HIGH
- **Eventual consistency:** CloudKit data arrives asynchronously. UI must handle the intermediate state where local data and cloud data diverge. Flag UI that assumes instant sync as MEDIUM

### UserDefaults boundaries
- **UserDefaults is for simple preferences only.** Not for structured data, not for large values (>1MB), not for sensitive data (use Keychain), not for data that needs querying. Flag UserDefaults storing arrays of model objects, JSON blobs, or anything that should be in SwiftData as HIGH
- **`@AppStorage` type limitations:** `@AppStorage` supports `String`, `Int`, `Double`, `Bool`, `URL`, and `Data`. Storing complex types via `Data` encoding is fragile and loses type safety. Flag `@AppStorage` with `Data`-encoded complex types as MEDIUM
