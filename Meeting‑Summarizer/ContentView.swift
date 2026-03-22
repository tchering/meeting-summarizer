//
//  ContentView.swift
//  Meeting‑Summarizer
//
//  Created by sonam sherpa on 22/03/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.and.mic")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
            Text("Meeting Summarizer")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Phase 1 foundation is in progress.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
