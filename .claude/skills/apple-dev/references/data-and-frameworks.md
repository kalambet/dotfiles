# Data, Persistence, and System Frameworks Reference

SwiftData, networking, and the Apple framework ecosystem. Covers data persistence, system integrations, and common framework usage patterns.

## Table of Contents
1. [SwiftData](#swiftdata)
2. [Core Data (Legacy)](#core-data-legacy)
3. [Networking](#networking)
4. [CloudKit and Sync](#cloudkit-and-sync)
5. [Local Storage](#local-storage)
6. [StoreKit 2](#storekit-2)
7. [System Frameworks Quick Reference](#system-frameworks-quick-reference)

---

## SwiftData

SwiftData is the modern persistence framework. It wraps Core Data with Swift-native syntax, integrates with the Observation framework, and works seamlessly with SwiftUI.

### Model definition
```swift
import SwiftData

@Model
class Task {
    var title: String
    var notes: String
    var dueDate: Date?
    var isCompleted: Bool
    var priority: Priority
    var category: Category?  // relationship

    @Relationship(deleteRule: .cascade, inverse: \Subtask.parent)
    var subtasks: [Subtask]

    init(title: String, priority: Priority = .medium) {
        self.title = title
        self.notes = ""
        self.isCompleted = false
        self.priority = priority
        self.subtasks = []
    }
}

enum Priority: Int, Codable {
    case low, medium, high, critical
}
```

### Container setup
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Task.self, Category.self])
    }
}

// Custom configuration
let config = ModelConfiguration(
    "MyStore",
    schema: Schema([Task.self]),
    isStoredInMemoryOnly: false,
    cloudKitDatabase: .automatic  // enables CloudKit sync
)
let container = try ModelContainer(for: Task.self, configurations: config)
```

### Querying in views
```swift
struct TaskListView: View {
    @Query(
        filter: #Predicate<Task> { !$0.isCompleted },
        sort: [SortDescriptor(\Task.dueDate)],
        animation: .default
    )
    var activeTasks: [Task]

    // Dynamic queries with parameters
    @Query var tasks: [Task]

    init(category: Category) {
        let id = category.persistentModelID
        _tasks = Query(
            filter: #Predicate<Task> { task in
                task.category?.persistentModelID == id
            }
        )
    }

    var body: some View {
        List(activeTasks) { task in
            TaskRow(task: task)
        }
    }
}
```

### CRUD operations
```swift
struct TaskListView: View {
    @Environment(\.modelContext) var modelContext

    func addTask() {
        let task = Task(title: "New Task")
        modelContext.insert(task)
        // Auto-saves — no manual save() needed in most cases
    }

    func deleteTask(_ task: Task) {
        modelContext.delete(task)
    }
}
```

### Concurrent operations with ModelActor
For background work, use SwiftData's actor-based concurrency:
```swift
@ModelActor
actor BackgroundProcessor {
    func importTasks(from data: [TaskDTO]) throws {
        for dto in data {
            let task = Task(title: dto.title)
            task.notes = dto.notes
            modelContext.insert(task)
        }
        try modelContext.save()
    }
}

// Usage
let processor = BackgroundProcessor(modelContainer: container)
try await processor.importTasks(from: importedData)
```

### Schema migration
```swift
enum TaskSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Task.self] }

    @Model class Task {
        var title: String
        var isCompleted: Bool
    }
}

enum TaskSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [Task.self] }

    @Model class Task {
        var title: String
        var isCompleted: Bool
        var priority: Int // new field
    }
}

enum TaskMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [TaskSchemaV1.self, TaskSchemaV2.self] }
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: TaskSchemaV1.self,
        toVersion: TaskSchemaV2.self
    )
}
```

### SwiftData best practices
- Let `@Query` drive view updates — it's the primary observation mechanism
- Use `@Model` directly in views. Creating a separate DTO layer adds overhead without clear benefit for most apps
- Use `#Predicate` for type-safe filtering. Avoid string-based predicates
- For testing, create in-memory containers: `ModelConfiguration(isStoredInMemoryOnly: true)`
- Use `@ModelActor` for background imports/exports. Never pass `@Model` objects across actor boundaries — use `PersistentIdentifier`
- Keep inheritance hierarchies shallow. SwiftData supports class inheritance in iOS 26+

## Core Data (Legacy)

Only relevant for existing codebases. For new projects, use SwiftData.

**Migration path to SwiftData:**
- SwiftData uses Core Data under the hood — same SQLite store
- You can coexist: access the same store from both Core Data and SwiftData
- Migrate incrementally: new features in SwiftData, legacy code stays Core Data
- `NSManagedObject` subclasses can be replaced with `@Model` classes one at a time

## Networking

### URLSession async/await
```swift
func fetchProducts() async throws -> [Product] {
    let url = URL(string: "https://api.example.com/products")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
        throw APIError.badResponse(response)
    }

    return try JSONDecoder().decode([Product].self, from: data)
}
```

### A lightweight API client
```swift
actor APIClient {
    private let session: URLSession
    private let baseURL: URL
    private let decoder = JSONDecoder()

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func get<T: Decodable>(_ path: String) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        let (data, response) = try await session.data(from: url)
        try validate(response)
        return try decoder.decode(T.self, from: data)
    }

    func post<T: Decodable, Body: Encodable>(_ path: String, body: Body) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)
        try validate(response)
        return try decoder.decode(T.self, from: data)
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.notHTTP
        }
        guard 200..<300 ~= http.statusCode else {
            throw APIError.httpError(http.statusCode)
        }
    }
}
```

