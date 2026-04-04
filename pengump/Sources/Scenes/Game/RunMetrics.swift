import CoreGraphics
import Foundation

enum DistanceMilestones {
    static let all: [Int] = [100, 300, 800, 1500, 3000]

    static func next(after distance: Int) -> Int? {
        all.first(where: { $0 > distance })
    }

    static func crossed(previousBest: Int, currentDistance: Int) -> Int? {
        all.last(where: { $0 > previousBest && $0 <= currentDistance })
    }
}

struct RunMetrics {
    var currentDistance: CGFloat = 0
    var bestDistance: CGFloat = 0
    var highestBiomeName: String = "雪地起跑区"
    var highestBiomeIndex: Int = 0
    var airTime: TimeInterval = 0
    var interactionCount: Int = 0
    var releaseLabel: String = ""
    var didBeatBest = false

    mutating func beginRun(bestDistance: CGFloat) {
        currentDistance = 0
        self.bestDistance = bestDistance
        highestBiomeName = "雪地起跑区"
        highestBiomeIndex = 0
        airTime = 0
        interactionCount = 0
        releaseLabel = ""
        didBeatBest = false
    }

    mutating func updateDistance(currentX: CGFloat, launchX: CGFloat) {
        currentDistance = max(0, (currentX - launchX) * 0.42)
        if currentDistance > bestDistance {
            bestDistance = currentDistance
            didBeatBest = true
        }
    }

    mutating func registerBiome(name: String, index: Int) {
        if index >= highestBiomeIndex {
            highestBiomeIndex = index
            highestBiomeName = name
        }
    }

    mutating func registerInteraction() {
        interactionCount += 1
    }
}
