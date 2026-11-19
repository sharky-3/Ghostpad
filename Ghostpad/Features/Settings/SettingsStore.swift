import Foundation

@Observable
final class SettingsStore {
    static let widthRange: ClosedRange<Double> = 280...480
    static let opacityRange: ClosedRange<Double> = 0.4...1

    private let defaults = UserDefaults.standard

    var anchor: HUDAnchor {
        didSet { defaults.set(anchor.rawValue, forKey: "hudAnchor") }
    }

    var hudWidth: Double {
        didSet { defaults.set(hudWidth, forKey: "hudWidth") }
    }

    var hudOpacity: Double {
        didSet { defaults.set(hudOpacity, forKey: "hudOpacity") }
    }

    var layoutID: String {
        didSet { defaults.set(layoutID, forKey: "layout") }
    }

    var customLayouts: [KeypadLayout] {
        didSet { defaults.set(try? JSONEncoder().encode(customLayouts), forKey: "customLayouts") }
    }

    var inactivityTimeout: TimeInterval {
        didSet { defaults.set(inactivityTimeout, forKey: "inactivityTimeout") }
    }

    var layouts: [KeypadLayout] {
        KeypadLayout.builtIn + customLayouts
    }

    var layout: KeypadLayout {
        layouts.first { $0.id == layoutID } ?? .standard
    }

    init() {
        anchor = defaults.string(forKey: "hudAnchor").flatMap(HUDAnchor.init(rawValue:)) ?? .bottomCenter
        hudWidth = defaults.object(forKey: "hudWidth") as? Double ?? 360
        hudOpacity = defaults.object(forKey: "hudOpacity") as? Double ?? 1
        layoutID = defaults.string(forKey: "layout") ?? KeypadLayout.standard.id
        customLayouts = defaults.data(forKey: "customLayouts").flatMap { try? JSONDecoder().decode([KeypadLayout].self, from: $0) } ?? []
        inactivityTimeout = defaults.object(forKey: "inactivityTimeout") as? TimeInterval ?? 30
    }

    func createLayout(from base: KeypadLayout?) {
        let name = uniqueName(base.map { "\($0.name) Copy" } ?? "Custom Layout")
        let layout = base?.copy(named: name) ?? KeypadLayout(id: UUID().uuidString, name: name, columns: 4, rows: 4, keys: [])
        customLayouts.append(layout)
        layoutID = layout.id
    }

    func update(_ layout: KeypadLayout) {
        guard let index = customLayouts.firstIndex(where: { $0.id == layout.id }) else { return }
        customLayouts[index] = layout
    }

    func deleteLayout(id: String) {
        customLayouts.removeAll { $0.id == id }
        if layoutID == id {
            layoutID = KeypadLayout.standard.id
        }
    }

    private func uniqueName(_ base: String) -> String {
        let names = Set(layouts.map(\.name))
        guard names.contains(base) else { return base }
        var index = 2
        while names.contains("\(base) \(index)") {
            index += 1
        }
        return "\(base) \(index)"
    }
}
