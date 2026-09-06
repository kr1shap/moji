import CoreGraphics

enum MojiEventSource {
    static let userData: Int64 = 0x4D_6F_6A_69

    static func isGenerated(_ event: CGEvent) -> Bool {
        event.getIntegerValueField(.eventSourceUserData) == userData
    }
}
