import Foundation
import SwiftUI
import AppKit
import CoreGraphics

public enum AppTab: String, CaseIterable, Identifiable {
    case autoClicker = "Oto Tıklayıcı"
    case recorder = "Makro Kaydedici"
    case inspector = "Koordinat & Hedef"
    case settings = "Ayarlar"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .autoClicker: return "bolt.horizontal.fill"
        case .recorder: return "record.circle"
        case .inspector: return "scope"
        case .settings: return "gearshape.fill"
        }
    }
}

@MainActor
public final class AppViewModel: ObservableObject {
    public static let shared = AppViewModel()
    
    // Services
    public let accessibility = AccessibilityManager.shared
    public let recorder = MouseRecorder.shared
    public let player = MacroPlayer.shared
    public let clicker = AutoClicker.shared
    public let hotkeys = HotKeyManager.shared
    public let sound = SoundManager.shared
    
    // Navigation
    @Published public var activeTab: AppTab = .autoClicker
    
    // Auto Clicker State
    @Published public var autoClickerConfig = AutoClickerConfig()
    
    // Macro State
    @Published public var currentSequence = MacroSequence(name: "Yeni Makro")
    @Published public var savedSequences: [MacroSequence] = []
    @Published public var selectedSavedMacroId: UUID?
    
    // Live Coordinate Tracking
    @Published public var currentMouseX: Double = 0.0
    @Published public var currentMouseY: Double = 0.0
    @Published public var lastCapturedCoord: CGPoint? = nil
    
    // App Settings
    @Published public var soundEnabled: Bool = true {
        didSet { sound.soundEnabled = soundEnabled }
    }
    @Published public var failSafeCornerEnabled: Bool = true {
        didSet {
            player.failSafeCornersEnabled = failSafeCornerEnabled
            clicker.failSafeCornersEnabled = failSafeCornerEnabled
        }
    }
    @Published public var recordMovementsEnabled: Bool = false {
        didSet { recorder.recordMovements = recordMovementsEnabled }
    }
    @Published public var showFloatingHUD: Bool = true
    
    // Alert / Toast
    @Published public var toastMessage: String? = nil
    
    private var mouseTrackerTimer: Timer?
    
    public init() {
        loadPersistedData()
        setupHotKeyBindings()
        
        // Populate sample macros if empty
        if savedSequences.isEmpty {
            createDefaultSampleMacros()
        }
    }
    
    // MARK: - Status
    public var appStatus: AppStatus {
        if recorder.isRecording {
            return .recording(eventCount: recorder.recordedEvents.count, duration: recorder.recordingDuration)
        } else if player.isPlaying {
            return .playingMacro(
                macroName: currentSequence.name,
                currentLoop: player.currentLoop,
                totalLoops: player.totalLoops,
                eventIndex: player.currentEventIndex,
                totalEvents: player.totalEvents
            )
        } else if clicker.isRunning {
            return .autoClicking(
                clicksDone: clicker.clicksDone,
                targetClicks: autoClickerConfig.isInfinite ? nil : autoClickerConfig.targetClickCount
            )
        } else {
            return .idle
        }
    }
    
    // MARK: - Actions: Auto Clicker
    public func toggleAutoClicker() {
        if clicker.isRunning {
            clicker.stop()
            showToast("Oto Tıklayıcı durduruldu")
        } else {
            guard accessibility.isGranted else {
                accessibility.requestPermission()
                showToast("Erişilebilirlik izni gerekli!")
                return
            }
            clicker.start(config: autoClickerConfig) { [weak self] in
                self?.showToast("Oto Tıklayıcı tamamlandı")
            }
            showToast("Oto Tıklayıcı başlatıldı (Durdurmak için ⌥C veya ESC)")
        }
    }
    
    // MARK: - Actions: Macro Recorder
    public func toggleRecording() {
        if recorder.isRecording {
            let events = recorder.stopRecording()
            currentSequence.events = events
            showToast("Kayıt tamamlandı: \(events.count) adım")
        } else {
            guard accessibility.isGranted else {
                accessibility.requestPermission()
                showToast("Erişilebilirlik izni gerekli!")
                return
            }
            recorder.startRecording()
            showToast("Makro kaydı başladı (Bitirmek için ⌥R)")
        }
    }
    
    // MARK: - Actions: Macro Player
    public func togglePlayback() {
        if player.isPlaying {
            player.stop()
            showToast("Makro oynatımı durduruldu")
        } else {
            guard accessibility.isGranted else {
                accessibility.requestPermission()
                showToast("Erişilebilirlik izni gerekli!")
                return
            }
            guard !currentSequence.events.isEmpty else {
                showToast("Oynatılacak makro adımı yok!")
                return
            }
            player.play(sequence: currentSequence) { [weak self] in
                self?.showToast("Makro oynatımı tamamlandı")
            }
            showToast("Makro başlatıldı (Durdurmak için ⌥P veya ESC)")
        }
    }
    
    // MARK: - Emergency Stop
    public func emergencyStop() {
        if recorder.isRecording {
            _ = recorder.stopRecording()
        }
        if player.isPlaying {
            player.stop()
        }
        if clicker.isRunning {
            clicker.stop()
        }
        showToast("Tüm eylemler durduruldu")
    }
    
