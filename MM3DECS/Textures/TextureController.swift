import Foundation
import MetalKit

class TextureController {
    static let shared = TextureController()
    private var textures: [String: MTLTexture] = [:]

    private init() {}

    func loadTexture(texture: MDLTexture, name: String) -> MTLTexture? {
        if let texture = textures[name] {
            return texture
        }
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [
            .origin: MTKTextureLoader.Origin.bottomLeft,
            .generateMipmaps: true
        ]
        guard let texture = try? textureLoader.newTexture(texture: texture, options: textureLoaderOptions) else {
            print("Failed to load texture from USD file")
            return nil
        }
        print("Loaded texture from USD file")
        textures[name] = texture
        return texture
    }

    func loadTexture(name: String) -> MTLTexture? {
        if let texture = textures[name] {
            return texture
        }
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        var texture: MTLTexture?
        texture = try? textureLoader.newTexture(name: name, scaleFactor: 1.0, bundle: Bundle.main, options: nil)
        if texture != nil {
            print("Loaded texture: \(name)")
            textures[name] = texture
        } else {
            print("Failed to load texture: \(name), creating placeholder")
            texture = createPlaceholderTexture(device: Renderer.device, color: SIMD4<Float>(1, 0, 0, 1)) // Red color
            textures[name] = texture
        }
        return texture
    }

    private func createPlaceholderTexture(device: MTLDevice, color: SIMD4<Float>) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .rgba8Unorm
        textureDescriptor.width = 1
        textureDescriptor.height = 1
        textureDescriptor.usage = [.shaderRead]

        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            return nil
        }

        let rawData: [UInt8] = [
            UInt8(color.x * 255),
            UInt8(color.y * 255),
            UInt8(color.z * 255),
            UInt8(color.w * 255)
        ]

        let region = MTLRegionMake2D(0, 0, 1, 1)
        texture.replace(region: region, mipmapLevel: 0, withBytes: rawData, bytesPerRow: 4)

        return texture
    }
}
