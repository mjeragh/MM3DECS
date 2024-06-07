import Foundation
import MetalKit
import OSLog

struct RenderableComponent: Component {
    var mesh: MTKMesh
    var texture: MTLTexture?
    var baseColor: SIMD4<Float>?
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
    }

    func render(encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: VertexBuffer.index)
        
        if let texture = texture {
            encoder.setFragmentTexture(texture, index: BaseColor.index)
        }

        if var baseColor = baseColor {
            encoder.setFragmentBytes(&baseColor, length: MemoryLayout<SIMD4<Float>>.stride, index: BaseColor.index)
        } else {
            var baseColor = float4(0.1,0.1,0.4,1)
            encoder.setFragmentBytes(&baseColor, length: MemoryLayout<SIMD4<Float>>.stride, index: BaseColor.index)
        }

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
