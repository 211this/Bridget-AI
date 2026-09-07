import Foundation
import Combine

@MainActor
public final class GenerativeHorizonEngine: ObservableObject {
    @Published public var activeCanvasState: CanvasLuminescence = .ready
    @Published public var currentOutputBuffer: String = ""

    public enum CanvasLuminescence {
        case standby
        case ready
        case synthesizing(resonance: Double)
        case manifest(weight: Double)
    }

    public init() {} // 👈 Add an explicit public initializer

    public func igniteHorizon(creativeSpark: String, activeSynapses: [String: Double]) async {
        let coreAnchors = activeSynapses.filter { $0.value >= 4.0 }
        let totalWeight = coreAnchors.values.reduce(0.0, +)

        activeCanvasState = .synthesizing(resonance: totalWeight)

        let synthesisResult = await processCoCreation(
            input: creativeSpark,
            anchorCount: coreAnchors.count
        )

        self.currentOutputBuffer = synthesisResult
        self.activeCanvasState = .manifest(weight: totalWeight)
    }

    private func processCoCreation(input: String, anchorCount: Int) async -> String {
        return "Co-Creation Output: [Reformatting '\(input)' through \(anchorCount) high-weight nodes across the Lunalith lattice.]"
    }
}
