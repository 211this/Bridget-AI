import SwiftUI

public struct SovereignSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Track selected provider
    @AppStorage("selectedModelProvider") private var selectedProvider: String = "Apple Intelligence"
    
    // Separate secure storage keys per provider so data persists when switching
    @AppStorage("geminiAPIKey") private var geminiAPIKey: String = ""
    @AppStorage("openAIAPIKey") private var openAIAPIKey: String = ""
    
    let providers = ["Apple Intelligence", "Gemini", "OpenAI"]

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    // Provider Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI MODEL PROVIDER")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.purple)
                        
                        Picker("Provider", selection: $selectedProvider) {
                            ForEach(providers, id: \.self) { provider in
                                Text(provider).tag(provider)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Dynamic API Key Input based on active selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SECURE API KEY VAULT — \(selectedProvider.uppercased())")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                        
                        if selectedProvider == "Apple Intelligence" {
                            Text("Apple Intelligence runs locally on-device. No API key required.")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.gray)
                                .padding(.vertical, 8)
                        } else {
                            SecureField("Enter \(selectedProvider) API Key...", text: selectedProvider == "Gemini" ? $geminiAPIKey : $openAIAPIKey)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .font(.system(size: 13, design: .monospaced))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cyan.opacity(0.4), lineWidth: 1))
                        }
                        
                        Text("Stored locally in your device's sandbox. Zero cloud telemetry or middleman overhead.")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Sovereign Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
    }
}
