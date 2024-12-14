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
        HTTPClient.shared.data(for: URL(string: "https://a-url.com")!)
    }
}

class HTTPClient {
    static var shared = HTTPClient()
    func data(for url: URL) {}
}

class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?
    override func data(for url: URL) {
        requestedURL = url
    }
}

struct GeminiClientTests {
    @Test func does_not_request_data_on_initialization() throws {
        let client = HTTPClientSpy()
        HTTPClient.shared = client
        let _ = GeminiClient()
        #expect(client.requestedURL == nil)
    }
    
    @Test func requests_data_on_send() async throws {
        let client = HTTPClientSpy()
        HTTPClient.shared = client
        let sut = GeminiClient()
        _ = try await sut.send()
        #expect(client.requestedURL != nil)
    }
}
