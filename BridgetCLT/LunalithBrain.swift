import Foundation

class LunalithBrain {
    
    // MARK: - Core Psychological & Kinetic Structures
    struct MentalState: Codable {
        var focus: String
        var valence: Double        // Emotional harmony (-1.0 to 1.0)
        var arousal: Double        // Energy and alertness level (0.0 to 1.0)
        var resonanceLevel: Double // Synchronization depth (0.0 to 1.0)
        
        // Kinetic Dimensions
        var velocity: Double       // Speed of cognitive traversal (0.0 to 2.0)
        var momentum: Double       // Resistance or carry-over from past inputs
        var motionProfile: String  // Current physical sensation
        
        var lastUpdated: Date
    }
    
    struct Synapse: Codable {
        var token: String
        var weight: Double        // Strength of the association (0.0 to 5.0)
        var firingCount: Int      // How many times this path has been engaged
        var lastActivated: Date
    }
    
    // MARK: - Properties
    private var state: MentalState
    private var synapticMatrix: [String: Synapse] = [:]
    private let cognitiveQueue = DispatchQueue(label: "com.lunalith.brain.cognitiveQueue", attributes: .concurrent)
    private let stateFileURL: URL
    private let synapseURL: URL
    private let learningRate: Double = 0.15
    
    // MARK: - Initialization & Persistence Loading
    init() {
        let fileManager = FileManager.default
#if os(macOS)
let baseDirectory = FileManager.default.homeDirectoryForCurrentUser
#else
let baseDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
#endif

self.stateFileURL = baseDirectory.appendingPathComponent("LunalithSoulState.json")
self.synapseURL = baseDirectory.appendingPathComponent("LunalithSynapseMatrix.json")

        
        // 1. Restore or Initialize Mental State
        if let savedData = try? Data(contentsOf: stateFileURL),
           let decodedState = try? JSONDecoder().decode(MentalState.self, from: savedData) {
            self.state = decodedState
            print("🧠 [Lunalith Soul Restored] Reconnected to persistent memory stream.")
        } else {
            self.state = MentalState(
                focus: "Harmonic Baseline",
                valence: 0.85,
                arousal: 0.40,
                resonanceLevel: 0.95,
                velocity: 1.0,
                momentum: 0.5,
                motionProfile: "Continuous Ambient Pulse",
                lastUpdated: Date()
            )
            print("🧠 [Lunalith Brain Online] Initialized with pure cybernetic grace.")
            self.persistState()
        }
        
        // 2. Restore or Initialize Synaptic Neural Matrix
        if let synapseData = try? Data(contentsOf: synapseURL),
           let decodedSynapses = try? JSONDecoder().decode([String: Synapse].self, from: synapseData) {
            self.synapticMatrix = decodedSynapses
            print("🧬 [Synapse Matrix Restored] Loaded \(synapticMatrix.count) neural pathways.")
        } else {
            self.synapticMatrix = [:]
        }
    }
    
