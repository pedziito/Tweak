# How to Build PC_Tweaks.exe on Windows

This guide explains how to build the PC_Tweaks.exe executable file on Windows.

## Prerequisites

1. **Python 3.8 or higher** - Download from https://python.org
   - During installation, check "Add Python to PATH"
2. **Git** (optional) - For cloning the repository
3. **Administrator rights** - For some hardware detection features

## Quick Build Method (Recommended)

1. Open Command Prompt or PowerShell as Administrator
2. Navigate to the project directory:
   ```
   cd path\to\Tweak
   ```
3. Run the build script:
   ```
   build.bat
   ```
4. The executable will be created in `dist\PC_Tweaks.exe`

## Manual Build Method

If you prefer to build manually or troubleshoot issues:

### Step 1: Install Dependencies

```bash
pip install -r requirements.txt
```

This will install:
- psutil - For system monitoring
- py-cpuinfo - For CPU detection
- GPUtil - For GPU detection
- wmi - For Windows hardware information
- pyinstaller - For creating the executable

### Step 2: Build the Executable

```bash
pyinstaller PC_Tweaks.spec
```

Or using the one-file command:

```bash
pyinstaller --onefile --name=PC_Tweaks --console main.py
```

### Step 3: Find Your Executable

The executable will be in the `dist` folder:
```
dist\PC_Tweaks.exe
```

## Testing the Executable

1. Navigate to the `dist` folder
2. Double-click `PC_Tweaks.exe` or run from command line:
   ```
   dist\PC_Tweaks.exe
   ```
3. The application will:
   - Detect your hardware
   - Display detected components
   - Show recommended tweaks

## Troubleshooting

### "Python is not recognized"
- Reinstall Python and check "Add Python to PATH"
- Or manually add Python to your PATH environment variable

### "pip is not recognized"
- Python installation might be corrupted
- Try: `python -m pip install -r requirements.txt`

### Build fails with "ModuleNotFoundError"
- Ensure all dependencies are installed: `pip install -r requirements.txt`
- Try updating pip: `python -m pip install --upgrade pip`

### Executable is very large
- This is normal - PyInstaller bundles Python and all dependencies
- Typical size: 10-20 MB

### Antivirus flags the executable
- This is a false positive (common with PyInstaller)
- Add an exception for the executable in your antivirus
- Or build from source yourself to verify safety

### Hardware not detected correctly
- Run as Administrator for full hardware detection
- Some features require WMI (included in Windows)

## Customization

### Change Icon (Optional)

1. Create or find an `.ico` file
2. Edit `PC_Tweaks.spec` and change:
   ```python
   icon=None
   ```
   to:
   ```python
   icon='path/to/your/icon.ico'
   ```
3. Rebuild: `pyinstaller PC_Tweaks.spec`

### Remove Console Window

To create a GUI version without console window:

1. Edit `PC_Tweaks.spec` and change:
   ```python
   console=True
   ```
   to:
   ```python
   console=False
   ```
2. Rebuild: `pyinstaller PC_Tweaks.spec`

Note: For this application, console=True is recommended to see all the information.

## Distribution

The built executable is standalone and can be:
- Copied to other Windows PCs
- Shared with users (no Python installation required)
- Run directly without installation

### System Requirements for Running the Executable
- Windows 7 or higher
- No Python installation needed
- ~20MB free disk space
- Administrator rights (recommended for full functionality)

## Additional Notes

### UPX Compression
- UPX is enabled in the spec file (`upx=True`)
- This compresses the executable to reduce size
- If you have issues, set `upx=False` in `PC_Tweaks.spec`

### One-File vs One-Folder
- Current setup uses "one-file" mode (single .exe)
- Slower startup but easier to distribute
- For faster startup, use "one-folder" mode in the spec file

## Need Help?

If you encounter issues:
1. Check that Python 3.8+ is installed
2. Verify all dependencies installed: `pip list`
3. Try deleting `build` and `dist` folders and rebuilding
4. Check PyInstaller documentation: https://pyinstaller.org

## Building for Distribution

When building for distribution:
1. Test on a clean Windows VM first
2. Run antivirus scan on the executable
3. Consider code signing to reduce antivirus false positives
4. Include README.md with the executable for users
