//
//  InputComponent.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 20/04/2024.
//
import UIKit
import CoreMotion

struct InputComponent: Component {
    var translation: CGSize
    var velocity: CGSize // Speed of the drag gesture
    var isTouching: Bool = false
    var tapCount: Int = 0 // Number of taps, for detecting double taps, etc.
    var scale: CGFloat = 1.0 // Pinch gesture scale
    var rotation: CGFloat = 0.0 // Rotation gesture rotation
    var motion: CMAcceleration? // Accelerometer data for motion-based inputs

    // Initialize with default values
    init(translation: CGSize = .zero, velocity: CGSize = .zero, isTouching: Bool = false, tapCount: Int = 0, scale: CGFloat = 1.0, rotation: CGFloat = 0.0, motion: CMAcceleration? = nil) {
        self.translation = .zero
        self.velocity = .zero
        self.isTouching = false
        self.tapCount = 0
        self.scale = 1.0
        self.rotation = 0.0
        self.motion = nil
    }
    
    // Call this method when a drag gesture updates
    mutating func updateGesture(translation: CGSize, velocity: CGSize) {
        self.translation = translation
        self.velocity = velocity
    }

    // Call this method when a tap gesture updates
    mutating func updateTap(tapCount: Int) {
        self.tapCount = tapCount
    }

    // Call this method when a pinch gesture updates
    mutating func updatePinch(scale: CGFloat) {
        self.scale = scale
    }

    // Call this method when a rotation gesture updates
    mutating func updateRotation(rotation: CGFloat) {
        self.rotation = rotation
    }

    // Call this method to update motion data
    mutating func updateMotion(motion: CMAcceleration) {
        self.motion = motion
    }
    
    // Reset input data where necessary (e.g., when the touch ends)
    mutating func reset() {
        self.translation = .zero
        self.velocity = .zero
        self.isTouching = false
        self.tapCount = 0
        // Do not reset scale and rotation as they are cumulative
        // self.scale = 1.0
        // self.rotation = 0.0
        // Motion data doesn't need to be reset as it's updated constantly
    }
}
