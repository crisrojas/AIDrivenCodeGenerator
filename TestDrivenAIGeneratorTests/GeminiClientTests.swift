//
//  URLSessionHTTPClientTests.swift
//  TestDrivenAIGenerator
//
//  Created by Cristian Felipe Patiño Rojas on 14/12/24.
//

import Foundation
import Testing

final class GeminiClient {
    func send() async throws {
        HTTPClient.shared.requestedURL = URL(string: "https://a-url.com")!
    }
}

class HTTPClient {
    static var shared = HTTPClient()
    var requestedURL: URL?
}

struct GeminiClientTests {
    @Test func does_not_request_data_on_initialization() throws {
        let client = HTTPClient.shared
        let _ = GeminiClient()
        #expect(client.requestedURL == nil)
    }
    
    @Test func requests_data_on_send() async throws {
        let client = HTTPClient.shared
        let sut = GeminiClient()
        _ = try await sut.send()
        #expect(client.requestedURL != nil)
    }
}
