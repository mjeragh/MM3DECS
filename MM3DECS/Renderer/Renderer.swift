
import MetalKit
import OSLog

// swiftlint:disable implicitly_unwrapped_optional



class Renderer: NSObject {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!
    weak var delegate: RendererDelegate?
    
    var options: Options?
    
    var forwardPassPipelineState: MTLRenderPipelineState!
    let depthStencilState: MTLDepthStencilState?
    //static var defaultPipelinestate: MTLRenderPipelineState!
    var logger = Logger(subsystem: "MM3DECS", category: "Renderer")
    
//    var isReadyToRender = false
    static var params = Params()
    
    init(metalView: MTKView) {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue() else {
            fatalError("GPU not available")
        }
        Renderer.device = device
        Renderer.commandQueue = commandQueue
        metalView.device = device
        
        // create the shader function library
        let library = device.makeDefaultLibrary()
        Self.library = library
        let forwardPassVertexFunction = library?.makeFunction(name: "vertex_main")
        
        
        let functionConstantValues = MTLFunctionConstantValues()
        var hasTexture = false
        functionConstantValues.setConstantValue(&hasTexture, type: .bool, index: 0)
        
        let fragmentFunction = try! library?.makeFunction(name: "fragment_main", constantValues: functionConstantValues)
         
        // Create the model pipeline state object
        let forwardPassPipelineDescriptor = MTLRenderPipelineDescriptor()
        forwardPassPipelineDescriptor.vertexFunction = forwardPassVertexFunction
        forwardPassPipelineDescriptor.fragmentFunction = fragmentFunction
        forwardPassPipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        forwardPassPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        forwardPassPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultLayout
        
        do {
            forwardPassPipelineState = try device.makeRenderPipelineState(descriptor: forwardPassPipelineDescriptor)
        } catch let error {
            fatalError("Failed to create model pipeline state, error: \(error)")
        }
        
        depthStencilState = Renderer.buildDepthStencilState()
        super.init()
        metalView.clearColor = MTLClearColor(
            red: 0.0,
            green: 0.0,
            blue: 0.19,
            alpha: 1.0)
        metalView.depthStencilPixelFormat = .depth32Float
    }
    
    static func buildDepthStencilState() -> MTLDepthStencilState? {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        return Renderer.device.makeDepthStencilState(
            descriptor: descriptor)
    }
}

extension Renderer {
    func draw(in view: MTKView) {
        guard
            let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
            let descriptor = view.currentRenderPassDescriptor,
            let renderEncoder =
                commandBuffer.makeRenderCommandEncoder(
                    descriptor: descriptor) else {
            return
        }

        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setFragmentBytes(
            &Renderer.params,
            length: MemoryLayout<Params>.stride,
            index: ParamsBuffer.index)
        renderEncoder.setRenderPipelineState(forwardPassPipelineState)
        
        let deltaTime = 1 / Float(view.preferredFramesPerSecond)
        delegate?.updateSceneSystems(deltaTime: deltaTime, renderEncoder: renderEncoder)
        
        renderEncoder.endEncoding()
        
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func updateOptions(options: Options) {
        self.options = options
    }
}
