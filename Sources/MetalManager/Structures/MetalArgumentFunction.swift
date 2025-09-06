//
//  MetalArgs.swift
//  
//
//  Created by Vaida on 7/19/24.
//

import Foundation
@preconcurrency import Metal
import CoreGraphics


/// A metal function with information about its arguments (buffers).
///
/// - Important: You cannot reuse a function, due to the current design. Doing so would read from deallocated buffers.
public struct MetalArgumentFunction: MetalFunctionProtocol {
    
    public let _function: MetalFunction
    
    fileprivate let encoder: MetalCommandEncoder
    
    
    public func _get_encoder() -> MetalCommandEncoder? {
        self.encoder
    }
    
    
    init(function: MetalFunction, encoder: MetalCommandEncoder) {
        self._function = function
        self.encoder = encoder
    }
    
}


/// A Metal function.
public protocol MetalFunctionProtocol {
    
    var _function: MetalFunction { get }
    
    func _get_encoder() -> MetalCommandEncoder?
    
}


public extension MetalFunctionProtocol {
    
    /// Binds a buffer to the buffer argument table, allowing compute kernels to access its data on the GPU.
    consuming func argument(buffer: any MTLBuffer) -> MetalArgumentFunction {
        let encoder = self._get_encoder() ?? MetalCommandEncoder(function: self._function)
        encoder.setBuffer(buffer)
        
        return MetalArgumentFunction(function: self._function, encoder: encoder)
    }
    
    /// Copies data directly to the GPU to populate an entry in the buffer argument table.
    ///
    /// - Important: This method only works for data smaller than 4 kilobytes that doesn’t persist. Create an MTLBuffer instance if your data exceeds 4 KB, needs to persist on the GPU, or you access results on the CPU.
    consuming func argument<T>(bytes: T) -> MetalArgumentFunction {
        let length = MemoryLayout<T>.size
        let buffer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        buffer.initialize(to: bytes)
        
        let encoder = self._get_encoder() ?? MetalCommandEncoder(function: self._function)
        encoder.setBytes(buffer, length: length, deallocator: .free)
        
        return MetalArgumentFunction(function: self._function, encoder: encoder)
    }
    
    /// Copies data directly to the GPU to populate an entry in the buffer argument table.
    ///
    /// - Important: This method only works for data smaller than 4 kilobytes that doesn’t persist. Create an MTLBuffer instance if your data exceeds 4 KB, needs to persist on the GPU, or you access results on the CPU.
    consuming func argument<T>(state: MetalDependentState<T>) -> MetalArgumentFunction {
        let encoder = self._get_encoder() ?? MetalCommandEncoder(function: self._function)
        encoder.setBuffer(state.content)
        
        return MetalArgumentFunction(function: self._function, encoder: encoder)
    }
    
    /// Copies data directly to the GPU to populate an entry in the buffer argument table.
    ///
    /// - Important: This method only works for data smaller than 4 kilobytes that doesn’t persist. Create an MTLBuffer instance if your data exceeds 4 KB, needs to persist on the GPU, or you access results on the CPU.
    ///
    /// This function will not copy the pointer immediately, but when synced.
    ///
    /// - Parameters:
    ///   - bytes: The data.
    ///   - deallocator: The handler called after the bytes have been copied, which happens after the function returns.
    consuming func argument<T>(bytes: UnsafeMutablePointer<T>, deallocator: Data.Deallocator) -> MetalArgumentFunction {
        let length = MemoryLayout<T>.size
        let encoder = self._get_encoder() ?? MetalCommandEncoder(function: self._function)
        encoder.setBytes(bytes, length: length, deallocator: deallocator)
        
        return MetalArgumentFunction(function: self._function, encoder: encoder)
    }
    
    /// Binds a texture to the texture argument table, allowing compute kernels to access its data on the GPU.
    consuming func argument(texture: any MTLTexture) -> MetalArgumentFunction {
        let encoder = self._get_encoder() ?? MetalCommandEncoder(function: self._function)
        encoder.setTexture(texture)
        
        return MetalArgumentFunction(function: self._function, encoder: encoder)
    }
    
    /// Binds a sampler to the sampler argument table, allowing compute kernels to access its data on the GPU.
    consuming func argument(sampler: MTLSamplerDescriptor) -> MetalArgumentFunction {
        let encoder = self._get_encoder() ?? MetalCommandEncoder(function: self._function)
        encoder.setSampler(sampler)
        
        return MetalArgumentFunction(function: self._function, encoder: encoder)
    }
    
}


public extension MetalArgumentFunction {
    
    /// Dispatch to the `commandBuffer` for batched execution.
    consuming func dispatch(to commandBuffer: MetalCommandBuffer, width: Int, height: Int = 1, depth: Int = 1) async throws {
        let encoder = self.encoder
        encoder.dispatchSize = MTLSize(width: width, height: height, depth: depth)
        
        let library = try await Cache.shared.getLibrary(for: self._function.bundle)
        let pipelineState = try await Cache.getPipeline(for: self._function, library: library)
        encoder.pipelineState = pipelineState
        
        commandBuffer.add(encoder: encoder)
    }
    
    /// Dispatch to the `context` for batched execution.
    consuming func dispatch(to context: MetalContext, width: Int, height: Int, depth: Int = 1) async throws {
        try await self.dispatch(to: context.addJob(), width: width, height: height, depth: depth)
    }
    
    func perform(width: Int, height: Int = 1, depth: Int = 1) async throws {
        let commandBuffer = MetalCommandBuffer()
        try await self.dispatch(to: commandBuffer, width: width, height: height, depth: depth)
        
        try await commandBuffer.perform()
    }
    
}
