import Foundation
import AppKit
import ApplicationServices

@MainActor
public final class AccessibilityManager: ObservableObject {
    public static let shared = AccessibilityManager()
    
    @Published public private(set) var isGranted: Bool = false
    @Published public var hasPromptedOnce: Bool = false
    
    private var checkTimer: Timer?
    private let promptedKey = "com.blackowl.loopin.hasPromptedAccessibility"
    
    public init() {
        self.hasPromptedOnce = UserDefaults.standard.bool(forKey: promptedKey)
        checkStatus()
        startPeriodicCheck()
    }
    
    deinit {
        checkTimer?.invalidate()
    }
    
    @discardableResult
    public func checkStatus() -> Bool {
        let trusted = AXIsProcessTrusted()
        if isGranted != trusted {
            isGranted = trusted
            if trusted {
                // If just granted, sound a pleasant feedback and mark prompted
                SoundManager.shared.play(.playFinish)
                hasPromptedOnce = true
                UserDefaults.standard.set(true, forKey: promptedKey)
            }
        }
        
        // Stop timer immediately once granted to conserve CPU
        if trusted && checkTimer != nil {
            checkTimer?.invalidate()
            checkTimer = nil
        }
        return trusted
    }
    
    /// Requests accessibility permission from macOS and immediately opens the Privacy & Security settings pane.
    public func requestAndOpenSettings() {
        hasPromptedOnce = true
        UserDefaults.standard.set(true, forKey: promptedKey)
        
        // 1. Register with macOS TCC by prompting
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        
        // 2. Open System Settings directly to Privacy & Security -> Accessibility
        openAccessibilitySettings()
        
        // 3. Start high-frequency polling (every 0.8s) while the user is in settings
        startPeriodicCheck(interval: 0.8)
    }
    
    public func openAccessibilitySettings() {
        // macOS Ventura, Sonoma, and Sequoia URL scheme
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    public func startPeriodicCheck(interval: TimeInterval = 1.0) {
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkStatus()
            }
        }
    }
}
