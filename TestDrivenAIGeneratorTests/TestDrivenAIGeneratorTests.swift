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
   
    struct Status: Equatable {

        let currentIteration: Int
        let output: String?
        var state: State {
            switch output {
            case .none: return .loading
            case .some(let output) where output.isEmpty: return .success
            default: return .failure
            }
        }
        
        enum State: Equatable {
            case loading
            case failure
            case success
        }
        
        static let loading = Status(currentIteration: 1, output: nil)
        static func success(onIteration: Int) -> Self {
            .init(currentIteration: onIteration, output: "")
        }
        
        static func failure(onIteration: Int, output: String) -> Self {
            .init(currentIteration: onIteration, output: output)
        }
    }
 
    
    func generateCode(
        from specs: String,
        iterationLimit: Int = 5,
        statusCallback: (Status) -> Void
    ) async throws -> Result {
        statusCallback(.loading)
        var generated = try await client.send(specs: specs)
        var output    = runner.run(generated)
        var result: Result {
            Result(
                generatedCode: generated,
                specifications: specs,
                compliesSpecifications: output.isEmpty
            )
        }
        
        if result.compliesSpecifications {
            statusCallback(.success(onIteration: 1))
            return result
        } else {
            statusCallback(.failure(onIteration: 1, output: output))
        }
        
        var state = Status.loading {
            didSet { statusCallback(state) }
        }
        
        while state.currentIteration <= iterationLimit {
           
            generated = try await client.send(specs: specs)
            output = runner.run(generated)
            
            let currentIteration = state.currentIteration + 1
            state = result.compliesSpecifications
            ? .success(onIteration: currentIteration)
            : .failure(onIteration: currentIteration, output: output)
            
            if result.compliesSpecifications {
                break
            }
        }
        
        return result
    }
}

extension Generator {
    protocol Client {
        func send(specs: String) async throws -> String
    }
    
    protocol Runner {
        func run(_ code: String) -> String
    }
}


struct TestDrivenAIGeneratorTests {

    @Test func test_generator_delivers_success_output() async throws {
        let sut = Generator(client: DummyClient(), runner: DummyRunner())
        var capturedStatuses = [Generator.Status]()
        let result = try await sut.generateCode(
            from: anySpecs(),
            statusCallback: {capturedStatuses.append($0)}
        )
        
        #expect(result.compliesSpecifications)
        #expect(capturedStatuses == [.loading, .success(onIteration: 1)])
    }
    
    @Test func test_generator_delivers_success_output_after_N_iterations() async throws {
    
        let runner = StubRunner(succedingOnIteration: 3)
        
        let sut = Generator(client: DummyClient(), runner: runner)
        var capturedStatuses = [Generator.Status]()
        
        let result = try await sut.generateCode(
            from: anySpecs(),
            iterationLimit: 3,
            statusCallback: { capturedStatuses.append($0) }
        )
        
        #expect(result.compliesSpecifications)
        #expect(
            capturedStatuses == [
                .loading,
                .failure(onIteration: 1, output: "failure"),
                .failure(onIteration: 2, output: "failure"),
                .success(onIteration: 3)
            ]
        )
    }
    
    func anySpecs() -> String {
    """
    func test_adder() {
        let sut = Adder(1,2)
        assert(sut.result == 3)
    }
    """
    }
    
}

private extension TestDrivenAIGeneratorTests {
    
    final class StubRunner: Generator.Runner {
        let succedingOnIteration: Int
        var currentIteration = 1
        init(succedingOnIteration: Int) {
            self.succedingOnIteration = succedingOnIteration
        }
        
        private var shoudReturnSuccess: Bool {
            succedingOnIteration == currentIteration
        }
        
        func run(_ code: String) -> String {
           let output = shoudReturnSuccess
            ? ""
            : "failure"
            
            currentIteration += 1
            return output
        }
    }
    
    struct DummyClient: Generator.Client {
        func send(specs: String) async -> String {""}
    }
    
    struct DummyRunner: Generator.Runner {
        func run(_ code: String) -> String {""}
    }
}
