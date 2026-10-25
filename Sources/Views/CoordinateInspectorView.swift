import SwiftUI

public struct CoordinateInspectorView: View {
    @ObservedObject var vm: AppViewModel
    
    public init(vm: AppViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Large Live Coordinate Display Card (Symmetrical X & Y)
                liveCoordinateCard
                
                // Quick Action Buttons (Symmetrical 2x2 Grid with MacActionTile)
                actionGridCard
                
                // Screen & Display Info Card (Symmetrical 3-Column)
                displayInfoCard
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
        }
        .onAppear {
            vm.startMouseTracking()
        }
        .onDisappear {
            vm.stopMouseTracking()
        }
    }
    
    // MARK: - Live Coordinate Card
    private var liveCoordinateCard: some View {
        VStack(spacing: 16) {
            HStack {
                CardHeader(title: "Anlık Fare Konumu", systemImage: "scope", colors: [Color.blue, Color.indigo])
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .shadow(color: Color.green.opacity(0.6), radius: 3)
                    Text("Canlı Takip Aktif")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 16) {
                // X Coordinate (50% width)
                VStack(spacing: 4) {
                    Text("X KOORDİNATI")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(vm.currentMouseX))")
                        .font(.system(size: 46, weight: .heavy, design: .monospaced))
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(NSColor.textBackgroundColor).opacity(0.45))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.blue.opacity(0.12), lineWidth: 1)
                )
                
                // Y Coordinate (50% width)
                VStack(spacing: 4) {
                    Text("Y KOORDİNATI")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(vm.currentMouseY))")
                        .font(.system(size: 46, weight: .heavy, design: .monospaced))
                        .foregroundColor(.purple)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(NSColor.textBackgroundColor).opacity(0.45))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.purple.opacity(0.12), lineWidth: 1)
                )
            }
            
            HStack(spacing: 6) {
                Image(systemName: "hand.point.up.left.and.text")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text("İmlecinizi ekranın herhangi bir yerine götürdüğünüzde koordinatlar mikrosaniye hassasiyetinde yenilenir.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Action Grid Card (Balanced 2x2 Grid with MacActionTile)
    private var actionGridCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            CardHeader(title: "Hızlı Eylemler & Entegrasyon", systemImage: "sparkles", colors: [Color.purple, Color.indigo])
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                // Copy to Clipboard
                MacActionTile(
                    title: "Koordinatı Kopyala",
                    subtitle: "Sistem panosuna aktar",
                    badgeSystemImage: "doc.on.doc.fill",
                    badgeColors: [Color.blue, Color.cyan],
                    shortcutHint: "⌥X"
                ) {
                    vm.captureCurrentCoordinate()
                }
                
                // Set as Fixed Target
                MacActionTile(
                    title: "Tıklayıcı Hedefi Yap",
                    subtitle: "Oto Tıklayıcı konumuna ata",
                    badgeSystemImage: "target",
                    badgeColors: [Color.orange, Color.red]
                ) {
                    vm.setFixedTargetToCurrentMouse()
                }
                
                // Add to Macro
                MacActionTile(
                    title: "Makro Adımına Ekle",
                    subtitle: "Geçerli konumu makroya yaz",
                    badgeSystemImage: "plus.circle.fill",
                    badgeColors: [Color.green, Color.mint]
                ) {
                    vm.addManualClick(action: .leftClick)
                }
                
                // Test Click
                MacActionTile(
                    title: "Test Tıklaması Yap",
                    subtitle: "1 saniye gecikmeyle simüle et",
                    badgeSystemImage: "hand.tap.fill",
                    badgeColors: [Color.purple, Color.indigo]
                ) {
                    testClickAtCurrent()
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Screen Info Card (Symmetrical 3 Columns)
    private var displayInfoCard: some View {
        let screen = NSScreen.main ?? NSScreen.screens.first
        let frame = screen?.frame ?? .zero
        
        return VStack(alignment: .leading, spacing: 14) {
            CardHeader(title: "Ekran & Görüntü Özellikleri", systemImage: "display", colors: [Color.teal, Color.blue])
            
            HStack(spacing: 16) {
                // Resolution (33.3%)
                HStack(spacing: 10) {
                    IconBadge(systemName: "aspectratio", colors: [Color.blue, Color.indigo], size: 30, iconSize: 14)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Çözünürlük")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(frame.width)) × \(Int(frame.height))")
                            .font(.system(.subheadline, design: .monospaced).bold())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .frame(height: 30)
                
                // Color space (33.3%)
                HStack(spacing: 10) {
                    IconBadge(systemName: "paintpalette.fill", colors: [Color.purple, Color.pink], size: 30, iconSize: 14)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Renk Uzayı")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(screen?.colorSpace?.localizedName ?? "sRGB")
                            .font(.subheadline.bold())
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .frame(height: 30)
                
                // Scale factor (33.3%)
                HStack(spacing: 10) {
                    IconBadge(systemName: "sparkles.tv", colors: [Color.orange, Color.yellow], size: 30, iconSize: 14)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ölçekleme")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(screen?.backingScaleFactor ?? 2.0))x (Retina)")
                            .font(.subheadline.bold())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private func testClickAtCurrent() {
        let x = vm.currentMouseX
        let y = vm.currentMouseY
        vm.showToast("1 saniye sonra (\(Int(x)), \(Int(y))) konumuna tıklanacak...")
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.0) {
            let src = CGEventSource(stateID: .hidSystemState)
            let pt = CGPoint(x: x, y: y)
            let down = CGEvent(mouseEventSource: src, mouseType: .leftMouseDown, mouseCursorPosition: pt, mouseButton: .left)
            let up = CGEvent(mouseEventSource: src, mouseType: .leftMouseUp, mouseCursorPosition: pt, mouseButton: .left)
            down?.post(tap: .cghidEventTap)
            usleep(2_000)
            up?.post(tap: .cghidEventTap)
            Task { @MainActor in
                vm.showToast("Test tıklaması gerçekleştirildi!")
            }
        }
    }
}
