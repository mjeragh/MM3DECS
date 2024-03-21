//
//  System.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 20/03/2024.
//
import MetalKit
protocol System {
    func update(deltaTime: Float, renderEncoder: MTLRenderCommandEncoder)
}

