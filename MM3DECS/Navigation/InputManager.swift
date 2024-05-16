import SwiftUI
import Metal
import GameController
import Combine
import os.log

enum Settings {
    static var rotationSpeed : Float { 1.5 }
    static var translationSpeed : Float { 3.0 }
    static var mouseScrollSensitivity : Float { 2.5 }
    static var mousePanSensitivity : Float { 0.008 }
    static var touchZoomSensitivity: Float { 10 }
}



class InputManager {
    static let shared = InputManager()

    // Input States
    var keysPressed: Set<GCKeyCode> = []
    var leftMouseDown: Bool = false
    var mouseScroll: CGPoint = .zero
    var previousTranslation : CGSize = .zero
    
    var touchState = false

    var logger = Logger(subsystem: "com.lanterntech.mm3decs", category: "InputManager")
    
    // Touch input properties for SwiftUI binding
    var touchLocation: CGPoint?
    var touchDelta: CGSize? 

    private init() {
        setupGameControllerObservers()
    }

    private func setupGameControllerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardConnect(_:)), name: .GCKeyboardDidConnect, object: nil)
        
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
}
extension InputManager {
    func updateTouchLocation(_ location: CGPoint) {//Begin
            touchLocation = location
            touchState = true
        }
    func updateTouchDelta(_ translation: CGSize){
        //Move
        touchDelta = CGSize(width: translation.width - previousTranslation.width,
                            height: translation.height - previousTranslation.height)
        touchDelta?.height *= -1
        previousTranslation = translation
        
        leftMouseDown = touchDelta != nil
        
//        logger.debug("updateTouchDelta: mouseDelta:\(self.mouseDelta.x), \(self.mouseDelta.y), touchDelta:\(self.touchDelta!.width),\(self.touchDelta!.height)\n")
//        if abs(translation.width) > 1 ||
//            abs(translation.height) > 1 {
//            touchLocation = nil
//            logger.warning("touchlocation Resetted, because of touch")
//        }
    }
        func resetTouchDelta() {//end
            touchState = false
            previousTranslation = .zero
//            touchLocation = nil
//            touchDelta = nil
        }
}
