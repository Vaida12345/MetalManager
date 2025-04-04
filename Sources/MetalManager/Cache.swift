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
    
    static func getPipeline(for function: MetalFunction, library: any MTLLibrary) async throws -> any MTLComputePipelineState {
        let device = MetalManager.computeDevice
        let pipelineState: any MTLComputePipelineState
        if let pipeLine = await Cache.shared.pipelineState(for: function) {
            pipelineState = pipeLine
        } else {
            let metalFunction = try await function.makeFunction(library: library)
            let pipe = try await device.makeComputePipelineState(function: metalFunction)
            await Cache.shared.set(pipelineState: pipe, key: function)
            pipelineState = pipe
        }
        
        return pipelineState
    }
    
}
