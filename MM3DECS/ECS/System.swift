//
//  System.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 20/03/2024.
//
import MetalKit
protocol SystemProtocol {
    func update(deltaTime: Float, entityManager: EntityManager, renderEncoder: MTLRenderCommandEncoder)
}

