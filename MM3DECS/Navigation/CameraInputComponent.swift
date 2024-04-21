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
}
