//
//  ContentView.swift
//  ClassWiz
//
//  Created by Sarwad Hasan  on 2/8/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        RootRouter()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
