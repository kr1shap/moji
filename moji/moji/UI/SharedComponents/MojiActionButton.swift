import SwiftUI

struct MojiActionButton: View {
    let title: String
    let width: CGFloat
    let action: () -> Void

    init(_ title: String, width: CGFloat = 70, action: @escaping () -> Void) {
        self.title = title
        self.width = width
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            MojiActionLabel(title, width: width)
        }
            .buttonStyle(.plain)
    }
}

struct MojiActionLabel: View {
    let title: String
    let width: CGFloat

    init(_ title: String, width: CGFloat = 70) {
        self.title = title
        self.width = width
    }

    var body: some View {
        Text(title)
            .font(.bodyText)
            .foregroundStyle(.primary)
            .frame(width: width, height: 28)
            .background(.primary.opacity(0.1), in: Capsule())
            .contentShape(Capsule())
    }
}
