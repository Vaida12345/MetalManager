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
    
    /// Creates a `CGImage` from the texture.
    public func makeCGImage(colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()) -> CGImage? {
        
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
