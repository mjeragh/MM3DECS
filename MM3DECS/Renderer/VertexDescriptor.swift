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

extension MTLVertexDescriptor {
  static var defaultLayout: MTLVertexDescriptor? {
    MTKMetalVertexDescriptorFromModelIO(.defaultLayout)
  }
}

extension MDLVertexDescriptor {
  static var defaultLayout: MDLVertexDescriptor {
    let vertexDescriptor = MDLVertexDescriptor()
    var offset = 0
    vertexDescriptor.attributes[0] = MDLVertexAttribute(
      name: MDLVertexAttributePosition,
      format: .float3,
      offset: 0,
      bufferIndex: VertexBuffer.index)
    offset += MemoryLayout<float3>.stride

    vertexDescriptor.attributes[1] = MDLVertexAttribute(
      name: MDLVertexAttributeNormal,
      format: .float3,
      offset: offset,
      bufferIndex: VertexBuffer.index)
    offset += MemoryLayout<float3>.stride

    vertexDescriptor.attributes[2] = MDLVertexAttribute(
      name: MDLVertexAttributeTextureCoordinate,
      format: .float2,
      offset: offset,
      bufferIndex: VertexBuffer.index)
    offset += MemoryLayout<float2>.stride

    vertexDescriptor.attributes[3] = MDLVertexAttribute(
      name: MDLVertexAttributeColor,
      format: .float3,
      offset: offset,
      bufferIndex: VertexBuffer.index)
    offset += MemoryLayout<float3>.stride

    vertexDescriptor.attributes[4] = MDLVertexAttribute(
      name: MDLVertexAttributeTangent,
      format: .float3,
      offset: offset,
      bufferIndex: VertexBuffer.index)
    offset += MemoryLayout<float3>.stride

    vertexDescriptor.attributes[5] = MDLVertexAttribute(
      name: MDLVertexAttributeBitangent,
      format: .float3,
      offset: offset,
      bufferIndex: VertexBuffer.index)
    offset += MemoryLayout<float3>.stride

    vertexDescriptor.attributes[6] = MDLVertexAttribute(
      name: MDLVertexAttributeJointIndices,
      format: .uShort4,
      offset: offset,
      bufferIndex: VertexBuffer.index)
    offset += MemoryLayout<ushort>.stride * 4

    vertexDescriptor.attributes[7] = MDLVertexAttribute(
      name: MDLVertexAttributeJointWeights,
      format: .float4,
      offset: offset,
      bufferIndex: VertexBuffer.index)
    offset += MemoryLayout<float4>.stride

    vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: offset)
    return vertexDescriptor
  }
}

extension Attributes {
  var index: Int {
    return Int(self.rawValue)
  }
}

extension BufferIndices {
  var index: Int {
    return Int(self.rawValue)
  }
}

extension TextureIndices {
  var index: Int {
    return Int(self.rawValue)
  }
}
