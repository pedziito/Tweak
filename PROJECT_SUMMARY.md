# PC Tweaks System - Project Summary

## Overview
Complete PC hardware detection and optimization tweaks system that can be built into a standalone Windows executable (.exe) file.

## What This System Does

1. **Detects Your Hardware**:
   - CPU (brand, model, cores, threads, frequency)
   - GPU (model, memory, driver version)
   - RAM (capacity, available, usage)
   - Storage devices (all drives with capacity)
   - Motherboard (manufacturer and model on Windows)
   - Operating System information

2. **Provides Targeted Recommendations**:
   - Basic PC tweaks (work on all systems)
   - CPU-specific tweaks (Intel vs AMD)
   - GPU-specific tweaks (NVIDIA vs AMD)
   - RAM optimization tweaks
   - Storage tweaks (SSD vs HDD)
   - Windows system tweaks

3. **Smart Matching**:
   - Automatically shows only relevant tweaks for your hardware
   - No Intel tweaks shown if you have AMD CPU (and vice versa)
   - Different recommendations based on GPU vendor
   - Impact levels (High/Medium/Low) for each tweak

## Project Structure

```
Tweak/
├── main.py                    # Main application entry point
├── hardware_detector.py       # Hardware detection logic
├── tweaks_database.py         # Database of all tweaks
├── test_system.py            # Test suite
├── requirements.txt          # Python dependencies
├── PC_Tweaks.spec            # PyInstaller configuration
├── build.bat                 # Windows build script
├── build.sh                  # Linux/Mac build script
├── run.bat                   # Quick start script for Windows
├── README.md                 # Main documentation (English)
├── BRUGERVEJLEDNING.md       # User guide (Danish)
├── BUILD_INSTRUCTIONS.md     # Detailed build instructions
└── .gitignore               # Git ignore file
```

## Key Features

### Hardware Detection
- Uses `psutil` for system information
- Uses `py-cpuinfo` for detailed CPU info
- Uses `GPUtil` for GPU detection
- Uses `wmi` for Windows-specific hardware (optional)
- Graceful fallback if libraries not available

### Tweaks Database
- 5 basic PC tweaks (all systems)
- 5+ CPU tweaks (Intel/AMD specific)
- 6+ GPU tweaks (NVIDIA/AMD specific)
- 4 RAM optimization tweaks
- 7 storage tweaks (SSD/HDD)
- 4 Windows-specific tweaks

Each tweak includes:
- Title
- Description
- Step-by-step instructions
- Impact level (High/Medium/Low)
- Category (Performance/Gaming/Stability/etc.)

### User Interface
- Clean console-based interface
- Clear hardware information display
- Organized tweak categories
- Easy-to-follow instructions

### Build System
- PyInstaller for creating executables
- One-file output (single .exe)
- No external dependencies needed by end users
- Works on Windows, Linux, and Mac

## Quick Start

### For End Users (Windows)
1. Download `PC_Tweaks.exe`
2. Double-click to run
3. Review detected hardware
4. Follow recommended tweaks

### For Developers
1. Clone repository
2. Install dependencies: `pip install -r requirements.txt`
3. Run: `python main.py`
4. Build: `pyinstaller PC_Tweaks.spec`

## Technologies Used

- **Python 3.8+**: Main programming language
- **psutil**: Cross-platform system monitoring
- **py-cpuinfo**: CPU information detection
- **GPUtil**: GPU detection and monitoring
- **wmi**: Windows Management Instrumentation (Windows only)
- **PyInstaller**: Python to executable converter

## Security

- ✅ CodeQL security scan passed (0 alerts)
- ✅ All dependencies checked for vulnerabilities
- ✅ PyInstaller updated to >= 6.0.0 (no known CVEs)
- ✅ No code execution from user input
- ✅ Read-only operations (detection only)

## Testing

Test suite included (`test_system.py`) that verifies:
- Hardware detection works correctly
- Tweaks database is properly structured
- Relevant tweaks are matched to hardware
- All components integrate properly

## Documentation

- **README.md**: Main project documentation (English)
- **BRUGERVEJLEDNING.md**: User guide in Danish
- **BUILD_INSTRUCTIONS.md**: Detailed build instructions for Windows
- **This file**: Project summary and overview

## System Requirements

### For Building:
- Python 3.8 or higher
- pip (Python package manager)
- PyInstaller 6.0.0+

### For Running (.exe):
- Windows 7 or higher (Windows 10/11 recommended)
- No Python installation needed
- ~20MB free disk space
- Administrator rights recommended

## Supported Platforms

- **Development**: Windows, Linux, Mac
- **Executable**: Windows (primary target)
- **Hardware Detection**: Best on Windows (full WMI support)

## Future Enhancements (Optional)

Possible improvements:
- GUI interface (tkinter or PyQt)
- One-click tweak application
- Backup/restore functionality
- Detailed system report export
- Performance monitoring
- Before/after benchmarks

## Credits

- Developed for the pedziito/Tweak repository
- Uses open-source libraries (see requirements.txt)
- Built with Python and PyInstaller

## License

Open source. Use at your own risk.

## Disclaimer

This tool provides recommendations only. Users should:
- Create system restore points before making changes
- Understand each tweak before applying
- Have administrator rights for some operations
- Backup important data

The developers are not responsible for any issues arising from applying these tweaks.

---

**Status**: ✅ Complete and ready for use
**Last Updated**: 2026-02-09
