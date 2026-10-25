import Foundation
import AppKit
import ApplicationServices

@MainActor
public final class AccessibilityManager: ObservableObject {
    public static let shared = AccessibilityManager()
    
    @Published public private(set) var isGranted: Bool = false
    private var checkTimer: Timer?
    
    public init() {
        checkStatus()
        startPeriodicCheck()
    }
    
    deinit {
        checkTimer?.invalidate()
    }
    
    public func checkStatus() {
        let trusted = AXIsProcessTrusted()
        if isGranted != trusted {
            isGranted = trusted
        }
        if trusted && checkTimer != nil {
            checkTimer?.invalidate()
            checkTimer = nil
        }
    }
    
    public func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        checkStatus()
    }
    
    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func startPeriodicCheck() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkStatus()
            }
        }
    }
}
