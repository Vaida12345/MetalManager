//
//  TextureView.swift
//  
//
//  Created by Vaida on 7/19/24.
//

#if canImport(SwiftUI) && os(macOS)
import SwiftUI
import MetalKit


/// A view that renders the texture with the provided aspect ratio content mode. This view behaves similar to `SwiftUI.Image`.
@available(macOS 13.0, *)
public struct TextureView: NSViewRepresentable {
    
    let texture: MTLTexture
    
    let contentMode: ContentMode?
    
    let isPaused: Bool
    
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(cache: Coordinator.Cache())
    }
    
    public func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MetalManager.computeDevice
        view.delegate = context.coordinator
        view.enableSetNeedsDisplay = true
        view.isPaused = isPaused
        view.colorPixelFormat = .rgba8Unorm
        view.clearColor = MTLClearColorMake(0, 0, 0, 0)
        view.layer?.isOpaque = false
        
        context.coordinator.setupPipeline(view: view)
        return view
    }
    
    public func updateNSView(_ view: MTKView, context: Context) {
        context.coordinator.texture = texture
    }
    
    @available(macOS 13.0, *)
    public func sizeThatFits(
        _ proposal: ProposedViewSize,
        nsView: Self.NSViewType,
        context: Self.Context
    ) -> CGSize? {
        if let contentMode {
            if let width = proposal.width,
               let height = proposal.height {
                return CGSize(width: texture.width, height: texture.height).aspectRatio(contentMode, in: CGSize(width: width, height: height))
            }
        }
        
        return nil
    }
    
    /// Sets the content mode.
    ///
    /// - Parameters:
    ///   - contentMode: A flag indicating whether this view should fit or fill the parent context.
    public func aspectRatio(contentMode: ContentMode) -> TextureView {
        TextureView(texture: self.texture, aspectRatio: contentMode, isPaused: isPaused)
    }
    
    public init(texture: MTLTexture, aspectRatio contentMode: ContentMode? = nil, isPaused: Bool = true) {
        self.texture = texture
        self.contentMode = contentMode
        self.isPaused = isPaused
    }
    
    
    public final class Coordinator: NSObject, MTKViewDelegate {
        
        var texture: MTLTexture?
        
        var pipelineState: MTLRenderPipelineState?
        
        var vertexBuffer: MTLBuffer?
        
        let cache: Cache
        
        
        @MainActor func setupPipeline(view: MTKView) {
            guard let device = view.device else { return }
            
            let library: any MTLLibrary
            let vertexFunction: any MTLFunction
            let fragmentFunction: any MTLFunction
            
            if device.isEqual(MetalManager.Configuration.shared.computeDevice) {
                if let _library = cache.libraries[Bundle.module] {
                    library = _library
                } else {
                    library = try! device.makeDefaultLibrary(bundle: .module)
                    cache.libraries[Bundle.module] = library
                }
                
                let _vertex = MetalFunction(name: "textureView_vertex", bundle: .module)
                if let _vertexFunction = cache.functions[_vertex] {
                    vertexFunction = _vertexFunction
                } else {
                    vertexFunction = library.makeFunction(name: "textureView_vertex")!
                    cache.functions[_vertex] = vertexFunction
                }
                
                let _fragment = MetalFunction(name: "textureView_fragment", bundle: .module)
                if let _fragmentFunction = cache.functions[_fragment] {
                    fragmentFunction = _fragmentFunction
                } else {
                    fragmentFunction = library.makeFunction(name: "textureView_fragment")!
                    cache.functions[_fragment] = fragmentFunction
                }
            } else {
                library = try! device.makeDefaultLibrary(bundle: .module)
                vertexFunction = library.makeFunction(name: "textureView_vertex")!
                fragmentFunction = library.makeFunction(name: "textureView_fragment")!
            }
            
            let vertexDescriptor = MTLVertexDescriptor()
            vertexDescriptor.attributes[0].format = .half4
            vertexDescriptor.attributes[0].offset = 0
            vertexDescriptor.attributes[0].bufferIndex = 0
            vertexDescriptor.attributes[1].format = .float2
            vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 4
            vertexDescriptor.attributes[1].bufferIndex = 0
            vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 6
            vertexDescriptor.layouts[0].stepFunction = .perVertex
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.vertexDescriptor = vertexDescriptor
            pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
            
            // Enable blending
            pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
            pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
            pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .max
            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            
            pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            
            let vertices: [Float] = [
                -1, -1, 0, 1, 0, 1,  // Vertex 1: position (-1, -1) and texture coordinate (0, 1)
                 1, -1, 0, 1, 1, 1,  // Vertex 2: position ( 1, -1) and texture coordinate (1, 1)
                 -1,  1, 0, 1, 0, 0,  // Vertex 3: position (-1,  1) and texture coordinate (0, 0)
                 1,  1, 0, 1, 1, 0   // Vertex 4: position ( 1,  1) and texture coordinate (1, 0)
            ]
            
            vertexBuffer = view.device!.makeBuffer(bytes: vertices, length: MemoryLayout<Float>.size * vertices.count, options: [])
        }
        
        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle view size changes if necessary
        }
        
        public func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let texture = texture,
                  let pipelineState = pipelineState,
                  let commandBuffer = cache.commandQueue.makeCommandBuffer(),
                  let renderPassDescriptor = view.currentRenderPassDescriptor else {
                return
            }
            
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            encoder.setRenderPipelineState(pipelineState)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setFragmentTexture(texture, index: 0)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            encoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
            
            commandBuffer.waitUntilCompleted()
        }
        
        @MainActor
        final class Cache {
            
            var libraries: [Bundle : MTLLibrary] = [:]
            
            var functions: [MetalFunction : MTLFunction] = [:]
            
            var pipelineStates: [MetalFunction : MTLComputePipelineState] = [:]
            
            lazy var commandQueue: MTLCommandQueue = MetalManager.computeDevice.makeCommandQueue(maxCommandBufferCount: 1)!
            
            
            init() {
            }
        }
        
        init(texture: MTLTexture? = nil, pipelineState: MTLRenderPipelineState? = nil, cache: Cache) {
            self.texture = texture
            self.pipelineState = pipelineState
            self.cache = cache
        }
    }

}

@available(macOS 10.15, *)
private extension CGSize {
    
    func aspectRatio(_ contentMode: ContentMode, in target: CGSize) -> CGSize {
        let width: CGFloat
        let height: CGFloat
        
        switch contentMode {
        case .fit:
            // if the `size` is wider than `pixel size`
            if target.width / target.height >= self.width / self.height {
                height = target.height
                width = self.width * target.height / self.height
            } else {
                width = target.width
                height = self.height * target.width / self.width
            }
        case .fill:
            // if the `size` is wider than `pixel size`
            if target.width / target.height >= self.width / self.height {
                width = target.width
                height = self.height * target.width / self.width
            } else {
                height = target.height
                width = self.width * target.height / self.height
            }
        }
        
        return CGSize(width: width, height: height)
    }
    
}
#endif
