"""
Hardware Detection Module
Detects PC components including CPU, GPU, RAM, and storage devices.
"""

import platform
import psutil
import cpuinfo
from typing import Dict, List

try:
    import GPUtil
    GPU_AVAILABLE = True
except ImportError:
    GPU_AVAILABLE = False

try:
    import wmi
    WMI_AVAILABLE = True
except ImportError:
    WMI_AVAILABLE = False


class HardwareDetector:
    """Detects hardware components in the PC."""
    
    def __init__(self):
        self.hardware_info = {}
        
    def detect_all(self) -> Dict:
        """Detect all hardware components."""
        self.hardware_info = {
            'cpu': self.detect_cpu(),
            'gpu': self.detect_gpu(),
            'ram': self.detect_ram(),
            'storage': self.detect_storage(),
            'motherboard': self.detect_motherboard(),
            'os': self.detect_os()
        }
        return self.hardware_info
    
    def detect_cpu(self) -> Dict:
        """Detect CPU information."""
        try:
            cpu_info = cpuinfo.get_cpu_info()
            return {
                'name': cpu_info.get('brand_raw', 'Unknown CPU'),
                'cores': psutil.cpu_count(logical=False),
                'threads': psutil.cpu_count(logical=True),
                'frequency': psutil.cpu_freq().max if psutil.cpu_freq() else 0,
                'vendor': cpu_info.get('vendor_id_raw', 'Unknown'),
                'architecture': cpu_info.get('arch', platform.machine())
            }
        except Exception as e:
            return {
                'name': 'Unknown CPU',
                'cores': psutil.cpu_count(logical=False),
                'threads': psutil.cpu_count(logical=True),
                'error': str(e)
            }
    
    def detect_gpu(self) -> List[Dict]:
        """Detect GPU information."""
        gpus = []
        
        if GPU_AVAILABLE:
            try:
                gpu_list = GPUtil.getGPUs()
                for gpu in gpu_list:
                    gpus.append({
                        'name': gpu.name,
                        'memory': f"{gpu.memoryTotal}MB",
                        'driver': gpu.driver,
                        'id': gpu.id
                    })
            except Exception:
                pass
        
        # Fallback for Windows using WMI
        if not gpus and WMI_AVAILABLE and platform.system() == 'Windows':
            try:
                w = wmi.WMI()
                for gpu in w.Win32_VideoController():
                    gpus.append({
                        'name': gpu.Name,
                        'memory': f"{int(gpu.AdapterRAM or 0) / (1024**2)}MB" if gpu.AdapterRAM else "Unknown",
                        'driver': gpu.DriverVersion or "Unknown"
                    })
            except Exception:
                pass
        
        if not gpus:
            gpus.append({'name': 'Unknown GPU', 'memory': 'Unknown'})
        
        return gpus
    
    def detect_ram(self) -> Dict:
        """Detect RAM information."""
        try:
            memory = psutil.virtual_memory()
            return {
                'total': f"{memory.total / (1024**3):.2f}GB",
                'total_bytes': memory.total,
                'available': f"{memory.available / (1024**3):.2f}GB",
                'used_percent': f"{memory.percent}%"
            }
        except Exception as e:
            return {'error': str(e)}
    
    def detect_storage(self) -> List[Dict]:
        """Detect storage devices."""
        storage_devices = []
        try:
            partitions = psutil.disk_partitions()
            for partition in partitions:
                try:
                    usage = psutil.disk_usage(partition.mountpoint)
                    storage_devices.append({
                        'device': partition.device,
                        'mountpoint': partition.mountpoint,
                        'filesystem': partition.fstype,
                        'total': f"{usage.total / (1024**3):.2f}GB",
                        'used': f"{usage.used / (1024**3):.2f}GB",
                        'free': f"{usage.free / (1024**3):.2f}GB",
                        'percent': f"{usage.percent}%"
                    })
                except PermissionError:
                    continue
        except Exception as e:
            storage_devices.append({'error': str(e)})
        
        return storage_devices
    
    def detect_motherboard(self) -> Dict:
        """Detect motherboard information (Windows only)."""
        motherboard_info = {'name': 'Unknown Motherboard'}
        
        if WMI_AVAILABLE and platform.system() == 'Windows':
            try:
                w = wmi.WMI()
                for board in w.Win32_BaseBoard():
                    motherboard_info = {
                        'manufacturer': board.Manufacturer,
                        'product': board.Product,
                        'name': f"{board.Manufacturer} {board.Product}"
                    }
                    break
            except Exception:
                pass
        
        return motherboard_info
    
    def detect_os(self) -> Dict:
        """Detect operating system information."""
        return {
            'system': platform.system(),
            'release': platform.release(),
            'version': platform.version(),
            'name': f"{platform.system()} {platform.release()}"
        }
