//
//  Device Ex.swift
//  
//
//  Created by Vaida on 7/23/24.
//

@preconcurrency
import Metal
import CoreGraphics
import MetalKit


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
    
    
    private func make_texture_from_image_buffer(buffer: UnsafeMutableBufferPointer<UInt8>, source: TextureSource, width: Int, height: Int, context: MetalContext?, usage: MTLTextureUsage) async throws -> any MTLTexture {
        let date = Date()
        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = .rgba8Unorm
        descriptor.width = width
        descriptor.height = height
        descriptor.usage = usage
        descriptor.storageMode = .private
        descriptor.textureType = .type2D
        
        guard let texture = MetalManager.computeDevice.makeTexture(descriptor: descriptor) else {
            throw MetalResourceCreationError.cannotCreateTexture(reason: .cannotCreateEmptyTexture(width: width, height: height))
        }
        print("setup texture took: \(date.distance(to: Date()) * 1000)")
        
        let date3 = Date()
        let buffer = try MetalManager.computeDevice.makeBuffer(bytesNoCopy: buffer)
        print("no copy buffer took", date3.distance(to: Date()) * 1000)
        let date4 = Date()
        let commandBuffer = Cache.shared.commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeBlitCommandEncoder()!
        print("make encoders took", date4.distance(to: Date()) * 1000)
        
        encoder.copy(
            from: buffer,
            sourceOffset: 0,
            sourceBytesPerRow: 4 * width,
            sourceBytesPerImage: 0,
            sourceSize: MTLSize(width: width, height: height, depth: 1),
            to: texture,
            destinationSlice: 0,
            destinationLevel: 0,
            destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0)
        )
        encoder.optimizeContentsForGPUAccess(texture: texture)
        
        encoder.endEncoding()
        commandBuffer.addCompletedHandler { _ in
            source.release() // ensure the buffer is still alive.
        }
        commandBuffer.commit()
        
        let commitDate = Date()
        
        if let context {
//            nonisolated(unsafe) let work =
            await context.addPrerequisite {
                print("\(commitDate.distance(to: Date()) * 1000) since commit")
                print(commandBuffer.status.rawValue)
                let date = Date()
                commandBuffer.waitUntilCompleted()
                print("actual job \(date.distance(to: Date()) * 1000)")
            }
        } else {
            let date = Date()
            commandBuffer.waitUntilCompleted()
            print("wait for completion (as no context) \(date.distance(to: Date()) * 1000)")
        }
        
        print("fill texture took: \(date3.distance(to: Date()) * 1000)")
        
        return texture
    }
    
    private func make_texture_using_CGContext(from image: CGImage, context: MetalContext?, usage: MTLTextureUsage) async throws -> any MTLTexture {
        let date2 = Date()
        let cgContext = CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: 4 * image.width,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        cgContext.draw(image, in: CGRect(origin: .zero, size: CGSize(width: image.width, height: image.height)))
        print("setup context took: \(date2.distance(to: Date()) * 1000)")
        
        try Task.checkCancellation()
        
        return try await make_texture_from_image_buffer(
            buffer: UnsafeMutableBufferPointer<UInt8>(start: cgContext.data?.assumingMemoryBound(to: UInt8.self), count: image.width * image.height * 4),
            source: .cgContext(Unmanaged.passRetained(cgContext)),
            width: image.width,
            height: image.height,
            context: context,
            usage: usage
        )
    }
    
    /// Creates a MTLTexture from CGImage.
    ///
    /// The located texture is in `rgba8Unorm`, which indicates that each pixel has a red, green, blue, and alpha channel, where each channel is an 8-bit unsigned normalized value (i.e. 0 maps to 0.0 and 255 maps to 1.0).
    public func makeTexture(from image: CGImage, usage: MTLTextureUsage, context: MetalContext?) async throws -> any MTLTexture {
        let date = Date()
        defer {
            print("load texture", date.distance(to: Date()) * 1000)
        }
        
        guard image.bitsPerComponent == 8 && image.bitsPerPixel == 32 else {
            return try await make_texture_using_CGContext(from: image, context: context,  usage: usage)
        }
        
        print("use direct pass")
        
        guard let data = image.dataProvider?.data else {
            throw MetalResourceCreationError.cannotCreateTexture(reason: .cannotObtainImageData(image: image))
        }
        
        return try await make_texture_from_image_buffer(
            buffer: UnsafeMutableBufferPointer<UInt8>(start: .init(mutating: CFDataGetBytePtr(data)), count: image.width * image.height * 4),
            source: .cgImage(Unmanaged.passRetained(data)),
            width: image.width,
            height: image.height,
            context: context,
            usage: usage
        )
    }
    
}


private enum TextureSource: @unchecked Sendable {
    case cgImage(Unmanaged<CFData>)
    case cgContext(Unmanaged<CGContext>)
    
    func release() {
        switch self {
        case .cgImage(let unmanaged):
            unmanaged.release()
        case .cgContext(let unmanaged):
            unmanaged.release()
        }
    }
}
