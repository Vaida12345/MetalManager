import Testing
import AppKit
@testable import MetalManager

@Suite("Metal Manager Tests")
struct MetalManagerTests {
    
    @Test
    func textureConversion() async throws {
        let image = NSImage(systemSymbolName: "doc", accessibilityDescription: nil)!
        let sourceImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        let context = CGContext(
            data: nil,
            width: sourceImage.width,
            height: sourceImage.height,
            bitsPerComponent: 8,
            bytesPerRow: 4 * sourceImage.width,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.draw(sourceImage, in: CGRect(origin: .zero, size: CGSize(width: sourceImage.width, height: sourceImage.height)))
        let cgImage = context.makeImage()!
        
        let device = MetalManager.Configuration.shared.computeDevice
        let texture = try device.makeTexture(from: cgImage, usage: .shaderRead)
        let result = texture.makeCGImage()
        
        #expect(cgImage.dataProvider?.data as? Data == result?.dataProvider?.data as? Data)
    }
    
    @Test
    func serializedExecution() async throws {
        var array = [1, 2, 3, 4, 5, 6, 7, 8] as [Float]
        let buffer = try MetalManager.computeDevice.makeBuffer(bytesNoCopy: &array)
        
        let commandBuffer = try await MetalCommandBuffer()
        
        try await MetalFunction(name: "doubleValues", bundle: .module)
            .argument(buffer: buffer)
            .dispatch(to: commandBuffer, width: array.count)
        
        try await MetalFunction(name: "addConstant", bundle: .module)
            .argument(buffer: buffer)
            .dispatch(to: commandBuffer, width: array.count)
        
        await commandBuffer.perform()
        
        #expect(array == [7.0, 9.0, 11.0, 13.0, 15.0, 17.0, 19.0, 21.0])
    }
    
}
