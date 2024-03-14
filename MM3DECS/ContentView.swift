//
//  ContentView.swift
//  MM3DECS
//
//  Created by Mohammad Jeragh on 14/03/2024.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var options = Options()
    var body: some View {
        VStack {
            MetalView(options: options)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
      }
}

#Preview {
    ContentView()
}