### Streaming / SSE
For streaming responses (e.g., LLM APIs):
```swift
func streamResponse(url: URL) -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
        let task = Task {
            do {
                let (bytes, _) = try await URLSession.shared.bytes(from: url)
                for try await line in bytes.lines {
                    if line.hasPrefix("data: ") {
                        continuation.yield(String(line.dropFirst(6)))
                    }
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        continuation.onTermination = { _ in task.cancel() }
    }
}
```

### Image loading
Prefer `AsyncImage` for simple cases. For caching, consider a dedicated loader:
```swift
// Simple
AsyncImage(url: imageURL) { image in
    image.resizable().aspectRatio(contentMode: .fill)
} placeholder: {
    ProgressView()
}

// With caching — use an actor-based cache or a library like Kingfisher/Nuke
```

## CloudKit and Sync

### SwiftData + CloudKit
Enabling CloudKit with SwiftData is straightforward but has nuances:
```swift
let config = ModelConfiguration(cloudKitDatabase: .automatic)
```

**Key considerations:**
- All `@Model` properties must be optional or have defaults (CloudKit requirement)
- Sync is eventually consistent — UI must handle partial data gracefully
- Use `@Query` rather than accessing relationships directly for reliable updates
- CloudKit requires an Apple Developer account and iCloud entitlement
- Test with real devices — simulator CloudKit behavior differs

### CKContainer for custom CloudKit
For complex sync scenarios beyond automatic SwiftData sync:
```swift
let container = CKContainer.default()
let database = container.privateCloudDatabase

// Fetch
let query = CKQuery(recordType: "Note", predicate: NSPredicate(value: true))
let (results, _) = try await database.records(matching: query)
```

## Local Storage

### UserDefaults — simple values only
```swift
// SwiftUI integration
@AppStorage("hasOnboarded") var hasOnboarded = false
@AppStorage("theme") var theme: Theme = .system

// Suitable for: preferences, flags, small values
// NOT suitable for: large data, structured objects, sensitive data
```

### Keychain — sensitive data
Use Keychain for tokens, passwords, credentials:
```swift
// Wrap with a clean Swift API (Apple's Keychain API is C-based)
// Or use: KeychainAccess (third-party) or a custom wrapper
enum KeychainService {
    static func save(key: String, data: Data) throws { ... }
    static func load(key: String) throws -> Data? { ... }
    static func delete(key: String) throws { ... }
}
```

### File system
```swift
let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let fileURL = documentsURL.appendingPathComponent("export.json")

// Write
try data.write(to: fileURL)

// Read
let loaded = try Data(contentsOf: fileURL)
```

## StoreKit 2

Modern in-app purchase API with async/await:
```swift
import StoreKit

// Fetch products
let products = try await Product.products(for: ["premium_monthly", "premium_yearly"])

// Purchase
let result = try await product.purchase()
switch result {
case .success(let verification):
    let transaction = try checkVerified(verification)
    // Deliver content
    await transaction.finish()
case .userCancelled:
    break
case .pending:
    // Wait for approval (e.g., Ask to Buy)
    break
@unknown default:
    break
}

// Listen for transaction updates
func listenForTransactions() -> Task<Void, Never> {
    Task.detached {
        for await result in Transaction.updates {
            guard let transaction = try? self.checkVerified(result) else { continue }
            await self.updateSubscriptionStatus()
            await transaction.finish()
        }
    }
}

// Subscription status UI
SubscriptionStoreView(groupID: "premium") {
    PremiumMarketingContent()
}
.subscriptionStoreControlStyle(.prominentPicker)
```

## System Frameworks Quick Reference

### Core Location
```swift
// Modern: CLLocationUpdate (iOS 17+)
let updates = CLLocationUpdate.liveUpdates()
for try await update in updates {
    if let location = update.location {
        handleLocation(location)
    }
}
```

### MapKit
```swift
import MapKit

struct MapView: View {
    @State private var position = MapCameraPosition.automatic

    var body: some View {
        Map(position: $position) {
            ForEach(locations) { location in
                Marker(location.name, coordinate: location.coordinate)
            }
        }
    }
}
```

### AVFoundation
```swift
// Camera preview
import AVFoundation

actor CameraManager {
    private let session = AVCaptureSession()

    func configure() throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.noDevice
        }
        let input = try AVCaptureDeviceInput(device: device)
        session.addInput(input)
    }
}
```

### Push Notifications
```swift
// Request permission
let center = UNUserNotificationCenter.current()
let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])

// Register for remote
UIApplication.shared.registerForRemoteNotifications()

// Handle in AppDelegate or App struct
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    // Send to server
}
```

### HealthKit
```swift
let store = HKHealthStore()

// Request authorization
let types: Set<HKSampleType> = [HKQuantityType(.stepCount)]
try await store.requestAuthorization(toShare: [], read: types)

// Query with async
let descriptor = HKSampleQueryDescriptor(
    predicates: [.quantitySample(type: .init(.stepCount))],
    sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
    limit: 7
)
let results = try await descriptor.result(for: store)
```

### App Extensions
Key extension types and when to use them:
- **Widget Extension:** Home screen/Lock Screen glanceable content
- **Share Extension:** Receive shared content from other apps
- **Notification Content Extension:** Custom notification UI
- **Intents Extension:** Siri/Shortcuts actions (legacy — prefer App Intents)
- **Action Extension:** Quick actions on content in other apps
- **Control Extension (iOS 18+):** Custom Control Center controls

All extensions share code with the main app via app groups and shared frameworks (Swift packages).
