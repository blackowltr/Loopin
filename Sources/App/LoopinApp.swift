import SwiftUI
import AppKit

@main
struct LoopinApp: App {
    @StateObject private var vm = AppViewModel.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Main Application Window
        WindowGroup {
            MainWindow()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 780, height: 640)
        .commands {
            CommandMenu("Eylemler") {
                Button("Oto Tıklayıcıyı Başlat / Durdur") {
                    vm.toggleAutoClicker()
                }
                .keyboardShortcut("c", modifiers: [.option])
                
                Button("Makro Kaydını Başlat / Bitir") {
                    vm.toggleRecording()
                }
                .keyboardShortcut("r", modifiers: [.option])
                
                Button("Makroyu Oynat / Durdur") {
                    vm.togglePlayback()
                }
                .keyboardShortcut("p", modifiers: [.option])
                
                Divider()
                
                Button("Anlık Koordinatı Kopyala") {
                    vm.captureCurrentCoordinate()
                }
                .keyboardShortcut("x", modifiers: [.option])
                
                Button("Acil Durdurma") {
                    vm.emergencyStop()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
        }
        
        // Menu Bar Extra for instant access
        MenuBarExtra("Loopin", systemImage: "cursorarrow.rays") {
            MenuBarView(vm: vm)
        }
        .menuBarExtraStyle(.menu)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep running in Menu Bar when window is closed
    }
}
