import Foundation

/// A Route definition for HTTP path, method, and handler
public struct Route {
    public let path: String
    public let method: HttpMethod
    public let handler: (HttpRequest) async -> HttpResponse
}

/// Result builder for grouping Route definitions into an array
@resultBuilder
public struct RouteBuilder {
    public static func buildBlock(_ routes: Route...) -> [Route] {
        routes
    }
}

/// DSL helper to define an HTTP route
public func route(_ path: String, method: HttpMethod = .get,
                  handler: @escaping (HttpRequest) async -> HttpResponse) -> Route {
    Route(path: path, method: method, handler: handler)
}

public extension DispatcherServlet {
    /// Registers multiple routes via a RouteBuilder DSL
    /// - Parameter builder: Closure returning an array of Route definitions
    func registerRoutes(@RouteBuilder _ builder: () -> [Route]) async {
        let routes = builder()
        for route in routes {
            await registerHandler(path: route.path) { request in
                guard request.method == route.method else {
                    return HttpResponse(status: .methodNotAllowed)
                }
                return await route.handler(request)
            }
        }
    }
} 