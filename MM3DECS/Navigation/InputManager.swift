//
//  InputManager.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 11/05/2024.
//

import SwiftUI
import Metal
import GameController
import Combine

class InputManager {
    static let shared = InputManager()

    // Input States
    var keysPressed: Set<GCKeyCode> = []
    var mousePosition: CGPoint = .zero
    var leftMouseDown: Bool = false
    var mouseDelta: CGPoint = .zero
    var mouseScrollDelta: CGPoint = .zero
    
    var isTouchActive : Bool = false
    var touchStarted : Bool = false
    var touchEnded : Bool = true

    // Touch input properties for SwiftUI binding
    @Published var touchLocation: CGPoint?
    @Published var touchDelta: CGSize?

    private init() {
        setupGameControllerObservers()
    }

    private func setupGameControllerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardConnect(_:)), name: .GCKeyboardDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleMouseConnect(_:)), name: .GCMouseDidConnect, object: nil)
    }

    @objc private func handleKeyboardConnect(_ notification: Notification) {
        guard let keyboard = notification.object as? GCKeyboard else { return }
        keyboard.keyboardInput?.keyChangedHandler = { [weak self] (_, _, keyCode, pressed) in
            guard let self = self else { return }
            if pressed {
                self.keysPressed.insert(keyCode)
            } else {
                self.keysPressed.remove(keyCode)
            }
        }
    }

    

    
    @objc private func handleMouseConnect(_ notification: Notification) {
        guard let mouse = notification.object as? GCMouse else { return }

        mouse.mouseInput?.leftButton.pressedChangedHandler = { [weak self] (button, _, pressed) in
            self?.leftMouseDown = pressed
        }
        
        mouse.mouseInput?.mouseMovedHandler = { [weak self] (mouseInput, deltaX, deltaY) in
            // Ensure the types for deltaX and deltaY are CGFloat and convert if necessary
            self?.mouseDelta = CGPoint(x: CGFloat(deltaX), y: CGFloat(deltaY))
        }
        
        mouse.mouseInput?.scroll.valueChangedHandler = { [weak self] (mouseInput, xScroll, yScroll) in
            // xScroll and yScroll are likely CGFloats; convert if different
            self?.mouseScrollDelta = CGPoint(x: CGFloat(xScroll), y: CGFloat(yScroll))
        }
    }
}
extension InputManager {
    func updateTouchLocation(_ location: CGPoint) {
            touchLocation = location
            if !isTouchActive {
                isTouchActive = true
                touchStarted = true
            }
            touchEnded = false
        }
    func updateTouchDelta(_ translation: CGSize){
        touchDelta = translation
    }
        func resetTouchDelta() {
            if isTouchActive {
                touchEnded = true
            }
            isTouchActive = false
            touchLocation = nil
            touchStarted = false
        }

        // To be called at the end of each frame to reset the flags
        func clearTouchFlags() {
            touchStarted = false
            touchEnded = false
        }
}
