//
//  Device Ex.swift
//  
//
//  Created by Vaida on 7/23/24.
//

import Metal
import CoreGraphics


extension MetalManager {
    
    /// The default device defined in ``MetalManager/Configuration``.
    public static var computeDevice: any MTLDevice {
        get {
            MetalManager.Configuration.shared.computeDevice
        }
        set {
            MetalManager.Configuration.shared.computeDevice = newValue
        }
    }
    
}


extension MTLDevice {
    
    /// Allocates a new buffer of a given length and initializes its contents by copying existing data into it.
    ///
    /// - Parameters:
    ///   - buffer: A pointer to the starting memory address the method copies the initialization data from.
    ///   - options: An `MTLResourceOptions` instance that sets the buffer’s storage and hazard-tracking modes. The default one is `storageModeShared` for Apple Silicons.
    ///
    /// - throws: ``MetalResourceCreationError/cannotCreateBuffer(source:)``
    @inline(__always)
    public func makeBuffer<T>(
        bytes buffer: UnsafeMutableBufferPointer<T>,
        options: MTLResourceOptions = []
    ) throws -> any MTLBuffer {
        let label =  "copied from \(buffer.debugDescription)"
        guard let buffer = self.makeBuffer(bytes: buffer.baseAddress!, length: buffer.count &* MemoryLayout<T>.stride, options: options) else {
            throw MetalResourceCreationError.cannotCreateBuffer(source: buffer.debugDescription)
        }
        buffer.label = label
        
        return buffer
    }
    
    /// Creates a buffer that wraps an existing contiguous memory allocation.
    ///
    /// - Parameters:
    ///   - buffer: A page-aligned pointer to the starting memory address.
    ///   - options: An `MTLResourceOptions` instance that sets the buffer’s storage and hazard-tracking modes. The default one is `storageModeShared` for Apple Silicons.
    ///   - deallocator: A block the framework invokes when it deallocates the buffer so that your app can release the underlying memory; otherwise nil to opt out.
    @inline(__always)
    public func makeBuffer<T>(
        bytesNoCopy buffer: UnsafeMutableBufferPointer<T>,
        options: MTLResourceOptions = [],
        deallocator: ((UnsafeMutableRawPointer, Int) -> Void)? = nil
    ) throws -> any MTLBuffer {
        let label = "no copy from \(buffer.debugDescription)"
        guard let buffer = self.makeBuffer(bytesNoCopy: buffer.baseAddress!, length: buffer.count &* MemoryLayout<T>.stride, options: options, deallocator: deallocator) else {
            throw MetalResourceCreationError.cannotCreateBuffer(source: buffer.debugDescription)
        }
        buffer.label = label
        
        return buffer
    }
    
    /// Creates a buffer that wraps an existing contiguous memory allocation.
    @inline(__always)
    public func makeBuffer<T>(
        bytesNoCopy array: inout Array<T>,
        options: MTLResourceOptions = []
    ) throws -> any MTLBuffer {
        let label = "no copy from \(array.debugDescription)"
        guard let buffer = self.makeBuffer(bytesNoCopy: &array, length: array.count &* MemoryLayout<T>.stride, options: options, deallocator: .none) else {
            throw MetalResourceCreationError.cannotCreateBuffer(source: array.description)
        }
        buffer.label = label
        
        return buffer
    }
    
    /// Creates a buffer the method clears with zero values.
    @inline(__always)
    public func makeBuffer<T>(
        of type: T,
        count: Int,
        options: MTLResourceOptions = []
    ) throws -> any MTLBuffer {
        guard let buffer = self.makeBuffer(length: MemoryLayout<T>.stride &* count, options: options) else {
            throw MetalResourceCreationError.cannotCreateBuffer(source: "(type \(type), count: \(count))")
        }
        buffer.label = "empty from (type \(type), count: \(count))"
        
        return buffer
    }
    
    /// Creates a MTLTexture from CGImage.
    ///
    /// The located texture is in `rgba8Unorm`, which indicates that each pixel has a red, green, blue, and alpha channel, where each channel is an 8-bit unsigned normalized value (i.e. 0 maps to 0.0 and 255 maps to 1.0).
    @inlinable
    public func makeTexture(from image: CGImage, usage: MTLTextureUsage) throws -> any MTLTexture {
        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = .rgba8Unorm
        descriptor.width = image.width
        descriptor.height = image.height
        descriptor.usage = usage
        descriptor.storageMode = .shared
        
        guard let texture = MetalManager.Configuration.shared.computeDevice.makeTexture(descriptor: descriptor) else {
            throw MetalResourceCreationError.cannotCreateTexture(reason: .cannotCreateEmptyTexture(width: image.width, height: image.height))
        }
        texture.label = "Texture from \(image)"
        
        guard let data = image.dataProvider?.data as? Data else {
            throw MetalResourceCreationError.cannotCreateTexture(reason: .cannotObtainImageData(image: image))
        }
        
        data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            texture.replace(
                region: MTLRegion(
                    origin: MTLOrigin(x: 0, y: 0, z: 0),
                    size: MTLSize(width: image.width, height: image.height, depth: 1)
                ),
                mipmapLevel: 0,
                withBytes: bytes.baseAddress!,
                bytesPerRow: image.bytesPerRow
            )
        }
        
        return texture
    }
    
}
