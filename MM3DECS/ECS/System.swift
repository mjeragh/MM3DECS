//
//  System.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 20/03/2024.
//

protocol System {
    var entities: [Entity] { get set }
    func update(deltaTime: Float)
}

