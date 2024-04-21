//
//  MetalView.swift
//  MM3DUI
//
//  Created by Mohammad Jeragh on 06/06/2022.
//

import SwiftUI
import MetalKit
///Refrences
///https://metalbyexample.com/picking-hit-testing/
///https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-box-intersection
struct MetalView: View {
  let options: Options
  @State private var metalView = MTKView()
    @StateObject private var engine = Engine()
    @State private var previousTranslation = CGSize.zero
  @State private var previousScroll: CGFloat = 1

  var body: some View {
    VStack {
      MetalViewRepresentable(
        engine: engine,
        metalView: $metalView,
        options: options).gesture(DragGesture().onChanged { gesture in
            if let gameScene = engine.sceneManager?.currentScene as? GameScene,
               let inputSystem = gameScene.systems.compactMap({ $0 as? InputSystem }).first {
                inputSystem.touchMovedOrBegan(gesture: gesture)
            }
        }.onEnded { gesture in
            if let gameScene = engine.sceneManager?.currentScene as? GameScene,
               let inputSystem = gameScene.systems.compactMap({ $0 as? InputSystem }).first {
                inputSystem.touchEnded(gesture: gesture)
            }
        })
    }
  }
}


typealias ViewRepresentable = UIViewRepresentable

struct MetalViewRepresentable: ViewRepresentable {
    @ObservedObject var engine : Engine
    @Binding var metalView: MTKView
  let options: Options

  
  func makeUIView(context: Context) -> MTKView {
      let renderer = Renderer(metalView: metalView)
      engine.setupGame(
        renderer: renderer,
        sceneManager: SceneManager(scene: GameScene(entityManager: EntityManager())),
        options: options)
      engine.start()
      return metalView
  }

  func updateUIView(_ uiView: MTKView, context: Context) {
    
      updateMetalView()
  }
  

  func updateMetalView() {
      engine.updateOptions(options: options)
  }
}

struct MetalView_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      MetalView(options: Options())
      Text("Metal View")
    }
  }
}
