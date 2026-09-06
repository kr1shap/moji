import CoreGraphics

enum MojiEventSource {
    static let userData: Int64 = 0x4D_6F_6A_69 // Moji in ascii bytes to identify whether the event is generated 

    static func isGenerated(_ event: CGEvent) -> Bool {
        event.getIntegerValueField(.eventSourceUserData) == userData
    }
}
