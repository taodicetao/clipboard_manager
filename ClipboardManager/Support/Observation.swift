import Foundation
import Observation

func observeChanges<T>(_ read: @escaping () -> T, _ apply: @escaping (T) -> Void) {
    let value = withObservationTracking(read) {
        DispatchQueue.main.async { observeChanges(read, apply) }
    }
    apply(value)
}
