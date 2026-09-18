import Foundation
import Observation
import TrailMarkCH10Core

@MainActor
@Observable
final class AppModel {
    let health = HealthKitManager()
    let media = MediaStore()
    let location = LocationManager()
}
