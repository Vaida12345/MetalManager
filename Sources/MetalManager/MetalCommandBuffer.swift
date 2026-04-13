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
    
    var hasPendingEncoders: Bool {
        !self.encoders.isEmpty
    }
    
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
        guard self.hasPendingEncoders else { return }
        
        let encoders = self.encoders
        self.encoders.removeAll(keepingCapacity: true)
        
        guard let commandBuffer = Cache.shared.commandQueue.makeCommandBuffer() else { throw MetalManager.Error.cannotCreateMetalCommandBuffer }
        commandBuffer.label = "CommandBuffer(encoderCount: \(encoders.count))"
        
        guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            throw MetalManager.Error.cannotCreateMetalCommandEncoder
        }
        
        for encoder in encoders {
            encoder.encode(to: commandEncoder)
        }
        
        commandEncoder.endEncoding()
        commandBuffer.commit()
        
#if swift(>=6.2)
        await commandBuffer.completed()
#else
        await Task.yield()
        commandBuffer.waitUntilCompleted()
#endif
        
        if let error = commandBuffer.error {
            throw error
        }
    }
    
}
