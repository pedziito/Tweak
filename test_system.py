"""
Simple test script to verify the PC Tweaks system works correctly
"""

import sys
from hardware_detector import HardwareDetector
from tweaks_database import TweaksDatabase


def test_hardware_detection():
    """Test hardware detection functionality."""
    print("Testing hardware detection...")
    detector = HardwareDetector()
    hardware_info = detector.detect_all()
    
    # Check that all components were detected
    assert 'cpu' in hardware_info, "CPU not detected"
    assert 'gpu' in hardware_info, "GPU not detected"
    assert 'ram' in hardware_info, "RAM not detected"
    assert 'storage' in hardware_info, "Storage not detected"
    assert 'motherboard' in hardware_info, "Motherboard not detected"
    assert 'os' in hardware_info, "OS not detected"
    
    print("✓ Hardware detection test passed")
    return hardware_info


def test_tweaks_database():
    """Test tweaks database functionality."""
    print("Testing tweaks database...")
    db = TweaksDatabase()
    
    # Check that all tweak categories exist
    assert 'basic' in db.tweaks, "Basic tweaks not found"
    assert 'cpu' in db.tweaks, "CPU tweaks not found"
    assert 'gpu' in db.tweaks, "GPU tweaks not found"
    assert 'ram' in db.tweaks, "RAM tweaks not found"
    assert 'storage' in db.tweaks, "Storage tweaks not found"
    assert 'windows' in db.tweaks, "Windows tweaks not found"
    
    # Check that basic tweaks have content
    assert len(db.tweaks['basic']) > 0, "No basic tweaks found"
    
    print("✓ Tweaks database test passed")
    return db


def test_relevant_tweaks(hardware_info, db):
    """Test getting relevant tweaks for detected hardware."""
    print("Testing relevant tweaks retrieval...")
    relevant_tweaks = db.get_relevant_tweaks(hardware_info)
    
    # Check that relevant tweaks were generated
    assert 'basic' in relevant_tweaks, "Basic tweaks not in relevant tweaks"
    assert 'cpu' in relevant_tweaks, "CPU tweaks not in relevant tweaks"
    assert 'gpu' in relevant_tweaks, "GPU tweaks not in relevant tweaks"
    
    print("✓ Relevant tweaks test passed")
    return relevant_tweaks


def main():
    """Run all tests."""
    print("=" * 70)
    print("PC TWEAKS SYSTEM - TEST SUITE")
    print("=" * 70)
    print()
    
    try:
        hardware_info = test_hardware_detection()
        print()
        
        db = test_tweaks_database()
        print()
        
        relevant_tweaks = test_relevant_tweaks(hardware_info, db)
        print()
        
        print("=" * 70)
        print("ALL TESTS PASSED!")
        print("=" * 70)
        print()
        print("Sample detected hardware:")
        print(f"  CPU: {hardware_info['cpu'].get('name', 'Unknown')}")
        print(f"  RAM: {hardware_info['ram'].get('total', 'Unknown')}")
        print(f"  OS: {hardware_info['os'].get('name', 'Unknown')}")
        print()
        print(f"Total relevant tweaks: {sum(len(v) for v in relevant_tweaks.values() if isinstance(v, list))}")
        print()
        return 0
        
    except AssertionError as e:
        print()
        print(f"TEST FAILED: {e}")
        return 1
    except Exception as e:
        print()
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
