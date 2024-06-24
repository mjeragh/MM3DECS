import MetalKit
import OSLog

private let semantics: [MDLMaterialSemantic] = [
    .baseColor, .specular, .metallic, .roughness, .emission, .opacity,
    .displacement, .ambientOcclusion, .anisotropic,
    .clearcoatGloss, .sheen, .bump, .ambientOcclusionScale
]

struct RenderableComponent: Component {
    var meshes: [MTKMesh] = []
    var argumentBuffers: [[MTLBuffer?]] = []
    let name: String
    let boundingBox: MDLAxisAlignedBoundingBox
    let logger = Logger(subsystem: "com.lanterntech.mm3decs", category: "RenderableComponent")
    let log = OSLog(subsystem: "com.lanterntech.mm3decs", category: .pointsOfInterest)
    
    init(device: MTLDevice, name: String) {
        guard let assetURL = Bundle.main.url(forResource: name, withExtension: nil) else {
            fatalError("Model: \(name) not found")
        }
        
        let allocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(url: assetURL, vertexDescriptor: .defaultLayout, bufferAllocator: allocator)
        
        asset.loadTextures()
        
        var mdlMeshes: [MDLMesh] = []
        do {
            let (mdlMeshesArray, mtkMeshes) = try MTKMesh.newMeshes(asset: asset, device: device)
            self.meshes = mtkMeshes
            mdlMeshes = mdlMeshesArray
        } catch {
            fatalError("Failed to load meshes: \(error)")
        }
        
        self.name = name
        self.boundingBox = asset.boundingBox
        
        guard let fragmentFunction = Renderer.library.makeFunction(name: "fragment_main") else {
            fatalError("Fragment function not found")
        }
        
        let argumentEncoder = fragmentFunction.makeArgumentEncoder(bufferIndex: ArgumentsBuffer.index)
        let argumentBufferSize = argumentEncoder.encodedLength
        
        for mdlMesh in mdlMeshes {
            var submeshArgumentBuffers: [MTLBuffer?] = []
            
            // Check and apply transformations during loading
            let transformMatrix = (mdlMesh.transform)?.matrix ?? matrix_identity_float4x4
            if transformMatrix != matrix_identity_float4x4 {
                applyTransformToVerticesParallelCPU(of: mdlMesh, with: transformMatrix)
            }
            
            for submesh in mdlMesh.submeshes as? [MDLSubmesh] ?? [] {
                var foundTextureOrColor = false
                var texture: MTLTexture?
                var baseColor: SIMD4<Float>?
                
                if let material = submesh.material {
                    for semantic in semantics {
                        if let property = material.property(with: semantic) {
                            if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                                texture = TextureController.shared.loadTexture(texture: mdlTexture, name: "\(name)-\(semantic.rawValue)")
                                foundTextureOrColor = true
                                logger.debug("Loaded texture successfully for \(name) with semantic \(semantic.rawValue)")
                                break
                            } else if property.type == .float3 || property.type == .float4 {
                                baseColor = property.float4Value
                                foundTextureOrColor = true
                                logger.debug("Loaded base color successfully for \(name): \(property.float4Value)")
                                break
                            }
                        }
                    }
                }
                
                if !foundTextureOrColor {
                    logger.error("No valid texture or color found for submesh in \(name)")
                    texture = TextureController.shared.loadTexture(name: "\(name)-placeholder")
                    if texture != nil {
                        logger.debug("Created placeholder texture with color for: \(name)")
                    }
                }
                
                let argumentBuffer = device.makeBuffer(length: argumentBufferSize, options: [])
                argumentBuffer?.label = "ArgumentBuffer"
                argumentEncoder.setArgumentBuffer(argumentBuffer, offset: 0)
                
                if let texture = texture {
                    argumentEncoder.setTexture(texture, index: 1)
                    logger.debug("Texture loaded for submesh in \(name)")
                }
                
                if var baseColor = baseColor {
                    let bufferPointer = argumentEncoder.constantData(at: 0)
                    bufferPointer.copyMemory(from: &baseColor, byteCount: MemoryLayout<SIMD4<Float>>.size)
                    logger.debug("BaseColor: \(baseColor)")
                } else {
                    logger.debug("BaseColor is nil for submesh in \(name)")
                }
                
                var hasTexture: UInt = texture != nil ? 1 : 0
                logger.debug("HasTexture: \(hasTexture) for submesh in \(name)")
                let hasTexturePointer = argumentEncoder.constantData(at: 2)
                hasTexturePointer.copyMemory(from: &hasTexture, byteCount: MemoryLayout<UInt>.size)
                
                submeshArgumentBuffers.append(argumentBuffer)
            }
            self.argumentBuffers.append(submeshArgumentBuffers)
        }
    }
    
    func render(encoder: MTLRenderCommandEncoder, uniformsConstant: Uniforms) {
        for (meshIndex, mesh) in meshes.enumerated() {
            encoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: VertexBuffer.index)
            
            var uniforms = uniformsConstant
            
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: UniformsBuffer.index)
            
            for (submeshIndex, submesh) in mesh.submeshes.enumerated() {
                encoder.setFragmentBuffer(argumentBuffers[meshIndex][submeshIndex], offset: 0, index: ArgumentsBuffer.index)
                encoder.drawIndexedPrimitives(
                    type: .triangle,
                    indexCount: submesh.indexCount,
                    indexType: submesh.indexType,
                    indexBuffer: submesh.indexBuffer.buffer,
                    indexBufferOffset: submesh.indexBuffer.offset
                )
            }
        }
    }
    
 
    
    private func applyTransformToVerticesParallelCPU(of mesh: MDLMesh, with transform: matrix_float4x4) {
        os_signpost(.begin, log: log, name: "applyTransformToVerticesParallelCPU")
        defer {
            os_signpost(.end, log: log, name: "applyTransformToVerticesParallelCPU")
        }
        
        guard let vertexBuffer = mesh.vertexBuffers.first else { return }
        let bufferPointer = vertexBuffer.map().bytes.bindMemory(to: Float.self, capacity: vertexBuffer.length)
        let vertexCount = mesh.vertexCount
        let vertexDescriptor = mesh.vertexDescriptor
        
        // Correctly cast the position attribute and layout
        guard let positionAttribute = vertexDescriptor.attributes[Int(Position.rawValue)] as? MDLVertexAttribute,
              let layout = vertexDescriptor.layouts[Int(positionAttribute.bufferIndex)] as? MDLVertexBufferLayout else {
            return
        }
        let positionStride = layout.stride
        let positionOffset = positionAttribute.offset
        
        let queue = DispatchQueue(label: "com.example.vertexTransformation", attributes: .concurrent)
        let group = DispatchGroup()
        
        let chunkSize = 4 // Number of vertices to process in each concurrent task
        
        for chunkStart in stride(from: 0, to: vertexCount, by: chunkSize) {
            queue.async(group: group) {
                let chunkEnd = min(chunkStart + chunkSize, vertexCount)
                for i in chunkStart..<chunkEnd {
                    let positionPointer = bufferPointer.advanced(by: i * positionStride / MemoryLayout<Float>.size + positionOffset / MemoryLayout<Float>.size)
                    let position = SIMD4<Float>(positionPointer[0], positionPointer[1], positionPointer[2], 1.0)
                    let transformedPosition = transform * position
                    positionPointer[0] = transformedPosition.x
                    positionPointer[1] = transformedPosition.y
                    positionPointer[2] = transformedPosition.z
                    
                    // Debug log
                    self.logger.debug("Original Position: \(position), Transformed Position: \(transformedPosition)")
                }
            }
        }
        
        group.wait() // Wait for all chunks to be processed before continuing
    }
    
    
    private func applyTransformToVertices(of mesh: MDLMesh, with transform: matrix_float4x4) {
        os_signpost(.begin, log: log, name: "applyTransformToVertices")
        defer {
            os_signpost(.end, log: log, name: "applyTransformToVertices")
        }
        guard let vertexBuffer = mesh.vertexBuffers.first else { return }
        let bufferPointer = vertexBuffer.map().bytes.bindMemory(to: Float.self, capacity: vertexBuffer.length)
        let vertexCount = mesh.vertexCount
        let vertexDescriptor = mesh.vertexDescriptor
        
        // Correctly cast the position attribute and layout
        guard let positionAttribute = vertexDescriptor.attributes[Int(Position.rawValue)] as? MDLVertexAttribute,
              let layout = vertexDescriptor.layouts[Int(positionAttribute.bufferIndex)] as? MDLVertexBufferLayout else {
            return
        }
        let positionStride = layout.stride
        let positionOffset = positionAttribute.offset
        
        for i in 0..<vertexCount {
            let positionPointer = bufferPointer.advanced(by: i * positionStride / MemoryLayout<Float>.size + positionOffset / MemoryLayout<Float>.size)
            let position = SIMD4<Float>(positionPointer[0], positionPointer[1], positionPointer[2], 1.0)
            let transformedPosition = transform * position
            positionPointer[0] = transformedPosition.x
            positionPointer[1] = transformedPosition.y
            positionPointer[2] = transformedPosition.z
            
            // Debug log
            logger.debug("Original Position: \(position), Transformed Position: \(transformedPosition)")
        }
    }
    
    
    private func applyTransformToVerticesGPU(of mesh: MDLMesh, with transform: matrix_float4x4) {
        os_signpost(.begin, log: log, name: "applyTransformToVerticesGPU")
        defer {
            os_signpost(.end, log: log, name: "applyTransformToVerticesGPU")
        }

        guard let mtkVertexBuffer = mesh.vertexBuffers.first as? MTKMeshBuffer else {
            fatalError("Expected MTKMeshBuffer but found another type")
        }

        let vertexBuffer = mtkVertexBuffer.buffer
        let vertexCount = vertexBuffer.length / MemoryLayout<ModelVertexCPU>.stride

        // Create a debug buffer
        guard let debugBuffer = Renderer.device.makeBuffer(length: MemoryLayout<DebugInfoCPU>.stride * vertexCount, options: .storageModeShared) else {
            fatalError("Failed to create debug buffer")
        }

        guard let commandQueue = Renderer.device.makeCommandQueue(),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }

        let computePipelineState: MTLComputePipelineState
        let library = Renderer.device.makeDefaultLibrary()
        guard let computeFunction = library?.makeFunction(name: "transformVertices") else {
            fatalError("Unable to find function transformVertices in Metal library")
        }

        do {
            computePipelineState = try Renderer.device.makeComputePipelineState(function: computeFunction)
        } catch {
            fatalError("Unable to create compute pipeline state: \(error)")
        }

        computeEncoder.setComputePipelineState(computePipelineState)
        computeEncoder.setBuffer(vertexBuffer, offset: 0, index: 0)
        var transformVar = transform
        computeEncoder.setBytes(&transformVar, length: MemoryLayout<matrix_float4x4>.stride, index: 1)
        computeEncoder.setBuffer(debugBuffer, offset: 0, index: 2)

        let gridSize = MTLSize(width: vertexCount, height: 1, depth: 1)
        let threadGroupSize = MTLSize(width: min(Renderer.device.maxThreadsPerThreadgroup.width, gridSize.width), height: 1, depth: 1)

        computeEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        // Debugging: Print the initial and transformed buffer contents
        let bufferPointer = vertexBuffer.contents().bindMemory(to: ModelVertexCPU.self, capacity: vertexCount)
        for i in 0..<vertexCount {
            let vertex = bufferPointer[i]
            logger.debug("Initial Vertex \(i): \(vertex.position)")
        }

        // Debugging: Print the debug information
        let debugPointer = debugBuffer.contents().bindMemory(to: DebugInfoCPU.self, capacity: vertexCount)
        for i in 0..<vertexCount {
            let debugInfo = debugPointer[i]
            logger.debug("Debug Info for Vertex \(i):")
            logger.debug("  Input Position: \(debugInfo.inputPosition)")
            logger.debug("  Transform Row 0: \(debugInfo.transformRow0)")
            logger.debug("  Transform Row 1: \(debugInfo.transformRow1)")
            logger.debug("  Transform Row 2: \(debugInfo.transformRow2)")
            logger.debug("  Transform Row 3: \(debugInfo.transformRow3)")
            logger.debug("  Output Position: \(debugInfo.outputPosition)")
        }
    }
    
}//class
