//
//  MetalCommandBuffer.swift
//  MetalManager
//
//  Created by Vaida on 7/29/24.
//

@preconcurrency
import Metal


public final class MetalCommandBuffer: @unchecked Sendable {
    
    /// The sets of command associated with this metal manager.
    internal let commandBuffer: any MTLCommandBuffer
    
    
    public init() async throws {
        guard let commandBuffer = await Cache.shared.commandQueue.makeCommandBuffer() else { throw MetalManager.Error.cannotCreateMetalCommandBuffer }
        commandBuffer.label = "CommandBuffer(for: some MetalCommandBuffer)"
        self.commandBuffer = commandBuffer
    }
    
    /// Performs and waits for completion.
    public func perform() async {
        self.commandBuffer.commit()
        self.commandBuffer.waitUntilCompleted()
    }
    
}
