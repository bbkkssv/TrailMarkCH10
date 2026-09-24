import SwiftUI
import TrailMarkCH10Core

struct ContentView: View {
    @Environment(WatchModel.self) private var model

    var body: some View {
        NavigationStack {
            List {
                // Main Screen
                WristHomeView()

                // Navigation Menu
                Section {
                    NavigationLink {
                        WristHomeView()
                    } label: {
                        Label("Wrist Home", systemImage: "figure.walk")
                    }

                    NavigationLink {
                        WristMemoView()
                    } label: {
                        Label("Wrist Memo", systemImage: "mic.fill")
                    }

                    NavigationLink {
                        LiveVitalsView()
                    } label: {
                        Label("Live Vitals", systemImage: "heart.fill")
                    }

                    NavigationLink {
                        MotionView()
                    } label: {
                        Label("Motion", systemImage: "waveform.path.ecg")
                    }
                }
            }
        }
        .navigationTitle("TrailMark WatchOS")
        .task {
            await model.health.requestAuthorization()
            await model.health.refreshTodaysSummary()
        }
    }
}

#Preview {
    ContentView()
        .environment(WatchModel())
}
