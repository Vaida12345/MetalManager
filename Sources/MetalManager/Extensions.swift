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


extension UnsafeMutableBufferPointer {
    
    /// Creates a MTLBuffer from the given pointer.
    ///
    /// - Note: The default ``MetalManager/Configuration/computeDevice`` would be used to create such buffer.
    public func makeMTLBuffer() -> any MTLBuffer {
        MetalManager.Configuration.shared.computeDevice.makeBuffer(bytes: self.baseAddress!, length: self.count * MemoryLayout<Element>.stride, options: .storageModeShared)!
    }
    
}


extension CGImage {
    
    /// Creates a MTLTexture from CGImage.
    ///
    /// The located texture is in `rgba8Unorm`, which indicates that each pixel has a red, green, blue, and alpha channel, where each channel is an 8-bit unsigned normalized value (i.e. 0 maps to 0.0 and 255 maps to 1.0).
    ///
    /// - Note: The default ``MetalManager/Configuration/computeDevice`` would be used to create such texture.
    public func makeTexture(usage: MTLTextureUsage) throws -> any MTLTexture {
        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = .rgba8Unorm
        descriptor.width = self.width
        descriptor.height = self.height
        descriptor.usage = usage
        descriptor.storageMode = .shared
        
        guard let texture = MetalManager.Configuration.shared.computeDevice.makeTexture(descriptor: descriptor) else {
            throw MetalManager.Error.cannotCreateTextureFromImage
        }
        
        let data = self.dataProvider!.data! as Data
        
        data.withUnsafeBytes { bytes in
            texture.replace(
                region: MTLRegion(
                    origin: MTLOrigin(x: 0, y: 0, z: 0),
                    size: MTLSize(width: self.width, height: self.height, depth: 1)
                ),
                mipmapLevel: 0,
                withBytes: bytes,
                bytesPerRow: self.bytesPerRow
            )
        }
        
        return texture
    }
    
}


extension MTLTexture {
    
    /// Creates a `CGImage` from the texture.
    public func makeCGImage(colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()) -> CGImage? {
        
        let width = self.width
        let height = self.height
        let rowBytes = width * 4 // assuming 4 channels (BGRA)
        
        guard let dataPtr = malloc(width * height * 4) else {
            return nil
        }
        self.getBytes(dataPtr, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        
        let data = Data(bytesNoCopy: dataPtr, count: width * height * 4, deallocator: .free)
        
        guard let provider = CGDataProvider(data: data as CFData),
              let cgImage = CGImage(width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bitsPerPixel: 32,
                                    bytesPerRow: rowBytes,
                                    space: colorSpace,
                                    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                                    provider: provider,
                                    decode: nil,
                                    shouldInterpolate: false,
                                    intent: .defaultIntent) else {
            return nil
        }
        
        return cgImage
    }
    
}
