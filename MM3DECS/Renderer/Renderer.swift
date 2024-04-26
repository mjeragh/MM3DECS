/// Copyright (c) 2022 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import MetalKit

// swiftlint:disable implicitly_unwrapped_optional

enum CameraType {
    case perspective
    case arcball
    case orthographic
}



class Renderer: NSObject {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!
    weak var delegate: RendererDelegate?
    
    var options: Options?
    
    var forwardPassPipelineState: MTLRenderPipelineState!
    let depthStencilState: MTLDepthStencilState?
    
    var isReadyToRender = false
    var params = Params()
    
//    func startRendering() {
//        self.isReadyToRender = true
//    }
    
    init(metalView: MTKView) {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue() else {
            fatalError("GPU not available")
        }
        Renderer.device = device
        Renderer.commandQueue = commandQueue
        metalView.device = device
        
        //Scene Managment and entity init
        
        // create the shader function library
        let library = device.makeDefaultLibrary()
        Self.library = library
        let forwardPassVertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction =
        library?.makeFunction(name: "fragment_normals")
        
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
        //This code is marked as the beginning of the refactoring
       
        super.init()
        metalView.clearColor = MTLClearColor(
            red: 0.0,
            green: 0.0,
            blue: 0.19,
            alpha: 1.0)
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.delegate = self
        mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
        
        
    }//Init
    
    
    static func buildDepthStencilState() -> MTLDepthStencilState? {
        // 1
        let descriptor = MTLDepthStencilDescriptor()
        // 2
        descriptor.depthCompareFunction = .less
        // 3
        descriptor.isDepthWriteEnabled = true
        return Renderer.device.makeDepthStencilState(
            descriptor: descriptor)
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
        let aspect = Float(view.bounds.width) / Float(view.bounds.height)
        
        delegate?.updateSceneCamera(aspectRatio: aspect)
        
        
        params.width = UInt32(size.width)
        params.height = UInt32(size.height)
    }
    
    
    
    
    
    func draw(in view: MTKView) {
        guard delegate?.isRunning() == true else {
            return
        }
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
            &params,
            length: MemoryLayout<Params>.stride,
            index: 12)
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
