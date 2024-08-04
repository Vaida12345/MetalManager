//
//  Extensions.swift
//  
//
//  Created by Vaida on 7/19/24.
//

import Metal
import MetalKit
import MetalPerformanceShaders


extension MTLTextureUsage {
    
    /// A read-write texture.
    ///
    /// enabling the `access::read_write` attribute.
    public static var shaderReadWrite: MTLTextureUsage {
        [.shaderRead, .shaderWrite]
    }
    
}


extension MTLTexture {
    
    /// Creates buffer from the given texture.
    ///
    /// - Important: You are responsible for deallocation.
    public func makeBuffer(channelsCount: Int, bitsPerComponent: Int = 8) throws -> UnsafeMutableBufferPointer<UInt8> {
        let width = self.width
        let height = self.height
        let rowBytes = width * channelsCount * bitsPerComponent / 8
        
        let commandBuffer = Cache.shared.commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeBlitCommandEncoder()!
        
        let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: width * height * channelsCount)
        let metalBuffer = try MetalManager.computeDevice.makeBuffer(bytesNoCopy: buffer)
        
        encoder.copy(
            from: self,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
            sourceSize: MTLSize(width: width, height: height, depth: 1),
            to: metalBuffer,
            destinationOffset: 0,
            destinationBytesPerRow: rowBytes,
            destinationBytesPerImage: 0
        )
        
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        return buffer
    }
    
    /// Creates a `CGImage` from the texture.
    public func makeCGImage(channelsCount: Int = 4, bitsPerComponent: Int = 8, colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo = .premultipliedLast) throws -> CGImage {
        let buffer = try self.makeBuffer(channelsCount: channelsCount)
        let rowBytes = width * channelsCount * bitsPerComponent / 8
        let data = Data(bytesNoCopy: buffer.baseAddress!, count: width * height * 4, deallocator: .free)
        
        guard let provider = CGDataProvider(data: data as CFData),
              let cgImage = CGImage(width: width,
                                    height: height,
                                    bitsPerComponent: bitsPerComponent,
                                    bitsPerPixel: channelsCount * bitsPerComponent,
                                    bytesPerRow: rowBytes,
                                    space: colorSpace,
                                    bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo.rawValue),
                                    provider: provider,
                                    decode: nil,
                                    shouldInterpolate: false,
                                    intent: .defaultIntent) else {
            throw MetalResourceCreationError.cannotCreateCGImageFromTexture
        }
        
        return cgImage
    }
    
}
