//
//  MetalArgs.swift
//  
//
//  Created by Vaida on 7/19/24.
//

import Metal


public final class MetalArgumentFunction: MetalArgumentable {
    
    public let function: MetalFunction
    
    public let arguments: [Argument]
    
    
    public func perform(width: Int, height: Int = 1, depth: Int = 1) throws {
        let manager = try MetalManager(function: self, at: function.bundle)
        try manager.perform(width: width, height: height, depth: depth)
    }
    
    func makeCommandEncoder(commandBuffer: MTLCommandBuffer, commandState: MTLComputePipelineState) throws -> MTLComputeCommandEncoder {
        guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { throw MetalManager.Error.cannotCreateMetalCommandEncoder }
        commandEncoder.setComputePipelineState(commandState)
        
        var textureCount = 0
        var bufferCount = 0
        for argument in arguments {
            switch argument {
            case .texture(let texture):
                commandEncoder.setTexture(texture, index: textureCount)
                textureCount += 1
            case .buffer(let buffer):
                commandEncoder.setBuffer(buffer, offset: 0, index: bufferCount)
                bufferCount += 1
            }
        }
        
        commandEncoder.endEncoding()
        commandEncoder.label = "Encoder<Committed>(for: \(function.name))"
        
        return commandEncoder
    }
    
    
    init(function: MetalFunction, arguments: [Argument]) {
        self.function = function
        self.arguments = arguments
    }
    
    
    public enum Argument {
        case texture(any MTLTexture)
        case buffer(any MTLBuffer)
    }
    
}


public protocol MetalArgumentable {
    
    var function: MetalFunction { get }
    
    var arguments: [MetalArgumentFunction.Argument] { get }
    
}


public extension MetalArgumentable {
    
    consuming func argument(buffer: any MTLBuffer) -> MetalArgumentFunction {
        MetalArgumentFunction(function: self.function, arguments: self.arguments + [.buffer(buffer)])
    }
    
    consuming func argument(texture: any MTLTexture) -> MetalArgumentFunction {
        MetalArgumentFunction(function: self.function, arguments: self.arguments + [.texture(texture)])
    }
    
}
