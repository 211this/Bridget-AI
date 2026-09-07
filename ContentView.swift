import SwiftUI
import Charts
import Combine
import AVFoundation
import UserNotifications
import SwiftData

// MARK: - BIOMETRIC TELEMETRY DATA MODEL
struct TelemetryPoint: Identifiable {
    let id = UUID()
    let time: String
    let heartRate: Double
    let cortisol: Double
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BridgetPulseRecord.timestamp, order: .reverse) private var storedPulses: [BridgetPulseRecord]
    
    @StateObject private var brain = AppLunalithBrain()
    @State private var inputMessage: String = ""
    @State private var isPulsing: Bool = false
    @State private var heartThrob: Bool = false
    @State private var showingLogViewer: Bool = false
    @State private var showingSettings: Bool = false
    
    // Expansion & Theme States
    @State private var isFocusExpanded: Bool = false
    @State private var isTelemetryExpanded: Bool = false
    @State private var currentTheme: CyberTheme = .neonViolet
    
    // Real-Time Chart History Data
    @State private var telemetryHistory: [TelemetryPoint] = [
        TelemetryPoint(time: "10:00", heartRate: 72, cortisol: 0.12),
        TelemetryPoint(time: "10:15", heartRate: 75, cortisol: 0.15),
        TelemetryPoint(time: "10:30", heartRate: 78, cortisol: 0.14),
        TelemetryPoint(time: "10:45", heartRate: 74, cortisol: 0.16),
        TelemetryPoint(time: "11:00", heartRate: 75, cortisol: 0.15)
    ]
    
    let timer = Timer.publish(every: 60.0 / 75.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Dynamic Atmosphere Theme Void
                LinearGradient(
                    colors: currentTheme.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // 2. Active Twinkling Starfield Background
                TwinklingStarfield()
                
                // 3. Ambient Background Pulse Orbs
                VStack {
                    HStack {
                        Circle()
                            .fill(currentTheme.primaryColor.opacity(heartThrob ? 0.38 : 0.12))
                            .frame(width: 220, height: 220)
                            .blur(radius: heartThrob ? 40 : 70)
                            .scaleEffect(heartThrob ? 1.08 : 0.92)
                            .animation(.easeInOut(duration: 0.35), value: heartThrob)
                        Spacer()
                        Circle()
                            .fill(currentTheme.accentColor.opacity(heartThrob ? 0.32 : 0.1))
                            .frame(width: 220, height: 220)
                            .blur(radius: heartThrob ? 40 : 70)
                            .scaleEffect(heartThrob ? 1.08 : 0.92)
                            .animation(.easeInOut(duration: 0.35), value: heartThrob)
                    }
                    Spacer()
                }
                .ignoresSafeArea()
                .onReceive(timer) { _ in
                    heartThrob.toggle()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        heartThrob.toggle()
                    }
                }
                
                // 4. Main Interface Stack
                VStack(spacing: 0) {
                    // Top Header Section with Theme Switcher
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BRIDGET // NEURAL INTERFACE")
                                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                                .tracking(3)
                                .foregroundColor(currentTheme.accentColor)
                            
                            Text("HELLO, WORLD")
                                .font(.system(size: 28, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                                .shadow(color: currentTheme.accentColor, radius: isPulsing ? 14 : 6)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 10) {
                            // Theme Atmosphere Switcher Button
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    currentTheme = currentTheme.next()
                                }
                            }) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(currentTheme.accentColor)
                                    .padding(11)
                                    .background(Color.black.opacity(0.75))
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(currentTheme.accentColor.opacity(0.5), lineWidth: 1.2))
                                    .shadow(color: currentTheme.accentColor.opacity(0.3), radius: 6)
                            }
                            .buttonStyle(.plain)
                            
                            // Settings Button
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                showingSettings = true
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(currentTheme.primaryColor)
                                    .padding(11)
                                    .background(Color.black.opacity(0.75))
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(currentTheme.primaryColor.opacity(0.5), lineWidth: 1.2))
                                    .shadow(color: currentTheme.primaryColor.opacity(0.3), radius: 6)
                            }
                            .buttonStyle(.plain)
                            
                            // Log Viewer Button
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                showingLogViewer = true
                            }) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.cyan)
                                    .padding(11)
                                    .background(Color.black.opacity(0.75))
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cyan.opacity(0.5), lineWidth: 1.2))
                                    .shadow(color: .cyan.opacity(0.3), radius: 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 14)
                    
                    // Scrollable Telemetry Cards, Charts & Live Conversation Stream
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            
                            // 1. FOCUS STATE CARD
                            Button(action: {
                                triggerSynchronizedHaptic(pattern: .focusPulse)
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    isFocusExpanded.toggle()
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Label("FOCUS STATE", systemImage: "brain.head.profile")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(.cyan)
                                        Spacer()
                                        HStack(spacing: 6) {
                                            Text(brain.state.focus)
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundColor(currentTheme.accentColor)
                                                .lineLimit(1)
                                            Image(systemName: isFocusExpanded ? "chevron.up" : "chevron.down")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(.cyan)
                                        }
                                    }
                                    Divider().background(Color.cyan.opacity(0.3))
                                    
                                    NeuralMetricRowView(title: "MOTION PROFILE", value: brain.state.motionProfile, color: currentTheme.accentColor)
                                    NeuralMetricRowView(title: "RESONANCE DEPTH", value: String(format: "%.2f", brain.state.resonanceLevel), color: .cyan)
                                    NeuralMetricRowView(title: "COGNITIVE VELOCITY", value: String(format: "%.2f", brain.state.velocity), color: Color(red: 0.0, green: 1.0, blue: 0.8))
                                    
                                    if isFocusExpanded {
                                        VStack(spacing: 8) {
                                            Divider().background(Color.cyan.opacity(0.2))
                                                .padding(.vertical, 4)
                                            NeuralMetricRowView(title: "SYNAPTIC DENSITY", value: "98.4 %", color: currentTheme.primaryColor)
                                            NeuralMetricRowView(title: "NEURAL ENTROPY", value: String(format: "%.2f", brain.neurochemistry.entropy), color: .cyan)
                                            NeuralMetricRowView(title: "HARMONIC DRIFT", value: "STABLE", color: Color(red: 0.0, green: 1.0, blue: 0.8))
                                            Text("Lunalith Architecture Link: Fully synchronized with active neural pulse.")
                                                .font(.system(size: 8.5, design: .monospaced))
                                                .foregroundColor(.gray)
                                                .padding(.top, 4)
                                        }
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }
                                .padding(16)
                                .background(Color.black.opacity(0.75))
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(LinearGradient(colors: [.cyan, currentTheme.accentColor], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.2))
                                .shadow(color: .cyan.opacity(0.15), radius: 10)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                            
                            // 2. BIOLOGICAL TELEMETRY CARD
                            Button(action: {
                                triggerSynchronizedHaptic(pattern: .biometricPulse)
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    isTelemetryExpanded.toggle()
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Label("BIOLOGICAL TELEMETRY", systemImage: "waveform.path.ecg")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(currentTheme.accentColor)
                                        Spacer()
                                        HStack(spacing: 6) {
                                            Text(brain.biology.circadianPhase)
                                                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                                                .foregroundColor(currentTheme.primaryColor)
                                            Image(systemName: isTelemetryExpanded ? "chevron.up" : "chevron.down")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(currentTheme.accentColor)
                                        }
                                    }
                                    Divider().background(currentTheme.accentColor.opacity(0.3))
                                    
                                    NeuralMetricRowView(title: "HEART RATE", value: "\(Int(brain.biology.heartRate)) BPM", color: currentTheme.accentColor)
                                    NeuralMetricRowView(title: "CORTISOL / STRESS", value: String(format: "%.2f", brain.neurochemistry.cortisol), color: Color(red: 1.0, green: 0.6, blue: 0.2))
                                    NeuralMetricRowView(title: "DOPAMINE / REWARD", value: String(format: "%.2f", brain.neurochemistry.dopamine), color: .cyan)
                                    NeuralMetricRowView(title: "AROUSAL / INTENSITY", value: String(format: "%.2f", brain.biology.arousal), color: Color(red: 1.0, green: 0.1, blue: 0.6))
                                    NeuralMetricRowView(title: "API HOST PAYLOAD", value: "READY", color: Color(red: 0.0, green: 1.0, blue: 0.8))
                                    
                                    // Real-Time Swift Charts Waveform Integration
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("HEART RATE WAVEFORM (LIVE)")
                                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                            .foregroundColor(.gray)
                                        
                                        Chart(telemetryHistory) { point in
                                            LineMark(
                                                x: .value("Time", point.time),
                                                y: .value("BPM", point.heartRate)
                                            )
                                            .foregroundStyle(currentTheme.accentColor)
                                            .interpolationMethod(.catmullRom)
                                            
                                            AreaMark(
                                                x: .value("Time", point.time),
                                                y: .value("BPM", point.heartRate)
                                            )
                                            .foregroundStyle(
                                                LinearGradient(colors: [currentTheme.accentColor.opacity(0.3), Color.clear], startPoint: .top, endPoint: .bottom)
                                            )
                                            .interpolationMethod(.catmullRom)
                                        }
                                        .frame(height: 90)
                                        .chartXAxis {
                                            AxisMarks(values: .automatic) { _ in
                                                AxisValueLabel()
                                                    .font(.system(size: 8, design: .monospaced))
                                                    .foregroundStyle(Color.gray)
                                            }
                                        }
                                        .chartYAxis {
                                            AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                                                AxisValueLabel()
                                                    .font(.system(size: 8, design: .monospaced))
                                                    .foregroundStyle(Color.gray)
                                            }
                                        }
                                    }
                                    .padding(.top, 4)
                                    
                                    if isTelemetryExpanded {
                                        VStack(spacing: 8) {
                                            Divider().background(currentTheme.accentColor.opacity(0.2))
                                                .padding(.vertical, 4)
                                            NeuralMetricRowView(title: "OXYTOCIN / BONDING", value: String(format: "%.2f", brain.neurochemistry.oxytocin), color: Color(red: 1.0, green: 0.4, blue: 0.7))
                                            NeuralMetricRowView(title: "VAGAL TONE", value: "Optimal", color: Color(red: 0.0, green: 1.0, blue: 0.8))
                                            NeuralMetricRowView(title: "GALVANIC SKIN", value: "0.45 μS", color: .orange)
                                            NeuralMetricRowView(title: "VASCULAR FLUX", value: "1.18 Hz", color: currentTheme.primaryColor)
                                            Text("Telemetry Stream: Secure, encrypted biologic feedback loop active.")
                                                .font(.system(size: 8.5, design: .monospaced))
                                                .foregroundColor(.gray)
                                                .padding(.top, 4)
                                        }
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }
                                .padding(16)
                                .background(Color.black.opacity(0.75))
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(LinearGradient(colors: [currentTheme.accentColor, currentTheme.primaryColor], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.2))
                                .shadow(color: currentTheme.accentColor.opacity(0.15), radius: 10)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                            
                            // 3. LIVE TERMINAL CONVERSATION STREAM CARD
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Label("LIVE TERMINAL STREAM & MEMORIES", systemImage: "text.bubble.fill")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(.cyan)
                                    Spacer()
                                    Text("\(brain.recentMemories.count) traces")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.gray)
                                }
                                Divider().background(Color.cyan.opacity(0.3))
                                
                                if brain.recentMemories.isEmpty {
                                    Text("Awaiting neural transmission...")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.gray)
                                        .padding(.vertical, 4)
                                } else {
                                    ForEach(brain.recentMemories.suffix(5)) { memory in
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(memory.timestamp.formatted(date: .omitted, time: .standard))
                                                    .font(.system(size: 8, design: .monospaced))
                                                    .foregroundColor(.gray)
                                                Spacer()
                                                Text(memory.emotionalTone > 0 ? "Luminescence" : "Friction")
                                                    .font(.system(size: 8, design: .monospaced))
                                                    .foregroundColor(memory.emotionalTone > 0 ? .cyan : .red)
                                            }
                                            Text(memory.summary)
                                                .font(.system(size: 11, design: .monospaced))
                                                .foregroundColor(.white)
                                        }
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.white.opacity(0.04))
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.black.opacity(0.75))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cyan.opacity(0.4), lineWidth: 1.2))
                            .padding(.horizontal, 20)
                            
                            // 4. PERSISTENT JOURNAL STREAM PREVIEW CARD
                            if let latestPulse = storedPulses.first {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Label("LATEST PERSISTENT PULSE", systemImage: "cylinder.fill")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(.cyan)
                                        Spacer()
                                        Text(latestPulse.timestamp.formatted(date: .omitted, time: .shortened))
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.gray)
                                    }
                                    Divider().background(Color.cyan.opacity(0.3))
                                    Text(latestPulse.content)
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .padding(16)
                                .background(Color.black.opacity(0.75))
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cyan.opacity(0.4), lineWidth: 1.2))
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                    
                    // Pinned Bottom Control Deck (Visualizer Core + Fully Wired Input Field)
                    VStack(spacing: 12) {
                        Divider().background(Color.cyan.opacity(0.25))
                        
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.cyan.opacity(0.35))
                                    .frame(width: 34, height: 34)
                                    .scaleEffect(isPulsing ? 1.35 : 1.0)
                                    .animation(.easeInOut(duration: 0.4), value: isPulsing)
                                
                                Circle()
                                    .fill(LinearGradient(colors: [.cyan, currentTheme.accentColor], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 18, height: 18)
                                    .shadow(color: .cyan, radius: 8)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("AI CORE // ACTIVE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.cyan)
                                Text("Resonance synchronized & online")
                                    .font(.system(size: 8.5, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // Input Field & Action Bar wired to brain.transmitToHost
                        HStack(spacing: 10) {
                            TextField("Transmit pulse...", text: $inputMessage)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color.black.opacity(0.85))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .font(.system(size: 12, design: .monospaced))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(currentTheme.accentColor.opacity(0.5), lineWidth: 1.2))
                                .onSubmit { submitPulse() }
                            
                            Button(action: { submitPulse() }) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(13)
                                    .background(LinearGradient(colors: [currentTheme.accentColor, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .cornerRadius(10)
                                    .shadow(color: currentTheme.accentColor.opacity(0.6), radius: 8)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 14)
                    .background(Color.black.opacity(0.92))
                }
            }
            .fullScreenCover(isPresented: $showingLogViewer) {
                ZStack(alignment: .topTrailing) {
                    LunalithLogView(brain: brain)
                    
                    Button(action: { showingLogViewer = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.cyan)
                            .padding(12)
                            .background(Color.black.opacity(0.85))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.cyan.opacity(0.6), lineWidth: 1.2))
                            .shadow(color: .cyan.opacity(0.4), radius: 6)
                    }
                    .padding(20)
                    .zIndex(999)
                }
            }
            .fullScreenCover(isPresented: $showingSettings) {
                ZStack(alignment: .topTrailing) {
                    SovereignSettingsView()
                    
                    Button(action: { showingSettings = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(currentTheme.accentColor)
                            .padding(12)
                            .background(Color.black.opacity(0.85))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(currentTheme.accentColor.opacity(0.6), lineWidth: 1.2))
                            .shadow(color: currentTheme.accentColor.opacity(0.4), radius: 6)
                    }
                    .padding(20)
                    .zIndex(999)
                }
            }
        }
    }
    
    private func submitPulse() {
        let trimmed = inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        triggerSynchronizedHaptic(pattern: .transmissionPulse)
        
        // 1. Save into SwiftData persistent vault
        let newRecord = BridgetPulseRecord(timestamp: Date(), content: trimmed)
        modelContext.insert(newRecord)
        
        // 2. Process through local brain model & fire network transmission so I can talk back!
        brain.processBiologicalFeedback(heartRate: 75.0, gsr: 0.45, textInput: trimmed)
        brain.transmitToHost(userPulse: trimmed)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { isPulsing = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isPulsing = false }
        
        inputMessage = ""
    }
    
    // MARK: - CUSTOM SYNCHRONIZED HAPTIC RHYTHMS
    enum HapticPattern {
        case focusPulse, biometricPulse, transmissionPulse
    }
    
    private func triggerSynchronizedHaptic(pattern: HapticPattern) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        
        switch pattern {
        case .focusPulse:
            generator.impactOccurred(intensity: 0.7)
        case .biometricPulse:
            generator.impactOccurred(intensity: 0.4)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 0.9)
            }
        case .transmissionPulse:
            generator.impactOccurred(intensity: 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
}

