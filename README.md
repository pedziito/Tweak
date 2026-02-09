# Tweak — Performance Tuner

> Modern Qt 6 / C++ Windows tweaking utility with automatic hardware detection,
> safe reversible tweaks, and CS2-specific optimizations.

![Qt 6](https://img.shields.io/badge/Qt-6.5+-41cd52?logo=qt&logoColor=white)
![C++17](https://img.shields.io/badge/C++-17-blue?logo=cplusplus)
![Windows](https://img.shields.io/badge/platform-Windows%2010%2F11-0078d4?logo=windows)

---

## Features

| Area | What it does |
|------|-------------|
| **Hardware Detection** | Automatic WMI scan: CPU (cores, threads, clock), GPU (vendor classification), RAM, motherboard, storage (SSD/NVMe flags) |
| **Tweak Categories** | Gaming, Latency, FPS, Network, Power, Services |
| **Smart Recommendations** | Hardware-driven — discrete GPU enables CS2 tweaks, 16 GB+ RAM enables memory tweaks, SSD disables Superfetch |
| **One-Click Apply** | "Apply Recommended Settings" applies all flagged tweaks at once |
| **Full Restore** | Every tweak backs up original values; "Restore Defaults" reverts everything |
| **CS2 Optimization** | GPU preference, launch option hints, fullscreen optimization disable |
| **Power Plan** | Activates Ultimate/High Performance via powercfg |
| **Registry Tweaks** | SystemResponsiveness, MMCSS, network throttling, TCP ACK, Nagle, timer resolution |
| **Service Management** | Disable DiagTrack, SysMain, WSearch (registry start type — safe) |
| **Startup Cleanup** | Lists Run keys + Startup folders |
| **UAC Elevation** | "Elevate" button relaunches as admin via ShellExecuteEx runas |
| **CS2 Path Picker** | Dialog to set custom cs2.exe path, persisted in QSettings |
| **Dark Mode UI** | Material Dark theme with category color-coding and animated cards |

---

## Building

### Requirements

- **Qt 6.5+** with modules: Core, Gui, Qml, Quick, QuickControls2, Widgets
- **CMake 3.21+**
- **MSVC** (required for WMI / COM headers)
- Windows 10/11 SDK

```bash
mkdir build && cd build
cmake .. -G "Visual Studio 17 2022" -DCMAKE_PREFIX_PATH="C:/Qt/6.7.0/msvc2019_64"
cmake --build . --config Release
```

---

## Architecture

```
src/
  main.cpp                  # Entry point
  app/
    AppController.h/.cpp    # QML <-> C++ bridge
    HardwareDetector.h/.cpp # WMI hardware scan
    TweakEngine.h/.cpp      # Tweak definitions, apply/restore, backup
    TweakListModel.h/.cpp   # QAbstractListModel for ListView
    RegistryUtil.h/.cpp     # Registry read/write/delete
    PowerUtil.h/.cpp        # powercfg + CS2 path detection
    UacHelper.h/.cpp        # UAC elevation
    SettingsManager.h/.cpp  # QSettings persistence
    StartupScanner.h/.cpp   # Startup item scanner
qml/
    Main.qml                # Root window
    HardwarePanel.qml       # System info sidebar
    QuickActionsPanel.qml   # Action buttons
    StartupPanel.qml        # Startup items
    TweakCard.qml           # Tweak delegate card
    CategoryFilter.qml      # Category filter pills
    Cs2PathDialog.qml       # CS2 path input
```

### Hardware Detection

Uses raw COM (no ATL) to query WMI:
- `Win32_Processor` — Name, NumberOfCores, ThreadCount, MaxClockSpeed
- `Win32_VideoController` — Name (classified to NVIDIA/AMD/Intel)
- `Win32_PhysicalMemory` — Capacity (summed)
- `Win32_BaseBoard` — Product
- `Win32_DiskDrive` — Model, MediaType, InterfaceType (SSD/NVMe flags)

### Safety

- No bcdedit — no boot config changes
- No service stop/start — only registry Start type (takes effect on reboot)
- Full backup before every write in `%APPDATA%/Tweak/backup.json`
- Admin check before HKLM writes
- All tweaks individually reversible

---

## License

MIT
