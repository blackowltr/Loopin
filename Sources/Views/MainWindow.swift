import SwiftUI

public struct MainWindow: View {
    @StateObject private var vm = AppViewModel.shared
    
    public init() {}
    
    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Running State Banner (if active)
                if vm.appStatus.isBusy {
                    activeRunningBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Tab Content
                ZStack {
                    switch vm.activeTab {
                    case .autoClicker:
                        AutoClickerView(vm: vm)
                    case .recorder:
                        MacroRecorderView(vm: vm)
                    case .inspector:
                        CoordinateInspectorView(vm: vm)
                    case .settings:
                        SettingsView(vm: vm)
                    }
                    
                    // Floating Toast Notification
                    if let toast = vm.toastMessage {
                        VStack {
                            Spacer()
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text(toast)
                                    .font(.subheadline.weight(.medium))
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color(NSColor.windowBackgroundColor))
                                    .shadow(color: Color.black.opacity(0.18), radius: 10, y: 5)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                    )
                            )
                            .padding(.bottom, 24)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: vm.activeTab)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: vm.toastMessage)
            }
            .frame(minWidth: 760, minHeight: 620)
            .background(Color(NSColor.windowBackgroundColor))
            
            // First-launch One-Time Accessibility Permission Modal
            if !vm.accessibility.isGranted && !vm.accessibility.hasUserBypassedOnboarding {
                accessibilityOnboardingOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
            
            // Background Auto-Update Notification Dialog
            if vm.updateManager.showUpdateModal {
                updatePromptOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.accessibility.isGranted || vm.accessibility.hasUserBypassedOnboarding)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.updateManager.showUpdateModal)
        .toolbar {
            // Left: App Branding Pill (Fixed width 130 for bilateral balance)
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 8) {
                    IconBadge(systemName: "cursorarrow.rays", colors: [Color.blue, Color.purple], size: 22, iconSize: 11)
                    
                    Text("Loopin")
                        .font(.system(size: 13, weight: .bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(7)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                .frame(width: 130, alignment: .leading)
            }
            
            // Center: Symmetrically Centered Navigation Tabs (Dead center)
            ToolbarItem(placement: .principal) {
                Picker("", selection: $vm.activeTab) {
                    ForEach(AppTab.allCases) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.regular)
                .frame(width: 460)
            }
            
            // Right: Status Indicator Pill (Fixed width 130 for perfect symmetry)
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(vm.appStatus.isBusy ? Color.green : Color.secondary.opacity(0.4))
                        .frame(width: 7, height: 7)
                    Text(vm.appStatus.badgeText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(vm.appStatus.isBusy ? .green : .secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(7)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                .frame(width: 130, alignment: .trailing)
            }
        }
    }
    
    // MARK: - Active Running Banner
    private var activeRunningBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.fill")
                .foregroundColor(.yellow)
            
            Text(vm.appStatus.badgeText)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Text("Durdurmak için ESC tuşuna basın veya imleci ekran köşesine çekin")
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))
            
            Button(action: {
                vm.emergencyStop()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text("Durdur")
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.small)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            Color.indigo.opacity(0.9)
        )
    }
    
    // MARK: - Accessibility Onboarding Overlay
    private var accessibilityOnboardingOverlay: some View {
        ZStack {
            // Frosted backdrop to focus attention on setup
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Onboarding Card
            VStack(spacing: 20) {
                // Header Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                    
                    IconBadge(
                        systemName: "hand.raised.fill",
                        colors: [Color.blue, Color(red: 0.2, green: 0.5, blue: 1.0)],
                        size: 48,
                        iconSize: 24
                    )
                }
                
                // Title & Subtitle
                VStack(spacing: 6) {
                    Text("Loopin'e Hoş Geldiniz")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Kullanmaya başlamak için tek seferlik sistem izni gereklidir")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Explanatory steps box
                VStack(alignment: .leading, spacing: 12) {
                    stepRow(
                        number: "1",
                        title: "Sistem Ayarlarını Açın",
                        description: "Aşağıdaki butona tıkladığınızda macOS 'Gizlilik ve Güvenlik' penceresi otomatik açılır."
                    )
                    
                    Divider()
                        .opacity(0.6)
                    
                    stepRow(
                        number: "2",
                        title: "Loopin'i Etkinleştirin",
                        description: "'Erişilebilirlik' listesinde Loopin'in yanındaki anahtarı açık konuma getirin."
                    )
                    
                    Divider()
                        .opacity(0.6)
                    
                    stepRow(
                        number: "✓",
                        title: "Tek Seferlik Kurulum",
                        description: "İzin verildiğinde bu ekran kendiliğinden kapanır. Bir daha asla sorulmaz.",
                        isCheck: true
                    )
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                )
                
                // Primary Action Button
                Button(action: {
                    vm.accessibility.requestAndOpenSettings()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("1. Sistem Ayarlarını Aç ve İzin Ver")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color(red: 0.05, green: 0.4, blue: 0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(8)
                    .shadow(color: Color.blue.opacity(0.3), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                
                // Secondary Action Row (If user already granted in System Settings)
                HStack(spacing: 10) {
                    Button(action: {
                        vm.accessibility.relaunchApp()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .bold))
                            Text("Yeniden Başlat (Önerilen)")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Color.primary.opacity(0.06))
                        .foregroundColor(.primary)
                        .cornerRadius(7)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        vm.accessibility.bypassOnboarding()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("İzni Verdim, Giriş Yap")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(7)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                // Helpful Hint Box
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                        .padding(.top, 1)
                    
                    Text("Sistem Ayarlarında Loopin'i açtıysanız ancak ekran otomatik kapanmadıysa; macOS'in izni uygulamaya aktarması için 'Yeniden Başlat'a basın veya doğrudan 'İzni Verdim, Giriş Yap' butonuna tıklayın.")
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.blue.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.blue.opacity(0.12), lineWidth: 1)
                        )
                )
                
                // Real-time Detection Status & Dismiss
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    
                    Text("İzin durumu denetleniyor...")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Yeniden Kontrol Et") {
                        vm.accessibility.checkStatus()
                    }
                    .font(.system(size: 11, weight: .medium))
                    .buttonStyle(.link)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Button("Şimdilik Atla") {
                        vm.accessibility.bypassOnboarding()
                    }
                    .font(.system(size: 11, weight: .medium))
                    .buttonStyle(.link)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
            }
            .padding(26)
            .frame(width: 460)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: Color.black.opacity(0.25), radius: 25, y: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
    
    @ViewBuilder
    private func stepRow(number: String, title: String, description: String, isCheck: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCheck ? Color.green.opacity(0.18) : Color.blue.opacity(0.12))
                    .frame(width: 22, height: 22)
                
                Text(number)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isCheck ? Color.green : Color.blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - Software Update Prompt Overlay
    private var updatePromptOverlay: some View {
        ZStack {
            // Frosted backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    vm.updateManager.dismissUpdate(remindLater: true)
                }
            
            // Modal Card
            VStack(spacing: 18) {
                // Header Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)
                    
                    IconBadge(
                        systemName: "arrow.triangle.2.circlepath",
                        colors: [Color.blue, Color.cyan],
                        size: 46,
                        iconSize: 22
                    )
                }
                
                // Title & Subtitle
                VStack(spacing: 6) {
                    Text("Yeni Güncelleme Mevcut")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Loopin \(vm.updateManager.latestVersion) yayınlandı")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Version comparison pill
                HStack(spacing: 12) {
                    VStack(alignment: .center, spacing: 2) {
                        Text("Mevcut Sürüm")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("v\(vm.updateManager.currentVersion)")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.04))
                    .cornerRadius(8)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("Yeni Sürüm")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.blue)
                        Text(vm.updateManager.latestVersion)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Release notes excerpt
                if !vm.updateManager.releaseNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Yenilikler & Notlar:")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        ScrollView {
                            Text(vm.updateManager.releaseNotes)
                                .font(.system(size: 11))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                        }
                        .frame(maxHeight: 120)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                                )
                        )
                    }
                }
                
                // Download Progress (if downloading)
                if vm.updateManager.isDownloading {
                    VStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.regular)
                        Text("Güncelleme paketi indiriliyor...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                // Action Buttons
                VStack(spacing: 8) {
                    Button(action: {
                        vm.updateManager.downloadAndOpenDMG()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text(vm.updateManager.isDownloading ? "İndiriliyor..." : "Şimdi Güncelle ve Aç")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color(red: 0.05, green: 0.45, blue: 0.95)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(8)
                        .shadow(color: Color.blue.opacity(0.35), radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.updateManager.isDownloading)
                    
                    HStack(spacing: 12) {
                        Button("Tarayıcıda İncele") {
                            vm.updateManager.openReleasePage()
                        }
                        .buttonStyle(.link)
                        .font(.system(size: 12))
                        
                        Spacer()
                        
                        Button("Daha Sonra Hatırlat") {
                            vm.updateManager.dismissUpdate(remindLater: true)
                        }
                        .buttonStyle(.link)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(24)
            .frame(width: 460)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: Color.black.opacity(0.28), radius: 25, y: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
}