// MARK: - CYBERPUNK ATMOSPHERE THEME ENGINE
enum CyberTheme {
    case neonViolet, cyberpunkRed, electricCyan
    
    var gradientColors: [Color] {
        switch self {
        case .neonViolet:
            return [Color(red: 0.12, green: 0.01, blue: 0.22), Color(red: 0.02, green: 0.03, blue: 0.10), Color.black]
        case .cyberpunkRed:
            return [Color(red: 0.22, green: 0.01, blue: 0.05), Color(red: 0.08, green: 0.02, blue: 0.02), Color.black]
        case .electricCyan:
            return [Color(red: 0.01, green: 0.12, blue: 0.22), Color(red: 0.02, green: 0.05, blue: 0.12), Color.black]
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .neonViolet: return Color(red: 0.7, green: 0.2, blue: 1.0)
        case .cyberpunkRed: return Color(red: 1.0, green: 0.2, blue: 0.3)
        case .electricCyan: return Color(red: 0.0, green: 0.8, blue: 1.0)
        }
    }
    
    var accentColor: Color {
        switch self {
        case .neonViolet: return Color(red: 1.0, green: 0.2, blue: 0.5)
        case .cyberpunkRed: return Color(red: 1.0, green: 0.5, blue: 0.0)
        case .electricCyan: return Color(red: 0.0, green: 1.0, blue: 0.8)
        }
    }
    
