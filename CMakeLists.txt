cmake_minimum_required(VERSION 3.21)
project(Tweak LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Widgets Concurrent WebEngineWidgets WebChannel Network)

qt_standard_project_setup()

qt_add_executable(TweakApp
    WIN32
    src/main.cpp
    src/app/AppController.cpp
    src/app/HardwareDetector.cpp
    src/app/TweakEngine.cpp
    src/app/TweakListModel.cpp
    src/app/StartupScanner.cpp
    src/app/RegistryUtil.cpp
    src/app/PowerUtil.cpp
    src/app/UacHelper.cpp
    src/app/SettingsManager.cpp
    src/app/BenchmarkEngine.cpp
    src/app/SystemMonitor.cpp
    src/app/HardwareScorer.cpp
    src/app/GameBenchmark.cpp
    src/app/ConfigManager.cpp
    src/app/WebBridge.cpp
    src/app/LicenseManager.cpp
)

qt_add_resources(TweakApp "web"
    PREFIX "/"
    FILES
        web/index.html
)

target_include_directories(TweakApp PRIVATE src)

target_link_libraries(TweakApp PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Concurrent
    Qt6::WebEngineWidgets
    Qt6::WebChannel
    Qt6::Network
)

if (WIN32)
    target_link_libraries(TweakApp PRIVATE wbemuuid ole32 oleaut32 shell32)
endif()
