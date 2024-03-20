//
//  System.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 20/03/2024.
//

protocol System {
    func update(deltaTime: Float, entityManager: EntityManager)
}

