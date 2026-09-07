//
//  StatusRow.swift
//  moji
//
import SwiftUI

struct StatusRow: View {
    let state: RuntimeState

    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(statusColor)
                .frame(width: 15, height: 15)
                .clipShape(.rect(cornerRadius: 3))
                .rotationEffect(.radians(1.10))
                .accessibilityHidden(true)
            Text(state.menuLabel)
                .font(.label)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status: \(state.title)")
        .accessibilityIdentifier("runtimeStatus")
    }

    private var statusColor: Color {
        switch state {
        case .disabled: .secondary
        case .permissionRequired: .orange
        case .active: .green
        case .error: .red
        }
    }
}

// Preview-only examples for the status row states.
#Preview("Active") { StatusRow(state: .active).padding() }
#Preview("Permission Required") { StatusRow(state: .permissionRequired).padding() }
#Preview("Error") { StatusRow(state: .error("Moji could not start.")).padding() }
