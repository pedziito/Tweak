"""
PC Tweaks System - Main Application
Detects PC hardware and displays relevant optimization tweaks.
"""

import sys
from hardware_detector import HardwareDetector
from tweaks_database import TweaksDatabase


class PCTweaksApp:
    """Main application class for PC Tweaks System."""
    
    def __init__(self):
        self.detector = HardwareDetector()
        self.tweaks_db = TweaksDatabase()
        self.hardware_info = None
        self.relevant_tweaks = None
    
    def run(self):
        """Main application entry point."""
        self.print_header()
        self.detect_hardware()
        self.display_hardware_info()
        self.get_relevant_tweaks()
        self.display_tweaks()
        self.wait_for_exit()
    
    def print_header(self):
        """Print application header."""
        print("=" * 70)
        print(" " * 20 + "PC TWEAKS SYSTEM")
        print(" " * 15 + "Hardware Detection & Optimization")
        print("=" * 70)
        print()
    
    def detect_hardware(self):
        """Detect all hardware components."""
        print("Detecting hardware components...")
        print()
        self.hardware_info = self.detector.detect_all()
        print("✓ Hardware detection complete!")
        print()
    
    def display_hardware_info(self):
        """Display detected hardware information."""
        print("=" * 70)
        print("DETECTED HARDWARE")
        print("=" * 70)
        print()
        
        # Operating System
        os_info = self.hardware_info.get('os', {})
        print(f"Operating System: {os_info.get('name', 'Unknown')}")
        print()
        
        # CPU
        cpu = self.hardware_info.get('cpu', {})
        print(f"CPU: {cpu.get('name', 'Unknown')}")
        print(f"  Cores: {cpu.get('cores', 'Unknown')} | Threads: {cpu.get('threads', 'Unknown')}")
        if cpu.get('frequency'):
            print(f"  Max Frequency: {cpu.get('frequency', 0):.0f} MHz")
        print()
        
        # GPU
        gpus = self.hardware_info.get('gpu', [])
        if gpus:
            print(f"GPU: {len(gpus)} detected")
            for i, gpu in enumerate(gpus, 1):
                print(f"  {i}. {gpu.get('name', 'Unknown')}")
                print(f"     Memory: {gpu.get('memory', 'Unknown')}")
        print()
        
        # RAM
        ram = self.hardware_info.get('ram', {})
        print(f"RAM: {ram.get('total', 'Unknown')}")
        print(f"  Available: {ram.get('available', 'Unknown')} (% used: {ram.get('used_percent', 'Unknown')})")
        print()
        
        # Storage
        storage_devices = self.hardware_info.get('storage', [])
        print(f"Storage: {len(storage_devices)} drive(s) detected")
        for device in storage_devices:
            if 'error' not in device:
                print(f"  {device.get('device', 'Unknown')}: {device.get('total', 'Unknown')} "
                      f"({device.get('free', 'Unknown')} free)")
        print()
        
        # Motherboard
        mb = self.hardware_info.get('motherboard', {})
        print(f"Motherboard: {mb.get('name', 'Unknown')}")
        print()
        print("=" * 70)
        print()
    
    def get_relevant_tweaks(self):
        """Get tweaks relevant to detected hardware."""
        self.relevant_tweaks = self.tweaks_db.get_relevant_tweaks(self.hardware_info)
    
    def display_tweaks(self):
        """Display all relevant tweaks."""
        print("=" * 70)
        print("RECOMMENDED TWEAKS")
        print("=" * 70)
        print()
        
        # Basic Tweaks
        self.display_tweak_category("BASIC PC TWEAKS (All Systems)", 
                                    self.relevant_tweaks.get('basic', []))
        
        # CPU Tweaks
        self.display_tweak_category("CPU TWEAKS", 
                                    self.relevant_tweaks.get('cpu', []))
        
        # GPU Tweaks
        self.display_tweak_category("GPU TWEAKS", 
                                    self.relevant_tweaks.get('gpu', []))
        
        # RAM Tweaks
        self.display_tweak_category("RAM/MEMORY TWEAKS", 
                                    self.relevant_tweaks.get('ram', []))
        
        # Storage Tweaks
        self.display_tweak_category("STORAGE TWEAKS", 
                                    self.relevant_tweaks.get('storage', []))
        
        # Windows Tweaks
        self.display_tweak_category("WINDOWS TWEAKS", 
                                    self.relevant_tweaks.get('windows', []))
    
    def display_tweak_category(self, category_name, tweaks):
        """Display a category of tweaks."""
        if not tweaks:
            return
        
        print(f"\n{category_name}")
        print("-" * 70)
        
        for i, tweak in enumerate(tweaks, 1):
            print(f"\n{i}. {tweak.get('title', 'Unknown')} [Impact: {tweak.get('impact', 'Unknown')}]")
            print(f"   Category: {tweak.get('category', 'Unknown')}")
            print(f"   Description: {tweak.get('description', 'No description')}")
            print(f"   Instructions: {tweak.get('instructions', 'No instructions')}")
        
        print()
    
    def wait_for_exit(self):
        """Wait for user to exit the application."""
        print("=" * 70)
        print()
        input("Press Enter to exit...")


def main():
    """Main entry point."""
    try:
        app = PCTweaksApp()
        app.run()
    except KeyboardInterrupt:
        print("\n\nApplication terminated by user.")
        sys.exit(0)
    except Exception as e:
        print(f"\nError: {e}")
        print("\nPlease report this issue to the developer.")
        input("\nPress Enter to exit...")
        sys.exit(1)


if __name__ == "__main__":
    main()
