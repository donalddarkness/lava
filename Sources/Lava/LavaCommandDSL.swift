import Foundation

/// Result builder for grouping multiple Command instances into a CompositeCommand
@resultBuilder
public struct CommandBuilder {
    public static func buildBlock(_ commands: Command...) -> CompositeCommand {
        CompositeCommand(name: "Composite (DSL)", commands: commands)
    }
}

public extension CommandManager {
    /// Executes a group of commands specified in a CommandBuilder closure
    /// - Parameter builder: Closure returning a CompositeCommand via result builder
    func execute(@CommandBuilder _ builder: () -> CompositeCommand) async throws {
        let composite = builder()
        try await execute(composite)
    }
} 