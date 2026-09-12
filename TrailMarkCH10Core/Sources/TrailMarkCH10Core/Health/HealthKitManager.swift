import Foundation
import HealthKit
import Observation

@MainActor
@Observable
public final class HealthKitManager {

    public enum AuthorizationState: Equatable {
        case unknown
        case unavailable
        case requesting
        case authorized
        case denied
    }
    
    public private(set) var currentAuthStatus: AuthorizationState = .unknown
    
    public private(set) var todaysSummary: ActivitySummary = .empty
    
    private let store = HKHealthStore()
    
    public init() {
        if !HKHealthStore.isHealthDataAvailable() {
            currentAuthStatus = .unavailable
        }
    }
    
    // MARK: - Authorization Framework
    
    private var stepsType: HKQuantityType { HKQuantityType(.stepCount) }
    private var distanceType: HKQuantityType { HKQuantityType(.distanceWalkingRunning) }
    private var energyType: HKQuantityType { HKQuantityType(.activeEnergyBurned) }
    private var sleepType: HKCategoryType { HKCategoryType(.sleepAnalysis) } // Awake, REM, Core, Deep
    
    private var readTypes: Set<HKObjectType> {
        [stepsType, distanceType, energyType, sleepType]
    }

    private var shareTypes: Set<HKSampleType> {
        [energyType, distanceType, HKObjectType.workoutType()]
    }
    
    public func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            currentAuthStatus = .unavailable
            return
        }
        currentAuthStatus = .requesting
        do {
            try await store.requestAuthorization(toShare:  shareTypes, read: readTypes)
            currentAuthStatus = .authorized
        } catch {
            currentAuthStatus = .denied
        }
    }
    
    public func refreshTodaysSummary() async {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        async let steps = sumQuantity(stepsType, unit: .count(), since: startOfDay)
        async let distance = sumQuantity(distanceType, unit: .meter(), since: startOfDay)
        async let energy = sumQuantity(energyType, unit: .kilocalorie(), since: startOfDay)
        
        todaysSummary = ActivitySummary(
            steps: await steps,
            distanceMeteres: await distance,
            activeEnergyKcal: await energy,
            date: startOfDay
        )
    }
    
    /// This func returs the cumulative sum of a quantity type from a given start date to now
    ///
    private func sumQuantity(
        _ type: HKQuantityType,
        unit: HKUnit,
        since start: Date
    ) async -> Double {
        return await withCheckedContinuation { continuation in
            let timePredicate = HKQuery.predicateForSamples(withStart: start, end: Date())

            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: timePredicate,
                options: .cumulativeSum,
            ) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            
            store.execute(query)
        }
    }
}
