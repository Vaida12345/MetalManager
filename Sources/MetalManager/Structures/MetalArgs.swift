//
//  MetalArgs.swift
//  
//
//  Created by Vaida on 7/19/24.
//

@preconcurrency import Metal
import CoreGraphics


public final class MetalArgumentFunction: MetalArgumentable {
    
    public let _function: MetalFunction
    
    public let _arguments: [Argument]
    
    
    public func perform(width: Int, height: Int = 1, depth: Int = 1) async throws {
        let manager = try await MetalManager(function: self)
        try await manager.perform(width: width, height: height, depth: depth)
    }
    
    func passArgs(to commandEncoder: any MTLComputeCommandEncoder, commandBuffer: MTLCommandBuffer, commandState: MTLComputePipelineState) throws {
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
            case let .mutableBytes(bytes, length):
                commandEncoder.setBytes(bytes, length: length, index: bufferCount)
                bufferCount += 1
            }
        }
        commandEncoder.label = "Encoder(for: \(_function.name), textureCount: \(textureCount), bufferCount: \(bufferCount))"
    }
    
    
    init(function: MetalFunction, arguments: [Argument]) {
        self._function = function
        self._arguments = arguments
    }
    
    
    public enum Argument {
        case texture(any MTLTexture)
        case buffer(any MTLBuffer)
        case bytes(Any, length: Int)
        case mutableBytes(UnsafeRawPointer, length: Int)
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
    
    /// Copies data directly to the GPU to populate an entry in the buffer argument table.
    ///
    /// - Important: This method only works for data smaller than 4 kilobytes that doesn’t persist. Create an MTLBuffer instance if your data exceeds 4 KB, needs to persist on the GPU, or you access results on the CPU.
    consuming func argument<T>(state: MetalDependentState<T>) -> MetalArgumentFunction {
        let length = MemoryLayout<T>.size
        return MetalArgumentFunction(function: self._function, arguments: self._arguments + [.buffer(state.content)])
    }
    
    /// Copies data directly to the GPU to populate an entry in the buffer argument table.
    ///
    /// - Important: This method only works for data smaller than 4 kilobytes that doesn’t persist. Create an MTLBuffer instance if your data exceeds 4 KB, needs to persist on the GPU, or you access results on the CPU.
    consuming func argument<T>(bytes: UnsafeMutablePointer<T>) -> MetalArgumentFunction {
        let length = MemoryLayout<T>.size
        return MetalArgumentFunction(function: self._function, arguments: self._arguments + [.mutableBytes(bytes, length: length)])
    }
    
    /// Binds a texture to the texture argument table, allowing compute kernels to access its data on the GPU.
    consuming func argument(texture: any MTLTexture) -> MetalArgumentFunction {
        MetalArgumentFunction(function: self._function, arguments: self._arguments + [.texture(texture)])
    }
    
}


public extension MetalArgumentFunction {
    
    /// Dispatch to the `commandBuffer` for batched execution.
    consuming func dispatch(to commandBuffer: MetalCommandBuffer, width: Int, height: Int = 1, depth: Int = 1) async throws {
        // Get the function
        let device = MetalManager.computeDevice
        let library = try await Cache.shared.getLibrary(for: self._function.bundle)
        let pipelineState = try await Cache.getPipeline(for: self._function, library: library)
        
        let commandEncoder = commandBuffer.commandEncoder
        try self.passArgs(to: commandBuffer.commandEncoder, commandBuffer: commandBuffer.commandBuffer, commandState: pipelineState)
        
        // Commit the function & buffers
        let supportsNonuniform: Bool = MetalManager.supportsNonUniformGridSize
        let gridSize = MTLSize(width: width, height: height, depth: depth)
        
        if height == 1 && depth == 1 {
            let threadsPerThreadgroup = MTLSize(width: pipelineState.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
            let threadgroupsPerGrid = MTLSize(width: (gridSize.width + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
                                              height: 1,
                                              depth: 1)
            
            if supportsNonuniform {
                commandEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadsPerThreadgroup)
            } else {
                commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            }
        } else {
            let size = Int(sqrt(Double(pipelineState.maxTotalThreadsPerThreadgroup)))
            
            let threadsPerThreadgroup = MTLSize(width: size, height: size, depth: 1)
            let threadgroupsPerGrid = MTLSize(width: (width + size - 1) / size,
                                              height: (height + size - 1) / size,
                                              depth: 1)
            
            if supportsNonuniform {
                commandEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadsPerThreadgroup)
            } else {
                commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            }
        }
    }
    
}
