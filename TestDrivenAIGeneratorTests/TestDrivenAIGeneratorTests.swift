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
   
    struct State: Equatable {
        let state: _State
        let currentIteration: Int
        
        enum _State: Equatable {
            case loading
            case failure
            case success
        }
        
        static let loading = State(state: .loading, currentIteration: 1)
        static func success(onIteration: Int) -> Self {
            .init(state: .success, currentIteration: onIteration)
        }
        
        static func failure(onIteration: Int) -> Self {
            .init(state: .success, currentIteration: onIteration)
        }
    }
 
    
    func generateCode(
        from specs: String,
        iterationLimit: Int = 5,
        stateCallback: (State) -> Void
    ) async -> Result {
        stateCallback(.loading)
        var generated = await client.send(specs: specs)
        var output    = runner.run(generated)
        var result: Result {
            Result(
                generatedCode: generated,
                specifications: specs,
                compliesSpecifications: output.isEmpty
            )
        }
        
        if result.compliesSpecifications {
            stateCallback(.success(onIteration: 1))
            return result
        } else {
            stateCallback(.failure(onIteration: 1))
        }
        
        var state = State.loading {
            didSet { stateCallback(state) }
        }
        
        while state.currentIteration <= iterationLimit {
           
            generated = await client.send(specs: specs)
            output = runner.run(generated)
            
            let currentIteration = state.currentIteration + 1
            state = result.compliesSpecifications
            ? .success(onIteration: currentIteration)
            : .failure(onIteration: currentIteration)
            
            if result.compliesSpecifications {
                break
            }
        }
        
        return result
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
        let sut = Generator(client: DummyClient(), runner: DummyRunner())
        var capturedStates = [Generator.State]()
        let result = await sut.generateCode(
            from: anySpecs(),
            stateCallback: {capturedStates.append($0)}
        )
        
        #expect(result.compliesSpecifications)
        #expect(capturedStates == [.loading, .success(onIteration: 1)])
    }
    
    @Test func test_generator_delivers_success_output_after_N_iterations() async throws {
    
        let runner = StubRunner(succedingOnIteration: 3)
        
        let sut = Generator(client: DummyClient(), runner: runner)
        var capturedStates = [Generator.State]()
        
        let result = await sut.generateCode(
            from: anySpecs(),
            iterationLimit: 3,
            stateCallback: { capturedStates.append($0) }
        )
        
        #expect(result.compliesSpecifications)
        #expect(
            capturedStates == [
                .loading,
                .failure(onIteration: 1),
                .failure(onIteration: 2),
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
