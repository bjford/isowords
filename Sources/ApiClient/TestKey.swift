import CasePaths
import Dependencies
import Foundation
import SharedModels
import XCTestDebugSupport
import XCTestDynamicOverlay

extension DependencyValues {
  public var apiClient: ApiClient {
    get { self[ApiClient.self] }
    set { self[ApiClient.self] = newValue }
  }
}

extension ApiClient: TestDependencyKey {
  public static let previewValue = Self.noop

  public static let testValue = Self(
    apiRequest: unimplemented("\(Self.self).apiRequest"),
    authenticate: unimplemented("\(Self.self).authenticate"),
    baseUrl: unimplemented("\(Self.self).baseUrl", placeholder: URL(string: "/")!),
    currentPlayer: unimplemented("\(Self.self).currentPlayer"),
    logout: unimplemented("\(Self.self).logout"),
    refreshCurrentPlayer: unimplemented("\(Self.self).refreshCurrentPlayer"),
    request: unimplemented("\(Self.self).request"),
    setBaseUrl: unimplemented("\(Self.self).setBaseUrl")
  )
}

extension ApiClient {
  public static let noop = Self(
    apiRequest: { _ in try await Task.never() },
    authenticate: { _ in try await Task.never() },
    baseUrl: { URL(string: "/")! },
    currentPlayer: { nil },
    logout: {},
    refreshCurrentPlayer: { try await Task.never() },
    request: { _ in try await Task.never() },
    setBaseUrl: { _ in }
  )

  public mutating func override(
    route matchingRoute: ServerRoute.Api.Route,
    withResponse response: @escaping @Sendable () async throws -> (Data, URLResponse)
  ) {
    let fulfill = expectation(description: "route")
    self.apiRequest = { @Sendable [self] route in
      if route == matchingRoute {
        fulfill()
        return try await response()
      } else {
        return try await self.apiRequest(route)
      }
    }
  }

  public mutating func override<Value>(
    routeCase matchingRoute: CasePath<ServerRoute.Api.Route, Value>,
    withResponse response: @escaping @Sendable (Value) async throws -> (Data, URLResponse)
  ) {
    let fulfill = expectation(description: "route")
    self.apiRequest = { @Sendable [self] route in
      if let value = matchingRoute.extract(from: route) {
        fulfill()
        return try await response(value)
      } else {
        return try await self.apiRequest(route)
      }
    }
  }
}
