import MetalKit
import OSLog

// Define semantics array once, outside the struct
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

    init(device: MTLDevice, name: String) {
        guard let assetURL = Bundle.main.url(forResource: name, withExtension: nil) else {
            fatalError("Model: \(name) not found")
        }

        let allocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(url: assetURL, vertexDescriptor: .defaultLayout, bufferAllocator: allocator)
        
        // Load textures
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
        
        // Create Argument Encoder from the fragment function
        guard let fragmentFunction = Renderer.library.makeFunction(name: "fragment_main") else {
            fatalError("Fragment function not found")
        }

        let argumentEncoder = fragmentFunction.makeArgumentEncoder(bufferIndex: ArgumentsBuffer.index)
        let argumentBufferSize = argumentEncoder.encodedLength
        

        // Process each MDL mesh
        for mdlMesh in mdlMeshes {
            var submeshArgumentBuffers: [MTLBuffer?] = []

            // Process each submesh
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

                // Use a placeholder if no valid texture or color found
                if !foundTextureOrColor {
                    logger.error("No valid texture or color found for submesh in \(name)")
                    texture = TextureController.shared.loadTexture(name: "\(name)-placeholder")
                    if texture != nil {
                        logger.debug("Created placeholder texture with color for: \(name)")
                    }
                }

               
                // Create Argument Buffer
                let argumentBuffer = device.makeBuffer(length: argumentBufferSize, options: [])
                argumentBuffer?.label = "ArgumentBuffer"
                argumentEncoder.setArgumentBuffer(argumentBuffer, offset: 0)
                
                // Set Arguments
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
            }//for subMesh
            self.argumentBuffers.append(submeshArgumentBuffers)
        }//for mdlMesh
    }

    func render(encoder: MTLRenderCommandEncoder) {
        for (meshIndex, mesh) in meshes.enumerated() {
            encoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: VertexBuffer.index)

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
}
