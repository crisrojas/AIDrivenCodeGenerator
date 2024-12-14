//
//  URLSessionHTTPClientTests.swift
//  TestDrivenAIGenerator
//
//  Created by Cristian Felipe Patiño Rojas on 14/12/24.
//

import Foundation
import Testing

final class GeminiClient {
    
}

class HTTPClient {
    var requestedURL: URL?
}

struct GeminiClientTests {
    @Test func does_not_request_data_on_initialization() throws {
        let client = HTTPClient()
        let _ = GeminiClient()
        #expect(client.requestedURL == nil)
    }
}
