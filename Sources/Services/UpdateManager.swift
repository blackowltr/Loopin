import Foundation
import AppKit
import SwiftUI

public struct GitHubReleaseAsset: Decodable {
    public let name: String
    public let browser_download_url: String
    public let size: Int
}

public struct GitHubReleaseResponse: Decodable {
    public let tag_name: String
    public let name: String?
    public let body: String?
    public let html_url: String
    public let published_at: String?
    public let assets: [GitHubReleaseAsset]
}

@MainActor
public final class UpdateManager: ObservableObject {
    public static let shared = UpdateManager()
    
    // State
    @Published public var isChecking: Bool = false
    @Published public var updateAvailable: Bool = false
    @Published public var latestVersion: String = ""
    @Published public var latestReleaseTitle: String = ""
    @Published public var releaseNotes: String = ""
    @Published public var htmlUrl: URL? = nil
    @Published public var dmgDownloadUrl: URL? = nil
    @Published public var showUpdateModal: Bool = false
    @Published public var lastCheckDate: Date? = nil
    @Published public var statusMessage: String = "Henüz denetlenmedi"
    
    // Download state
    @Published public var isDownloading: Bool = false
    @Published public var downloadProgress: Double = 0.0
    
    // Preferences
    @Published public var autoCheckEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(autoCheckEnabled, forKey: autoCheckKey)
        }
    }
    
    private let autoCheckKey = "com.blackowl.loopin.autoCheckUpdates"
    private let ignoredVersionKey = "com.blackowl.loopin.ignoredUpdateVersion"
    private var periodicTimer: Timer?
    
    public var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    public var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    public init() {
        if UserDefaults.standard.object(forKey: autoCheckKey) != nil {
            self.autoCheckEnabled = UserDefaults.standard.bool(forKey: autoCheckKey)
        }
        
        // Start background check if enabled
        if autoCheckEnabled {
            scheduleStartupCheck()
            startPeriodicTimer()
        }
    }
    
    deinit {
        periodicTimer?.invalidate()
    }
    
    // MARK: - Background Scheduling
    private func scheduleStartupCheck() {
        Task {
            // Wait 3.5 seconds after launch to ensure smooth, non-blocking UI startup
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            if self.autoCheckEnabled {
                await self.checkForUpdates(silent: true)
            }
        }
    }
    
    private func startPeriodicTimer() {
        periodicTimer?.invalidate()
        // Check every 4 hours while app stays running
        periodicTimer = Timer.scheduledTimer(withTimeInterval: 4 * 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                if self?.autoCheckEnabled == true {
                    await self?.checkForUpdates(silent: true)
                }
            }
        }
    }
    
    // MARK: - Check for Updates
    public func checkForUpdates(silent: Bool = false) async {
        guard !isChecking else { return }
        isChecking = true
        statusMessage = "Güncellemeler denetleniyor..."
        
        defer {
            isChecking = false
            lastCheckDate = Date()
        }
        
        guard let url = URL(string: "https://api.github.com/repos/blackowltr/Loopin/releases/latest") else {
            statusMessage = "Geçersiz güncelleme sunucusu adresi."
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Loopin-macOS/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                statusMessage = "Güncelleme sunucusuna ulaşılamadı."
                return
            }
            
            let release = try JSONDecoder().decode(GitHubReleaseResponse.self, from: data)
            let remoteTag = release.tag_name.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
            
            self.latestVersion = release.tag_name
            self.latestReleaseTitle = release.name ?? release.tag_name
            self.releaseNotes = release.body ?? ""
            self.htmlUrl = URL(string: release.html_url)
            
            // Find DMG asset or fallback to first asset
            if let dmgAsset = release.assets.first(where: { $0.name.lowercased().hasSuffix(".dmg") }) {
                self.dmgDownloadUrl = URL(string: dmgAsset.browser_download_url)
            } else if let firstAsset = release.assets.first {
                self.dmgDownloadUrl = URL(string: firstAsset.browser_download_url)
            } else {
                self.dmgDownloadUrl = self.htmlUrl
            }
            
            // Compare semantic versions
            let isNewer = isVersion(remoteTag, higherThan: currentVersion)
            self.updateAvailable = isNewer
            
            if isNewer {
                statusMessage = "Yeni güncelleme mevcut: \(release.tag_name)"
                let ignored = UserDefaults.standard.string(forKey: ignoredVersionKey)
                
                // Show prompt if manual, or if silent and version wasn't explicitly dismissed
                if !silent || (silent && ignored != release.tag_name) {
                    self.showUpdateModal = true
                }
            } else {
                statusMessage = "Loopin güncel (v\(currentVersion))"
                if !silent {
                    AppViewModel.shared.showToast("Loopin en güncel sürümde (v\(currentVersion))")
                }
            }
        } catch {
            statusMessage = "Güncelleme kontrolü başarısız oldu."
            if !silent {
                AppViewModel.shared.showToast("Güncelleme sunucusuna bağlanılamadı")
            }
        }
    }
    
    // MARK: - Actions
    public func dismissUpdate(remindLater: Bool = true) {
        showUpdateModal = false
        if !remindLater {
            // Dismiss permanently for this version
            UserDefaults.standard.set(latestVersion, forKey: ignoredVersionKey)
        }
    }
    
    public func openReleasePage() {
        if let url = htmlUrl ?? URL(string: "https://github.com/blackowltr/Loopin/releases") {
            NSWorkspace.shared.open(url)
        }
        showUpdateModal = false
    }
    
    public func downloadAndOpenDMG() {
        guard let downloadUrl = dmgDownloadUrl else {
            openReleasePage()
            return
        }
        
        isDownloading = true
        downloadProgress = 0.05
        
        Task {
            do {
                let (tempUrl, response) = try await URLSession.shared.download(from: downloadUrl)
                let fileName = response.suggestedFilename ?? "Loopin-Update.dmg"
                
                let downloadsUrl = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                let destinationUrl = downloadsUrl.appendingPathComponent(fileName)
                
                // Remove existing if present
                try? FileManager.default.removeItem(at: destinationUrl)
                try FileManager.default.moveItem(at: tempUrl, to: destinationUrl)
                
                self.downloadProgress = 1.0
                self.isDownloading = false
                self.showUpdateModal = false
                
                // Open downloaded DMG in Finder
                NSWorkspace.shared.open(destinationUrl)
                AppViewModel.shared.showToast("Güncelleme indirildi: \(fileName)")
            } catch {
                self.isDownloading = false
                // Fallback to opening browser
                self.openReleasePage()
            }
        }
    }
    
    // MARK: - Semantic Version Comparison
    private func isVersion(_ v1: String, higherThan v2: String) -> Bool {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }
        
        let maxCount = max(parts1.count, parts2.count)
        for i in 0..<maxCount {
            let num1 = i < parts1.count ? parts1[i] : 0
            let num2 = i < parts2.count ? parts2[i] : 0
            if num1 > num2 { return true }
            if num1 < num2 { return false }
        }
        return false
    }
}
