# PC Tweaks System

A Windows application that detects your PC hardware components and provides optimized tweaks for better performance.

## Features

- **Hardware Detection**: Automatically detects CPU, GPU, RAM, storage devices, and motherboard
- **Component-Specific Tweaks**: Shows optimizations tailored to your specific hardware (Intel/AMD CPU, NVIDIA/AMD GPU, etc.)
- **Basic PC Tweaks**: General optimization tips applicable to all systems
- **Categorized Recommendations**: Tweaks organized by impact level and category (Performance, Gaming, Stability, etc.)

## Installation

### Option 1: Run from Source (Python Required)

1. Install Python 3.8 or higher
2. Clone this repository
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Run the application:
   ```bash
   python main.py
   ```

### Option 2: Use Pre-built Executable

Download `PC_Tweaks.exe` from the releases page and run it directly (no Python installation needed).

## Building the Executable

To build the .exe file yourself:

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Build using PyInstaller:
   ```bash
   pyinstaller PC_Tweaks.spec
   ```

3. The executable will be created in the `dist` folder:
   ```
   dist/PC_Tweaks.exe
   ```

### Alternative Build Method

If you don't have the spec file or want to customize:

```bash
pyinstaller --onefile --name=PC_Tweaks --console main.py
```

## System Requirements

- **Operating System**: Windows 7 or higher (Windows 10/11 recommended)
- **Python** (for source): Python 3.8+
- **Administrator Rights**: Some hardware detection features work best with admin privileges

## Usage

1. Run `PC_Tweaks.exe` (or `python main.py` if running from source)
2. The application will automatically detect your hardware components
3. Review the displayed hardware information
4. Browse through categorized tweaks:
   - Basic PC Tweaks (applicable to all systems)
   - CPU Tweaks (specific to Intel/AMD)
   - GPU Tweaks (specific to NVIDIA/AMD)
   - RAM/Memory Tweaks
   - Storage Tweaks (SSD/HDD)
   - Windows Tweaks
5. Follow the instructions for each tweak you want to apply

## Detected Hardware Components

The application detects:
- **CPU**: Brand, model, cores, threads, frequency
- **GPU**: Graphics card model, memory, driver version
- **RAM**: Total memory, available memory, usage percentage
- **Storage**: All drives with capacity and free space
- **Motherboard**: Manufacturer and model (Windows only)
- **OS**: Operating system version

## Tweak Categories

Tweaks are organized by:
- **Impact Level**: High, Medium, Low
- **Category**: Performance, Gaming, Stability, Power Saving, Privacy, etc.
- **Component Type**: CPU, GPU, RAM, Storage, Windows

## Safety Notice

- **Always create a system restore point before making system changes**
- Some tweaks require BIOS/UEFI access - only modify if you're comfortable
- Administrator rights may be needed for certain tweaks
- This tool provides recommendations only - you decide which to implement

## Dependencies

- `psutil`: System and process utilities
- `py-cpuinfo`: CPU information detection
- `GPUtil`: GPU detection and monitoring
- `wmi`: Windows Management Instrumentation (Windows only)
- `pyinstaller`: For building the executable

## Contributing

Contributions are welcome! Feel free to:
- Add new tweaks to `tweaks_database.py`
- Improve hardware detection in `hardware_detector.py`
- Enhance the user interface
- Report bugs or suggest features

## License

This project is open source. Use at your own risk.

## Disclaimer

This tool provides optimization recommendations. The developers are not responsible for any issues arising from applying these tweaks. Always backup your data and create restore points before making system changes.
