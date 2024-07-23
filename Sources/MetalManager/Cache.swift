//
//  Cache.swift
//  
//
//  Created by Vaida on 7/19/24.
//

import Foundation
import Metal


actor Cache {
    
    var libraries: [Bundle : MTLLibrary] = [:]
    
    var functions: [MetalFunction : MTLFunction] = [:]
    
    var pipelineStates: [MetalFunction : MTLComputePipelineState] = [:]
    
    lazy var commandQueue: MTLCommandQueue = MetalManager.Configuration.shared.computeDevice.makeCommandQueue(maxCommandBufferCount: MetalManager.Configuration.shared.commandQueueLength)!
    
    
    nonisolated(unsafe) static let shared = Cache()
    
    
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
    
}
