//
//  MetalArgs.swift
//  
//
//  Created by Vaida on 7/19/24.
//

import Metal
import CoreGraphics


public final class MetalArgumentFunction: MetalArgumentable {
    
    public let _function: MetalFunction
    
    public let _arguments: [Argument]
    
    
    public func perform(width: Int, height: Int = 1, depth: Int = 1) throws {
        let manager = try MetalManager(function: self, at: _function.bundle)
        try manager.perform(width: width, height: height, depth: depth)
    }
    
    func makeCommandEncoder(commandBuffer: MTLCommandBuffer, commandState: MTLComputePipelineState) throws -> MTLComputeCommandEncoder {
        guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { throw MetalManager.Error.cannotCreateMetalCommandEncoder }
        commandEncoder.label = "Encoder(for: \(_function.name))"
        
        commandEncoder.setComputePipelineState(commandState)
        
        var textureCount = 0
        var bufferCount = 0
        for argument in _arguments {
            switch argument {
            case .texture(let texture):
                commandEncoder.setTexture(texture, index: textureCount)
                textureCount += 1
            case .buffer(let buffer):
                commandEncoder.setBuffer(buffer, offset: 0, index: bufferCount)
                bufferCount += 1
            case let .bytes(bytes, length):
                var bytes = bytes
                commandEncoder.setBytes(&bytes, length: length, index: bufferCount)
                bufferCount += 1
            }
        }
        commandEncoder.label = "Encoder(for: \(_function.name), textureCount: \(textureCount), bufferCount: \(bufferCount))"
        
        return commandEncoder
    }
    
    
    init(function: MetalFunction, arguments: [Argument]) {
        self._function = function
        self._arguments = arguments
    }
    
    
    public enum Argument {
        case texture(any MTLTexture)
        case buffer(any MTLBuffer)
        case bytes(Any, length: Int)
    }
    
}


public protocol MetalArgumentable {
    
    var _function: MetalFunction { get }
    
    var _arguments: [MetalArgumentFunction.Argument] { get }
    
}


public extension MetalArgumentable {
    
    /// Binds a buffer to the buffer argument table, allowing compute kernels to access its data on the GPU.
    consuming func argument(buffer: any MTLBuffer) -> MetalArgumentFunction {
        MetalArgumentFunction(function: self._function, arguments: self._arguments + [.buffer(buffer)])
    }
    
    /// Copies data directly to the GPU to populate an entry in the buffer argument table.
    ///
    /// - Important: This method only works for data smaller than 4 kilobytes that doesn’t persist. Create an MTLBuffer instance if your data exceeds 4 KB, needs to persist on the GPU, or you access results on the CPU.
    consuming func argument<T>(bytes: T) -> MetalArgumentFunction {
        let length = MemoryLayout<T>.size
        return MetalArgumentFunction(function: self._function, arguments: self._arguments + [.bytes(bytes, length: length)])
    }
    
    /// Binds a texture to the texture argument table, allowing compute kernels to access its data on the GPU.
    consuming func argument(texture: any MTLTexture) -> MetalArgumentFunction {
        MetalArgumentFunction(function: self._function, arguments: self._arguments + [.texture(texture)])
    }
    
}
