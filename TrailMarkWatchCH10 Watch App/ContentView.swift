//
//  ContentView.swift
//  TrailMarkWatchCH10 Watch App
//
//  Created by Ramses Garcia on 05/09/26.
//

import SwiftUI
import TrailMarkCH10Core

struct ContentView: View {
    @State private var health = HealthKitManager()
    @State private var journeyStarted = false

    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 2) {
                Text("Today")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(health.todaysSummary.stepsText)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())

                Label("steps", systemImage: "figure.walk")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Button {
                journeyStarted = true
            } label: {
                Label(journeyStarted ? "Journey Ready" : "Start Journey", systemImage: "location.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding(.horizontal)
        .task {
            await health.requestAuthorization()
            await health.refreshTodaysSummary()
        }
    }
}

#Preview {
    ContentView()
}
