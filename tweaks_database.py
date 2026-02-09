"""
Tweaks Database
Contains all PC tweaks categorized by component type.
"""

class TweaksDatabase:
    """Database of PC tweaks organized by component type."""
    
    def __init__(self):
        self.tweaks = {
            'basic': self._get_basic_tweaks(),
            'cpu': self._get_cpu_tweaks(),
            'gpu': self._get_gpu_tweaks(),
            'ram': self._get_ram_tweaks(),
            'storage': self._get_storage_tweaks(),
            'windows': self._get_windows_tweaks()
        }
    
    def _get_basic_tweaks(self):
        """Basic tweaks applicable to all PCs."""
        return [
            {
                'title': 'Disable Startup Programs',
                'description': 'Disable unnecessary programs from starting with Windows to improve boot time',
                'instructions': 'Open Task Manager (Ctrl+Shift+Esc) > Startup tab > Disable unnecessary programs',
                'impact': 'High',
                'category': 'Performance'
            },
            {
                'title': 'Update Drivers',
                'description': 'Keep all system drivers up to date for optimal performance and stability',
                'instructions': 'Use Device Manager or manufacturer websites to update drivers',
                'impact': 'High',
                'category': 'Stability'
            },
            {
                'title': 'Clean Temporary Files',
                'description': 'Remove temporary files to free up disk space',
                'instructions': 'Run Disk Cleanup (cleanmgr.exe) or use Windows Storage Settings',
                'impact': 'Medium',
                'category': 'Storage'
            },
            {
                'title': 'Disable Visual Effects',
                'description': 'Disable unnecessary visual effects for better performance',
                'instructions': 'System Properties > Advanced > Performance Settings > Adjust for best performance',
                'impact': 'Medium',
                'category': 'Performance'
            },
            {
                'title': 'Enable Game Mode',
                'description': 'Windows Game Mode optimizes PC for gaming performance',
                'instructions': 'Settings > Gaming > Game Mode > Enable',
                'impact': 'Medium',
                'category': 'Gaming'
            }
        ]
    
    def _get_cpu_tweaks(self):
        """CPU-specific tweaks."""
        return {
            'intel': [
                {
                    'title': 'Intel Turbo Boost',
                    'description': 'Ensure Intel Turbo Boost is enabled in BIOS for better performance',
                    'instructions': 'Access BIOS/UEFI and enable Intel Turbo Boost Technology',
                    'impact': 'High',
                    'category': 'Performance'
                },
                {
                    'title': 'Intel Power Plan',
                    'description': 'Set Windows power plan to High Performance',
                    'instructions': 'Control Panel > Power Options > Select High Performance plan',
                    'impact': 'Medium',
                    'category': 'Performance'
                },
                {
                    'title': 'Disable CPU Parking',
                    'description': 'Prevent Windows from parking CPU cores',
                    'instructions': 'Use registry editor or third-party tools to disable CPU core parking',
                    'impact': 'Medium',
                    'category': 'Performance'
                }
            ],
            'amd': [
                {
                    'title': 'AMD Precision Boost',
                    'description': 'Enable Precision Boost Overdrive in BIOS for Ryzen CPUs',
                    'instructions': 'Access BIOS/UEFI and enable Precision Boost Overdrive',
                    'impact': 'High',
                    'category': 'Performance'
                },
                {
                    'title': 'AMD Ryzen Master',
                    'description': 'Use AMD Ryzen Master utility for optimal CPU settings',
                    'instructions': 'Download and install AMD Ryzen Master from AMD website',
                    'impact': 'High',
                    'category': 'Performance'
                },
                {
                    'title': 'AMD Power Plan',
                    'description': 'Use AMD Ryzen Balanced power plan for best performance',
                    'instructions': 'Install AMD chipset drivers and select Ryzen Balanced plan',
                    'impact': 'Medium',
                    'category': 'Performance'
                }
            ],
            'general': [
                {
                    'title': 'Set Process Priority',
                    'description': 'Set important applications to high priority in Task Manager',
                    'instructions': 'Task Manager > Details > Right-click process > Set Priority > High',
                    'impact': 'Low',
                    'category': 'Performance'
                },
                {
                    'title': 'Disable Hyper-Threading (if needed)',
                    'description': 'For some games, disabling HT/SMT can improve performance',
                    'instructions': 'Disable in BIOS if experiencing issues with specific applications',
                    'impact': 'Variable',
                    'category': 'Gaming'
                }
            ]
        }
    
    def _get_gpu_tweaks(self):
        """GPU-specific tweaks."""
        return {
            'nvidia': [
                {
                    'title': 'NVIDIA Control Panel Settings',
                    'description': 'Optimize NVIDIA Control Panel for maximum performance',
                    'instructions': 'NVIDIA Control Panel > Manage 3D Settings > Set to Performance mode',
                    'impact': 'High',
                    'category': 'Gaming'
                },
                {
                    'title': 'Update GeForce Drivers',
                    'description': 'Keep GeForce drivers updated using GeForce Experience',
                    'instructions': 'Install GeForce Experience and enable automatic driver updates',
                    'impact': 'High',
                    'category': 'Performance'
                },
                {
                    'title': 'Enable GPU Scheduling',
                    'description': 'Hardware-accelerated GPU scheduling reduces latency',
                    'instructions': 'Settings > Display > Graphics Settings > Enable Hardware-accelerated GPU scheduling',
                    'impact': 'Medium',
                    'category': 'Performance'
                },
                {
                    'title': 'Optimize Power Management',
                    'description': 'Set power management mode to Maximum Performance',
                    'instructions': 'NVIDIA Control Panel > Manage 3D Settings > Power management mode > Prefer maximum performance',
                    'impact': 'Medium',
                    'category': 'Performance'
                }
            ],
            'amd': [
                {
                    'title': 'AMD Radeon Settings',
                    'description': 'Optimize AMD Radeon settings for gaming',
                    'instructions': 'AMD Radeon Software > Gaming > Optimize performance settings',
                    'impact': 'High',
                    'category': 'Gaming'
                },
                {
                    'title': 'Update AMD Drivers',
                    'description': 'Keep AMD drivers updated via AMD Software',
                    'instructions': 'Use AMD Software: Adrenalin Edition for driver updates',
                    'impact': 'High',
                    'category': 'Performance'
                },
                {
                    'title': 'Enable Radeon Anti-Lag',
                    'description': 'Reduce input lag in games',
                    'instructions': 'AMD Radeon Software > Gaming > Radeon Anti-Lag > Enable',
                    'impact': 'Medium',
                    'category': 'Gaming'
                },
                {
                    'title': 'Radeon Chill',
                    'description': 'Regulate GPU power and reduce heat during gaming',
                    'instructions': 'AMD Radeon Software > Gaming > Radeon Chill > Configure',
                    'impact': 'Medium',
                    'category': 'Power Saving'
                }
            ],
            'general': [
                {
                    'title': 'Set GPU as Default',
                    'description': 'Ensure dedicated GPU is used instead of integrated graphics',
                    'instructions': 'Graphics Settings > Select app > Options > High performance',
                    'impact': 'High',
                    'category': 'Performance'
                },
                {
                    'title': 'Enable Resizable BAR',
                    'description': 'Enable Resizable BAR in BIOS for better GPU performance (if supported)',
                    'instructions': 'Check motherboard and GPU support, enable in BIOS',
                    'impact': 'Medium',
                    'category': 'Performance'
                }
            ]
        }
    
    def _get_ram_tweaks(self):
        """RAM-specific tweaks."""
        return [
            {
                'title': 'Enable XMP/DOCP Profile',
                'description': 'Enable XMP (Intel) or DOCP (AMD) in BIOS to run RAM at rated speed',
                'instructions': 'Enter BIOS/UEFI > Enable XMP/DOCP/EXPO profile',
                'impact': 'High',
                'category': 'Performance'
            },
            {
                'title': 'Adjust Virtual Memory',
                'description': 'Optimize page file size for your RAM capacity',
                'instructions': 'System Properties > Advanced > Performance Settings > Advanced > Virtual Memory',
                'impact': 'Medium',
                'category': 'Performance'
            },
            {
                'title': 'Disable Memory Compression (if sufficient RAM)',
                'description': 'Disable memory compression if you have 32GB+ RAM for slight performance gain',
                'instructions': 'Run PowerShell as admin: Disable-MMAgent -MemoryCompression (Recommended only for 32GB+ RAM)',
                'impact': 'Low',
                'category': 'Performance'
            },
            {
                'title': 'Clear Standby Memory',
                'description': 'Clear standby memory when RAM usage is high',
                'instructions': 'Use RAMMap or similar tools to clear standby memory',
                'impact': 'Low',
                'category': 'Maintenance'
            }
        ]
    
    def _get_storage_tweaks(self):
        """Storage-specific tweaks."""
        return {
            'ssd': [
                {
                    'title': 'Enable TRIM',
                    'description': 'Ensure TRIM is enabled for SSD longevity and performance',
                    'instructions': 'Run Command Prompt as admin: fsutil behavior query DisableDeleteNotify (should return 0)',
                    'impact': 'High',
                    'category': 'Performance'
                },
                {
                    'title': 'Disable Defragmentation',
                    'description': 'Disable scheduled defragmentation for SSDs (Windows optimizes automatically)',
                    'instructions': 'Defragment and Optimize Drives > Change settings > Verify SSD optimization',
                    'impact': 'High',
                    'category': 'Longevity'
                },
                {
                    'title': 'Enable Write Caching',
                    'description': 'Enable write caching for better SSD performance',
                    'instructions': 'Device Manager > Disk drives > Properties > Policies > Enable write caching',
                    'impact': 'Medium',
                    'category': 'Performance'
                },
                {
                    'title': 'Update SSD Firmware',
                    'description': 'Keep SSD firmware updated for optimal performance',
                    'instructions': 'Use manufacturer software (Samsung Magician, Crucial Storage Executive, etc.)',
                    'impact': 'Medium',
                    'category': 'Performance'
                }
            ],
            'hdd': [
                {
                    'title': 'Schedule Defragmentation',
                    'description': 'Regular defragmentation improves HDD performance',
                    'instructions': 'Defragment and Optimize Drives > Schedule weekly optimization',
                    'impact': 'High',
                    'category': 'Performance'
                },
                {
                    'title': 'Enable Write Caching',
                    'description': 'Enable write caching for better HDD performance',
                    'instructions': 'Device Manager > Disk drives > Properties > Policies > Enable write caching',
                    'impact': 'Medium',
                    'category': 'Performance'
                },
                {
                    'title': 'Disable Indexing on Large Drives',
                    'description': 'Disable indexing on storage drives (not OS drive)',
                    'instructions': 'Drive Properties > Uncheck "Allow files on this drive to have contents indexed"',
                    'impact': 'Low',
                    'category': 'Performance'
                }
            ]
        }
    
    def _get_windows_tweaks(self):
        """Windows-specific tweaks."""
        return [
            {
                'title': 'Disable Background Apps',
                'description': 'Prevent unnecessary apps from running in background',
                'instructions': 'Settings > Privacy > Background apps > Disable unnecessary apps',
                'impact': 'Medium',
                'category': 'Performance'
            },
            {
                'title': 'Disable Transparency Effects',
                'description': 'Disable transparency for better performance',
                'instructions': 'Settings > Personalization > Colors > Disable transparency effects',
                'impact': 'Low',
                'category': 'Performance'
            },
            {
                'title': 'Adjust Notification Settings',
                'description': 'Reduce distractions by limiting notifications',
                'instructions': 'Settings > System > Notifications > Disable unnecessary notifications',
                'impact': 'Low',
                'category': 'User Experience'
            },
            {
                'title': 'Disable Telemetry',
                'description': 'Reduce telemetry data collection',
                'instructions': 'Settings > Privacy > Diagnostics & feedback > Set to Basic',
                'impact': 'Low',
                'category': 'Privacy'
            }
        ]
    
    def get_relevant_tweaks(self, hardware_info):
        """Get tweaks relevant to detected hardware."""
        relevant_tweaks = {
            'basic': self.tweaks['basic'],
            'windows': self.tweaks['windows']
        }
        
        # CPU tweaks
        cpu_name = hardware_info.get('cpu', {}).get('name', '').lower()
        if 'intel' in cpu_name:
            relevant_tweaks['cpu'] = self.tweaks['cpu']['intel'] + self.tweaks['cpu']['general']
        elif 'amd' in cpu_name or 'ryzen' in cpu_name:
            relevant_tweaks['cpu'] = self.tweaks['cpu']['amd'] + self.tweaks['cpu']['general']
        else:
            relevant_tweaks['cpu'] = self.tweaks['cpu']['general']
        
        # GPU tweaks
        gpus = hardware_info.get('gpu', [])
        gpu_tweaks = []
        for gpu in gpus:
            gpu_name = gpu.get('name', '').lower()
            if 'nvidia' in gpu_name or 'geforce' in gpu_name:
                gpu_tweaks.extend(self.tweaks['gpu']['nvidia'])
            elif 'amd' in gpu_name or 'radeon' in gpu_name:
                gpu_tweaks.extend(self.tweaks['gpu']['amd'])
        gpu_tweaks.extend(self.tweaks['gpu']['general'])
        relevant_tweaks['gpu'] = gpu_tweaks
        
        # RAM tweaks
        relevant_tweaks['ram'] = self.tweaks['ram']
        
        # Storage tweaks - assume SSD for now (could be enhanced)
        relevant_tweaks['storage'] = self.tweaks['storage']['ssd'] + self.tweaks['storage']['hdd']
        
        return relevant_tweaks
