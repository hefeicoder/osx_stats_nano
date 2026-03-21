import AppKit

/// Builds an NSView showing detailed stats. Created lazily on menu click.
final class StatsDetailView: NSView {
    private let stack = NSStackView()

    init(snapshot: StatsSnapshot) {
        super.init(frame: NSRect(x: 0, y: 0, width: 260, height: 0))

        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.edgeInsets = NSEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)

        addHeader("OSX Stats Nano")
        addSeparator()
        addRow("CPU", String(format: "%.1f%%", snapshot.cpu))
        addRow("Memory", String(format: "%.1f / %.1f GB (%.0f%%)",
               snapshot.memory.usedGB, snapshot.memory.totalGB, snapshot.memory.percentage))
        addRow("GPU", snapshot.gpu >= 0 ? String(format: "%.1f%%", snapshot.gpu) : "N/A")
        addSeparator()
        addRow("↓ Down", snapshot.network.formattedIn)
        addRow("↑ Up", snapshot.network.formattedOut)

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.widthAnchor.constraint(equalToConstant: 260),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    private func addHeader(_ text: String) {
        let label = NSTextField(labelWithString: text)
        label.font = .boldSystemFont(ofSize: 13)
        stack.addArrangedSubview(label)
    }

    private func addSeparator() {
        let sep = NSBox()
        sep.boxType = .separator
        stack.addArrangedSubview(sep)
        sep.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -24).isActive = true
    }

    private func addRow(_ label: String, _ value: String) {
        let row = NSStackView()
        row.orientation = .horizontal
        row.distribution = .fill

        let lbl = NSTextField(labelWithString: label)
        lbl.font = .systemFont(ofSize: 12, weight: .medium)

        let val = NSTextField(labelWithString: value)
        val.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        val.alignment = .right

        row.addArrangedSubview(lbl)
        row.addArrangedSubview(val)
        val.setContentHuggingPriority(.defaultLow, for: .horizontal)
        lbl.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        stack.addArrangedSubview(row)
        row.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -24).isActive = true
    }
}
