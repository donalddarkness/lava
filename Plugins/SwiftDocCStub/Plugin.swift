import PackagePlugin

@main
struct SwiftDocCStub: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        Diagnostics.note("SwiftDocCStub: skipping actual documentation generation.")
    }
} 