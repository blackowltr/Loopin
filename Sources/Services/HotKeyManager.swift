import Foundation
import AppKit

@MainActor
public final class HotKeyManager: ObservableObject {
    public static let shared = HotKeyManager()
    
    public var onToggleRecord: (() -> Void)?
    public var onTogglePlay: (() -> Void)?
    public var onToggleClicker: (() -> Void)?
    public var onEmergencyStop: (() -> Void)?
    public var onCaptureCoordinate: (() -> Void)?
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    public init() {
        setupMonitors()
    }
    
    deinit {
        if let gm = globalMonitor {
            NSEvent.removeMonitor(gm)
        }
        if let lm = localMonitor {
            NSEvent.removeMonitor(lm)
        }
    }
    
    public func setupMonitors() {
        stopMonitors()
        
        // Global monitor: Fast synchronous pre-filter before creating any async Task
        // Prevents generating thousands of unnecessary Tasks when the user is typing in other apps
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            let isEsc = event.keyCode == 53
            let hasOption = event.modifierFlags.contains(.option)
            if isEsc || hasOption {
                Task { @MainActor in
                    self?.handleKeyEvent(event)
                }
            }
        }
        
        // Local monitor: Fast synchronous pre-filter for local key events
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            let isEsc = event.keyCode == 53
            let hasOption = event.modifierFlags.contains(.option)
            if isEsc || hasOption {
                Task { @MainActor in
                    self?.handleKeyEvent(event)
                }
            }
            return event
        }
    }
    
    public func stopMonitors() {
        if let gm = globalMonitor {
            NSEvent.removeMonitor(gm)
            globalMonitor = nil
        }
        if let lm = localMonitor {
            NSEvent.removeMonitor(lm)
            localMonitor = nil
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        // ESC key (keyCode 53)
        if event.keyCode == 53 {
            onEmergencyStop?()
            return
        }
        
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let isOption = flags.contains(.option)
        
        guard isOption else { return }
        guard let chars = event.charactersIgnoringModifiers?.lowercased() else { return }
        
        switch chars {
        case "r":
            onToggleRecord?()
        case "p":
            onTogglePlay?()
        case "c":
            onToggleClicker?()
        case "x":
            onCaptureCoordinate?()
        default:
            break
        }
    }
}
