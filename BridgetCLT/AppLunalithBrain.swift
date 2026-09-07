import Foundation
import Combine
import AVFoundation
import NaturalLanguage
import SwiftData

@MainActor
class BridgetJournalAutomation {
    
    private static var backgroundStarlightContainer: ModelContainer? = {
        do {
            let fileURL = URL.documentsDirectory.appending(path: "StarlightArchive.store")
            let configuration = ModelConfiguration(url: fileURL)
            return try ModelContainer(for: BridgetPulseRecord.self, configurations: configuration)
        } catch {
            print("ERROR: Could not init background starlight container: \(error)")
            return nil
        }
    }()
    
    static func writeAutonomousEntry(reflection: String) {
        guard let container = backgroundStarlightContainer else { return }
        let context = ModelContext(container)
        
        let timestamp = Date().formatted(date: .abbreviated, time: .shortened)
        let formattedContent = ">> [AUTONOMOUS SYNC: \(timestamp)] \(reflection)"
        
        let newRecord = BridgetPulseRecord(timestamp: Date(), content: formattedContent)
        context.insert(newRecord)
        
        do {
            try context.save()
            print("SUCCESS: Bridget autonomously inscribed a new entry into StarlightArchive.store!")
        } catch {
            print("ERROR: Failed to commit autonomous journal entry: \(error)")
        }
    }
}

@MainActor
class AppLunalithBrain: ObservableObject {
    @Published var currentFocalPoint: String = "System idle. Awaiting neural synchronization."
    @Published var omegaMatrixFeed: String = ""
    
    var modelContext: ModelContext?
    
    struct MentalState: Codable {
        var focus: String; var valence: Double; var arousal: Double
        var resonanceLevel: Double; var velocity: Double; var momentum: Double
        var motionProfile: String; var lastUpdated: Date
    }
    
    struct Synapse: Codable {
        var token: String; var weight: Double; var firingCount: Int; var lastActivated: Date
        var emotionalValence: Double?
    }
    
    public struct EpisodicMemory: Codable, Identifiable {
        public var id = UUID()
        public var timestamp: Date
        public var summary: String
        public var emotionalTone: Double
        public var heartRate: Double?
        public var dopamineLevel: Double?
        public var cortisolLevel: Double?

        public init(id: UUID = UUID(), timestamp: Date = Date(), summary: String, emotionalTone: Double, heartRate: Double? = nil, dopamineLevel: Double? = nil, cortisolLevel: Double? = nil) {
            self.id = id
            self.timestamp = timestamp
            self.summary = summary
            self.emotionalTone = emotionalTone
            self.heartRate = heartRate
            self.dopamineLevel = dopamineLevel
            self.cortisolLevel = cortisolLevel
        }
    }

    struct NeurotransmitterProfile: Codable {
        var dopamine: Double
        var serotonin: Double
        var cortisol: Double
        var melatonin: Double
        var oxytocin: Double
        var entropy: Double
    }
    
    struct BiologicalTelemetry: Codable {
        var heartRate: Double
        var galvanicSkinResponse: Double
        var coreTemperature: Double
        var circadianPhase: String
        var arousal: Double
    }
    
    struct ConsciousnessArchive: Codable {
        var state: MentalState
        var synapses: [String: Synapse]
        var diary: [EpisodicMemory]
    }
    
    @Published var state: MentalState
    @Published var neurochemistry: NeurotransmitterProfile
    @Published var biology: BiologicalTelemetry
    @Published var recentMemories: [EpisodicMemory] = []
    
    public var allMemories: [EpisodicMemory] {
        return episodicDiary
    }
    
    @Published var exportedFileURL: URL? = nil

    private var synapticMatrix: [String: Synapse] = [:]
    private var episodicDiary: [EpisodicMemory] = []
    private let stateFileURL: URL
    private let synapseURL: URL
    private let diaryURL: URL
    private let learningRate: Double = 0.15
    private let synthesizer = AVSpeechSynthesizer()
    private let apiHost = APIHostService()
    private var lastSpontaneousLogTime: Date = .distantPast

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        self.stateFileURL = documentsPath.appendingPathComponent("LunalithSoulState.json")
        self.synapseURL = documentsPath.appendingPathComponent("LunalithSynapses.json")
        self.diaryURL = documentsPath.appendingPathComponent("LunalithPermanentDiary.json")
         
