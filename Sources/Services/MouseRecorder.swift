import Foundation
import AppKit
import CoreGraphics

@MainActor
public final class MouseRecorder: ObservableObject {
    public static let shared = MouseRecorder()
    
    @Published public private(set) var isRecording: Bool = false
    @Published public private(set) var recordedEvents: [MacroEvent] = []
    @Published public private(set) var recordingDuration: Double = 0.0
    
    public var recordMovements: Bool = false
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var durationTimer: Timer?
    private var lastEventTime: Date?
    private var startTime: Date?
    
    public init() {}
    
    public func startRecording(clearExisting: Bool = true) {
        guard !isRecording else { return }
        
        if clearExisting {
            recordedEvents.removeAll()
        }
        
        isRecording = true
        startTime = Date()
        lastEventTime = Date()
        recordingDuration = 0.0
        
        SoundManager.shared.play(.recordStart)
        
        // Timer for duration updates
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let start = self.startTime else { return }
                self.recordingDuration = Date().timeIntervalSince(start)
            }
        }
        
        var mask: NSEvent.EventTypeMask = [
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown,
            .scrollWheel
        ]
        
        if recordMovements {
            mask.insert(.mouseMoved)
            mask.insert(.leftMouseDragged)
        }
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            Task { @MainActor in
                self?.handleIncomingEvent(event)
            }
        }
    }
    
    public func stopRecording() -> [MacroEvent] {
        guard isRecording else { return recordedEvents }
        
        isRecording = false
        durationTimer?.invalidate()
        durationTimer = nil
        
        if let gm = globalMonitor {
            NSEvent.removeMonitor(gm)
            globalMonitor = nil
        }
        if let lm = localMonitor {
            NSEvent.removeMonitor(lm)
            localMonitor = nil
        }
        
        SoundManager.shared.play(.recordStop)
        return recordedEvents
    }
    
    private func handleIncomingEvent(_ event: NSEvent) {
        guard isRecording else { return }
        
        let now = Date()
        let delay = lastEventTime != nil ? now.timeIntervalSince(lastEventTime!) : 0.0
        lastEventTime = now
        
        // Exact CG coordinates
        let cgLocation = CGEvent(source: nil)?.location ?? CGPoint(x: event.locationInWindow.x, y: event.locationInWindow.y)
        
        let actionType: MacroActionType
        switch event.type {
        case .leftMouseDown:
            if event.clickCount >= 2 {
                actionType = .doubleClick
            } else {
                actionType = .leftClick
            }
        case .rightMouseDown:
            actionType = .rightClick
        case .otherMouseDown:
            actionType = .middleClick
        case .scrollWheel:
            let dy = Int(event.deltaY)
            if abs(dy) < 1 { return }
            actionType = .scroll(deltaY: dy)
        case .mouseMoved, .leftMouseDragged:
            // Throttle rapid movements to avoid massive event lists
            if let last = recordedEvents.last, last.action == .mouseMove, delay < 0.03 {
                return
            }
            actionType = .mouseMove
        default:
            return
        }
        
        let newEvent = MacroEvent(
            action: actionType,
            x: Double(cgLocation.x),
            y: Double(cgLocation.y),
            delayBefore: delay
        )
        
        recordedEvents.append(newEvent)
    }
    
    public func clear() {
        recordedEvents.removeAll()
        recordingDuration = 0.0
    }
    
    public func removeEvent(at index: Int) {
        guard index >= 0 && index < recordedEvents.count else { return }
        recordedEvents.remove(at: index)
    }
    
    public func insertEvent(_ event: MacroEvent, at index: Int) {
        if index >= recordedEvents.count {
            recordedEvents.append(event)
        } else {
            recordedEvents.insert(event, at: max(0, index))
        }
    }
}
