# SwiftUI Patterns Reference

Comprehensive reference for building SwiftUI interfaces across all Apple platforms. Covers architecture, state management, navigation, layout, accessibility, and platform-adaptive design.

## Table of Contents
1. [Architecture and State Management](#architecture-and-state-management)
2. [Navigation](#navigation)
3. [Layout System](#layout-system)
4. [Lists, Grids, and Collections](#lists-grids-and-collections)
5. [Animations and Transitions](#animations-and-transitions)
6. [Previews](#previews)
7. [Accessibility](#accessibility)
8. [Platform-Adaptive Design](#platform-adaptive-design)
9. [Widgets and App Intents](#widgets-and-app-intents)
10. [Common Anti-Patterns](#common-anti-patterns)

---

## Architecture and State Management

### The SwiftUI mental model
In SwiftUI, **views are a function of state**. You declare what the UI should look like for a given state, and SwiftUI handles the diffing and updating. Views are lightweight value types — creating them is cheap. The framework calls `body` whenever relevant state changes.

### State ownership hierarchy

**`@State`** — View owns the data. Use for simple, view-local state:
```swift
struct CounterView: View {
    @State private var count = 0

    var body: some View {
        Button("Count: \(count)") { count += 1 }
    }
}
```

**`@Binding`** — View borrows a reference to state owned elsewhere:
```swift
struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(title, isOn: $isOn)
    }
}
```

**`@Observable` (modern)** — Observable class for shared state. Replaces `ObservableObject`:
```swift
@Observable
class AppState {
    var currentUser: User?
    var selectedTab: Tab = .home
    var isOnboarded = false
}

// In views — no wrapper needed for read-only, @Bindable for mutations
struct ProfileView: View {
    var appState: AppState // read-only access

    var body: some View {
        if let user = appState.currentUser {
            Text(user.name)
        }
    }
}

struct SettingsView: View {
    @Bindable var appState: AppState // for $ bindings

    var body: some View {
        Toggle("Onboarded", isOn: $appState.isOnboarded)
    }
}
```

**`@State` with `@Observable`** — View owns the observable object's lifecycle:
```swift
struct ContentView: View {
    @State private var viewModel = ContentViewModel()

    var body: some View {
        List(viewModel.items) { item in
            Text(item.name)
        }
        .task { await viewModel.load() }
    }
}
```

**`@Environment`** — Inject dependencies through the view hierarchy:
```swift
// Define custom environment values
extension EnvironmentValues {
    @Entry var analyticsClient: AnalyticsClient = .live
}

// Inject
ContentView()
    .environment(\.analyticsClient, .mock)

// Read
struct FeatureView: View {
    @Environment(\.analyticsClient) var analytics
}
```

**`@Query`** — SwiftData fetching. Lives in views, reacts to data changes:
```swift
struct TaskListView: View {
    @Query(sort: \TaskItem.dueDate) var tasks: [TaskItem]

    var body: some View {
        List(tasks) { task in
            TaskRow(task: task)
        }
    }
}
```

### Where does logic live?
- **Simple view logic** (formatting, conditional display): In the view's `body` or computed properties
- **Business logic** (fetching, transforming, saving): In `@Observable` models or standalone functions
- **Data fetching and persistence**: SwiftData `@Query` in views, mutations via `ModelContext` in model methods or view actions
- **Navigation state**: In the view hierarchy using `NavigationStack` path, or a dedicated navigation model

### The "views are the view model" principle
Apple's recommended pattern for SwiftUI is simpler than traditional MVVM. Views can own state and logic directly. A separate ViewModel class is appropriate when:
- Logic is complex enough to warrant isolation for testing
- Multiple views share the same state/logic
- You need to coordinate multiple async operations

Don't create a ViewModel for every view reflexively.

## Navigation

### NavigationStack (iOS 16+)
```swift
struct AppView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView()
                .navigationDestination(for: Product.self) { product in
                    ProductDetailView(product: product)
                }
                .navigationDestination(for: Category.self) { category in
                    CategoryView(category: category)
                }
        }
    }
}

// Push programmatically
Button("View Product") {
    path.append(product)
}
```

### NavigationSplitView (multicolumn, iPad/Mac)
```swift
struct AppView: View {
    @State private var selectedCategory: Category?
    @State private var selectedItem: Item?

    var body: some View {
        NavigationSplitView {
            CategorySidebar(selection: $selectedCategory)
        } content: {
            if let category = selectedCategory {
                ItemList(category: category, selection: $selectedItem)
            }
        } detail: {
            if let item = selectedItem {
                ItemDetailView(item: item)
            } else {
                ContentUnavailableView("Select an item", systemImage: "doc")
            }
        }
    }
}
```

### TabView
```swift
struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                HomeView()
            }
            Tab("Search", systemImage: "magnifyingglass", value: .search) {
                SearchView()
            }
            Tab("Profile", systemImage: "person", value: .profile) {
                ProfileView()
            }
        }
    }
}
```

### Sheet, fullScreenCover, alert, confirmationDialog
```swift
struct ParentView: View {
    @State private var showSettings = false
    @State private var itemToDelete: Item?

    var body: some View {
        content
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("Delete Item?",
                   isPresented: .init(
                       get: { itemToDelete != nil },
                       set: { if !$0 { itemToDelete = nil } }
                   )
            ) {
                Button("Delete", role: .destructive) {
                    delete(itemToDelete!)
                }
            }
    }
}
```

## Layout System

### Core layout containers
- `VStack` / `HStack` / `ZStack` — basic stacking
- `Grid` — two-dimensional alignment (iOS 16+)
- `ViewThatFits` — automatically picks the first child that fits (great for adaptive layouts)
- `GeometryReader` — last resort for reading size. Avoid when possible — it makes views eager instead of lazy and breaks layout negotiation

### Sizing
```swift
Text("Hello")
    .frame(maxWidth: .infinity, alignment: .leading) // fill width, left-aligned
    .padding()

// Fixed aspect ratio
Image("photo")
    .resizable()
    .aspectRatio(16/9, contentMode: .fit)

// Minimum touch target (HIG: 44pt)
Button("Tap") { }
    .frame(minWidth: 44, minHeight: 44)
```

### Spacing and padding
Use system spacing. Don't hardcode pixel values for standard gaps:
```swift
VStack(spacing: 16) { ... }  // explicit but consistent
VStack { ... }.padding()       // system default padding (usually 16pt)
```

### Safe areas
Respect safe areas by default. Only ignore them intentionally:
```swift
// Extends behind status bar / home indicator
Color.blue.ignoresSafeArea()

// Content respects safe area by default — this is correct
ScrollView {
    content.padding()
}
```

## Lists, Grids, and Collections

### List
```swift
List {
    Section("Active") {
        ForEach(activeItems) { item in
            ItemRow(item: item)
        }
        .onDelete(perform: deleteItems)
        .onMove(perform: moveItems)
    }
    Section("Completed") {
        ForEach(completedItems) { item in
            ItemRow(item: item)
        }
    }
}
.listStyle(.insetGrouped)
```

### LazyVGrid / LazyHGrid
```swift
let columns = [GridItem(.adaptive(minimum: 150, maximum: 200))]

LazyVGrid(columns: columns, spacing: 16) {
    ForEach(items) { item in
        ItemCard(item: item)
    }
}
```

### Performance
- Use `List` or `LazyVStack` for large datasets — they only instantiate visible rows
- Give each item a stable, unique `id` (conform to `Identifiable`)
- Avoid expensive computed properties in `body` — precompute in the model
- Use `EquatableView` or `@Observable` property-level tracking to minimize redraws

## Animations and Transitions

```swift
// Implicit animation
Text(score.description)
    .animation(.spring, value: score)

// Explicit animation
withAnimation(.easeInOut(duration: 0.3)) {
    showDetail.toggle()
}

// Transitions
if showDetail {
    DetailView()
        .transition(.move(edge: .bottom).combined(with: .opacity))
}

// Matched geometry for hero animations
@Namespace private var namespace

// In source view:
Image(item.photo)
    .matchedGeometryEffect(id: item.id, in: namespace)

// In destination view:
Image(item.photo)
    .matchedGeometryEffect(id: item.id, in: namespace)
```

### Animation principles
- Use `.spring` as the default animation curve — it feels natural on Apple platforms
- Keep durations short (0.2-0.4s) for UI state changes
- Use `withAnimation` for discrete state changes; `.animation(_:value:)` for continuous
- Always provide a `value` parameter to `.animation()` to avoid surprising over-animation

## Previews

Previews are central to the SwiftUI development workflow. Structure code to be previewable:

```swift
#Preview("Default State") {
    TaskListView()
        .modelContainer(previewContainer)
}

#Preview("Empty State") {
    TaskListView()
        .modelContainer(emptyContainer)
}

#Preview("Loading") {
    TaskListView()
        .environment(\.dataState, .loading)
}
```

Design for previewability:
- Inject dependencies via `@Environment` or initializer parameters
- Create preview-specific containers for SwiftData
- Test multiple states: empty, loading, error, populated
- Preview on multiple device sizes

## Accessibility

Accessibility is not optional. It's a quality bar and an App Store review criterion.

### Essential checklist
- **Labels:** Every interactive element needs an accessibility label
- **Touch targets:** Minimum 44×44 points
- **Dynamic Type:** All text must scale. Use system fonts or scalable custom fonts
- **Color contrast:** Minimum 4.5:1 for body text, 3:1 for large text
- **VoiceOver navigation:** Test the full app flow with VoiceOver
- **Reduce Motion:** Respect `accessibilityReduceMotion`

```swift
Button(action: share) {
    Image(systemName: "square.and.arrow.up")
}
.accessibilityLabel("Share")
.accessibilityHint("Opens sharing options")

Text(item.title)
    .font(.body) // scales with Dynamic Type automatically
    .minimumScaleFactor(0.8) // allows slight shrinking before truncation
```

### Semantic grouping
```swift
HStack {
    Image(systemName: "star.fill")
    Text("4.8")
    Text("(120 reviews)")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Rated 4.8 out of 5 with 120 reviews")
```

## Platform-Adaptive Design

### Detecting platform
```swift
#if os(iOS)
// iPhone/iPad specific
#elseif os(macOS)
// Mac specific
#elseif os(watchOS)
// Watch specific
#elseif os(visionOS)
// Vision Pro specific
#endif
```

### Responsive layouts
```swift
struct AdaptiveView: View {
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        if sizeClass == .compact {
            VStack { content }
        } else {
            HStack { content }
        }
    }
}

// Better: let the system decide
ViewThatFits {
    HStack { wideContent }
    VStack { narrowContent }
}
```

### macOS considerations
- Use `Settings` scene for preferences
- Support keyboard shortcuts (`.keyboardShortcut()`)
- Toolbars behave differently — use `.toolbar` with proper placement
- Menus via `commands` modifier on `WindowGroup`
- Window management: `Window`, `WindowGroup`, `DocumentGroup`

## Widgets and App Intents

### WidgetKit
```swift
struct MyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MyWidget", provider: MyProvider()) { entry in
            MyWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("My Widget")
        .description("Shows the latest data")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}
```

### App Intents (iOS 16+)
Make features available to Siri, Shortcuts, and Spotlight:
```swift
struct OpenTask: AppIntent {
    static var title: LocalizedStringResource = "Open Task"
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Task")
    var task: TaskEntity

    func perform() async throws -> some IntentResult {
        NavigationModel.shared.navigate(to: task)
        return .result()
    }
}
```

## Common Anti-Patterns

### ❌ GeometryReader for simple sizing
```swift
// Bad: GeometryReader to make something full-width
GeometryReader { proxy in
    Text("Hello").frame(width: proxy.size.width)
}
// Good: use frame modifier
Text("Hello").frame(maxWidth: .infinity)
```

### ❌ ObservableObject in new code
```swift
// Legacy
class ViewModel: ObservableObject {
    @Published var items: [Item] = []
}
// Modern
@Observable
class ViewModel {
    var items: [Item] = []
}
```

### ❌ onAppear + Task instead of .task
```swift
// Bad: manual task management, no auto-cancellation
.onAppear {
    Task { await load() }
}
// Good: auto-cancels when view disappears
.task { await load() }
```

### ❌ Passing ModelContext around
```swift
// Bad: threading ModelContext through initializers
DetailView(item: item, context: modelContext)
// Good: read from environment
struct DetailView: View {
    @Environment(\.modelContext) var modelContext
    let item: Item
}
```

### ❌ Over-abstracting with ViewModels everywhere
Not every view needs a ViewModel. Simple views can own their state and logic. Extract a ViewModel when the logic is complex enough to test independently or when multiple views share it.
