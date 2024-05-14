import SwiftUI
import Metal
import GameController
import Combine
import os.log

enum Settings {
    static var rotationSpeed : Float { 1.5 }
    static var translationSpeed : Float { 3.0 }
    static var mouseScrollSensitivity : Float { 0.1 }
    static var mousePanSensitivity : Float { 0.008 }
    static var touchZoomSensitivity: Float { 10 }
}



class InputManager {
    static let shared = InputManager()

    // Input States
    var keysPressed: Set<GCKeyCode> = []
    var mousePosition: CGPoint = .zero
    var leftMouseDown: Bool = false
    var mouseDelta: CGPoint = .zero
    var mouseScrollDelta: CGPoint = .zero
    var previousTranslation : CGSize = .zero
    
    var isTouchActive : Bool = false
    var touchStarted : Bool = false
    var touchEnded : Bool = true

    var logger = Logger(subsystem: "com.lanterntech.mm3decs", category: "InputManager")
    
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
    func updateTouchLocation(_ location: CGPoint) {//Begin
            touchLocation = location
            mouseDelta = location
            if !isTouchActive {
                isTouchActive = true
                touchStarted = true
            }
            touchEnded = false
        }
    func updateTouchDelta(_ translation: CGSize){//Move
        mouseDelta = CGPoint(x: translation.width - previousTranslation.width, y: translation.height-previousTranslation.height)
        touchDelta = CGSize(width: translation.width - previousTranslation.width,
                            height: translation.height - previousTranslation.height)
        previousTranslation = translation
        
        leftMouseDown = touchDelta != nil
        
        logger.debug("updateTouchDelta: mouseDelta:\(self.mouseDelta.x), \(self.mouseDelta.y), touchDelta:\(self.touchDelta!.width),\(self.touchDelta!.height)\n")
        if abs(translation.width) > 1 ||
            abs(translation.height) > 1 {
            touchLocation = nil
            logger.warning("touchlocation Resetted, because of touch")
        }
    }
        func resetTouchDelta() {//end
            if isTouchActive {
                touchEnded = true
                previousTranslation = .zero
            }
            isTouchActive = false
            touchLocation = nil
            touchStarted = false
            touchDelta = nil
        }
}
