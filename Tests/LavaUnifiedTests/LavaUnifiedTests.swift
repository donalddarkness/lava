import Foundation
import Testing

@testable import Lava

/// Tests for the unified Lava API surface
final class LavaUnifiedTests {
    @Test
    func testAsyncFutureAlias() throws {
        let executor = Lava.Async.newSingleThreadExecutor()
        let future: LavaFuture<Int> = executor.submit { 42 }
        let result = try future.get(timeout: 1)
        #assertEqual(result, 42)
    }

    @Test
    func testSyncSynchronizedAlias() async throws {
        var flag = false
        let value = try await Lava.Sync.synchronized {
            flag = true
            return "synced"
        }
        #assert(flag)
        #assertEqual(value, "synced")
    }

    @Test
    func testMVCErrorAlias() {
        let err: LavaError = .invalidParameter("test")
        #assertEqual(err.errorCode, "INVALID_PARAMETER")
    }

    @Test
    func testSerializationHelperAlias() throws {
        struct Simple: JavaSerializable, Equatable {
            let text: String
            init(text: String) { self.text = text }
            func serialize() -> Data? {
                try? JSONEncoder().encode(["text": text])
            }
            static func deserialize(from data: Data) -> Simple? {
                guard let dict = try? JSONDecoder().decode([String: String].self, from: data),
                      let t = dict["text"] else { return nil }
                return Simple(text: t)
            }
        }
        let obj = Simple(text: "hello")
        let tempPath = FileManager.default.temporaryDirectory.appendingPathComponent("lava_test.json").path
        try Lava.Serialization.Helper.writeJson(obj, to: tempPath)
        let read: Simple = try Lava.Serialization.Helper.readJson(from: tempPath)
        #assertEqual(read, obj)
    }

    @Test
    func testCommandBuilderDSL() async throws {
        let manager = CommandManager(maxStackSize: 10)
        // Use DSL to execute two no-op commands
        try await manager.execute {
            CompositeCommand(name: "A")
            CompositeCommand(name: "B")
        }
        #assertEqual(manager.undoCount, 1)
        #assert(manager.canUndo)
    }
} 