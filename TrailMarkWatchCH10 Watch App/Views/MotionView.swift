import SwiftUI
import CoreMotion
import Observation

@Observable
final class MotionSensor {
    var magnitude: Double = 0

    private let motionManager = CMMotionManager()

    func start() {
        motionManager.deviceMotionUpdateInterval = 0.2
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let acceleration = motion?.userAcceleration else { return }
            self?.magnitude = sqrt(
                acceleration.x * acceleration.x +
                acceleration.y * acceleration.y +
                acceleration.z * acceleration.z
            )
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}

struct MotionView: View {
    @State private var sensor = MotionSensor()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Motion")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(sensor.magnitude, format: .number.precision(.fractionLength(2)))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
            Text(activityText)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Motion")
        .task {
            sensor.start()
        }
        .onDisappear {
            sensor.stop()
        }
    }

    private var activityText: String {
        if sensor.magnitude < 0.1 {
            "Still"
        } else if sensor.magnitude < 0.5 {
            "Walking"
        } else {
            "Active"
        }
    }
}
