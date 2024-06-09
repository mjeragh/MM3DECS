import MetalKit
import OSLog

struct RenderableComponent: Component {
    var mesh: MTKMesh
    var texture: MTLTexture?
    var baseColor: SIMD4<Float>?
    var argumentBuffer: MTLBuffer?
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
        
        guard let mdlMesh = asset.childObjects(of: MDLMesh.self).first as? MDLMesh else {
            fatalError("No mesh available")
        }

        do {
            self.mesh = try MTKMesh(mesh: mdlMesh, device: device)
        } catch {
            fatalError("Failed to load mesh: \(error)")
        }
        self.name = name
        self.boundingBox = asset.boundingBox

        var foundTexture = false
        for submesh in mdlMesh.submeshes as? [MDLSubmesh] ?? [] {
            if let material = submesh.material {
                let semantics: [MDLMaterialSemantic] = [
                    .baseColor, .specular, .metallic, .roughness, .emission, .opacity,
                    .displacement, .ambientOcclusion, .anisotropic,
                    .clearcoatGloss, .sheen, .bump, .ambientOcclusionScale
                ]
                for semantic in semantics {
                    if let property = material.property(with: semantic) {
                        if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                            self.texture = TextureController.loadTexture(texture: mdlTexture, name: name)
                            foundTexture = true
                            logger.debug("Loaded texture successfully for \(name) with semantic \(semantic.rawValue)")
                            break
                        } else if property.type == .float3 || property.type == .float4 {
                            self.baseColor = property.float4Value
                            foundTexture = true
                            logger.debug("Loaded base color successfully for \(name): \(property.float4Value)")
                            break
                        }
                    }
                }
                if foundTexture {
                    break
                }
            }
        }
        if !foundTexture {
            logger.error("No valid texture or color found for \(name)")
        }
        
        // Define Argument Descriptors
        let baseColorDescriptor = MTLArgumentDescriptor()
        baseColorDescriptor.dataType = .float4
        baseColorDescriptor.index = 1
        baseColorDescriptor.access = .readOnly

        let textureDescriptor = MTLArgumentDescriptor()
        textureDescriptor.dataType = .texture
        textureDescriptor.index = 0
        textureDescriptor.access = .readOnly

        let hasTextureDescriptor = MTLArgumentDescriptor()
        hasTextureDescriptor.dataType = .bool
        hasTextureDescriptor.index = 2
        hasTextureDescriptor.access = .readOnly

        let argumentDescriptors = [textureDescriptor, baseColorDescriptor, hasTextureDescriptor]
        
        // Create Argument Encoder
        guard let argumentEncoder = Renderer.device.makeArgumentEncoder(arguments: argumentDescriptors) else {
            fatalError("Failed to create argument encoder")
        }
        
        // Create Argument Buffer
        let argumentBufferSize = argumentEncoder.encodedLength
        argumentBuffer = device.makeBuffer(length: argumentBufferSize, options: [])
        argumentBuffer?.label = "ArgumentBuffer"
        argumentEncoder.setArgumentBuffer(argumentBuffer, offset: 0)
        
        // Set Arguments
        if let texture = texture {
            argumentEncoder.setTexture(texture, index: 0)
        }
        
        if let baseColor = baseColor {
            var color = baseColor
            let buffer = device.makeBuffer(bytes: &color, length: MemoryLayout<SIMD4<Float>>.stride, options: [])
            argumentEncoder.setBuffer(buffer, offset: 0, index: 1)
        }
        
        var hasTexture = texture != nil
        let hasTextureBuffer = device.makeBuffer(bytes: &hasTexture, length: MemoryLayout<Bool>.stride, options: [])
        argumentEncoder.setBuffer(hasTextureBuffer, offset: 0, index: 2)
    }

    func render(encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: VertexBuffer.index)
        encoder.setFragmentBuffer(argumentBuffer, offset: 0, index: ArgumentsBuffer.index)

        for submesh in mesh.submeshes {
            encoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: submesh.indexCount,
                indexType: submesh.indexType,
                indexBuffer: submesh.indexBuffer.buffer,
                indexBufferOffset: submesh.indexBuffer.offset)
        }
    }
}
