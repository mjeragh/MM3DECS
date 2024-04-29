//
//  SelectionComponent.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 21/04/2024.
//

struct SelectionComponent: Component {
    var isSelected: Bool = false
    var distance : float3 = float3.infinity// I dont know why it was float4 from the previous project
}
