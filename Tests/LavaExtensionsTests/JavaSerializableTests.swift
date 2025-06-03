import Foundation
import Testing

@testable import Lava

/// Tests for the JavaSerializable protocol and its serialization utilities
///
/// These tests validate the JSON serialization/deserialization capabilities
/// and the file I/O operations provided by SerializationHelper
final class JavaSerializableTests {
    /// Test model implementing JavaSerializable with comprehensive property types
    struct TestSerializable: JavaSerializable, Equatable {
        var name: String
        var age: Int
        var tags: [String]?
        var isActive: Bool
        var score: Double?
        var lastUpdated: Date?
        var metadata: [String: String]?
        var nestedObject: NestedData?

        struct NestedData: Equatable, Codable {
            var id: Int
            var value: String
        }

        init(
            name: String,
            age: Int,
            tags: [String]? = nil,
            isActive: Bool = true,
            score: Double? = nil,
            lastUpdated: Date? = nil,
            metadata: [String: String]? = nil,
            nestedObject: NestedData? = nil
        ) {
            self.name = name
            self.age = age
            self.tags = tags
            self.isActive = isActive
            self.score = score
            self.lastUpdated = lastUpdated
            self.metadata = metadata
            self.nestedObject = nestedObject
            self.isActive = isActive
            self.score = score
            self.lastUpdated = lastUpdated
            self.metadata = metadata
            self.nestedObject = nestedObject
        }

        func serialize() -> Data? {
            var dict: [String: Any] = [
                "name": name,
                "age": age,
                "isActive": isActive,
            ]

            if let tags = tags {
                dict["tags"] = tags
            }
            if let score = score {
                dict["score"] = score
            }
            if let lastUpdated = lastUpdated {
                dict["lastUpdated"] = lastUpdated.timeIntervalSince1970
            }
            if let metadata = metadata {
                dict["metadata"] = metadata
            }
            if let nestedObject = nestedObject {
                dict["nestedObject"] = [
                    "id": nestedObject.id,
                    "value": nestedObject.value,
                ]
            }
            return try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        }

        static func deserialize(from data: Data) -> TestSerializable? {
            guard
                let dict = try? JSONSerialization.jsonObject(with: data, options: [])
                    as? [String: Any],
                let name = dict["name"] as? String,
                let age = dict["age"] as? Int,
                let isActive = dict["isActive"] as? Bool
            else {
                return nil
            }

            let tags = dict["tags"] as? [String]
            let score = dict["score"] as? Double

            var lastUpdated: Date?
            if let timestamp = dict["lastUpdated"] as? TimeInterval {
                lastUpdated = Date(timeIntervalSince1970: timestamp)
            }

            let metadata = dict["metadata"] as? [String: String]

            var nestedObject: NestedData?
            if let nestedDict = dict["nestedObject"] as? [String: Any],
                let id = nestedDict["id"] as? Int,
                let value = nestedDict["value"] as? String
            {
                nestedObject = NestedData(id: id, value: value)
            }

            return TestSerializable(
                name: name,
                age: age,
                tags: tags,
                isActive: isActive,
                score: score,
                lastUpdated: lastUpdated,
                metadata: metadata,
                nestedObject: nestedObject
            )
        }

        func toJson() -> String? {
            guard let data = serialize() else { return nil }
            return String(data: data, encoding: .utf8)
        }

        static func fromJson(_ json: String) -> TestSerializable? {
            guard let data = json.data(using: .utf8) else { return nil }
            return deserialize(from: data)
        }
    }

    // Helper method to create complex test objects
    func createComplexTestObject() -> TestSerializable {
        return TestSerializable(
            name: "Complex Object",
            age: 42,
            tags: ["complex", "test", "object"],
            isActive: true,
            score: 99.5,
            lastUpdated: Date(),
            metadata: ["created_by": "test", "purpose": "testing"],
            nestedObject: TestSerializable.NestedData(id: 123, value: "nested value")
        )
    }

    @Test
    func testSerializeToDataAndBack() {
        let original = TestSerializable(name: "John Doe", age: 30, tags: ["developer", "swift"])
        let data = original.serialize()
        #assert(data != nil)

        let deserialized = TestSerializable.deserialize(from: data!)
        #assert(deserialized != nil)
        #assertEqual(deserialized, original)
    }

    /// Tests JSON string serialization and deserialization
    @Test
    func testSerializeToJsonAndBack() {
        let original = TestSerializable(
            name: "Jane Doe",
            age: 25,
            tags: ["analyst", "finance"],
            score: 3.9,
            metadata: ["role": "Team Lead"]
        )

        // Test conversion to JSON string
        let json = original.toJson()
        #assert(json != nil, "JSON string conversion should succeed")
        #assert(json!.contains("Jane Doe"), "JSON should contain the name")
        #assert(json!.contains("analyst"), "JSON should contain tag values")

        // Test parsing from JSON string
        let deserialized = TestSerializable.fromJson(json!)
        #assert(deserialized != nil, "JSON parsing should succeed")
        #assertEqual(deserialized?.name, original.name)
        #assertEqual(deserialized?.age, original.age)
        #assertEqual(deserialized?.tags, original.tags)
        #assertEqual(deserialized?.score, original.score)
        #assertEqual(deserialized?.metadata, original.metadata)
    }

