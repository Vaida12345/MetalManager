//
//  MetalCommandBuffer.swift
//  MetalManager
//
//  Created by Vaida on 7/29/24.
//

@preconcurrency
import Metal


/// A class with info about the command buffer and command encoder.
public final class MetalCommandBuffer: @unchecked Sendable {
    
    /// The sets of command associated with this metal manager.
    internal let commandBuffer: any MTLCommandBuffer
    
    internal let commandEncoder: any MTLComputeCommandEncoder
    
    private var isEncoded = false
    
    
    public init() async throws {
        guard let commandBuffer = await Cache.shared.commandQueue.makeCommandBuffer() else { throw MetalManager.Error.cannotCreateMetalCommandBuffer }
        commandBuffer.label = "CommandBuffer(for: some MetalCommandBuffer)"
        self.commandBuffer = commandBuffer
        self.commandEncoder = self.commandBuffer.makeComputeCommandEncoder()!
    }
    
    public func getCommandBuffer() -> any MTLCommandBuffer {
        self.commandBuffer
    }
    
    /// Performs and waits for completion.
    public func perform() async {
        self.isEncoded = true
        self.commandEncoder.endEncoding()
        self.commandBuffer.commit()
        self.commandBuffer.waitUntilCompleted()
    }
    
    deinit {
        guard !self.isEncoded else { return }
        self.commandEncoder.endEncoding()
    }
    
}