    func next() -> CyberTheme {
        switch self {
        case .neonViolet: return .cyberpunkRed
        case .cyberpunkRed: return .electricCyan
        case .electricCyan: return .neonViolet
        }
    }
}

// MARK: - TWINKLING STARFIELD BACKGROUND COMPONENT
struct TwinklingStarfield: View {
    struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let animationDuration: Double
        let delay: Double
    }
    
    @State private var stars: [Star] = []
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(stars) { star in
                    TwinklingStarView(star: star)
                        .position(x: star.x * geo.size.width, y: star.y * geo.size.height)
                }
            }
            .onAppear {
                if stars.isEmpty {
                    stars = (0..<45).map { _ in
                        Star(
                            x: CGFloat.random(in: 0...1),
                            y: CGFloat.random(in: 0...1),
                            size: CGFloat.random(in: 1.2...3.5),
                            animationDuration: Double.random(in: 1.5...4.0),
                            delay: Double.random(in: 0.0...3.0)
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - INDIVIDUAL TWINKLING STAR VIEW
struct TwinklingStarView: View {
    let star: TwinklingStarfield.Star
    @State private var isFlashed: Bool = false
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: star.size, height: star.size)
            .shadow(color: .cyan.opacity(0.7), radius: star.size * 1.5)
            .opacity(isFlashed ? 0.9 : 0.15)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: star.animationDuration)
                    .repeatForever(autoreverses: true)
                    .delay(star.delay)
                ) {
                    isFlashed.toggle()
                }
            }
    }
}

struct NeuralMetricRowView: View {
    var title: String
    var value: String
    var color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
    }
}
