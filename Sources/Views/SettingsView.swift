import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject var vm: AppViewModel
    
    public init(vm: AppViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Accessibility Permission Card
                accessibilityCard
                
                // Safety & Fail-Safe Card
                safetyCard
                
                // Sound & Preferences Card
                soundAndGeneralCard
                
                // Global Shortcuts Reference Card
                shortcutsCard
                
                // About / Architecture Card
                aboutCard
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
        }
    }
    
    // MARK: - Accessibility Permission Card
    private var accessibilityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            CardHeader(
                title: "Sistem İzinleri & Erişilebilirlik",
                systemImage: "lock.shield.fill",
                colors: vm.accessibility.isGranted ? [Color.green, Color.mint] : [Color.orange, Color.red]
            )
            
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(vm.accessibility.isGranted ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: vm.accessibility.isGranted ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .font(.title2)
                        .foregroundColor(vm.accessibility.isGranted ? .green : .orange)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(vm.accessibility.isGranted ? "Erişilebilirlik İzni Aktif" : "Erişilebilirlik İzni Bekleniyor")
                        .font(.headline)
                        .foregroundColor(vm.accessibility.isGranted ? .green : .orange)
                    
                    Text(vm.accessibility.isGranted ?
                         "Loopin, macOS üzerinde küresel fare eylemlerini ve tıklamaları güvenle simüle edebilir." :
                         "macOS güvenlik politikası gereği, fare otomasyonu için Erişilebilirlik izni gereklidir.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !vm.accessibility.isGranted {
                    MacHeroButton(title: "Ayarları Aç ve İzin Ver", systemImage: "arrow.up.forward.app", width: 190, height: 32) {
                        vm.accessibility.requestAndOpenSettings()
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(vm.accessibility.isGranted ? Color.green.opacity(0.2) : Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Safety Card
    private var safetyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            CardHeader(title: "Güvenlik & Acil Durdurma", systemImage: "shield.lefthalf.filled", colors: [Color.teal, Color.blue])
            
            Toggle(isOn: $vm.failSafeCornerEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ekran Köşesi Acil Durdurma (Fail-Safe)")
                        .font(.subheadline.bold())
                    Text("Oynatma veya tıklama sırasında fareyi ekranın herhangi bir köşesine çekerseniz işlem anında durdurulur.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            
            Divider()
            
            HStack(spacing: 12) {
                Image(systemName: "keyboard.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("ESC Tuşu Koruması")
                        .font(.subheadline.bold())
                    Text("Klavyedeki ESC tuşuna basıldığında tüm aktif makrolar ve oto tıklayıcı derhal iptal edilir.")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
    
    // MARK: - Sound & General Card
    private var soundAndGeneralCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            CardHeader(title: "Tercihler & Kayıt Seçenekleri", systemImage: "slider.horizontal.3", colors: [Color.orange, Color.yellow])
            
            Toggle(isOn: $vm.soundEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("macOS Doğal Ses Bildirimleri")
                        .font(.subheadline.bold())
                    Text("Kayıt başladığında, bittiğinde ve acil durdurmalarda hafif sistem sesleri (Tink, Pop, Purr) çalar.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            
            Divider()
            
            Toggle(isOn: $vm.recordMovementsEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Fare Gezinme Hareketlerini de Kaydet")
                        .font(.subheadline.bold())
                    Text("Kapalıyken yalnızca tıklama adımları kaydedilir (daha hafif ve temiz makrolar). Açıldığında imleç rotası da kaydedilir.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
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
    
    // MARK: - Shortcuts Card (Symmetrical Aligned Badges with Icons)
    private var shortcutsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            CardHeader(title: "Küresel Kısayol Tuşları", systemImage: "command", colors: [Color.indigo, Color.purple])
            
            VStack(spacing: 10) {
                shortcutRow(
                    title: "Oto Tıklayıcıyı Başlat / Durdur",
                    icon: "bolt.horizontal.fill",
                    iconColor: .orange,
                    shortcut: "⌥ C"
                )
                shortcutRow(
                    title: "Makro Kaydını Başlat / Bitir",
                    icon: "record.circle.fill",
                    iconColor: .red,
                    shortcut: "⌥ R"
                )
                shortcutRow(
                    title: "Makroyu Oynat / Durdur",
                    icon: "play.fill",
                    iconColor: .blue,
                    shortcut: "⌥ P"
                )
                shortcutRow(
                    title: "Anlık Koordinatı Kopyala",
                    icon: "scope",
                    iconColor: .cyan,
                    shortcut: "⌥ X"
                )
                shortcutRow(
                    title: "Acil Durdurma",
                    icon: "exclamationmark.octagon.fill",
                    iconColor: .red,
                    shortcut: "ESC"
                )
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
    
    private func shortcutRow(title: String, icon: String, iconColor: Color, shortcut: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 18)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(shortcut)
                .font(.system(.subheadline, design: .monospaced).bold())
                .frame(width: 58, height: 26)
                .background(Color(NSColor.textBackgroundColor).opacity(0.6))
                .cornerRadius(6)
        }
    }
    
    // MARK: - About Card
    private var aboutCard: some View {
        HStack(spacing: 16) {
            if let img = appIconImage {
                Image(nsImage: img)
                    .resizable()
                    .frame(width: 48, height: 48)
                    .cornerRadius(11)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
            } else {
                IconBadge(systemName: "cursorarrow.rays", colors: [Color.blue, Color.purple], size: 48, iconSize: 22)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("Loopin")
                        .font(.headline)
                    Text("v1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Apple Silicon ARM64 Native")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                
                Text("macOS için hafif, sade ve enerji dostu fare makro & oto-tıklayıcı uygulaması.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
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
    
    private var appIconImage: NSImage? {
        let appSupport = Bundle.main.url(forResource: "AppIcon_1024", withExtension: "png")
        if let url = appSupport, let img = NSImage(contentsOf: url) {
            return img
        }
        if let fallback = NSImage(named: "AppIcon") {
            return fallback
        }
        return nil
    }
}
