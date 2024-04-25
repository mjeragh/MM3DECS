//
//  CameraInputComponent.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 21/04/2024.
//
import Foundation

struct CameraInputComponent: Component {
    var dragStartPosition: CGPoint?  // Store the initial touch position
    var dragCurrentPosition: CGPoint?  // Store the current touch position during a drag
    var lastTouchPosition: CGPoint?  // Store the last touch position
    var cameraType: CameraType = .arcball
    
    init(dragStartPosition: CGPoint? = nil, dragCurrentPosition: CGPoint? = nil, lastTouchPosition: CGPoint? = nil, cameraType: CameraType = .arcball) {
        self.dragStartPosition = dragStartPosition
        self.dragCurrentPosition = dragCurrentPosition
        self.lastTouchPosition = lastTouchPosition
    }
}
