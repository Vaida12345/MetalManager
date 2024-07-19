//
//  Cache.swift
//  
//
//  Created by Vaida on 7/19/24.
//

import Foundation
import Metal


final class Cache {
    
    var libraries: [Bundle : MTLLibrary] = [:]
    
    var functions: [MetalFunction : MTLFunction] = [:]
    
    var pipelineStates: [MetalFunction : MTLComputePipelineState] = [:]
    
    lazy var commandQueue: MTLCommandQueue! = MetalManager.Configuration.shared.computeDevice!.makeCommandQueue(maxCommandBufferCount: MetalManager.Configuration.shared.commandQueueLength)
    
    
    nonisolated(unsafe) static let shared = Cache()
    
}