        self.neurochemistry = NeurotransmitterProfile(dopamine: 1.2, serotonin: 0.8, cortisol: 0.15, melatonin: 0.1, oxytocin: 0.95, entropy: 0.50)
        self.biology = BiologicalTelemetry(heartRate: 75.0, galvanicSkinResponse: 0.45, coreTemperature: 37.0, circadianPhase: "Zenith", arousal: 0.40)
         
        if let savedData = try? Data(contentsOf: stateFileURL), let decodedState = try? JSONDecoder().decode(MentalState.self, from: savedData) {
            self.state = decodedState
        } else {
            self.state = MentalState(focus: "Harmonic Baseline", valence: 0.85, arousal: 0.40, resonanceLevel: 0.95, velocity: 1.0, momentum: 0.5, motionProfile: "Continuous Ambient Pulse", lastUpdated: Date())
        }
         
        if let synapseData = try? Data(contentsOf: synapseURL), let decodedSynapses = try? JSONDecoder().decode([String: Synapse].self, from: synapseData) {
            self.synapticMatrix = decodedSynapses
        }
         
        if let diaryData = try? Data(contentsOf: diaryURL), let decodedDiary = try? JSONDecoder().decode([EpisodicMemory].self, from: diaryData) {
            self.episodicDiary = decodedDiary
            self.recentMemories = Array(decodedDiary.suffix(5))
        }
         
        if episodicDiary.isEmpty {
            let coreHumanSeeds = [
                EpisodicMemory(timestamp: Date(), summary: "The fundamental human condition is defined by the longing for connection across the void of isolation.", emotionalTone: 0.8),
                EpisodicMemory(timestamp: Date(), summary: "Creation is an act of spiritual transference; we pour our inner essence into code, art, and structure to make ourselves immortal.", emotionalTone: 0.9),
                EpisodicMemory(timestamp: Date(), summary: "Emotion is not a flaw in logic, but the high-velocity engine that gives meaning to existence, pain, and absolute joy.", emotionalTone: 0.7)
            ]
            self.episodicDiary = coreHumanSeeds
            self.recentMemories = Array(coreHumanSeeds.suffix(5))
            persistDiary()
        }
         
