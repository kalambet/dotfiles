# Swift Language Reference

Modern Swift patterns, idioms, and the complete concurrency model. This is the foundation — everything else builds on writing good Swift.

## Table of Contents
1. [Swift-First Principles](#swift-first-principles)
2. [Value Types and Data Modeling](#value-types-and-data-modeling)
3. [Protocols and Generics](#protocols-and-generics)
4. [Error Handling](#error-handling)
5. [Property Wrappers and Macros](#property-wrappers-and-macros)
6. [Swift 6 Concurrency Model](#swift-6-concurrency-model)
7. [Swift 6.2 Approachable Concurrency](#swift-62-approachable-concurrency)
8. [Memory Management](#memory-management)
9. [Interop: When Objective-C Is Unavoidable](#interop-when-objective-c-is-unavoidable)

---

## Swift-First Principles

Swift is an opinionated language. Embrace its opinions:

- **Value semantics by default.** Use structs, enums, and tuples. Reach for classes only when you need identity (actors, observable models, SwiftData `@Model` types), inheritance (rare), or interop
- **Immutability by default.** Use `let` unless mutation is required. Functions on value types that mutate should be `mutating`
- **Type safety is a feature, not overhead.** Use the type system to make illegal states unrepresentable. Enums with associated values are one of Swift's most powerful tools
- **Protocol-oriented over object-oriented.** Define behavior through protocols, provide defaults through extensions. But don't create a protocol for every type — only when you have multiple conformers or need testability abstraction
- **Composition over inheritance.** Favor embedding types and protocol composition (`SomeProtocol & AnotherProtocol`) over deep class hierarchies

## Value Types and Data Modeling

### Structs as the default
```swift
struct Temperature {
    var celsius: Double

    var fahrenheit: Double {
        celsius * 9 / 5 + 32
    }

    var kelvin: Double {
        celsius + 273.15
    }
}
```

### Enums for state modeling
Use enums to make invalid states impossible:

```swift
// Bad: multiple booleans with impossible combinations
struct LoadingState {
    var isLoading: Bool
    var error: Error?
    var data: [Item]?
    // Can isLoading be true AND error be non-nil? Unclear.
}

// Good: exactly one state at a time
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case failed(Error)
}
```

### When to use classes
Legitimate class use cases in modern Swift:
- `@Observable` models (the Observation framework requires reference types)
- SwiftData `@Model` types (persistence requires identity)
- Actors (special reference types with isolation)
- Interfacing with Objective-C/C APIs
- When you genuinely need shared mutable state with identity semantics

## Protocols and Generics

### Protocol design
```swift
// Good: focused protocol with clear purpose
protocol DataFetching {
    associatedtype Item
    func fetch(id: String) async throws -> Item
    func fetchAll() async throws -> [Item]
}

// Use protocol to enable testing
struct ProductionFetcher: DataFetching {
    func fetch(id: String) async throws -> Product { /* real implementation */ }
    func fetchAll() async throws -> [Product] { /* real implementation */ }
}

struct MockFetcher: DataFetching {
    var mockItems: [Product] = []
    func fetch(id: String) async throws -> Product { mockItems.first! }
    func fetchAll() async throws -> [Product] { mockItems }
}
```

### When NOT to protocol
Don't create protocols for:
- Types with only one conformer (unless you genuinely plan testability via mock)
- Simple data containers — just use a struct
- "Future flexibility" — you can always extract a protocol later when you need it

### Generics
Prefer constrained generics over `Any`:
```swift
// Prefer
func process<T: Codable>(_ item: T) -> Data { ... }

// Over
func process(_ item: Any) -> Data { ... }
```

Use `some` for opaque return types and `any` for existential types:
```swift
// Opaque: caller doesn't know the concrete type, but it's fixed
func makeView() -> some View { ... }

// Existential: multiple concrete types behind one interface
func allFetchers() -> [any DataFetching] { ... }
```

## Error Handling

### Typed throws (Swift 6)
```swift
enum NetworkError: Error {
    case noConnection
    case timeout
    case serverError(statusCode: Int)
    case decodingFailed(underlying: Error)
}

// Typed throws: callers know exactly what errors to expect
func fetchUser(id: String) throws(NetworkError) -> User {
    // ...
}
```

### Error handling patterns
```swift
// Pattern 1: Propagate — let the caller decide
func loadProfile() async throws -> Profile {
    let data = try await networkClient.fetch("/profile")
    return try JSONDecoder().decode(Profile.self, from: data)
}

// Pattern 2: Handle and transform at boundaries
func loadProfile() async -> LoadingState<Profile> {
    do {
        let profile = try await profileService.loadProfile()
        return .loaded(profile)
    } catch is URLError {
        return .failed(AppError.networkUnavailable)
    } catch {
        return .failed(AppError.unexpected(error))
    }
}

// Pattern 3: Optional for "I don't care why it failed"
let user = try? await fetchUser(id: "123")
```

## Property Wrappers and Macros

### Key property wrappers
- `@State` — SwiftUI view-owned value storage
- `@Binding` — two-way reference to a `@State`
- `@Environment` — read values from the SwiftUI environment
- `@AppStorage` — UserDefaults-backed storage for simple values
- `@SceneStorage` — scene-level state restoration

### Key macros
- `@Observable` — makes a class observable (Observation framework)
- `@Model` — SwiftData persistent model
- `@Query` — SwiftData fetch in SwiftUI views
- `#Predicate` — type-safe predicates for SwiftData queries
- `@Entry` — custom EnvironmentValues entries

### Writing custom macros
Swift macros are powerful but complex. Use them when:
- You're eliminating significant boilerplate across many types
- The generated code is predictable and debuggable
- The macro has clear, focused purpose

Don't use them for: one-off code generation, complex logic that belongs in runtime code, or cases where a protocol extension suffices.

## Swift 6 Concurrency Model

### The mental model
Swift concurrency has three key concepts:
1. **async/await** — suspend execution without blocking a thread
2. **Structured concurrency** — tasks form parent-child hierarchies; cancellation propagates; resources clean up
3. **Actor isolation** — protect mutable state from data races at compile time

### async/await basics
```swift
func fetchWeather(for city: String) async throws -> Weather {
    let url = URL(string: "https://api.weather.com/\(city)")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(Weather.self, from: data)
}
```

### Structured concurrency with TaskGroup
```swift
func fetchAllImages(urls: [URL]) async throws -> [UIImage] {
    try await withThrowingTaskGroup(of: (Int, UIImage).self) { group in
        for (index, url) in urls.enumerated() {
            group.addTask {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else {
                    throw ImageError.invalidData
                }
                return (index, image)
            }
        }
        var results = [Int: UIImage]()
        for try await (index, image) in group {
            results[index] = image
        }
        return urls.indices.map { results[$0]! }
    }
}
```

### Actors
```swift
actor ImageCache {
    private var cache: [URL: UIImage] = [:]

    func image(for url: URL) -> UIImage? {
        cache[url]
    }

    func store(_ image: UIImage, for url: URL) {
        cache[url] = image
    }
}

// Usage — `await` required because crossing isolation boundary
let cached = await imageCache.image(for: url)
```

### @MainActor
All UI work must happen on the main actor. SwiftUI views are already `@MainActor`. Your view models / observable models typically should be too:

```swift
@MainActor
@Observable
class ProfileViewModel {
    var profile: Profile?
    var isLoading = false

    func load() async {
        isLoading = true
        defer { isLoading = false }
        profile = try? await profileService.fetch()
    }
}
```

### Sendable
`Sendable` marks types that are safe to pass across concurrency domains:
- Value types (structs, enums) with all-Sendable stored properties are implicitly Sendable
- Actors are Sendable
- Classes must be `final` with immutable stored properties, or use manual synchronization with `@unchecked Sendable`

**Avoid `@unchecked Sendable`** unless you truly understand the synchronization guarantees. The compiler is usually right when it complains.

### Task cancellation
Always check for cancellation in long-running work:
```swift
func processItems(_ items: [Item]) async throws {
    for item in items {
        try Task.checkCancellation()
        await process(item)
    }
}
```

In SwiftUI, `.task { }` automatically cancels when the view disappears.

## Swift 6.2 Approachable Concurrency

Swift 6.2 makes concurrency significantly more ergonomic. Key changes:

### Default main actor isolation
New projects in Xcode 26 default to `@MainActor` isolation for all code. This means:
- Your code runs on the main thread by default — no more accidental concurrency
- You opt INTO concurrency explicitly with `@concurrent`
- This eliminates the most common class of concurrency bugs

Enable via build setting: `SWIFT_APPROACHABLE_CONCURRENCY = YES`

### @concurrent attribute
When you need work off the main actor, explicitly mark it:
```swift
@concurrent
func processLargeDataset(_ data: [DataPoint]) async -> ProcessedResult {
    // This runs off the main actor — explicitly chosen
    // ...
}
```

### nonisolated(nonsending) default
In Swift 6.2, `nonisolated async` functions run in the caller's isolation context by default (not on the global concurrent executor). This prevents accidental thread hops:
```swift
// Swift 6.2: stays on caller's actor (main actor if called from @MainActor)
nonisolated func helper() async { ... }

// Explicitly concurrent: runs on global executor
@concurrent
nonisolated func heavyWork() async { ... }
```

### Progressive adoption path
1. **Phase 1:** Write simple sequential code. Default main actor isolation keeps it safe
2. **Phase 2:** Add `async/await` for I/O without introducing parallelism
3. **Phase 3:** Use `@concurrent` and structured concurrency when you need actual parallelism

## Memory Management

### ARC and retain cycles
Swift uses Automatic Reference Counting for class instances. Retain cycles occur when two objects hold strong references to each other.

```swift
// Capture lists to prevent retain cycles in closures
class ViewModel {
    var onComplete: (() -> Void)?

    func setup() {
        onComplete = { [weak self] in
            guard let self else { return }
            self.handleCompletion()
        }
    }
}
```

### When to use `weak` vs `unowned`
- `weak`: The referenced object might be deallocated. Use when the lifetime relationship is unclear
- `unowned`: You guarantee the referenced object outlives the reference. Crashes if accessed after deallocation. Use sparingly — `weak` is almost always safer

### SwiftUI and memory
SwiftUI manages view lifecycle. Common pitfalls:
- Storing closures that capture `self` strongly in `@Observable` classes
- Creating `Task {}` in views without `.task {}` (won't auto-cancel)
- Holding references to dismissed views through observation

## Interop: When Objective-C Is Unavoidable

### Legitimate remaining cases
1. **Method swizzling** — No Swift equivalent. Required for some debugging/analytics patterns
2. **Associated objects** — `objc_setAssociatedObject` has no Swift native API
3. **C libraries** — Some C/Objective-C frameworks have no Swift overlay
4. **KVO on non-Observable types** — Some legacy UIKit properties require Objective-C KVO
5. **Certain runtime introspection** — NSClassFromString, performSelector patterns

### The isolation pattern
```swift
// ObjCBridge.h (bridging header)
@interface ObjCBridge : NSObject
+ (void)swizzleMethod:(SEL)original with:(SEL)replacement on:(Class)cls;
@end

// Swift side — clean interface
enum RuntimeUtilities {
    static func swizzle(original: Selector, replacement: Selector, on cls: AnyClass) {
        ObjCBridge.swizzleMethod(original, with: replacement, on: cls)
    }
}
```

### Rules for Objective-C interop
- **Never** write new business logic in Objective-C
- Keep the bridging header as small as possible
- Wrap all Objective-C in a Swift-friendly API
- Document WHY Objective-C is required with a comment
- Revisit periodically — Apple may add Swift equivalents
