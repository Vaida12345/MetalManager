//
//  Cache.swift
//  
//
//  Created by Vaida on 7/19/24.
//

import Foundation
@preconcurrency import Metal


actor Cache {
    
    var libraries: [Bundle : MTLLibrary] = [:]
    
    var functions: [MetalFunction : MTLFunction] = [:]
    
    var pipelineStates: [MetalFunction : MTLComputePipelineState] = [:]

    private var pipelineBuildTasks: [MetalFunction : Task<MTLComputePipelineState, any Error>] = [:]
    
    nonisolated(unsafe)
    var commandQueue: MTLCommandQueue = MetalManager.computeDevice.makeCommandQueue(maxCommandBufferCount: MetalManager.Configuration.shared.commandQueueLength)!
    
    
    static let shared = Cache()
    
    
    func library(for bundle: Bundle) -> (any MTLLibrary)? {
        self.libraries[bundle]
    }
    
    func set(library: any MTLLibrary, key: Bundle) {
        self.libraries[key] = library
    }
    
    func function(for description: MetalFunction) -> (any MTLFunction)? {
        self.functions[description]
    }
    
    func set(function: any MTLFunction, key: MetalFunction) {
        self.functions[key] = function
    }
    
    func pipelineState(for description: MetalFunction) -> (any MTLComputePipelineState)? {
        self.pipelineStates[description]
    }
    
    func set(pipelineState: any MTLComputePipelineState, key: MetalFunction) {
        self.pipelineStates[key] = pipelineState
    }
    
    
    func getLibrary(for bundle: Bundle) throws -> any MTLLibrary {
        let device = MetalManager.computeDevice
        let library: MTLLibrary
        if let _library = self.library(for: bundle) {
            library = _library
        } else {
            library = try device.makeDefaultLibrary(bundle: bundle)
            library.label = "MTLLibrary(bundle: \(bundle))"
            
            self.set(library: library, key: bundle)
        }
        
        return library
    }

    func getPipeline(for function: MetalFunction, library: any MTLLibrary) async throws -> any MTLComputePipelineState {
        if let pipelineState = self.pipelineState(for: function) {
            return pipelineState
        }

        if let task = self.pipelineBuildTasks[function] {
            return try await task.value
        }

        let buildTask = Task {
            let metalFunction = try await function.makeFunction(library: library)
            return try await MetalManager.computeDevice.makeComputePipelineState(function: metalFunction)
        }

        self.pipelineBuildTasks[function] = buildTask

        do {
            let pipelineState = try await buildTask.value
            self.set(pipelineState: pipelineState, key: function)
            self.pipelineBuildTasks[function] = nil
            return pipelineState
        } catch {
            self.pipelineBuildTasks[function] = nil
            throw error
        }
    }
    
}
