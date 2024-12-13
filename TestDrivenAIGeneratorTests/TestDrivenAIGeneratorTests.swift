//
//  TestDrivenAIGeneratorTests.swift
//  TestDrivenAIGeneratorTests
//
//  Created by Cristian Felipe Patiño Rojas on 13/12/24.
//

import Testing
@testable import TestDrivenAIGenerator

struct Generator {
    let client: Client
    let runner: Runner
    
    struct Result {
        let generatedCode: String
        let specifications: String
        let compliesSpecifications: Bool
    }
    
    func generateCode(from specs: String) async -> Result {
        let result = await client.send(specs: specs)
        let output = runner.run(result)
        
        return .init(
            generatedCode: result,
            specifications: specs,
            compliesSpecifications: output.isEmpty
        )
    }
}

extension Generator {
    protocol Client {
        func send(specs: String) async -> String
    }
    
    protocol Runner {
        func run(_ code: String) -> String
    }
}


struct TestDrivenAIGeneratorTests {

    @Test func test_generator_delivers_success_output() async throws {
        struct MockClient: Generator.Client {
            func send(specs: String) async -> String {""}
        }
        
        struct MockRunner: Generator.Runner {
            func run(_ code: String) -> String {""}
        }

        let sut = Generator(client: MockClient(), runner: MockRunner())
        let specs = """
        func test_adder() {
            let sut = Adder(1,2)
            assert(sut.result == 3)
        }
        """
        
        let result = await sut.generateCode(from: specs)
        
        #expect(result.compliesSpecifications)
    }
    
}
