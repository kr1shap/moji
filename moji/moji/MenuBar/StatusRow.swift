//
//  StatusRow.swift
//  moji
//
import SwiftUI

struct StatusRow: View {
    let state: RuntimeState

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(state.title)
                    .font(.body)
                if case let .error(message) = state {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            Image(systemName: state.systemImage)
                .foregroundStyle(statusColor)
        }
        .accessibilityElement(children: .combine)
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

#Preview("Active") { StatusRow(state: .active).padding() }
#Preview("Permission Required") { StatusRow(state: .permissionRequired).padding() }
#Preview("Error") { StatusRow(state: .error("Moji could not start.")).padding() }
