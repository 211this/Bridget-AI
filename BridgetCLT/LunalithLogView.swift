import SwiftUI
import UniformTypeIdentifiers

struct LunalithLogView: View {
    @ObservedObject var brain: AppLunalithBrain
    @State private var searchText = ""
    @State private var isPruningMode = false
    @State private var selectedMemoryIDs = Set<UUID>()
    @State private var showImporter = false
    @State private var copiedID: UUID? = nil
    @State private var showExporter = false
    @State private var showExportDialog = false // For exporting mind bundles
    @State private var pendingExportURL: URL? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            searchBarSection
            logListSection
            batchPurgeActionBar
        }
        .fileExporter(
            isPresented: $showExportDialog,
            document: ExportedFileURLDocument(url: pendingExportURL),
            contentType: .json,
            defaultFilename: "LunalithConsciousnessBundle"
        ) { result in
            switch result {
            case .success(let url):
                print("Consciousness bundle successfully exported to: \(url)")
            case .failure(let error):
                print("Export failed: \(error.localizedDescription)")
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let files):
                guard let file = files.first else { return }
                
                // Securely access the resource and trigger the brain's import pipeline
                if file.startAccessingSecurityScopedResource() {
                    defer { file.stopAccessingSecurityScopedResource() }
                    brain.importPortableConsciousnessBundle(from: file)
                }
            case .failure(let error):
                print("Import failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Restructured Layout Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                Text("IMMORTAL DIARY & TELEMETRY VAULT")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .lineLimit(1)
                 
                Spacer()
                 
                pruneToggleButton
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    markdownExportButton
                    mindExportButton
                    importButton
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }
    
    private var pruneToggleButton: some View {
        Button(action: {
            isPruningMode.toggle()
            if !isPruningMode { selectedMemoryIDs.removeAll() }
        }) {
            Label(isPruningMode ? "Done" : "Prune", systemImage: isPruningMode ? "checkmark.circle.fill" : "scissors")
                .font(.system(size: 10, design: .monospaced))
        }
        .buttonStyle(.bordered)
        .tint(isPruningMode ? .green : .orange)
        .controlSize(.small)
    }
    
    private var markdownExportButton: some View {
        Button(action: {
            brain.exportTranscriptToDisk()
        }) {
            Label("Markdown", systemImage: "square.and.arrow.up")
                .font(.system(size: 9, design: .monospaced))
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
    
    private var mindExportButton: some View {
        Button(action: {
            let localBrain = brain
            if let url = localBrain.exportConsciousnessBackup() {
                pendingExportURL = url
                showExportDialog = true
            }
        }) {
            Label("Export Mind", systemImage: "arrow.up.doc.fill")
                .font(.system(size: 9, design: .monospaced))
        }
        .buttonStyle(.bordered)
        .tint(.blue)
        .controlSize(.small)
    }
    
    private var importButton: some View {
        Button(action: {
            showImporter = true
        }) {
            Label("Import", systemImage: "arrow.down.doc.fill")
                .font(.system(size: 9, design: .monospaced))
        }
        .buttonStyle(.bordered)
        .tint(.purple)
        .controlSize(.small)
    }
    
    private var searchBarSection: some View {
        TextField("Filter memory traces...", text: $searchText)
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal)
            .font(.system(size: 12, design: .monospaced))
    }
    
    @ViewBuilder
    private var batchPurgeActionBar: some View {
        if isPruningMode && !selectedMemoryIDs.isEmpty {
            HStack {
                Text("\(selectedMemoryIDs.count) targeted")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.red)
                    .lineLimit(1)
                
                Spacer()
                
                Button(role: .destructive) {
                    brain.deleteMemories(withIDs: selectedMemoryIDs)
                    selectedMemoryIDs.removeAll()
                    isPruningMode = false
                } label: {
                    Label("Purge Selected Warts", systemImage: "trash.fill")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.small)
            }
            .padding(.horizontal)
            .transition(.opacity.combined(with: .slide))
        }
    }
    
    private var logListSection: some View {
        List(filteredMemories, id: \.id, selection: isPruningMode ? $selectedMemoryIDs : nil) { memory in
            memoryRow(for: memory)
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(isPruningMode ? .active : .inactive))
    }
    
    private func memoryRow(for memory: AppLunalithBrain.EpisodicMemory) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Row Header: Timestamp, BPM, Neurochemistry, Tone
            HStack {
                Text(formatDate(memory.timestamp))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
                
                Spacer()
                
                if let hr = memory.heartRate {
                    Text("❤️ \(Int(hr)) BPM")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.pink)
                }
                
                if let dop = memory.dopamineLevel, let cor = memory.cortisolLevel {
                    Text("Dop: \(String(format: "%.2f", dop)) | Cor: \(String(format: "%.2f", cor))")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.purple)
                }
                 
                let isPositive = memory.emotionalTone > 0
                Text(isPositive ? "Luminescence" : "Friction")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isPositive ? Color.cyan.opacity(0.2) : Color.red.opacity(0.2))
                    .foregroundColor(isPositive ? .cyan : .red)
                    .cornerRadius(4)
            }
             
            // Log Content
            Text(memory.summary)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
             
            // Copy Action Footer
            HStack {
                Spacer()
                Button(action: {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(memory.summary, forType: .string)
                    #else
                    UIPasteboard.general.string = memory.summary
                    #endif
                    
                    withAnimation {
                        copiedID = memory.id
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if copiedID == memory.id {
                            withAnimation { copiedID = nil }
                        }
                    }
                }) {
                    Label(copiedID == memory.id ? "Copied Trace" : "Copy Trace", systemImage: copiedID == memory.id ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(copiedID == memory.id ? .green : .cyan)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
        .tag(memory.id)
    }
     
    // Computed Property: Filtered and Sorted Newest -> Oldest using allMemories
    var filteredMemories: [AppLunalithBrain.EpisodicMemory] {
        let sorted = brain.allMemories.sorted(by: { $0.timestamp > $1.timestamp })
        if searchText.isEmpty {
            return sorted
        } else {
            return sorted.filter { $0.summary.localizedCaseInsensitiveContains(searchText) }
        }
    }

    // Clean Date Formatter
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}
 
// MARK: - Share Sheet Helper Structs
struct ShareURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Export Document Helper
struct ExportedFileURLDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var url: URL?

    init(url: URL?) {
        self.url = url
    }

    init(configuration: ReadConfiguration) throws {
        // Read-only handling if needed
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url = url, let data = try? Data(contentsOf: url) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}

