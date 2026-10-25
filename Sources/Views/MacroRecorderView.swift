import SwiftUI

public struct MacroRecorderView: View {
    @ObservedObject var vm: AppViewModel
    
    public init(vm: AppViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Controls Bar (Balanced & Unified Height)
            topControlBar
            
            Divider()
            
            // Middle: Event Timeline List or Empty State
            if vm.currentSequence.events.isEmpty && !vm.recorder.isRecording {
                emptyStateView
            } else {
                eventsListView
            }
            
            Divider()
            
            // Bottom Playback Config Bar (Symmetrical 4-segment)
            bottomPlaybackBar
        }
    }
    
    // MARK: - Top Controls Bar (3-Group Balanced Alignment)
    private var topControlBar: some View {
        HStack(spacing: 12) {
            // Left Group: Macro Name & Saved Selector
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                    TextField("Makro Adı", text: $vm.currentSequence.name)
                        .font(.system(size: 12, weight: .semibold))
                        .textFieldStyle(.plain)
                        .frame(width: 130)
                }
                .padding(.horizontal, 10)
                .frame(height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(NSColor.textBackgroundColor).opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                
                // Saved Macros Menu
                Menu {
                    ForEach(vm.savedSequences) { seq in
                        Button(action: {
                            vm.loadSequence(seq)
                        }) {
                            HStack {
                                Text(seq.name)
                                Text("(\(seq.events.count) adım)")
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: {
                        vm.clearCurrentMacro()
                    }) {
                        Label("Listeyi Temizle", systemImage: "trash")
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "folder")
                            .font(.system(size: 11))
                        Text("Kayıtlı (\(vm.savedSequences.count))")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .menuStyle(.borderedButton)
                .controlSize(.regular)
                .frame(height: 32)
            }
            
            Spacer()
            
            // Center Group: Timeline summary
            if !vm.currentSequence.events.isEmpty {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                    Text("\(vm.currentSequence.events.count) Adım")
                        .font(.system(size: 11, weight: .bold))
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f sn", vm.currentSequence.totalDuration))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(6)
            }
            
            Spacer()
            
            // Right Group: Symmetrical Action Buttons (All exactly 32pt height)
            HStack(spacing: 8) {
                MacSecondaryButton(title: "Kaydet", systemImage: "square.and.arrow.down") {
                    vm.saveCurrentSequence()
                }
                .opacity(vm.currentSequence.events.isEmpty ? 0.45 : 1.0)
                
                MacSecondaryButton(title: "Temizle", systemImage: "trash", isDestructive: true) {
                    vm.clearCurrentMacro()
                }
                
                // Record Button (32pt height match)
                MacHeroButton(
                    title: vm.recorder.isRecording ? "Durdur" : "Kaydet",
                    systemImage: "record.circle",
                    isRunning: vm.recorder.isRecording,
                    width: 105,
                    height: 32
                ) {
                    vm.toggleRecording()
                }
                
                // Play Button (32pt height match)
                MacHeroButton(
                    title: vm.player.isPlaying ? "Durdur" : "Oynat",
                    systemImage: vm.player.isPlaying ? "stop.fill" : "play.fill",
                    isRunning: vm.player.isPlaying,
                    width: 105,
                    height: 32
                ) {
                    vm.togglePlayback()
                }
                .opacity((vm.currentSequence.events.isEmpty && !vm.player.isPlaying) ? 0.45 : 1.0)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Events List View (Symmetrical Table Columns)
    private var eventsListView: some View {
        VStack(spacing: 0) {
            // Table Header
            HStack(spacing: 0) {
                Text("Adım")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(width: 48, alignment: .center)
                
                Text("Eylem")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 12)
                
                Text("Koordinat (X, Y)")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(width: 140, alignment: .center)
                
                Text("Gecikme")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(width: 95, alignment: .center)
                
                Text("Sil")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(width: 48, alignment: .center)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(Array(vm.currentSequence.events.enumerated()), id: \.element.id) { index, event in
                        eventRow(index: index, event: event)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Event Row
    private func eventRow(index: Int, event: MacroEvent) -> some View {
        let isCurrent = vm.player.isPlaying && vm.player.currentEventIndex == index + 1
        
        return HStack(spacing: 0) {
            // Step index badge
            Text("#\(index + 1)")
                .font(.system(.caption, design: .monospaced).bold())
                .foregroundColor(isCurrent ? .blue : .secondary)
                .frame(width: 48, alignment: .center)
            
            // Action
            HStack(spacing: 10) {
                actionMiniBadge(for: event.action)
                Text(event.action.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(isCurrent ? .blue : .primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 12)
            
            // Coordinate
            Text(event.formattedCoords)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 140, alignment: .center)
            
            // Delay Before
            Text("+ \(event.formattedDelay)")
                .font(.system(.caption, design: .rounded))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.primary.opacity(0.06))
                .cornerRadius(5)
                .frame(width: 95, alignment: .center)
            
            // Delete button
            Button(action: {
                vm.removeEvent(at: index)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary.opacity(0.7))
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .frame(width: 48, alignment: .center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .background(
            isCurrent ?
            Color.blue.opacity(0.12) :
            (index % 2 == 0 ? Color.clear : Color.primary.opacity(0.015))
        )
    }
    
    private func actionMiniBadge(for action: MacroActionType) -> some View {
        let colors: [Color]
        switch action {
        case .leftClick: colors = [Color.blue, Color.cyan]
        case .rightClick: colors = [Color.purple, Color.indigo]
        case .middleClick: colors = [Color.orange, Color.yellow]
        case .doubleClick: colors = [Color.pink, Color.red]
        case .mouseMove: colors = [Color.gray, Color.secondary]
        case .scroll: colors = [Color.green, Color.mint]
        }
        
        return ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 22, height: 22)
            Image(systemName: action.icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.08))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "record.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 6) {
                Text("Henüz Kaydedilmiş Adım Yok")
                    .font(.headline)
                
                Text("Yukarıdaki 'Kaydet' düğmesine veya küresel ⌥R kısayoluna basarak\nfare tıklamalarınızı ve hareketlerinizi gerçek zamanlı kaydedin.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 14) {
                MacSecondaryButton(title: "Sol Tıklama Adımı Ekle", systemImage: "cursorarrow.click.2") {
                    vm.addManualClick(action: .leftClick)
                }
                
                MacSecondaryButton(title: "Çift Tıklama Adımı Ekle", systemImage: "bolt.fill") {
                    vm.addManualClick(action: .doubleClick)
                }
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding(32)
    }
    
    // MARK: - Bottom Playback Bar (Symmetrical 4 Partitions)
    private var bottomPlaybackBar: some View {
        HStack(spacing: 0) {
            // Speed Multiplier
            HStack(spacing: 6) {
                Image(systemName: "speedometer")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text("Hız:")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                Picker("", selection: $vm.currentSequence.speedMultiplier) {
                    Text("0.5x (Yavaş)").tag(0.5)
                    Text("1.0x (Normal)").tag(1.0)
                    Text("1.5x").tag(1.5)
                    Text("2.0x (Hızlı)").tag(2.0)
                    Text("5.0x (Süper)").tag(5.0)
                    Text("10x (Maks)").tag(10.0)
                }
                .pickerStyle(.menu)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            Divider()
                .frame(height: 22)
            
            // Repeat Count
            HStack(spacing: 6) {
                Image(systemName: "repeat")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text("Döngü:")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                Picker("", selection: $vm.currentSequence.repeatCount) {
                    Text("1 Kez").tag(1)
                    Text("2 Kez").tag(2)
                    Text("5 Kez").tag(5)
                    Text("10 Kez").tag(10)
                    Text("50 Kez").tag(50)
                    Text("Sonsuz (∞)").tag(0)
                }
                .pickerStyle(.menu)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            Divider()
                .frame(height: 22)
            
            // Loop delay
            HStack(spacing: 6) {
                Image(systemName: "hourglass")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text("Tur Arası:")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                Picker("", selection: $vm.currentSequence.loopDelay) {
                    Text("0.1 sn").tag(0.1)
                    Text("0.3 sn").tag(0.3)
                    Text("0.5 sn").tag(0.5)
                    Text("1.0 sn").tag(1.0)
                    Text("2.0 sn").tag(2.0)
                }
                .pickerStyle(.menu)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            Divider()
                .frame(height: 22)
            
            // Total Duration Preview
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                Text("Toplam Süre:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f sn", vm.currentSequence.totalDuration))
                    .font(.system(.caption, design: .monospaced).bold())
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
