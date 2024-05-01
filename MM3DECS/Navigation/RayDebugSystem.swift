//
//  RayDebugSystem.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 30/04/2024.
//

import Foundation
import MetalKit
import simd

class RayDebugSystem : SystemProtocol {
    
    var debugEnabledMode = false
    var projectionMatrix: matrix_float4x4
    let device: MTLDevice
    var linePipelineState: MTLRenderPipelineState!
    // Buffer to hold line vertices for debugging
   var lineVertexBuffer: MTLBuffer?

    init(projectionMatrix: matrix_float4x4) {
        self.device = Renderer.device
        
        let defaultLibrary = device.makeDefaultLibrary()
        let vertexFunction = defaultLibrary?.makeFunction(name: "line_vertex")
        let fragmentFunction = defaultLibrary?.makeFunction(name: "line_fragment")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<float3>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        vertexDescriptor.layouts[0].stepRate = 1

        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
//        renderPassDescriptor.colorAttachments[0].texture = colorTexture
//        renderPassDescriptor.colorAttachments[0].loadAction = .clear
//        renderPassDescriptor.colorAttachments[0].storeAction = .store
//        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
//
//        renderPassDescriptor.depthAttachment.texture = depthTexture
//        renderPassDescriptor.depthAttachment.loadAction = .clear
//        renderPassDescriptor.depthAttachment.storeAction = .dontCare
//        renderPassDescriptor.depthAttachment.clearDepth = 1.0

        do {
            linePipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error: \(error)")
        }
        self.projectionMatrix = projectionMatrix
        
    }

    func update(deltaTime: Float, entityManager: EntityManager, renderEncoder: any MTLRenderCommandEncoder) {
        drawDebugLines(renderEncoder: renderEncoder)
    }
    
    func drawDebugLines(renderEncoder: MTLRenderCommandEncoder) {
            guard let lineVertexBuffer = lineVertexBuffer else { return }
            var pm = self.projectionMatrix
            renderEncoder.setRenderPipelineState(linePipelineState)
            renderEncoder.setVertexBuffer(lineVertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBytes(&pm, length: MemoryLayout<matrix_float4x4>.size, index: 1)
        renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: lineVertexBuffer.length / MemoryLayout<float3>.stride)
        updateLineVertices(vertices: [])
        renderEncoder.setRenderPipelineState(Renderer.defaultPipelinestate)
        }
    
    func updateLineVertices(vertices: [float3]) {
        if vertices.isEmpty { return }
            let dataSize = vertices.count * MemoryLayout<float3>.stride
            lineVertexBuffer = Renderer.device.makeBuffer(bytes: vertices, length: dataSize, options: [])
        }

    func updateCameraProjectionMatrix(projectionMatrix: matrix_float4x4){
       self.projectionMatrix = projectionMatrix
    }
    
    


}
