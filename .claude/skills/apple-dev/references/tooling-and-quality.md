# Tooling, Testing, and Quality Reference

Xcode, Swift Package Manager, testing, profiling, CI/CD, and App Store workflow.

## Table of Contents
1. [Swift Package Manager](#swift-package-manager)
2. [Project Organization](#project-organization)
3. [Testing](#testing)
4. [Instruments and Profiling](#instruments-and-profiling)
5. [Debugging Techniques](#debugging-techniques)
6. [CI/CD and Automation](#cicd-and-automation)
7. [App Store Submission](#app-store-submission)

---

## Swift Package Manager

SPM is the standard. Don't use CocoaPods or Carthage for new projects.

### Package structure
```swift
// Package.swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MyFeature", targets: ["MyFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/example/SomeDep.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "MyFeature",
            dependencies: ["SomeDep"]
        ),
        .testTarget(
            name: "MyFeatureTests",
            dependencies: ["MyFeature"]
        ),
    ]
)
```

### Local packages for modularization
Create local packages within your Xcode project for feature modules:
```
MyApp/
├── MyApp.xcodeproj
├── MyApp/            (app target)
├── Packages/
│   ├── Core/         (shared models, networking)
│   ├── FeatureA/     (feature module)
│   └── FeatureB/     (feature module)
```

Benefits: faster incremental builds, enforced dependency boundaries, reusability, testability in isolation.

### Dependency management rules
- Pin to exact versions or tight ranges for critical dependencies
- Audit dependencies before adding. Check: maintenance activity, Swift 6 compatibility, license
- Minimize third-party dependencies. Many common tasks (networking, JSON, image loading) are well-served by Apple's APIs
- Use `.upToNextMinor(from:)` for dependencies you trust, `.exact()` for everything else

## Project Organization

### Recommended structure
```
Sources/
├── App/
│   ├── MyApp.swift              (entry point)
│   └── AppDelegate.swift        (if needed for push, etc.)
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift  (if complex enough)
│   │   └── Components/
│   ├── Settings/
│   └── Profile/
├── Models/
│   ├── Task.swift               (@Model types)
│   └── User.swift
├── Services/
│   ├── APIClient.swift
│   └── AuthService.swift
├── Shared/
│   ├── Components/              (reusable views)
│   ├── Extensions/
│   └── Utilities/
└── Resources/
    ├── Assets.xcassets
    └── Localizable.xcstrings
```

### File organization principles
- One primary type per file
- Group by feature, not by type (don't have a "Views" folder with 50 files)
- Keep files small. If a view file exceeds 200 lines, consider extracting subviews
- Use `// MARK: -` for sections within a file

## Testing

### Swift Testing framework (modern, preferred)
```swift
import Testing
@testable import MyFeature

@Suite("TaskManager Tests")
struct TaskManagerTests {
    let manager: TaskManager

    init() {
        manager = TaskManager(store: MockStore())
    }

    @Test("Creating a task sets default values")
    func createTask() throws {
        let task = manager.createTask(title: "Test")
        #expect(task.title == "Test")
        #expect(task.isCompleted == false)
        #expect(task.priority == .medium)
    }

    @Test("Completing a task updates timestamp")
    func completeTask() async throws {
        let task = manager.createTask(title: "Test")
        try await manager.complete(task)
        #expect(task.isCompleted == true)
        #expect(task.completedAt != nil)
    }

    @Test("Priority filtering", arguments: [
        (Priority.high, 3),
        (Priority.medium, 5),
        (Priority.low, 2),
    ])
    func filterByPriority(priority: Priority, expectedCount: Int) {
        let filtered = manager.tasks(withPriority: priority)
        #expect(filtered.count == expectedCount)
    }
}
```

### XCTest (legacy, still needed for UI tests)
```swift
import XCTest
@testable import MyFeature

final class TaskManagerXCTests: XCTestCase {
    var sut: TaskManager!

    override func setUp() {
        super.setUp()
        sut = TaskManager(store: MockStore())
    }

    func testCreateTask() {
        let task = sut.createTask(title: "Test")
        XCTAssertEqual(task.title, "Test")
    }
}
```

### UI Testing
```swift
final class TaskFlowUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    func testCreateAndCompleteTask() {
        app.buttons["Add Task"].tap()
        app.textFields["Task Title"].typeText("Buy groceries")
        app.buttons["Save"].tap()

        let cell = app.cells.staticTexts["Buy groceries"]
        XCTAssertTrue(cell.waitForExistence(timeout: 3))

        cell.swipeLeft()
        app.buttons["Complete"].tap()
    }
}
```

### Testing SwiftData
```swift
@Suite("TaskPersistence")
struct TaskPersistenceTests {
    @Test("Tasks persist and query correctly")
    func persistenceRoundTrip() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Task.self, configurations: config)
        let context = ModelContext(container)

        let task = Task(title: "Test")
        context.insert(task)
        try context.save()

        let descriptor = FetchDescriptor<Task>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "Test")
    }
}
```

### Testing async code
```swift
@Test("Network fetch returns data")
func fetchProducts() async throws {
    let client = APIClient(session: mockSession)
    let products = try await client.get("/products") as [Product]
    #expect(!products.isEmpty)
}
```

### Testing best practices
- Test behavior, not implementation. Assert on outcomes, not internal state
- Use in-memory containers for SwiftData tests
- Mock external dependencies (network, location, etc.) via protocols
- Test error paths, not just happy paths
- Keep tests fast — mock I/O, avoid real network calls
- Use `@Suite` grouping in Swift Testing for logical organization

## Instruments and Profiling

### Key Instruments templates
- **Time Profiler:** CPU usage and hot paths. Start here for "the app feels slow"
- **Allocations:** Memory usage, allocation patterns, leaks
- **Leaks:** Retain cycle detection
- **SwiftUI Performance (new):** View body evaluations, state change frequency. Essential for SwiftUI optimization
- **Network:** Request timing, payload sizes
- **Core Data / SwiftData:** Fetch counts, fault resolution, cache behavior
- **Animation Hitches:** Frame drops and their causes
- **Energy Log:** Battery impact

### SwiftUI-specific profiling
The SwiftUI Performance instrument (Xcode 16+) tracks:
- How often `body` is called per view
- Which state changes trigger updates
- Unnecessary recomputations

Common findings:
- Views recomputing because a parent's unrelated state changed → extract into separate views
- `@Observable` models causing updates for properties the view doesn't use → split into focused models
- Expensive computations in `body` → precompute or cache
- Large `ForEach` without lazy container → use `List` or `LazyVStack`

### Memory debugging
```swift
// In debug builds, watch for:
// 1. Retain cycles in closures — use [weak self]
// 2. Strong references in observation — @Observable handles this, but custom observation might not
// 3. Large image caches — set limits, respond to memory warnings
```

## Debugging Techniques

### LLDB essentials
```
po expression          // print object description
p expression           // print value
v variable             // faster than p for local variables
e expression           // evaluate (can modify state)
bt                     // backtrace
br set -n functionName // set breakpoint
```

### SwiftUI debugging
```swift
// Print when body evaluates
let _ = Self._printChanges() // inside body — shows which state triggered update

// Debug view hierarchy
.background(Color.random) // visualize view boundaries
```

### Concurrency debugging
- Enable Thread Sanitizer in scheme settings to catch data races at runtime
- Enable "Strict Concurrency Checking" in build settings (it's the default in Swift 6)
- Use `#isolation` to print current isolation context in debug builds
- Actor reentrancy issues: add logging around `await` points in actors

### Network debugging
- Use `URLProtocol` subclass to intercept and log all requests
- Charles Proxy or Proxyman for HTTPS inspection
- `CFNetworkDiagnostics` environment variable for low-level networking logs

## CI/CD and Automation

### Xcode Cloud
Apple's integrated CI/CD. Configured via Xcode or App Store Connect:
- Triggered by: push, PR, tag, schedule
- Workflows: build, test, archive, distribute
- Custom scripts: `ci_scripts/ci_post_clone.sh`, `ci_pre_xcodebuild.sh`, etc.

### Command-line builds
```bash
# Build
xcodebuild build \
    -scheme MyApp \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -configuration Debug

# Test
xcodebuild test \
    -scheme MyApp \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -resultBundlePath TestResults.xcresult

# Archive for distribution
xcodebuild archive \
    -scheme MyApp \
    -archivePath build/MyApp.xcarchive \
    -destination 'generic/platform=iOS'
```

### Fastlane (community standard)
```ruby
lane :beta do
    increment_build_number
    build_app(scheme: "MyApp")
    upload_to_testflight
end
```

### GitHub Actions with Xcode
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.app
      - name: Test
        run: xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 16'
```

## App Store Submission

### Pre-submission checklist
- [ ] All required app icons (1024×1024 single source in asset catalog)
- [ ] Launch screen configured (storyboard or Info.plist keys)
- [ ] Privacy manifest (`PrivacyInfo.xcprivacy`) with required API declarations
- [ ] App Tracking Transparency if using tracking
- [ ] Required device capabilities declared in Info.plist
- [ ] All required App Store metadata (screenshots, description, keywords)
- [ ] Tested on minimum supported OS version
- [ ] Accessibility audit passed
- [ ] No private API usage
- [ ] Proper entitlements for used capabilities

### Code signing
- **Automatic signing:** Let Xcode manage. Works for most cases
- **Manual signing:** Needed for complex setups (enterprise, multiple teams, CI/CD)
- **Provisioning profiles:** Development, Ad Hoc, App Store. Xcode Cloud and Xcode manage these automatically with automatic signing

### Privacy manifest (required since Spring 2024)
```xml
<!-- PrivacyInfo.xcprivacy -->
<!-- Declare all required reason APIs your app uses -->
<!-- Common: UserDefaults, file timestamp, disk space, etc. -->
```

### App Review tips
- Provide demo account credentials if login is required
- Include notes explaining non-obvious features
- Respond promptly to review feedback
- Test on the latest stable OS before submission
- Ensure all URLs (privacy policy, support) are live and accessible
