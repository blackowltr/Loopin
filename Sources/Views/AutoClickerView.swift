import SwiftUI

public struct AutoClickerView: View {
    @ObservedObject var vm: AppViewModel
    
    public init(vm: AppViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Status & Main Action Hero Card
                mainHeroCard
                
                // Interval & Speed Configuration
                intervalConfigCard
                
                // Mouse & Action Settings (Symmetrical 2-Column)
                mouseActionCard
                
                // Target Position Card
                targetPositionCard
                
                // Humanizer & Organic Jitter Card (Symmetrical 2-Column)
                jitterCard
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
        }
    }
    
    // MARK: - Hero Card
    private var mainHeroCard: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(vm.clicker.isRunning ? Color.green : Color.secondary.opacity(0.4))
                        .frame(width: 9, height: 9)
                        .shadow(color: vm.clicker.isRunning ? Color.green.opacity(0.6) : .clear, radius: 4)
                    
                    Text(vm.clicker.isRunning ? "Tıklanıyor..." : "Beklemede")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(vm.clicker.isRunning ? .green : .secondary)
                }
                
                if vm.clicker.isRunning {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(vm.clicker.clicksDone)")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(.primary)
                        Text("tıklama tamamlandı")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if vm.clicker.currentCPS > 0 {
                            Text("•  \(String(format: "%.1f", vm.clicker.currentCPS)) CPS")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.12))
                                .cornerRadius(6)
                        }
                    }
                } else {
                    Text("Ultra Hızlı & Hassas Fare Tıklayıcısı")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Symmetrical MacHeroButton
            MacHeroButton(
                title: vm.clicker.isRunning ? "Durdur" : "Başlat",
                systemImage: vm.clicker.isRunning ? "stop.fill" : "play.fill",
                isRunning: vm.clicker.isRunning,
                width: 130,
                height: 38
            ) {
                vm.toggleAutoClicker()
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
    
    // MARK: - Interval Configuration Card
    private var intervalConfigCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            CardHeader(title: "Tıklama Sıklığı (Aralık & Hız)", systemImage: "timer", colors: [Color.blue, Color.cyan])
            
            // Preset Pills (4 Equal Width Symmetrical Columns)
            HStack(spacing: 10) {
                MacPresetPill(
                    title: "100 CPS",
                    subtitle: "10 ms",
                    isSelected: vm.autoClickerConfig.intervalMs == 10
                ) {
                    vm.autoClickerConfig.intervalMs = 10
                }
                
                MacPresetPill(
                    title: "20 CPS",
                    subtitle: "50 ms",
                    isSelected: vm.autoClickerConfig.intervalMs == 50
                ) {
                    vm.autoClickerConfig.intervalMs = 50
                }
                
                MacPresetPill(
                    title: "10 CPS",
                    subtitle: "100 ms",
                    isSelected: vm.autoClickerConfig.intervalMs == 100
                ) {
                    vm.autoClickerConfig.intervalMs = 100
                }
                
                MacPresetPill(
                    title: "1 CPS",
                    subtitle: "1000 ms",
                    isSelected: vm.autoClickerConfig.intervalMs == 1000
                ) {
                    vm.autoClickerConfig.intervalMs = 1000
                }
            }
            
            Divider()
            
            // Custom Millisecond Input Row (Symmetrical 2 Columns)
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Özel Tıklama Aralığı")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        TextField("ms", value: $vm.autoClickerConfig.intervalMs, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 90)
                        
                        Stepper("", value: $vm.autoClickerConfig.intervalMs, in: 2...60000, step: 10)
                            .labelsHidden()
                        
                        Text("milisaniye (ms)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .frame(height: 36)
                
                // Calculated CPS preview
                let calculatedCPS = vm.autoClickerConfig.intervalMs > 0 ? (1000.0 / Double(vm.autoClickerConfig.intervalMs)) : 0
                HStack(spacing: 10) {
                    IconBadge(systemName: "speedometer", colors: [Color.indigo, Color.purple], size: 28, iconSize: 14)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Teorik Tıklama Hızı")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "≈ %.1f CPS", calculatedCPS))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
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
    
    // MARK: - Mouse Action Card (Perfect 50%-50% symmetry)
    private var mouseActionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            CardHeader(title: "Tıklama Tipi & Tuş", systemImage: "computermouse.fill", colors: [Color.indigo, Color.purple])
            
            HStack(spacing: 20) {
                // Mouse Button Picker (50% width)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Fare Tuşu")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $vm.autoClickerConfig.button) {
                        ForEach(MouseButton.allCases) { btn in
                            Label(btn.rawValue, systemImage: btn.iconName).tag(btn)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .frame(maxWidth: .infinity)
                
                // Click Type Picker (50% width)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tıklama Şekli")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $vm.autoClickerConfig.clickType) {
                        ForEach(ClickType.allCases) { ct in
                            Label(ct.rawValue, systemImage: ct.iconName).tag(ct)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .frame(maxWidth: .infinity)
            }
            
            Divider()
            
            // Symmetrical Repeat Mode Row (50% - 50%)
            HStack(spacing: 20) {
                // Left 50%: Infinite Loop Toggle
                Toggle("Sonsuz Döngü (Durdurulana kadar)", isOn: $vm.autoClickerConfig.isInfinite)
                    .toggleStyle(.checkbox)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .frame(height: 30)
                
                // Right 50%: Target Click Count
                HStack(spacing: 8) {
                    Text("Hedef Adet:")
                        .font(.subheadline)
                        .foregroundColor(vm.autoClickerConfig.isInfinite ? .secondary.opacity(0.5) : .secondary)
                    
                    TextField("Adet", value: $vm.autoClickerConfig.targetClickCount, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 90)
                        .disabled(vm.autoClickerConfig.isInfinite)
                    
                    Stepper("", value: $vm.autoClickerConfig.targetClickCount, in: 1...1000000, step: 50)
                        .labelsHidden()
                        .disabled(vm.autoClickerConfig.isInfinite)
                }
                .opacity(vm.autoClickerConfig.isInfinite ? 0.45 : 1.0)
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
    
    // MARK: - Target Position Card (Balanced 3-Column Grid)
    private var targetPositionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            CardHeader(title: "Tıklama Konumu (Hedef)", systemImage: "scope", colors: [Color.orange, Color.red])
            
            // Mode selector (Segmented style)
            Picker("Konum Modu", selection: $vm.autoClickerConfig.useFixedPosition) {
                Text("Serbest İmleç (İmleci Takip Et)").tag(false)
                Text("Sabit Koordinata Tıkla (X, Y)").tag(true)
            }
            .pickerStyle(.segmented)
            
            if vm.autoClickerConfig.useFixedPosition {
                HStack(spacing: 14) {
                    // X (33.3%)
                    HStack(spacing: 8) {
                        Text("X:")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.blue)
                        TextField("X", value: $vm.autoClickerConfig.fixedX, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Y (33.3%)
                    HStack(spacing: 8) {
                        Text("Y:")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.purple)
                        TextField("Y", value: $vm.autoClickerConfig.fixedY, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Action button (33.3% - Full width match)
                    MacSecondaryButton(title: "İmleç Konumunu Al", systemImage: "scope", fullWidth: true) {
                        vm.setFixedTargetToCurrentMouse()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 4)
            } else {
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "cursorarrow.rays")
                            .foregroundColor(.secondary)
                        Text("İmleciniz ekranın neresinde durursa doğrudan o noktaya tıklar.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                        .frame(height: 24)
                    
                    HStack(spacing: 6) {
                        IconBadge(systemName: "scope", colors: [Color.blue, Color.cyan], size: 22, iconSize: 11)
                        Text("Canlı İmleç:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("(\(Int(vm.currentMouseX)), \(Int(vm.currentMouseY)))")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.vertical, 4)
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
    
    // MARK: - Jitter / Organic Card (Perfect 50%-50% symmetry)
    private var jitterCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                CardHeader(title: "İnsansı Rastgelelik & Titreşim (Anti-Detection)", systemImage: "waveform.path.ecg", colors: [Color.purple, Color.pink])
                
                Spacer()
                
                Toggle("", isOn: $vm.autoClickerConfig.jitterEnabled)
                    .toggleStyle(.switch)
            }
            
            if vm.autoClickerConfig.jitterEnabled {
                HStack(spacing: 24) {
                    // Left slider (50% width)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Zaman Dalgalanması")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("±\(vm.autoClickerConfig.jitterMs) ms")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.blue)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(vm.autoClickerConfig.jitterMs) },
                            set: { vm.autoClickerConfig.jitterMs = Int($0) }
                        ), in: 2...100, step: 2)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right slider (50% width)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Piksel Sapması")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("±\(vm.autoClickerConfig.jitterPx) px")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.purple)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(vm.autoClickerConfig.jitterPx) },
                            set: { vm.autoClickerConfig.jitterPx = Int($0) }
                        ), in: 1...10, step: 1)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Tıklamalar arasındaki süreye ve konuma organik mikroskobik sapmalar ekleyerek bot korumalarını aşar.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
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
}
