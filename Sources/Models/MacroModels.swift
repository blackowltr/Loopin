import Foundation
import CoreGraphics

// MARK: - Mouse Button Types
public enum MouseButton: String, Codable, CaseIterable, Identifiable {
    case left = "Sol Tık"
    case right = "Sağ Tık"
    case middle = "Orta Tık"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .left: return "computermouse.fill"
        case .right: return "computermouse"
        case .middle: return "button.programmable"
        }
    }
}

// MARK: - Click Action Types
public enum ClickType: String, Codable, CaseIterable, Identifiable {
    case single = "Tek Tık"
    case double = "Çift Tık"
    case triple = "Üçlü Tık"
    case hold = "Basılı Tut"
    
    public var id: String { rawValue }
    
    public var clickCount: Int {
        switch self {
        case .single: return 1
        case .double: return 2
        case .triple: return 3
        case .hold: return 1
        }
    }
    
    public var iconName: String {
        switch self {
        case .single: return "1.circle.fill"
        case .double: return "2.circle.fill"
        case .triple: return "3.circle.fill"
        case .hold: return "hand.tap.fill"
        }
    }
}

// MARK: - Macro Action
public enum MacroActionType: Codable, Equatable, Hashable {
    case leftClick
    case rightClick
    case doubleClick
    case middleClick
    case mouseMove
    case scroll(deltaY: Int)
    
    public var title: String {
        switch self {
        case .leftClick: return "Sol Tıklama"
        case .rightClick: return "Sağ Tıklama"
        case .doubleClick: return "Çift Tıklama"
        case .middleClick: return "Orta Tıklama"
        case .mouseMove: return "İmleç Hareketi"
        case .scroll(let dy): return "Kaydırma (\(dy > 0 ? "Yukarı" : "Aşağı"))"
        }
    }
    
    public var icon: String {
        switch self {
        case .leftClick: return "cursorarrow.click.2"
        case .rightClick: return "cursorarrow.click"
        case .doubleClick: return "bolt.fill"
        case .middleClick: return "button.programmable"
        case .mouseMove: return "arrow.up.and.down.and.arrow.left.and.right"
        case .scroll: return "arrow.up.and.down"
        }
    }
}

// MARK: - Single Macro Event
public struct MacroEvent: Identifiable, Codable, Equatable {
    public var id: UUID
    public var action: MacroActionType
    public var x: Double
    public var y: Double
    public var delayBefore: Double // in seconds
    
    public init(id: UUID = UUID(), action: MacroActionType, x: Double, y: Double, delayBefore: Double) {
        self.id = id
        self.action = action
        self.x = x
        self.y = y
        self.delayBefore = delayBefore
    }
    
    public var point: CGPoint {
        CGPoint(x: x, y: y)
    }
    
    public var formattedCoords: String {
        String(format: "X: %.0f, Y: %.0f", x, y)
    }
    
    public var formattedDelay: String {
        if delayBefore < 0.001 {
            return "0 ms"
        } else if delayBefore < 1.0 {
            return String(format: "%.0f ms", delayBefore * 1000)
        } else {
            return String(format: "%.2f s", delayBefore)
        }
    }
}

// MARK: - Macro Sequence
public struct MacroSequence: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var events: [MacroEvent]
    public var repeatCount: Int // 0 means Infinite
    public var speedMultiplier: Double // 0.5, 1.0, 2.0 etc.
    public var loopDelay: Double // pause between loops in seconds
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        events: [MacroEvent] = [],
        repeatCount: Int = 1,
        speedMultiplier: Double = 1.0,
        loopDelay: Double = 0.3,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.events = events
        self.repeatCount = repeatCount
        self.speedMultiplier = speedMultiplier
        self.loopDelay = loopDelay
        self.createdAt = createdAt
    }
    
    public var totalDuration: Double {
        let baseSum = events.reduce(0.0) { $0 + $1.delayBefore }
        return baseSum / max(0.1, speedMultiplier)
    }
}

// MARK: - Auto Clicker Configuration
public struct AutoClickerConfig: Codable, Equatable {
    public var intervalMs: Int
    public var button: MouseButton
    public var clickType: ClickType
    public var isInfinite: Bool
    public var targetClickCount: Int
    public var useFixedPosition: Bool
    public var fixedX: Double
    public var fixedY: Double
    public var jitterEnabled: Bool
    public var jitterMs: Int
    public var jitterPx: Int
    
    public init(
        intervalMs: Int = 100,
        button: MouseButton = .left,
        clickType: ClickType = .single,
        isInfinite: Bool = true,
        targetClickCount: Int = 100,
        useFixedPosition: Bool = false,
        fixedX: Double = 500,
        fixedY: Double = 500,
        jitterEnabled: Bool = false,
        jitterMs: Int = 15,
        jitterPx: Int = 2
    ) {
        self.intervalMs = intervalMs
        self.button = button
        self.clickType = clickType
        self.isInfinite = isInfinite
        self.targetClickCount = targetClickCount
        self.useFixedPosition = useFixedPosition
        self.fixedX = fixedX
        self.fixedY = fixedY
        self.jitterEnabled = jitterEnabled
        self.jitterMs = jitterMs
        self.jitterPx = jitterPx
    }
}

// MARK: - Application Global Status
public enum AppStatus: Equatable {
    case idle
    case recording(eventCount: Int, duration: Double)
    case playingMacro(macroName: String, currentLoop: Int, totalLoops: Int, eventIndex: Int, totalEvents: Int)
    case autoClicking(clicksDone: Int, targetClicks: Int?)
    
    public var isBusy: Bool {
        switch self {
        case .idle: return false
        default: return true
        }
    }
    
    public var badgeText: String {
        switch self {
        case .idle:
            return "Hazır"
        case .recording(let count, _):
            return "Kaydediliyor (\(count))"
        case .playingMacro(let name, let cur, let tot, _, _):
            let loopStr = tot == 0 ? "\(cur)/∞" : "\(cur)/\(tot)"
            return "\(name) [\(loopStr)]"
        case .autoClicking(let done, let target):
            if let target = target {
                return "\(done)/\(target) Tık"
            } else {
                return "\(done) Tık"
            }
        }
    }
}
