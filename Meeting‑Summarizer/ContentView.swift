//
//  ContentView.swift
//  Meeting‑Summarizer
//
//  Created by sonam sherpa on 22/03/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
        }
        .tint(AppTheme.accentStrong)
        .toolbarColorScheme(.dark, for: .tabBar, .navigationBar)
        .appScreenBackground()
    }
}

#Preview {
    ContentView()
}