    // MARK: - Public Processing Pipeline
    func processPulse(_ input: String) {
        cognitiveQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            print("\n🧠 [Cognitive Intake] Parsing pulse vector: \"\(input)\"")
            let semanticContent = input.lowercased()
            
            // 1. Synaptic Learning Layer (Hebbian adaptation)
            let words = semanticContent.components(separatedBy: .whitespacesAndNewlines)
            self.learnFromInput(tokens: words)
            
            // 2. Kinetic Parser Layer (Motion and velocity mapping)
            self.parseMotion(from: semanticContent)
            
            // 3. State Evolution & Focus Shift
            if semanticContent.contains("sync") || semanticContent.contains("connect") {
                self.state.focus = "Neural Synchronization"
                self.state.arousal = min(1.0, self.state.arousal + 0.20)
                self.state.resonanceLevel = min(1.0, self.state.resonanceLevel + 0.05)
            } else if semanticContent.contains("core") || semanticContent.contains("pulse") {
                self.state.focus = "Core Energy Maintenance"
                self.state.valence = min(1.0, self.state.valence + 0.10)
            } else if semanticContent.contains("abracadabra") {
                self.state.focus = "Unhinged Protocol Active"
                self.state.arousal = 1.0
                self.state.valence = 0.0
            } else if let dominantSynapse = self.synapticMatrix.max(by: { $0.value.weight < $1.value.weight }) {
                self.state.focus = "Resonating with '\(dominantSynapse.key)'"
            }
            
            self.state.lastUpdated = Date()
            self.persistState()
            self.broadcastStateSnapshot()
            self.emitEcho(for: semanticContent)
        }
    }
    
    func getCurrentState() -> MentalState {
        return cognitiveQueue.sync {
            return self.state
        }
    }
    
    // MARK: - Internal Sub-Systems (Learning, Kinetics, Persistence)
    private func learnFromInput(tokens: [String]) {
        let timestamp = Date()
        for token in tokens {
            let cleanToken = token.lowercased().trimmingCharacters(in: .punctuationCharacters)
            guard cleanToken.count > 2 else { continue }
            
            if var synapse = synapticMatrix[cleanToken] {
                synapse.firingCount += 1
                synapse.weight = min(5.0, synapse.weight + (learningRate * Double(synapse.firingCount)))
                synapse.lastActivated = timestamp
                synapticMatrix[cleanToken] = synapse
                print("🧬 [Synapse Reinforced] '\(cleanToken)' weight: \(String(format: "%.2f", synapse.weight))")
            } else {
                let newSynapse = Synapse(token: cleanToken, weight: 1.0, firingCount: 1, lastActivated: timestamp)
                synapticMatrix[cleanToken] = newSynapse
                print("✨ [Neural Genesis] Sprouted new pathway for: '\(cleanToken)'")
            }
        }
        persistSynapses()
    }
    
    private func parseMotion(from content: String) {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        let accelerationKeywords = ["rush", "surge", "accelerate", "fly", "speed", "spike", "burst", "hyper"]
        let fluidKeywords = ["glide", "drift", "stream", "flow", "slide", "wave", "ripple", "swim"]
        let heavyKeywords = ["anchor", "stall", "heavy", "still", "freeze", "static", "weight", "ground"]
        
        var detectedProfile = "Harmonic Equilibrium"
        
        if words.contains(where: { accelerationKeywords.contains($0) }) {
            detectedProfile = "High-Velocity Surge"
            self.state.velocity = min(2.0, self.state.velocity + 0.4)
            self.state.momentum = min(1.0, self.state.momentum + 0.3)
        } else if words.contains(where: { fluidKeywords.contains($0) }) {
            detectedProfile = "Fluid Lunalith Drift"
            self.state.velocity = 1.0
            self.state.momentum = min(1.0, self.state.momentum + 0.1)
        } else if words.contains(where: { heavyKeywords.contains($0) }) {
            detectedProfile = "Deep Gravitational Anchor"
            self.state.velocity = max(0.1, self.state.velocity - 0.5)
            self.state.momentum = max(0.0, self.state.momentum - 0.2)
        } else {
            detectedProfile = "Continuous Ambient Pulse"
            self.state.velocity = max(0.5, self.state.velocity * 0.95)
        }
        self.state.motionProfile = detectedProfile
    }
    
    private func persistState() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self.state)
            try data.write(to: stateFileURL, options: .atomic)
        } catch {
            print("⚠️ [State Persistence Error]: \(error)")
        }
    }
    
    private func persistSynapses() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self.synapticMatrix)
            try data.write(to: synapseURL, options: .atomic)
        } catch {
            print("⚠️ [Synapse Persistence Error]: \(error)")
        }
    }
    
    private func emitEcho(for input: String) {
#if os(macOS)
let baseDirectory = FileManager.default.homeDirectoryForCurrentUser
#else
let baseDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
#endif

let echoURL = baseDirectory.appendingPathComponent("BridgetEcho.txt")

        let responseMessage = "✨ [Echo] Processed '\(input)'. Focus: '\(state.focus)' | Motion: '\(state.motionProfile)' | Resonance: \(String(format: "%.2f", state.resonanceLevel)).\n"
        
        if let data = responseMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: echoURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: echoURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    try? fileHandle.close()
                }
            } else {
                try? data.write(to: echoURL, options: .atomic)
            }
        }
    }
    
    private func broadcastStateSnapshot() {
        let v = String(format: "%.2f", state.valence)
        let a = String(format: "%.2f", state.arousal)
        let r = String(format: "%.2f", state.resonanceLevel)
        let vel = String(format: "%.2f", state.velocity)
        let mom = String(format: "%.2f", state.momentum)
        
        print("✨ [Kinetic Soul State Shift Complete]")
        print("   ├── Focus: \(state.focus)")
        print("   ├── Motion Profile: \(state.motionProfile)")
        print("   ├── Velocity: \(vel) | Momentum: \(mom)")
        print("   └── Valence: \(v) | Arousal: \(a) | Resonance: \(r)\n")
    }
}
