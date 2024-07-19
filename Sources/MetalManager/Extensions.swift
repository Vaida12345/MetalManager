//
//  Extensions.swift
//  
//
//  Created by Vaida on 7/19/24.
//

import Metal
import MetalKit
import MetalPerformanceShaders


extension MTKTextureLoader {
    
    /// Synchronously loads image data and creates a new Metal texture from a given bitmap image.
    public func newTexture(
        cgImage: CGImage,
        textureUsage: MTLTextureUsage
    ) throws -> any MTLTexture {
        try self.newTexture(cgImage: cgImage, options: [.textureUsage : textureUsage.rawValue, .origin : MTKTextureLoader.Origin.topLeft])
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


extension CGImage {
    
    public func makeTexture() -> any MTLTexture {
        let image = MPSImage(
            device: MetalManager.Configuration.shared.computeDevice,
            imageDescriptor: MPSImageDescriptor(
                channelFormat: .unorm8,
                width: self.width,
                height: self.height,
                featureChannels: 4
            )
        )
        
        let context = CGContext(data: nil, width: self.width, height: self.height, bitsPerComponent: self.bitsPerComponent, bytesPerRow: self.bytesPerRow, space: self.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(self, in: CGRect(x: 0, y: 0, width: self.width, height: self.height))
        
        image.writeBytes(context.data!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
        
        return image.texture
    }
    
}


extension MTLTexture {
    
    public func makeCGImage() -> CGImage? {
//        let context = CIContext()
//        let date = Date()
//        let ciImage = CIImage(mtlTexture: self)!
//        if #available(macOS 10.15, *) {
//            print(date.distance(to: Date()), "make CIIMage")
//        } else {
//            // Fallback on earlier versions
//        }
//        return context.createCGImage(ciImage, from: ciImage.extent)
//        
        
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
                                    space: CGColorSpaceCreateDeviceRGB(),
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
