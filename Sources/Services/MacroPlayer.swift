import Foundation
import AppKit
import CoreGraphics

@MainActor
public final class MacroPlayer: ObservableObject {
    public static let shared = MacroPlayer()
    
    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var currentLoop: Int = 0
    @Published public private(set) var totalLoops: Int = 0
    @Published public private(set) var currentEventIndex: Int = 0
    @Published public private(set) var totalEvents: Int = 0
    
    public var failSafeCornersEnabled: Bool = true
    
    private var playbackTask: Task<Void, Never>?
    
    public init() {}
    
    public func play(sequence: MacroSequence, onFinish: (() -> Void)? = nil) {
        guard !isPlaying else { return }
        guard !sequence.events.isEmpty else { return }
        
        isPlaying = true
        currentLoop = 0
        totalLoops = sequence.repeatCount
        currentEventIndex = 0
        totalEvents = sequence.events.count
        
        SoundManager.shared.play(.playStart)
        
        // Pre-cache screen bounds to eliminate WindowServer IPC calls inside playback
        let screenBounds = NSScreen.main?.frame.size ?? CGSize(width: 1920, height: 1080)
        let screenW = screenBounds.width
        let screenH = screenBounds.height
        let threshold: CGFloat = 8.0
        let failSafeActive = failSafeCornersEnabled
        
        playbackTask = Task.detached(priority: .high) { [weak self] in
            guard let self = self else { return }
            
            let repeatCount = sequence.repeatCount // 0 is infinite
            let speed = max(0.1, sequence.speedMultiplier)
            let events = sequence.events
            let loopDelay = max(0.01, sequence.loopDelay)
            
            var loop = 1
            var lastFailSafeTime = Date.distantPast
            var lastProgressTime = Date.distantPast
            
            while !Task.isCancelled {
                if repeatCount > 0 && loop > repeatCount {
                    break
                }
                
                let currentL = loop
                Task { @MainActor [weak self] in
                    self?.currentLoop = currentL
                }
                
                for (idx, event) in events.enumerated() {
                    if Task.isCancelled { break }
                    
                    let now = Date()
                    // Throttled fail-safe check: maximum every 50ms (Zero redundant IPC)
                    if failSafeActive && now.timeIntervalSince(lastFailSafeTime) >= 0.05 {
                        lastFailSafeTime = now
                        if let mousePos = CGEvent(source: nil)?.location {
                            let isTopLeft = mousePos.x <= threshold && mousePos.y <= threshold
                            let isTopRight = mousePos.x >= screenW - threshold && mousePos.y <= threshold
                            let isBottomLeft = mousePos.x <= threshold && mousePos.y >= screenH - threshold
                            let isBottomRight = mousePos.x >= screenW - threshold && mousePos.y >= screenH - threshold
                            
                            if isTopLeft || isTopRight || isBottomLeft || isBottomRight {
                                await MainActor.run {
                                    SoundManager.shared.play(.emergencyStop)
                                    self.stop()
                                }
                                return
                            }
                        }
                    }
                    
                    // Delay before event scaled by speed
                    let sleepSecs = event.delayBefore / speed
                    if sleepSecs > 0.001 {
                        let nanos = UInt64(sleepSecs * 1_000_000_000)
                        try? await Task.sleep(nanoseconds: nanos)
                    }
                    
                    if Task.isCancelled { break }
                    
                    // Dispatch CGEvent
                    Self.executeEvent(event)
                    
                    // Throttled UI progress update: maximum 20 FPS (every 50ms) or on final event
                    // Eliminates task flooding on high event counts or high-speed replays
                    if now.timeIntervalSince(lastProgressTime) >= 0.05 || idx == events.count - 1 {
                        lastProgressTime = now
                        let currentIdx = idx + 1
                        Task { @MainActor [weak self] in
                            self?.currentEventIndex = currentIdx
                        }
                    }
                }
                
                if Task.isCancelled { break }
                
                loop += 1
                
                // Pause between loops if continuing
                if repeatCount == 0 || loop <= repeatCount {
                    let loopNanos = UInt64(loopDelay * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: loopNanos)
                }
            }
            
            await MainActor.run {
                if self.isPlaying {
                    self.isPlaying = false
                    SoundManager.shared.play(.playFinish)
                    onFinish?()
                }
            }
        }
    }
    
    public func stop() {
        guard isPlaying else { return }
        playbackTask?.cancel()
        playbackTask = nil
        isPlaying = false
        currentLoop = 0
        currentEventIndex = 0
        SoundManager.shared.play(.playFinish)
    }
    
    nonisolated private static func executeEvent(_ event: MacroEvent) {
        let source = CGEventSource(stateID: .hidSystemState)
        let pt = event.point
        
        switch event.action {
        case .leftClick:
            synthesizeClick(at: pt, button: .left, clickCount: 1, source: source)
        case .rightClick:
            synthesizeClick(at: pt, button: .right, clickCount: 1, source: source)
        case .doubleClick:
            synthesizeClick(at: pt, button: .left, clickCount: 2, source: source)
        case .middleClick:
            synthesizeClick(at: pt, button: .center, clickCount: 1, source: source)
        case .mouseMove:
            let move = CGEvent(mouseEventSource: source, mouseType: .mouseMoved, mouseCursorPosition: pt, mouseButton: .left)
            move?.post(tap: .cghidEventTap)
        case .scroll(let deltaY):
            let scroll = CGEvent(scrollWheelEvent2Source: source, units: .pixel, wheelCount: 1, wheel1: Int32(deltaY * 5), wheel2: 0, wheel3: 0)
            scroll?.post(tap: .cghidEventTap)
        }
    }
    
    nonisolated private static func synthesizeClick(at point: CGPoint, button: CGMouseButton, clickCount: Int, source: CGEventSource?) {
        let downType: CGEventType
        let upType: CGEventType
        
        switch button {
        case .left:
            downType = .leftMouseDown
            upType = .leftMouseUp
        case .right:
            downType = .rightMouseDown
            upType = .rightMouseUp
        case .center:
            downType = .otherMouseDown
            upType = .otherMouseUp
        @unknown default:
            downType = .leftMouseDown
            upType = .leftMouseUp
        }
        
        for i in 1...clickCount {
            if let down = CGEvent(mouseEventSource: source, mouseType: downType, mouseCursorPosition: point, mouseButton: button) {
                down.setIntegerValueField(.mouseEventClickState, value: Int64(i))
                down.post(tap: .cghidEventTap)
            }
            
            usleep(2_000)
            
            if let up = CGEvent(mouseEventSource: source, mouseType: upType, mouseCursorPosition: point, mouseButton: button) {
                up.setIntegerValueField(.mouseEventClickState, value: Int64(i))
                up.post(tap: .cghidEventTap)
            }
            
            if i < clickCount {
                usleep(4_000)
            }
        }
    }
}
