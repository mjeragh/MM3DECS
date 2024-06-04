//
//  TextureController.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 26/05/2024.
//

import Foundation
import MetalKit

enum TextureController {
  static var textures: [String: MTLTexture] = [:]

  static func loadTexture(texture: MDLTexture, name: String) -> MTLTexture? {
    if let texture = textures[name] {
      return texture
    }
    let textureLoader = MTKTextureLoader(device: Renderer.device)
    let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [
      .origin: MTKTextureLoader.Origin.bottomLeft,
      .generateMipmaps: true
    ]
    let texture = try? textureLoader.newTexture(
      texture: texture,
      options: textureLoaderOptions)
    if texture != nil {
      print("Loaded texture from USD file: \(name)")
      textures[name] = texture
    } else {
      print("Failed to load texture from USD file: \(name)")
    }
    return texture
  }

  static func loadTexture(name: String) -> MTLTexture? {
    if let texture = textures[name] {
      return texture
    }
    let textureLoader = MTKTextureLoader(device: Renderer.device)
    let texture: MTLTexture?
    texture = try? textureLoader.newTexture(
      name: name,
      scaleFactor: 1.0,
      bundle: Bundle.main,
      options: nil)
    if texture != nil {
      print("Loaded texture: \(name)")
      textures[name] = texture
    } else {
      print("Failed to load texture: \(name)")
    }
    return texture
  }
}
