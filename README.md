# OSX Stats Nano <img src="icon.png" width="48">

The world's lightest macOS menu bar system monitor. Pure AppKit, zero dependencies, ~800 lines of Swift.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License: MIT](https://img.shields.io/badge/License-MIT-green)
[![Download](https://img.shields.io/github/v/release/hefeicoder/osx_stats_nano?label=download&color=blue)](https://github.com/hefeicoder/osx_stats_nano/releases/latest)

## What it does

Displays live **CPU**, **Memory**, **GPU**, and **Network** stats in your menu bar with minimal resource usage.

<img src="docs/screenshots/preview.png" width="25%">

- **CPU** — ring gauge (green)
- **Memory** — ring gauge (orange)
- **GPU** — ring gauge (purple, hidden if unavailable)
- **Network** — ↓/↑ throughput text

Click the menu bar item for a detailed breakdown with core counts and live-updating values.

## Why another stats app?

Most menu bar monitors pull in SwiftUI, Combine, or third-party charting libraries. OSX Stats Nano uses **none of that**:

- **Pure AppKit** — no SwiftUI, no dependencies beyond Apple system frameworks
- **Zero-alloc draw path** — widgets draw directly to `CGContext`, SF Symbol icons cached at init
- **Change detection** — skips display updates when your system is idle
- **Per-monitor polling** — each metric has its own configurable interval
- **~10 MB RSS** target (vs 15–20 MB for SwiftUI-based alternatives)

## Install

**Download (recommended):**

1. Download `OSXStatsNano-x.x.x.dmg` from [Releases](https://github.com/hefeicoder/osx_stats_nano/releases/latest)
2. Open the DMG and drag **OSXStatsNano** into Applications
3. **First launch:** macOS will block the app since it is not notarized. To open it:
   - Run in Terminal: `xattr -d com.apple.quarantine /Applications/OSXStatsNano.app`, or
   - Go to **System Settings → Privacy & Security**, scroll down to find _"OSXStatsNano was blocked"_, and click **Open Anyway**

   > **Note:** On macOS Ventura+, double-clicking shows a "Move to Trash / Done" dialog with no Open option — dismiss it with **Done**, then follow the Privacy & Security steps above.

**Build from source:**

```bash
git clone https://github.com/hefeicoder/osx_stats_nano.git
cd osx_stats_nano
./run.sh
```

Requires **macOS 13+** and **Xcode**.

## Configuration

On first launch, a config file is created at:

```
~/.config/osx-stats-nano/config.yaml
```

```yaml
# Intervals: seconds between polls per monitor
cpu_interval: 2.0      # default: 2s
memory_interval: 2.0   # default: 2s
gpu_interval: 6.0      # default: 6s (IOKit is heavier)
network_interval: 2.0  # default: 2s

# Toggle monitors on/off
show_cpu: true
show_memory: true
show_gpu: true
show_network: true
```

Edit the file and restart the app to apply changes.

## Architecture

```
Monitors (system calls)  →  StatsPoller (background timer)  →  StatsSnapshot (cache)  →  Display (widgets)
```

| Layer | What it does |
|-------|-------------|
| **Monitors** | Thin wrappers around Mach (`host_processor_info`, `host_statistics64`), BSD (`getifaddrs`), and IOKit (`IOAccelerator`) |
| **StatsPoller** | Single `DispatchSourceTimer` on a utility queue; each monitor fires on its own interval |
| **StatsSnapshot** | Immutable value type with `isDifferent()` — 1% threshold for CPU/Mem/GPU, 1 KB/s for network |
| **StatusBarView** | Custom `NSView` on the `NSStatusItem` button; rebuilds widget list once per update, `draw()` is zero-alloc |
| **StatsDetailView** | Pure AppKit `NSStackView` — built lazily via `NSMenuDelegate.menuWillOpen`, only on click |

## Project Structure

```
Sources/
├── main.swift                    # Entry point
├── AppDelegate.swift             # Lifecycle, wires poller → display
├── AppConfig.swift               # YAML config loader (no dependencies)
├── StatsPoller.swift             # Background polling with per-monitor intervals
├── StatsSnapshot.swift           # Immutable cache with change detection
├── StatusBarController.swift     # NSStatusItem + custom NSView
├── Monitors/
│   ├── CPUMonitor.swift          # Mach host_processor_info
│   ├── MemoryMonitor.swift       # Mach host_statistics64
│   ├── GPUMonitor.swift          # IOKit IOAccelerator
│   └── NetworkMonitor.swift      # BSD getifaddrs
├── Widgets/
│   ├── StatusBarWidget.swift     # Protocol
│   ├── PercentageBarWidget.swift # Horizontal bar
│   ├── PercentageCircleWidget.swift # Ring gauge
│   └── TextWidget.swift          # Plain text
└── Views/
    └── StatsDetailView.swift     # Dropdown detail panel
```

## License

MIT — see [LICENSE](LICENSE).
