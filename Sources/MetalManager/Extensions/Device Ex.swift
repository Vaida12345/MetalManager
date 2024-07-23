//
//  Device Ex.swift
//  
//
//  Created by Vaida on 7/23/24.
//

import Metal
import CoreGraphics


extension MTLDevice {
    
    /// Allocates a new buffer of a given length and initializes its contents by copying existing data into it.
    ///
    /// - Parameters:
    ///   - buffer: A pointer to the starting memory address the method copies the initialization data from.
    ///   - options: An `MTLResourceOptions` instance that sets the buffer’s storage and hazard-tracking modes. The default one uses `storageModeShared` for Apple Silicons.
    ///
    /// - throws: ``MetalResourceCreationError/cannotCreateBuffer(source:)``
    @inline(__always)
    public func makeBuffer<T>(
        bytes buffer: UnsafeMutableBufferPointer<T>,
        options: MTLResourceOptions = []
    ) throws -> any MTLBuffer {
        guard let buffer = self.makeBuffer(bytes: buffer.baseAddress!, length: buffer.count * MemoryLayout<T>.stride, options: options) else {
            throw MetalResourceCreationError.cannotCreateBuffer(source: buffer.debugDescription)
        }
        
        return buffer
    }
    
    /// Creates a MTLTexture from CGImage.
    ///
    /// The located texture is in `rgba8Unorm`, which indicates that each pixel has a red, green, blue, and alpha channel, where each channel is an 8-bit unsigned normalized value (i.e. 0 maps to 0.0 and 255 maps to 1.0).
    public func makeTexture(from image: CGImage, usage: MTLTextureUsage) throws -> any MTLTexture {
        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = .rgba8Unorm
        descriptor.width = image.width
        descriptor.height = image.height
        descriptor.usage = usage
        descriptor.storageMode = .shared
        
        guard let texture = MetalManager.Configuration.shared.computeDevice.makeTexture(descriptor: descriptor) else {
            throw MetalResourceCreationError.cannotCreateTexture(reason: .cannotCreateEmptyTexture)
        }
        
        guard let data = image.dataProvider?.data as? Data else {
            throw MetalResourceCreationError.cannotCreateTexture(reason: .cannotObtainImageData(image: image))
        }
        
        withUnsafePointer(to: data) { bytes in
            texture.replace(
                region: MTLRegion(
                    origin: MTLOrigin(x: 0, y: 0, z: 0),
                    size: MTLSize(width: image.width, height: image.height, depth: 1)
                ),
                mipmapLevel: 0,
                withBytes: bytes,
                bytesPerRow: image.bytesPerRow
            )
        }
        
        return texture
    }
    
}


public enum MetalResourceCreationError: LocalizedError, CustomStringConvertible {
    /// Indicates failure of `MTLBuffer` creation.
    case cannotCreateBuffer(source: String)
    case cannotCreateTexture(reason: TextureFailureReason)
    
    
    public var description: String {
        switch self {
        case .cannotCreateBuffer(let source):
            "Failed to create Metal buffer from \(source)"
        case .cannotCreateTexture(let reason):
            "Failed to create Metal texture: \(reason.description)"
        }
    }
    
    public var errorDescription: String? {
        self.description
    }
    
    public enum TextureFailureReason: CustomStringConvertible, Sendable {
        case cannotCreateEmptyTexture
        case cannotObtainImageData(image: CGImage)
        
        public var description: String {
            switch self {
            case .cannotCreateEmptyTexture:
                "Failed to create an empty texture."
            case .cannotObtainImageData(let image):
                "Failed to obtain image data from \(image)"
            }
        }
    }
}
