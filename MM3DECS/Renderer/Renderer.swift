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
    var entityManager: EntityManager
    var renderSystem: RenderSystem
    var systems: [System] = []
    
  static var device: MTLDevice!
  static var commandQueue: MTLCommandQueue!
  static var library: MTLLibrary!

  var options: Options

  var forwardPassPipelineState: MTLRenderPipelineState!
  let depthStencilState: MTLDepthStencilState?

 
  var timer: Float = 0
  var params = Params()

  init(metalView: MTKView, options: Options) {
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
    let fragmentFunction =
      library?.makeFunction(name: "fragment_main")

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

    self.options = options
    depthStencilState = Renderer.buildDepthStencilState()
      //This code is marked as the beginning of the refactoring
      self.entityManager = EntityManager()
      self.renderSystem = RenderSystem(entityManager: entityManager)
      self.systems = [renderSystem]
      
    super.init()
    metalView.clearColor = MTLClearColor(
      red: 0.0,
      green: 0.0,
      blue: 0.19,
      alpha: 1.0)
    metalView.depthStencilPixelFormat = .depth32Float
    metalView.delegate = self
    mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
      setupEntites()
      entityManager.addEntity(entity: createCameraEntity(type: .perspective))
  }//Init

    func createCameraEntity(type: CameraType) -> Entity {
        let cameraEntity = Entity()
        entityManager.addEntity(entity: cameraEntity)
        
        // Common transform component for all cameras
        entityManager.addComponent(component: TransformComponent(position: [0, 0, -5]), to: cameraEntity)
        
        let aspect = Float(16) / Float(9) // Example aspect ratio
        
        switch type {
        case .perspective:
            let cameraComponent = CameraComponent(fieldOfView: Float(70).degreesToRadians, nearClippingPlane: 0.1, farClippingPlane: 100, aspectRatio: aspect)
            entityManager.addComponent(component: cameraComponent, to: cameraEntity)
            
        case .arcball:
            let arcballCameraComponent = ArcballCameraComponent(aspect: aspect, fov: Float(70).degreesToRadians, near: 0.1, far: 100, target: [0, 0, 0], distance: 5, minDistance: 1, maxDistance: 20)
            entityManager.addComponent(component: arcballCameraComponent, to: cameraEntity)
            
        case .orthographic:
            let orthographicCameraComponent = OrthographicCameraComponent(aspect: aspect, viewSize: 10, near: 0.1, far: 100)
            entityManager.addComponent(component: orthographicCameraComponent, to: cameraEntity)
        }
        
        return cameraEntity
    }




    
    func setupEntites() {
        let trainEntity = Entity()
                entityManager.addEntity(entity: trainEntity)
                entityManager.addComponent(component: RenderableComponent(device: Renderer.device, name: "train.usd"), to: trainEntity)
        entityManager.addComponent(component: TransformComponent(position: float3(0, -0.6, 0), rotation: float3(0, 0, 0), scale: float3(1, 1, 1)), to: trainEntity)
               // Add other entities and components as needed
        
    }
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

        // Update Perspective Camera
        if let cameraEntity = entityManager.entitiesWithAnyComponents([CameraComponent.self]).first,
           var cameraComponent = entityManager.getComponent(type: CameraComponent.self, for: cameraEntity) {
            cameraComponent.aspectRatio = aspect
            entityManager.addComponent(component: cameraComponent, to: cameraEntity)
        }

        // Update Arcball Camera
        if let arcballCameraEntity = entityManager.entitiesWithAnyComponents([ArcballCameraComponent.self]).first,
           var arcballCameraComponent = entityManager.getComponent(type: ArcballCameraComponent.self, for: arcballCameraEntity) {
            arcballCameraComponent.aspect = aspect
            entityManager.addComponent(component: arcballCameraComponent, to: arcballCameraEntity)
        }

        // Update Orthographic Camera
        if let orthoCameraEntity = entityManager.entitiesWithAnyComponents([OrthographicCameraComponent.self]).first,
           var orthoCameraComponent = entityManager.getComponent(type: OrthographicCameraComponent.self, for: orthoCameraEntity) {
            orthoCameraComponent.aspect = aspect
            entityManager.addComponent(component: orthoCameraComponent, to: orthoCameraEntity)
        }

        params.width = UInt32(size.width)
        params.height = UInt32(size.height)
    }




 
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
      &params,
      length: MemoryLayout<Uniforms>.stride,
      index: 12)
      renderEncoder.setRenderPipelineState(forwardPassPipelineState)

     let deltaTime = 1 / Float(view.preferredFramesPerSecond)
      systems.forEach { $0.update(deltaTime: deltaTime, renderEncoder: renderEncoder) }

    renderEncoder.endEncoding()
    guard let drawable = view.currentDrawable else {
      return
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}
