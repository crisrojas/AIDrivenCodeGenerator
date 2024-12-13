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
    
    enum State {
        case loading
        case success
        case failure
    }
    
    func generateCode(
        from specs: String,
        iterationLimit: Int = 5,
        stateCallback: (State) -> Void,
        iterationCallback: (Int) -> Void
    ) async -> Result {
        stateCallback(.loading)
        iterationCallback(1)
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
            stateCallback(.success)
            return result
        }
        
        var currentIteration = 1 {
            didSet {
                iterationCallback(currentIteration)
            }
        }
        
        stateCallback(.failure)
        
        while currentIteration <= iterationLimit {
            currentIteration += 1
            generated = await client.send(specs: specs)
            output = runner.run(generated)
            stateCallback(result.compliesSpecifications ? .success : .failure)
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
        var capturedIterations = [Int]()
        let result = await sut.generateCode(
            from: anySpecs(),
            stateCallback: {capturedStates.append($0)},
            iterationCallback: {capturedIterations.append($0)}
        )
        
        #expect(result.compliesSpecifications)
        #expect(capturedIterations == [1])
        #expect(capturedStates == [.loading, .success])
    }
    
    @Test func test_generator_delivers_success_output_after_N_iterations() async throws {
    
        let runner = StubRunner(succedingOnIteration: 3)
        
        let sut = Generator(client: DummyClient(), runner: runner)
        var capturedIterations = [Int]()
        var capturedStates = [Generator.State]()
        
        let result = await sut.generateCode(
            from: anySpecs(),
            iterationLimit: 3,
            stateCallback: { capturedStates.append($0) },
            iterationCallback: { capturedIterations.append($0) }
        )
        
        #expect(result.compliesSpecifications)
        #expect(capturedIterations == [1,2,3])
        #expect(capturedStates == [.loading, .failure, .failure, .success])
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
