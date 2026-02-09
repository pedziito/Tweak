cmake_minimum_required(VERSION 3.21)
project(Tweak LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Widgets Concurrent)

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
)

qt_add_qml_module(TweakApp
    URI Tweak
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/HardwarePanel.qml
        qml/QuickActionsPanel.qml
        qml/StartupPanel.qml
        qml/TweakCard.qml
        qml/CategoryFilter.qml
        qml/Cs2PathDialog.qml
        qml/PerformanceGraph.qml
)

target_include_directories(TweakApp PRIVATE src)

target_link_libraries(TweakApp PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Widgets
    Qt6::Concurrent
)

if (WIN32)
    target_link_libraries(TweakApp PRIVATE wbemuuid ole32 oleaut32 shell32)
endif()

# Copy QML files for development convenience
if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_custom_command(TARGET TweakApp POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_SOURCE_DIR}/qml
        $<TARGET_FILE_DIR:TweakApp>/qml
    )
endif()
