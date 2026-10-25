import Foundation
import AppKit
import ApplicationServices

@MainActor
public final class AccessibilityManager: ObservableObject {
    public static let shared = AccessibilityManager()
    
    @Published public private(set) var isGranted: Bool = false
    @Published public var hasPromptedOnce: Bool = false
    @Published public var hasUserBypassedOnboarding: Bool = false
    
    private var checkTimer: Timer?
    private let promptedKey = "com.blackowl.loopin.hasPromptedAccessibility"
    private let bypassedKey = "com.blackowl.loopin.hasUserBypassedOnboarding"
    
    public init() {
        self.hasPromptedOnce = UserDefaults.standard.bool(forKey: promptedKey)
        self.hasUserBypassedOnboarding = UserDefaults.standard.bool(forKey: bypassedKey)
        checkStatus()
        startPeriodicCheck()
    }
    
    deinit {
        checkTimer?.invalidate()
    }
    
    @discardableResult
    public func checkStatus() -> Bool {
        // 1. Check with options dictionary (uncached in modern macOS)
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        var trusted = AXIsProcessTrustedWithOptions(options)
        
        // 2. Secondary check
        if !trusted {
            trusted = AXIsProcessTrusted()
        }
        
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
    
    /// Allows the user to bypass the onboarding overlay and enter the app directly.
    public func bypassOnboarding() {
        hasUserBypassedOnboarding = true
        UserDefaults.standard.set(true, forKey: bypassedKey)
        checkStatus()
    }
    
    /// macOS TCC requires processes to be restarted when their accessibility permission is toggled from OFF to ON while running.
    public func relaunchApp() {
        let bundleUrl = Bundle.main.bundleURL
        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: bundleUrl, configuration: config) { _, error in
            if error == nil {
                DispatchQueue.main.async {
                    NSApp.terminate(nil)
                }
            }
        }
    }
}
