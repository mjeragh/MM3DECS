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
        options: options).gesture(DragGesture(minimumDistance: 0).onChanged { value in
            InputManager.shared.touchLocation = value.location
            InputManager.shared.touchDelta = CGSize(
              width: value.translation.width - previousTranslation.width,
              height: value.translation.height - previousTranslation.height)
            previousTranslation = value.translation
            // if the user drags, cancel the tap touch
//            if abs(value.translation.width) > 1 ||
//              abs(value.translation.height) > 1 {
//              InputManager.shared.touchLocation = nil
//            }
            InputManager.shared.updateTouchDelta()
            InputManager.shared.updateTouchLocation()
        }.onEnded { _ in
            previousTranslation = .zero
            InputManager.shared.resetTouchDelta()
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
      engine.setupGame(
        metalView: metalView,
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
