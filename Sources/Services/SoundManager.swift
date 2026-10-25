import Foundation
import AppKit

public final class SoundManager {
    public static let shared = SoundManager()
    
    public var soundEnabled: Bool = true
    
    public enum SoundType {
        case recordStart
        case recordStop
        case playStart
        case playFinish
        case tick
        case emergencyStop
        
        var systemSoundName: String {
            switch self {
            case .recordStart: return "Tink"
            case .recordStop: return "Pop"
            case .playStart: return "Hero"
            case .playFinish: return "Purr"
            case .tick: return "Tink"
            case .emergencyStop: return "Basso"
            }
        }
    }
    
    public func play(_ type: SoundType) {
        guard soundEnabled else { return }
        DispatchQueue.main.async {
            NSSound(named: NSSound.Name(type.systemSoundName))?.play()
        }
    }
}
