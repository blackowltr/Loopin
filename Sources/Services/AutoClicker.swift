import Foundation
import AppKit
import CoreGraphics

@MainActor
public final class AutoClicker: ObservableObject {
    public static let shared = AutoClicker()
    
    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var clicksDone: Int = 0
    @Published public private(set) var currentCPS: Double = 0.0
    
    public var failSafeCornersEnabled: Bool = true
    
    private var clickTask: Task<Void, Never>?
    
    public init() {}
    
    public func start(config: AutoClickerConfig, onFinish: (() -> Void)? = nil) {
        guard !isRunning else { return }
        
        isRunning = true
        clicksDone = 0
        currentCPS = 0.0
        
        SoundManager.shared.play(.playStart)
        
        // Cache screen bounds once before loop to prevent WindowServer IPC stalls
        let screenBounds = NSScreen.main?.frame.size ?? CGSize(width: 1920, height: 1080)
        let screenW = screenBounds.width
        let screenH = screenBounds.height
        let threshold: CGFloat = 8.0
        let failSafeActive = failSafeCornersEnabled
        
        clickTask = Task.detached(priority: .high) { [weak self] in
            guard let self = self else { return }
            
            let source = CGEventSource(stateID: .hidSystemState)
            let baseIntervalSecs = Double(max(1, config.intervalMs)) / 1000.0
            
            var localClicks = 0
            var clicksInPeriod = 0
            var lastUIUpdateTime = Date()
            var lastCPSUpdateTime = Date()
            var lastFailSafeCheckTime = Date.distantPast
            
            let fixedPt = CGPoint(x: config.fixedX, y: config.fixedY)
            let useFixed = config.useFixedPosition
            let jitterEnabled = config.jitterEnabled
            let jitterPx = config.jitterPx
            let jitterMs = config.jitterMs
            
            while !Task.isCancelled {
                let now = Date()
                var currentMousePos: CGPoint? = nil
                
                // Throttled fail-safe check: every 50ms instead of every single click at 100 CPS
                // Saves ~90% of redundant WindowServer CGEvent allocations
                if failSafeActive && now.timeIntervalSince(lastFailSafeCheckTime) >= 0.05 {
                    lastFailSafeCheckTime = now
                    currentMousePos = CGEvent(source: nil)?.location
                    if let mousePos = currentMousePos {
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
                
                // Determine target point (Reuses currentMousePos if already fetched, or fixedPt)
                var targetPt: CGPoint
                if useFixed {
                    targetPt = fixedPt
                } else {
                    targetPt = currentMousePos ?? CGEvent(source: nil)?.location ?? .zero
                }
                
                // Apply jitter if enabled
                if jitterEnabled && jitterPx > 0 {
                    let jx = CGFloat.random(in: -CGFloat(jitterPx)...CGFloat(jitterPx))
                    let jy = CGFloat.random(in: -CGFloat(jitterPx)...CGFloat(jitterPx))
                    targetPt.x += jx
                    targetPt.y += jy
                }
                
                // Execute click (High performance, low latency)
                Self.performClick(at: targetPt, button: config.button, clickType: config.clickType, source: source)
                
                localClicks += 1
                clicksInPeriod += 1
                
                // Check target count locally (Never awaits MainActor)
                if !config.isInfinite && localClicks >= config.targetClickCount {
                    break
                }
                
                // Throttled UI state sync: update every 100ms (10 FPS) asynchronously
                if now.timeIntervalSince(lastUIUpdateTime) >= 0.1 {
                    let currentCount = localClicks
                    let cpsDelta = now.timeIntervalSince(lastCPSUpdateTime)
                    let calculatedCPS: Double?
                    if cpsDelta >= 0.4 {
                        calculatedCPS = Double(clicksInPeriod) / cpsDelta
                        clicksInPeriod = 0
                        lastCPSUpdateTime = now
                    } else {
                        calculatedCPS = nil
                    }
                    lastUIUpdateTime = now
                    
                    Task { @MainActor [weak self] in
                        guard let self = self, self.isRunning else { return }
                        self.clicksDone = currentCount
                        if let cps = calculatedCPS {
                            self.currentCPS = cps
                        }
                    }
                }
                
                // Calculate next interval with jitter
                var sleepSecs = baseIntervalSecs
                if jitterEnabled && jitterMs > 0 {
                    let jitterDelta = Double.random(in: -Double(jitterMs)...Double(jitterMs)) / 1000.0
                    sleepSecs = max(0.001, sleepSecs + jitterDelta)
                }
                
                // High precision sleep
                let nanos = UInt64(max(0.0005, sleepSecs) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
            }
            
            // Final completion sync
            let finalCount = localClicks
            await MainActor.run {
                if self.isRunning {
                    self.clicksDone = finalCount
                    self.currentCPS = 0.0
                    self.isRunning = false
                    SoundManager.shared.play(.playFinish)
                    onFinish?()
                }
            }
        }
    }
    
    public func stop() {
        guard isRunning else { return }
        clickTask?.cancel()
        clickTask = nil
        isRunning = false
        currentCPS = 0.0
        SoundManager.shared.play(.playFinish)
    }
    
    nonisolated private static func performClick(at point: CGPoint, button: MouseButton, clickType: ClickType, source: CGEventSource?) {
        let downType: CGEventType
        let upType: CGEventType
        let cgButton: CGMouseButton
        
        switch button {
        case .left:
            downType = .leftMouseDown
            upType = .leftMouseUp
            cgButton = .left
        case .right:
            downType = .rightMouseDown
            upType = .rightMouseUp
            cgButton = .right
        case .middle:
            downType = .otherMouseDown
            upType = .otherMouseUp
            cgButton = .center
        }
        
        if clickType == .hold {
            let down = CGEvent(mouseEventSource: source, mouseType: downType, mouseCursorPosition: point, mouseButton: cgButton)
            down?.post(tap: .cghidEventTap)
            return
        }
        
        let clicks = clickType.clickCount
        for i in 1...clicks {
            if let down = CGEvent(mouseEventSource: source, mouseType: downType, mouseCursorPosition: point, mouseButton: cgButton) {
                down.setIntegerValueField(.mouseEventClickState, value: Int64(i))
                down.post(tap: .cghidEventTap)
            }
            
            // Micro hold time for HID recognition without freezing
            usleep(2_000)
            
            if let up = CGEvent(mouseEventSource: source, mouseType: upType, mouseCursorPosition: point, mouseButton: cgButton) {
                up.setIntegerValueField(.mouseEventClickState, value: Int64(i))
                up.post(tap: .cghidEventTap)
            }
            
            if i < clicks {
                usleep(4_000)
            }
        }
    }
}