    // MARK: - Macro Management
    public func saveCurrentSequence(name: String? = nil) {
        if let name = name, !name.isEmpty {
            currentSequence.name = name
        }
        
        if let idx = savedSequences.firstIndex(where: { $0.id == currentSequence.id }) {
            savedSequences[idx] = currentSequence
        } else {
            savedSequences.append(currentSequence)
        }
        persistSequences()
        showToast("'\(currentSequence.name)' kaydedildi")
    }
    
    public func loadSequence(_ seq: MacroSequence) {
        currentSequence = seq
        selectedSavedMacroId = seq.id
        showToast("'\(seq.name)' yüklendi")
    }
    
    public func deleteSequence(_ seq: MacroSequence) {
        savedSequences.removeAll { $0.id == seq.id }
        if currentSequence.id == seq.id {
            currentSequence = MacroSequence(name: "Yeni Makro")
        }
        persistSequences()
        showToast("Makro silindi")
    }
    
    public func clearCurrentMacro() {
        currentSequence = MacroSequence(name: "Yeni Makro")
        recorder.clear()
        showToast("Makro temizlendi")
    }
    
    public func addManualClick(action: MacroActionType, delay: Double = 0.5) {
        let pt = CGEvent(source: nil)?.location ?? CGPoint(x: 500, y: 500)
        let event = MacroEvent(
            action: action,
            x: Double(pt.x),
            y: Double(pt.y),
            delayBefore: delay
        )
        currentSequence.events.append(event)
        showToast("Yeni adım eklendi")
    }
    
    public func removeEvent(at index: Int) {
        guard index >= 0 && index < currentSequence.events.count else { return }
        currentSequence.events.remove(at: index)
    }
    
    // MARK: - Inspector Actions
    public func captureCurrentCoordinate() {
        let pt = CGEvent(source: nil)?.location ?? .zero
        lastCapturedCoord = pt
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(String(format: "%.0f, %.0f", pt.x, pt.y), forType: .string)
        showToast("Koordinat kopyalandı: \(Int(pt.x)), \(Int(pt.y))")
    }
    
    public func setFixedTargetToCurrentMouse() {
        let pt = CGEvent(source: nil)?.location ?? .zero
        autoClickerConfig.fixedX = Double(pt.x)
        autoClickerConfig.fixedY = Double(pt.y)
        autoClickerConfig.useFixedPosition = true
        showToast("Oto Tıklayıcı hedefi: (\(Int(pt.x)), \(Int(pt.y)))")
    }
    
    // MARK: - Toast helper
    public func showToast(_ msg: String) {
        toastMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            if self?.toastMessage == msg {
                self?.toastMessage = nil
            }
        }
    }
    
    // MARK: - Private Setup
    private func setupHotKeyBindings() {
        hotkeys.onToggleRecord = { [weak self] in
            self?.toggleRecording()
        }
        hotkeys.onTogglePlay = { [weak self] in
            self?.togglePlayback()
        }
        hotkeys.onToggleClicker = { [weak self] in
            self?.toggleAutoClicker()
        }
        hotkeys.onEmergencyStop = { [weak self] in
            self?.emergencyStop()
        }
        hotkeys.onCaptureCoordinate = { [weak self] in
            self?.captureCurrentCoordinate()
        }
    }
    
    public func startMouseTracking() {
        guard mouseTrackerTimer == nil else { return }
        mouseTrackerTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let pos = CGEvent(source: nil)?.location else { return }
            let roundedX = round(pos.x)
            let roundedY = round(pos.y)
            Task { @MainActor in
                guard let self = self else { return }
                if self.currentMouseX != roundedX || self.currentMouseY != roundedY {
                    self.currentMouseX = roundedX
                    self.currentMouseY = roundedY
                }
            }
        }
    }
    
    public func stopMouseTracking() {
        mouseTrackerTimer?.invalidate()
        mouseTrackerTimer = nil
    }
    
    private func createDefaultSampleMacros() {
        let sample1 = MacroSequence(
            name: "Hızlı Çift Tık & Bekle",
            events: [
                MacroEvent(action: .leftClick, x: 500, y: 500, delayBefore: 0.1),
                MacroEvent(action: .leftClick, x: 500, y: 500, delayBefore: 0.05),
                MacroEvent(action: .scroll(deltaY: -3), x: 500, y: 500, delayBefore: 0.5)
            ],
            repeatCount: 5,
            speedMultiplier: 1.0,
            loopDelay: 1.0
        )
        
        let sample2 = MacroSequence(
            name: "Üç Nokta Gezinme",
            events: [
                MacroEvent(action: .leftClick, x: 300, y: 400, delayBefore: 0.2),
                MacroEvent(action: .leftClick, x: 600, y: 400, delayBefore: 0.4),
                MacroEvent(action: .leftClick, x: 900, y: 400, delayBefore: 0.4)
            ],
            repeatCount: 1,
            speedMultiplier: 1.5,
            loopDelay: 0.5
        )
        
        savedSequences = [sample1, sample2]
        persistSequences()
    }
    
    private var storageUrl: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Loopin", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("macros.json")
    }
    
    private func persistSequences() {
        do {
            let data = try JSONEncoder().encode(savedSequences)
            try data.write(to: storageUrl)
        } catch {
            print("Failed to persist macros: \(error)")
        }
    }
    
    private func loadPersistedData() {
        do {
            if FileManager.default.fileExists(atPath: storageUrl.path) {
                let data = try Data(contentsOf: storageUrl)
                savedSequences = try JSONDecoder().decode([MacroSequence].self, from: data)
            }
        } catch {
            print("Failed to load macros: \(error)")
        }
    }
}