    /// Tests writing to and reading from files using SerializationHelper
    @Test
    func testWriteToAndReadFromFile() throws {
        // Create a temporary file path for testing
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let original = TestSerializable(
            name: "Alice",
            age: 40,
            tags: ["manager", "executive"],
            isActive: true,
            score: 4.5,
            nestedObject: TestSerializable.NestedData(id: 100, value: "Executive Data")
        )
        let filePath = temporaryDirectory.appendingPathComponent("test_serializable.json").path

        // Test writing to file
        try SerializationHelper.writeJson(original, to: filePath)
        #assert(FileManager.default.fileExists(atPath: filePath), "File should be created")

        // Test file contents
        let fileContents = try? String(contentsOfFile: filePath, encoding: .utf8)
        #assert(fileContents != nil, "File should have readable contents")
        #assert(fileContents!.contains("Alice"), "File should contain the serialized name")

        // Test reading from file
        let deserialized: TestSerializable = try SerializationHelper.readJson(from: filePath)
        #assertEqual(deserialized.name, original.name)
        #assertEqual(deserialized.age, original.age)
        #assertEqual(deserialized.tags, original.tags)
        #assertEqual(deserialized.isActive, original.isActive)
        #assertEqual(deserialized.score, original.score)
        #assertEqual(deserialized.nestedObject?.id, original.nestedObject?.id)
        #assertEqual(deserialized.nestedObject?.value, original.nestedObject?.value)

        // Clean up
        try? FileManager.default.removeItem(atPath: filePath)
    }

    /// Tests error handling for missing files
    @Test
    func testHandlesMissingFiles() {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let nonExistentPath = temporaryDirectory.appendingPathComponent("non_existent.json").path

        // Verify that attempting to read from a non-existent file throws an error
        #assertThrows("Should throw an error for missing file") {
            let _: TestSerializable = try SerializationHelper.readJson(from: nonExistentPath)
        }
    }

    /// Tests handling of empty or minimal objects
    @Test
    func testHandlesEmptyObjects() {
        let emptyObject = TestSerializable(name: "", age: 0, isActive: false)
        let data = emptyObject.serialize()
        #assert(data != nil, "Should be able to serialize minimal objects")

        let deserialized = TestSerializable.deserialize(from: data!)
        #assertEqual(deserialized?.name, emptyObject.name)
        #assertEqual(deserialized?.age, emptyObject.age)
        #assertEqual(deserialized?.isActive, emptyObject.isActive)
    }

    /// Tests handling of invalid JSON data
    @Test
    func testHandlesInvalidData() {
        // Create invalid JSON data
        let invalidData = Data("This is not valid JSON".utf8)

        // Verify deserialization fails gracefully
        let result = TestSerializable.deserialize(from: invalidData)
        #assert(result == nil, "Should return nil for invalid data")
    }

    /// Tests the binary serialization path
    @Test
    func testBinarySerialization() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let original = TestSerializable(
            name: "Binary Test",
            age: 35,
            isActive: true,
            nestedObject: TestSerializable.NestedData(id: 555, value: "Binary Data")
        )
        let filePath = temporaryDirectory.appendingPathComponent("binary_test").path

        // Test direct data serialization
        let serializedData = original.serialize()
        #assert(serializedData != nil, "Data serialization should succeed")

        // Write raw data to file
        try serializedData!.write(to: URL(fileURLWithPath: filePath))

        // Read raw data and deserialize
        let loadedData = try Data(contentsOf: URL(fileURLWithPath: filePath))
        let deserialized = TestSerializable.deserialize(from: loadedData)

        #assert(deserialized != nil, "Binary deserialization should succeed")
        #assertEqual(deserialized?.name, original.name)
        #assertEqual(deserialized?.age, original.age)

        // Clean up
        try? FileManager.default.removeItem(atPath: filePath)
    }
}

@Test
func testComplexObjectSerialization() {
    let complex = createComplexTestObject()
    let data = complex.serialize()
    #assert(data != nil)

    let deserialized = TestSerializable.deserialize(from: data!)
    #assert(deserialized != nil)
    #assertEqual(deserialized, complex)
}

@Test
func testInvalidJsonDeserialization() {
    let invalidJson = "{\"name\": \"Invalid, \"age\": not_a_number}"
    let result = TestSerializable.fromJson(invalidJson)
    #assert(result == nil)
}

@Test
func testBatchSerializationPerformance() throws {
    let objectCount = 100
    var objects: [TestSerializable] = []

    // Create multiple test objects
    for i in 0..<objectCount {
        objects.append(
            TestSerializable(
                name: "Batch Object \(i)",
                age: i,
                isActive: i % 2 == 0
            ))
    }

    // Test batch serialization performance
    let startTime = Date()
    let serializedObjects = objects.compactMap { $0.serialize() }
    let endTime = Date()

    #assertEqual(serializedObjects.count, objectCount)
    let elapsedTime = endTime.timeIntervalSince(startTime)
    print("Batch serialization time for \(objectCount) objects: \(elapsedTime) seconds")

    // Verify deserialization works for all objects
    for (index, data) in serializedObjects.enumerated() {
        let deserialized = TestSerializable.deserialize(from: data)
        #assert(deserialized != nil)
        #assertEqual(deserialized, objects[index])
    }
}

@Test
func testNestedObjectHandling() {
    let nested = TestSerializable(
        name: "Parent",
        age: 50,
        isActive: true,
        nestedObject: TestSerializable.NestedData(id: 999, value: "Child")
    )

    let data = nested.serialize()
    #assert(data != nil)

    let deserialized = TestSerializable.deserialize(from: data!)
    #assert(deserialized != nil)
    #assert(deserialized?.nestedObject != nil)
    #assertEqual(deserialized?.nestedObject?.id, 999)
    #assertEqual(deserialized?.nestedObject?.value, "Child")
}