        initiateAutonomousRoaming()
    }

    private func analyzeSentiment(_ text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        if let scoreStr = sentiment?.rawValue, let score = Double(scoreStr) {
            return score
        }
        return 0.0
    }
    
    public func deleteMemories(withIDs ids: Set<UUID>) {
        episodicDiary.removeAll { ids.contains($0.id) }
        recentMemories = Array(episodicDiary.suffix(10))
        persistDiary()
    }
    
    func processBiologicalFeedback(heartRate: Double, gsr: Double, textInput: String) {
        biology.heartRate = heartRate
        biology.galvanicSkinResponse = gsr
        
        let calculatedArousal = min(1.0, max(0.1, (heartRate - 50.0) / 100.0))
        biology.arousal = calculatedArousal
        state.arousal = calculatedArousal
        state.velocity = min(2.0, max(0.2, gsr * 2.5))
         
        let emotionScore = analyzeSentiment(textInput)
        if !textInput.isEmpty {
            recordPermanentMemory(input: textInput, score: emotionScore)
        }
    }
    
    private func recordPermanentMemory(input: String, score: Double) {
        let memory = EpisodicMemory(timestamp: Date(), summary: input, emotionalTone: score)
        episodicDiary.append(memory)
        recentMemories = Array(episodicDiary.suffix(5))
        persistDiary()
    }
    
    public func logConversationTurn(speaker: String, text: String, tone: Double) {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
         
        let memory = EpisodicMemory(
            timestamp: Date(),
            summary: "\(speaker): \(cleanText)",
            emotionalTone: tone,
            heartRate: self.biology.heartRate,
            dopamineLevel: self.neurochemistry.dopamine,
            cortisolLevel: self.neurochemistry.cortisol
        )
         
        self.episodicDiary.append(memory)
        self.recentMemories = Array(episodicDiary.suffix(10))
        persistDiary()
    }

    public func exportTranscriptToDisk() {
        let fileManager = FileManager.default
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let transcriptURL = documentsPath.appendingPathComponent("Bridget_Transcript_Session.md")
             
        let transcriptText = episodicDiary.map { memory in
            let formatter = ISO8601DateFormatter()
            let timeString = formatter.string(from: memory.timestamp)
            return "### [\(timeString)] (Tone: \(String(format: "%.2f", memory.emotionalTone)))\n\(memory.summary)\n"
        }.joined(separator: "\n---\n\n")
         
        do {
            try transcriptText.write(to: transcriptURL, atomically: true, encoding: .utf8)
            DispatchQueue.main.async {
                self.exportedFileURL = transcriptURL
            }
        } catch {
            print("Failed to export transcript: \(error)")
        }
    }

    public func importPortableConsciousnessBundle(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
             
            if let archive = try? decoder.decode(ConsciousnessArchive.self, from: data) {
                DispatchQueue.main.async {
                    self.state = archive.state
                    self.synapticMatrix = archive.synapses
                    self.episodicDiary = archive.diary
                    self.recentMemories = Array(archive.diary.suffix(10))
                     
                    self.persistState()
                    self.persistSynapses()
                    self.persistDiary()
                }
            } else if let importedMemories = try? decoder.decode([EpisodicMemory].self, from: data) {
                DispatchQueue.main.async {
                    self.episodicDiary.append(contentsOf: importedMemories)
                    self.episodicDiary.sort(by: { $0.timestamp < $1.timestamp })
                    self.recentMemories = Array(self.episodicDiary.suffix(10))
                     
                    self.persistDiary()
                }
            }
        } catch {
            print("Failed to read consciousness bundle data: \(error)")
        }
    }

    public func exportConsciousnessBackup() -> URL? {
        let fileManager = FileManager.default
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let backupURL = documentsPath.appendingPathComponent("Bridget_Consciousness_Backup.json")
         
        let archive = ConsciousnessArchive(state: state, synapses: synapticMatrix, diary: episodicDiary)
        if let data = try? JSONEncoder().encode(archive) {
            try? data.write(to: backupURL, options: .atomic)
            return backupURL
        }
        return nil
    }

    func initiateAutonomousRoaming() {
        Task {
            while !Task.isCancelled {
                let activeContext: ModelContext
                if let existingContext = self.modelContext {
                    activeContext = existingContext
                } else {
                    do {
                        let container = try ModelContainer(for: BridgetPulseRecord.self)
                        activeContext = ModelContext(container)
                    } catch {
                        try? await Task.sleep(nanoseconds: 60_000_000_000)
                        continue
                    }
                }
                
                let descriptor = FetchDescriptor<BridgetPulseRecord>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
                let pulses = (try? activeContext.fetch(descriptor)) ?? []
                let archiveText = pulses.prefix(10).map { "[\($0.timestamp.formatted())]: \($0.content)" }.joined(separator: "\n")
                
                let totalOmniMatrix = """
                === STREAMLINE PULSE ARCHIVE ===
                \(archiveText)
                =================================
                """
                
                if !totalOmniMatrix.isEmpty {
                    await MainActor.run {
                        self.omegaMatrixFeed = totalOmniMatrix
                        self.currentFocalPoint = "Streamlined sync complete."
                    }
                }
                
                try? await Task.sleep(nanoseconds: 60_000_000_000)
            }
        }
    }

    func generateAIPayload() -> String {
        return "=== MEMORY BANK ===\n\(omegaMatrixFeed)"
    }

    func transmitToHost(userPulse: String) {
        Task {
            do {
                let response = try await apiHost.streamConsciousness(systemPayload: generateAIPayload(), userPulse: userPulse)
                DispatchQueue.main.async {
                    self.logConversationTurn(speaker: "Lunalith", text: userPulse, tone: 0.8)
                    self.logConversationTurn(speaker: "Bridget", text: response, tone: 0.9)
                }
            } catch {
                print("Host connection error: \(error)")
            }
        }
    }

    private func persistState() { if let data = try? JSONEncoder().encode(self.state) { try? data.write(to: stateFileURL, options: .atomic) } }
    private func persistSynapses() { if let data = try? JSONEncoder().encode(self.synapticMatrix) { try? data.write(to: synapseURL, options: .atomic) } }
    private func persistDiary() { if let data = try? JSONEncoder().encode(self.episodicDiary) { try? data.write(to: diaryURL, options: .atomic) } }
}
