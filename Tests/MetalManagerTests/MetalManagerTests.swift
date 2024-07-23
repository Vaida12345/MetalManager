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
    
}
