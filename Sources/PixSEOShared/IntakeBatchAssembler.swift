import Foundation

/// Joins the chunks of a split `IntakeRequest` back into one request.
///
/// LaunchServices may deliver chunk URLs out of order. A request is released as soon as all of
/// its chunks have arrived; if some never arrive, `drainExpired` releases what was received so
/// the user still gets the files that made it.
public struct IntakeBatchAssembler {
    private struct Pending {
        var firstSeen: Date
        var parts: [Int: IntakeRequest]
        var count: Int
    }

    private var pending: [String: Pending] = [:]

    public init() {}

    /// Returns a complete request, or `nil` while chunks of its batch are still missing.
    public mutating func accept(_ request: IntakeRequest, now: Date = Date()) -> IntakeRequest? {
        guard let chunk = request.chunk else { return request }

        var entry = pending[chunk.batchID] ?? Pending(firstSeen: now, parts: [:], count: chunk.count)
        entry.parts[chunk.index] = request
        guard entry.parts.count == entry.count else {
            pending[chunk.batchID] = entry
            return nil
        }
        pending[chunk.batchID] = nil
        return Self.merge(entry)
    }

    /// Releases batches that have waited longer than `timeout`, with whatever chunks arrived.
    public mutating func drainExpired(now: Date = Date(), timeout: TimeInterval = 2) -> [IntakeRequest] {
        let expired = pending.filter { now.timeIntervalSince($0.value.firstSeen) >= timeout }
        expired.keys.forEach { pending[$0] = nil }
        return expired.values.compactMap(Self.merge)
    }

    public var hasPending: Bool { !pending.isEmpty }

    private static func merge(_ entry: Pending) -> IntakeRequest? {
        let ordered = entry.parts.keys.sorted().compactMap { entry.parts[$0] }
        guard let first = ordered.first else { return nil }
        return IntakeRequest(action: first.action, width: first.width, files: ordered.flatMap(\.files))
    }
}
