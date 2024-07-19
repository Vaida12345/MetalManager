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
