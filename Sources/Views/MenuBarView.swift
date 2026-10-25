import SwiftUI
import AppKit

public struct MenuBarView: View {
    @ObservedObject var vm: AppViewModel
    
    public init(vm: AppViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Status Header
            HStack(spacing: 8) {
                Circle()
                    .fill(vm.appStatus.isBusy ? Color.green : Color.secondary.opacity(0.4))
                    .frame(width: 8, height: 8)
                
                Text(vm.appStatus.badgeText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(vm.appStatus.isBusy ? .green : .primary)
                
                Spacer()
                
                Text("Loopin")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            
            Divider()
                .padding(.vertical, 2)
            
            // Auto Clicker Quick Toggle
            menuBarButton(
                title: vm.clicker.isRunning ? "Oto Tıklayıcıyı Durdur" : "Oto Tıklayıcıyı Başlat",
                systemImage: vm.clicker.isRunning ? "stop.fill" : "bolt.horizontal.fill",
                shortcut: "⌥C",
                action: { vm.toggleAutoClicker() }
            )
            
            // Macro Play Quick Toggle
            menuBarButton(
                title: vm.player.isPlaying ? "Makroyu Durdur" : "Makroyu Oynat",
                systemImage: vm.player.isPlaying ? "stop.fill" : "play.fill",
                shortcut: "⌥P",
                action: { vm.togglePlayback() }
            )
            .opacity((vm.currentSequence.events.isEmpty && !vm.player.isPlaying) ? 0.45 : 1.0)
            
            // Macro Record Quick Toggle
            menuBarButton(
                title: vm.recorder.isRecording ? "Kaydı Durdur" : "Yeni Makro Kaydet",
                systemImage: vm.recorder.isRecording ? "stop.circle.fill" : "record.circle",
                shortcut: "⌥R",
                action: { vm.toggleRecording() }
            )
            
            Divider()
                .padding(.vertical, 2)
            
            // Open Main Window
            menuBarButton(
                title: "Loopin Penceresini Aç",
                systemImage: "macwindow",
                shortcut: nil,
                action: {
                    NSApp.activate(ignoringOtherApps: true)
                    for window in NSApp.windows where !(window is NSPanel) {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
            )
            
            Divider()
                .padding(.vertical, 2)
            
            // Quit
            menuBarButton(
                title: "Çıkış",
                systemImage: "power",
                shortcut: "⌘Q",
                isDestructive: true,
                action: {
                    NSApplication.shared.terminate(nil)
                }
            )
        }
        .padding(10)
        .frame(width: 240)
    }
    
    private func menuBarButton(
        title: String,
        systemImage: String,
        shortcut: String?,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isDestructive ? .red : .secondary)
                    .frame(width: 16, alignment: .center)
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(isDestructive ? .red : .primary)
                
                Spacer()
                
                if let sc = shortcut {
                    Text(sc)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
        }
        .buttonStyle(MenuBarItemButtonStyle(isDestructive: isDestructive))
    }
}

public struct MenuBarItemButtonStyle: ButtonStyle {
    public let isDestructive: Bool
    
    public init(isDestructive: Bool = false) {
        self.isDestructive = isDestructive
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(configuration.isPressed ? Color.accentColor.opacity(0.18) : Color.clear)
            )
    }
}
