//
//  MetalCommandBuffer.swift
//  MetalManager
//
//  Created by Vaida on 7/29/24.
//

import Metal


/// A class with info about the command buffer and command encoder.
///
/// A command buffer only contains information to construct a `MTLComputeCommandBuffer`, hence you can discard `MetalCommandBuffer` whenever you want.
public final class MetalCommandBuffer: @unchecked Sendable {
    
    private var encoders: [MetalCommandEncoder]
    
    func add(encoder: MetalCommandEncoder) {
        self.encoders.append(encoder)
    }
    
    public init() {
        self.encoders = []
    }
    
    /// Performs and waits for completion.
    ///
    /// This function contains a suspension point after the command buffer has been committed. This function will not return while the command buffer it creates is alive.
    public func perform() async throws {
        guard let commandBuffer = Cache.shared.commandQueue.makeCommandBuffer() else { throw MetalManager.Error.cannotCreateMetalCommandBuffer }
        commandBuffer.label = "CommandBuffer(encoders: \(self.encoders))"
        
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        for encoder in encoders {
            encoder.encode(to: commandEncoder)
        }
        
        commandEncoder.endEncoding()
        
        commandBuffer.commit()
        
        await Task.yield()
        
        commandBuffer.waitUntilCompleted()
        
        if let error = commandBuffer.error {
            throw error
        }
    }
    
}
