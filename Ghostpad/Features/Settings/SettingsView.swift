import SwiftUI

enum SettingsPane: String, CaseIterable, Identifiable {
    case general
    case position
    case layouts

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .general: "General"
        case .position: "Position"
        case .layouts: "Layouts"
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gearshape"
        case .position: "macbook"
        case .layouts: "square.grid.3x3"
        }
    }
}

struct SettingsView: View {
    let settings: SettingsStore
    let permissions: PermissionMonitor
    let aspectRatio: Double
    let onPreview: () -> Void

    @State private var pane: SettingsPane? = .position

    var body: some View {
        NavigationSplitView {
            List(SettingsPane.allCases, selection: $pane) { pane in
                Label(pane.title, systemImage: pane.systemImage)
                    .tag(pane)
            }
            .toolbar(removing: .sidebarToggle)
            .navigationSplitViewColumnWidth(190)
        } detail: {
            detail
                .navigationTitle((pane ?? .general).title)
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch pane ?? .general {
        case .general: GeneralSettingsView(settings: settings, permissions: permissions)
        case .position: PositionSettingsView(settings: settings, aspectRatio: aspectRatio, onPreview: onPreview)
        case .layouts: LayoutSettingsView(settings: settings, aspectRatio: aspectRatio)
        }
    }
}
