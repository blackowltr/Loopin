import SwiftUI
import AppKit

// MARK: - Gradient Icon Badge
public struct IconBadge: View {
    public let systemName: String
    public let colors: [Color]
    public let size: CGFloat
    public let iconSize: CGFloat
    
    public init(
        systemName: String,
        colors: [Color] = [Color.blue, Color.cyan],
        size: CGFloat = 28,
        iconSize: CGFloat = 14
    ) {
        self.systemName = systemName
        self.colors = colors
        self.size = size
        self.iconSize = iconSize
    }
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.75)
                )
                .shadow(color: (colors.first ?? .blue).opacity(0.25), radius: size * 0.12, y: size * 0.06)
                .frame(width: size, height: size)
            
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Symmetrical Card Header
public struct CardHeader: View {
    public let title: String
    public let systemName: String
    public let colors: [Color]
    
    public init(
        title: String,
        systemName: String,
        colors: [Color] = [Color.blue, Color.cyan]
    ) {
        self.title = title
        self.systemName = systemName
        self.colors = colors
    }
    
    public init(
        title: String,
        systemImage: String,
        colors: [Color] = [Color.blue, Color.cyan]
    ) {
        self.title = title
        self.systemName = systemImage
        self.colors = colors
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            IconBadge(systemName: systemName, colors: colors, size: 26, iconSize: 13)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Button Styles (Bug-Free Click Hitboxes & Bilateral Symmetry)

public struct MacHeroButtonStyle: ButtonStyle {
    public let isRunning: Bool
    public let width: CGFloat?
    public let height: CGFloat
    
    public init(isRunning: Bool = false, width: CGFloat? = 130, height: CGFloat = 36) {
        self.isRunning = isRunning
        self.width = width
        self.height = height
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: isRunning ?
                                    [Color(red: 0.95, green: 0.25, blue: 0.25), Color(red: 0.80, green: 0.15, blue: 0.15)] :
                                    [Color(red: 0.15, green: 0.50, blue: 0.98), Color(red: 0.08, green: 0.38, blue: 0.88)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                }
            )
            .shadow(
                color: (isRunning ? Color.red : Color.blue).opacity(configuration.isPressed ? 0.15 : 0.35),
                radius: configuration.isPressed ? 2 : 5,
                y: configuration.isPressed ? 1 : 2
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

public struct MacSecondaryButtonStyle: ButtonStyle {
    public let isDestructive: Bool
    public let fullWidth: Bool
    
    public init(isDestructive: Bool = false, fullWidth: Bool = false) {
        self.isDestructive = isDestructive
        self.fullWidth = fullWidth
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isDestructive ? .red : .primary)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(configuration.isPressed ? Color.primary.opacity(0.12) : Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isDestructive ? Color.red.opacity(0.3) : Color.primary.opacity(0.10), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

public struct MacTileButtonStyle: ButtonStyle {
    public let badgeColor: Color
    
    public init(badgeColor: Color = .blue) {
        self.badgeColor = badgeColor
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(configuration.isPressed ? Color.primary.opacity(0.08) : Color(NSColor.textBackgroundColor).opacity(0.45))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(configuration.isPressed ? badgeColor.opacity(0.4) : Color.primary.opacity(0.08), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

public struct MacPresetPillStyle: ButtonStyle {
    public let isSelected: Bool
    
    public init(isSelected: Bool) {
        self.isSelected = isSelected
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isSelected ? Color.blue.opacity(0.14) : (configuration.isPressed ? Color.primary.opacity(0.08) : Color.primary.opacity(0.03)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(isSelected ? Color.blue.opacity(0.4) : Color.primary.opacity(0.07), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Reusable High-Level Buttons

public struct MacHeroButton: View {
    public let title: String
    public let systemImage: String
    public let isRunning: Bool
    public let width: CGFloat?
    public let height: CGFloat
    public let action: () -> Void
    
    public init(
        title: String,
        systemImage: String,
        isRunning: Bool = false,
        width: CGFloat? = 130,
        height: CGFloat = 36,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isRunning = isRunning
        self.width = width
        self.height = height
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
        }
        .buttonStyle(MacHeroButtonStyle(isRunning: isRunning, width: width, height: height))
    }
}

public struct MacSecondaryButton: View {
    public let title: String
    public let systemImage: String?
    public let isDestructive: Bool
    public let fullWidth: Bool
    public let action: () -> Void
    
    public init(
        title: String,
        systemImage: String? = nil,
        isDestructive: Bool = false,
        fullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isDestructive = isDestructive
        self.fullWidth = fullWidth
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let img = systemImage {
                    Image(systemName: img)
                        .font(.system(size: 11, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(MacSecondaryButtonStyle(isDestructive: isDestructive, fullWidth: fullWidth))
    }
}

public struct MacActionTile: View {
    public let title: String
    public let subtitle: String
    public let badgeSystemImage: String
    public let badgeColors: [Color]
    public let shortcutHint: String?
    public let action: () -> Void
    
    public init(
        title: String,
        subtitle: String,
        badgeSystemImage: String,
        badgeColors: [Color],
        shortcutHint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.badgeSystemImage = badgeSystemImage
        self.badgeColors = badgeColors
        self.shortcutHint = shortcutHint
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                IconBadge(systemName: badgeSystemImage, colors: badgeColors, size: 36, iconSize: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 4)
                
                if let hint = shortcutHint {
                    Text(hint)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.primary.opacity(0.06))
                        )
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(MacTileButtonStyle(badgeColor: badgeColors.first ?? .blue))
    }
}

public struct MacPresetPill: View {
    public let title: String
    public let subtitle: String
    public let isSelected: Bool
    public let action: () -> Void
    
    public init(
        title: String,
        subtitle: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .blue : .primary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .blue.opacity(0.8) : .secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(MacPresetPillStyle(isSelected: isSelected))
    }
}
