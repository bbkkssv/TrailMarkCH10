import Foundation
import Observation

@MainActor
@Observable
public final class JourneyStore {
    public private(set) var jounerys = []
}
