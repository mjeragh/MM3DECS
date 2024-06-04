//
//  RenderableComponent.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 04/06/2024.
//

import Foundation
import MetalKit
// Example components
import simd
import os.log



struct RenderableComponent: Component {
    var mesh: MTKMesh
    var texture: MTLTexture?
    var baseColor: SIMD4<Float>?
    let name: String
    let boundingBox: MDLAxisAlignedBoundingBox
    let logger = Logger(subsystem: "com.lanterntech.mm3decs", category: "RenderableComponent")

    init(device: MTLDevice, name: String, textureName: String? = nil) {
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

        // Debugging: Print all materials and their properties
        for submesh in mdlMesh.submeshes as? [MDLSubmesh] ?? [] {
            if let material = submesh.material {
                logger.debug("Found material for submesh: \(material.name)")
                
                // Iterate over all possible material semantics
                let semantics: [MDLMaterialSemantic] = [
                    .baseColor, .specular, .metallic, .roughness, .emission, .opacity,
                    .displacement, .ambientOcclusion, .anisotropic,
                    .clearcoatGloss, .sheen, .bump, .ambientOcclusionScale
                    // Add other semantics as needed
                ]
                
                var foundTexture = false
                for semantic in semantics {
                    if let property = material.property(with: semantic) {
                        logger.debug("Material property: \(property.name) of type \(property.type.rawValue) with semantic \(semantic.rawValue)")
                        if property.type == .texture, let mdlTexture = property.textureSamplerValue?.texture {
                            self.texture = TextureController.loadTexture(texture: mdlTexture, name: name)
                            if self.texture != nil {
                                logger.debug("Loaded texture successfully for \(name) with semantic \(semantic.rawValue)")
                                foundTexture = true
                                break
                            } else {
                                logger.error("Failed to load texture for \(name) with semantic \(semantic.rawValue)")
                            }
                        } else if property.type == .float3 || property.type == .float4 {
                            // Handle color properties (baseColor)
                            let color = property.float4Value
                            self.baseColor = color
                            logger.debug("Loaded base color successfully for \(name): \(color)")
                        }
                    }
                }
                if !foundTexture {
                    logger.error("No valid texture found for \(name)")
                }
            } else {
                logger.error("Submesh does not have a material")
            }
        }
    }
}

extension RenderableComponent {
    func render(encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: VertexBuffer.index)
        
        if let texture = texture {
            encoder.setFragmentTexture(texture, index: BaseColor.index)
        } else if let baseColor = baseColor {
            var color = baseColor
            encoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.stride, index: BaseColor.index)
            logger.debug("Using base color for \(name)")
        } else {
            logger.error("No texture or base color set for \(name)")
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
