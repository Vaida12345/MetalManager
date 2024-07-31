import Testing
import AppKit
@testable import MetalManager


@Suite("Metal Manager Tests")
struct MetalManagerTests {
    
    @Test
    func textureConversion() async throws {
        let cgImage = makeSampleCGImage()
        
        let device = MetalManager.Configuration.shared.computeDevice
        let texture = try device.makeTexture(from: cgImage, usage: .shaderRead)
        let result = texture.makeCGImage()
        
        #expect(cgImage.dataProvider?.data as? Data == result?.dataProvider?.data as? Data)
    }
    
    @Test
    func singularExecution() async throws {
        var array = [1, 2, 3, 4, 5, 6, 7, 8] as [Float]
        let buffer = try MetalManager.computeDevice.makeBuffer(bytesNoCopy: &array)
        
        try await MetalFunction(name: "doubleValues", bundle: .module)
            .argument(buffer: buffer)
            .perform(width: array.count)
        
        #expect(array == [2, 4, 6, 8, 10, 12, 14, 16])
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
    
    @Test
    func serializedExecutionWithAdvancedControls() async throws {
        var array = [1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1] as [Float]
        let buffer = try MetalManager.computeDevice.makeBuffer(bytesNoCopy: &array)
        
        let context = try await MetalContext()
        let result = MetalDependentState(initialValue: true, context: context)
        
        try await MetalFunction(name: "allEqual", bundle: .module)
            .argument(buffer: buffer)
            .argument(state: result)
            .dispatch(to: context.addJob(), width: array.count)
        
        try await context.synchronize()
        try await #expect(result.synchronize() == false)
    }
    
}


private func makeSampleCGImage() -> CGImage {
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
    return context.makeImage()!
}
