//
//  MetalCommandEncoder.swift
//  MetalManager
//
//  Created by Vaida on 8/5/24.
//

import Metal


/// An delegate of command encoder, which is responsible for passing arguments to a `ComputePipelineState`.
///
/// A command buffer only contains information to construct a `MTLComputeCommandEncoder`, hence you can discard `MetalCommandEncoder` whenever you want.
public final class MetalCommandEncoder: @unchecked Sendable, CustomStringConvertible {
    
    private let function: MetalFunction
    
    private var buffers: [(buffer: any MTLBuffer, index: Int)]
    
    private var bytes: [(pointer: UnsafeRawPointer, length: Int, deallocator: Data.Deallocator, index: Int)]
    
    private var textures: [any MTLTexture]
    
    private var samplers: [(any MTLSamplerState)?]
    
    internal var dispatchSize: MTLSize?
    
    internal var pipelineState: (any MTLComputePipelineState)?
    
    private var bufferCount = 0
    
    
    public var description: String {
        "MetalCommandEncoder(for: \(self.function))"
    }
    
    
    func encode(to encoder: any MTLComputeCommandEncoder) {
        precondition(dispatchSize != nil)
        precondition(pipelineState != nil)
        
        encoder.setComputePipelineState(pipelineState!)
        
        for buffer in buffers {
            encoder.setBuffer(buffer.buffer, offset: 0, index: buffer.index)
        }
        
        for byte in bytes {
            encoder.setBytes(byte.pointer, length: byte.length, index: byte.index)
            
            switch byte.deallocator {
            case .free:
                byte.pointer.deallocate()
                
            case .none:
                break
                
            case .custom(let block):
                block(.init(mutating: byte.pointer), byte.length)
                
            default:
                fatalError()
            }
        }
        
        encoder.setTextures(textures, range: 0..<textures.count)
        if !self.samplers.isEmpty {
            encoder.setSamplerStates(self.samplers, range: 0..<samplers.count)
        }
        
        encoder.label = "Encoder(for: \(function.name), textureCount: \(textures.count), bufferCount: \(bufferCount), dispatchSize: \(dispatchSize!))"

        MTLComputeCommandEncoderDispatch(
            encoder: encoder,
            pipelineState: pipelineState!,
            width: dispatchSize!.width,
            height: dispatchSize!.height,
            depth: dispatchSize!.depth
        )
    }
    
    
    public init(function: MetalFunction) {
        self.function = function
        self.buffers = []
        self.bytes = []
        self.textures = []
        self.dispatchSize = nil
        self.pipelineState = nil
        self.samplers = []
    }
    
    
    public func setBuffer(_ buffer: any MTLBuffer) {
        self.buffers.append((buffer, bufferCount))
        self.bufferCount += 1
    }
    
    /// Copies data directly to the GPU to populate an entry in the buffer argument table.
    ///
    /// This function will not copy the pointer immediately, but when synced.
    ///
    /// - Parameters:
    ///   - pointer: The pointer to data.
    ///   - length: The length of data in bytes, which is usually different to the `count` property.
    ///   - deallocator: The handler called after the bytes have been copied, which happens after the function returns.
    ///
    /// - Precondition: Pointee must be bitwise-copyable.
    public func setBytes(_ pointer: UnsafeRawPointer, length: Int, deallocator: Data.Deallocator) {
        self.bytes.append((pointer, length, deallocator, self.bufferCount))
        self.bufferCount += 1
    }
    
    public func setSampler(_ sampler: MTLSamplerDescriptor) {
        self.samplers.append(MetalManager.computeDevice.makeSamplerState(descriptor: sampler))
    }
    
    public func setTexture(_ texture: any MTLTexture) {
        self.textures.append(texture)
    }
    
}
