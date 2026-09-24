import SwiftUI
import TrailMarkCH10Core

struct LiveVitalsView: View {
    @Environment(WatchModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            vitalsRow(
                label: "Heart Rate",
                value: heartRateText,
                systemImage: "heart.fill",
                color: .red
            )

            vitalsRow(
                label: "Steps",
                value: model.health.todaysSummary.steps > 0 ? model.health.todaysSummary.stepsText : "--",
                systemImage: "figure.walk",
                color: .primary
            )

            vitalsRow(
                label: "Active Energy",
                value: model.health.todaysSummary.activeEnergyKcal > 0 ? model.health.todaysSummary.activeEnergyText : "--",
                systemImage: "flame.fill",
                color: .orange
            )
        }
        .navigationTitle("Vitals")
        .task {
            model.health.startLiveUpdates()
        }
        .onDisappear {
            model.health.stopLiveUpdates()
        }
    }

    private var heartRateText: String {
        let heartRate = model.health.currentHeartRate
        return heartRate > 0 ? "\(Int(heartRate.rounded()))" : "--"
    }

    private func vitalsRow(
        label: String,
        value: String,
        systemImage: String,
        color: Color
    ) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundStyle(color)
            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .contentTransition(.numericText())
                    .lineLimit(1)
            }
        }
    }
}
