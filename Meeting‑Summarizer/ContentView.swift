//
//  ContentView.swift
//  Meeting‑Summarizer
//
//  Created by sonam sherpa on 22/03/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

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
        .task {
            do {
                try SampleMeetingData.seedIfNeeded(in: modelContext)
            } catch {
                assertionFailure("Failed to seed sample meeting data: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleMeetingData.previewContainer)
}
