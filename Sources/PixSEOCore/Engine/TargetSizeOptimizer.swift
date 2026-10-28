import Foundation

/// Finds the highest quality whose encoded size stays under a byte limit.
public enum TargetSizeOptimizer {
    public static let minimumQuality = 0.40
    public static let maxIterations = 7

    public struct Outcome {
        public let data: Data
        public let quality: Double
        /// False when even `minimumQuality` is over the limit; `data` is then that smallest attempt.
        public let met: Bool
    }

    /// Tries `maxQuality` first; if it is too big, binary-searches down to `minimumQuality`.
    public static func encode(target: Int?, maxQuality: Double, encode: (Double) throws -> Data) throws -> Outcome {
        let first = try encode(maxQuality)
        guard let target, first.count > target else { return Outcome(data: first, quality: maxQuality, met: true) }

        var low = minimumQuality
        var high = maxQuality
        var best: (data: Data, quality: Double)?
        for _ in 0..<maxIterations {
            try Task.checkCancellation()
            let mid = (low + high) / 2
            let data = try encode(mid)
            if data.count <= target {
                best = (data, mid)
                low = mid
            } else {
                high = mid
            }
        }
        if let best { return Outcome(data: best.data, quality: best.quality, met: true) }
        let smallest = try encode(minimumQuality)
        return Outcome(data: smallest, quality: minimumQuality, met: smallest.count <= target)
    }
}
