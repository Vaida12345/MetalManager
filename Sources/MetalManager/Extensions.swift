//
//  Extensions.swift
//  
//
//  Created by Vaida on 7/19/24.
//

import Metal
import MetalKit


extension MTKTextureLoader {
    
    /// Synchronously loads image data and creates a new Metal texture from a given bitmap image.
    public func newTexture(
        cgImage: CGImage,
        textureUsage: MTLTextureUsage
    ) throws -> any MTLTexture {
        try self.newTexture(cgImage: cgImage, options: [.textureUsage: NSNumber(value: textureUsage.rawValue)])
    }
    
}


extension MTLTextureUsage {
    
    /// A read-write texture.
    ///
    /// enabling the `access::read_write` attribute.
    public static var shaderReadWrite: MTLTextureUsage {
        [.shaderRead, .shaderWrite]
    }
    
}


extension MTLTexture {
    
    public func makeCGImage() -> CGImage? {
        let width = self.width
        let height = self.height
        let rowBytes = width * 4 // assuming 4 channels (RGBA)
        
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
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                                    provider: provider,
                                    decode: nil,
                                    shouldInterpolate: false,
                                    intent: .defaultIntent) else {
            return nil
        }
        
        return cgImage
    }
    
}
