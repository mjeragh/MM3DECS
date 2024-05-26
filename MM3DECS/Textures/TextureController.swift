//
//  TextureController.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 26/05/2024.
//

import Foundation
import MetalKit

class TextureController {
    static let shared = TextureController()
    private var textures: [String: MTLTexture] = [:]
    
    private init() {}
    
    func loadTexture(device: MTLDevice, name: String) -> MTLTexture? {
        if let texture = textures[name] {
            return texture
        }
        
        guard let url = Bundle.main.url(forResource: name, withExtension: nil) else {
            fatalError("Failed to load texture \(name)")
        }
        
        let textureLoader = MTKTextureLoader(device: device)
        do {
            let texture = try textureLoader.newTexture(URL: url, options: nil)
            textures[name] = texture
            return texture
        } catch {
            fatalError("Failed to load texture \(name): \(error.localizedDescription)")
        }
    }
    
    func getTexture(name: String) -> MTLTexture? {
        return textures[name]
    }
}
