//
//  URLSessionHTTPClientTests.swift
//  TestDrivenAIGenerator
//
//  Created by Cristian Felipe Patiño Rojas on 14/12/24.
//

import Foundation
import Testing

final class GeminiClient {
    let client: HTTPClient
    init(client c: HTTPClient) {
        client = c
    }
    
    func send() async throws {
        client.data(for: URL(string: "https://a-url.com")!)
    }
}

protocol HTTPClient {
    func data(for url: URL)
}

class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?
    func data(for url: URL) {
        requestedURL = url
    }
}

struct GeminiClientTests {
    @Test func does_not_request_data_on_initialization() throws {
        let client = HTTPClientSpy()
        let _ = GeminiClient(client: client)
        #expect(client.requestedURL == nil)
    }
    
    @Test func requests_data_on_send() async throws {
        let client = HTTPClientSpy()
        let sut = GeminiClient(client: client)
        _ = try await sut.send()
        #expect(client.requestedURL != nil)
    }
}
