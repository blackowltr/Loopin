import SwiftUI

public struct MainWindow: View {
    @StateObject private var vm = AppViewModel.shared
    
    public init() {}
    
    public var body: some View {
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
}
