@echo off
:: ═══════════════════════════════════════════════════════════
:: ADAMV TWEAKS — Build, Deploy & Package Script
:: ═══════════════════════════════════════════════════════════
::
:: Prerequisites:
::   - Qt 6.4+ installed with MSVC kit
::   - CMake on PATH
::   - Inno Setup 6 installed (for installer)
::   - 7-Zip installed (for portable exe)
::
:: Usage:
::   package.bat              — Build + deploy + create both packages
::   package.bat build        — Build only
::   package.bat deploy       — Run windeployqt only
::   package.bat installer    — Create installer only
::   package.bat portable     — Create portable exe only
::
:: ═══════════════════════════════════════════════════════════

setlocal enabledelayedexpansion

set "ROOT=%~dp0.."
set "BUILD_DIR=%ROOT%\build"
set "DEPLOY_DIR=%ROOT%\deploy"
set "DIST_DIR=%ROOT%\dist"
set "APP_NAME=ADAMV_TWEAKS"
set "APP_VERSION=5.0.0"
set "EXE_NAME=TweakApp.exe"

:: Detect tools
where cmake >nul 2>&1 || (echo ERROR: cmake not found on PATH & exit /b 1)

:: Find Qt installation
if defined Qt6_DIR (
    set "QT_BIN=%Qt6_DIR%\..\..\bin"
) else if defined QTDIR (
    set "QT_BIN=%QTDIR%\bin"
) else (
    for /f "delims=" %%i in ('where windeployqt 2^>nul') do set "QT_BIN=%%~dpi"
)
if not exist "%QT_BIN%\windeployqt.exe" (
    echo WARNING: windeployqt not found. Set Qt6_DIR or QTDIR, or add Qt bin to PATH.
)

:: Default: do everything
set "DO_BUILD=1"
set "DO_DEPLOY=1"
set "DO_INSTALLER=1"
set "DO_PORTABLE=1"

if "%1"=="build"     (set DO_DEPLOY=0& set DO_INSTALLER=0& set DO_PORTABLE=0)
if "%1"=="deploy"    (set DO_BUILD=0& set DO_INSTALLER=0& set DO_PORTABLE=0)
if "%1"=="installer" (set DO_BUILD=0& set DO_DEPLOY=0& set DO_PORTABLE=0)
if "%1"=="portable"  (set DO_BUILD=0& set DO_DEPLOY=0& set DO_INSTALLER=0)

echo.
echo  ╔══════════════════════════════════════╗
echo  ║     ADAMV TWEAKS Package Builder     ║
echo  ╚══════════════════════════════════════╝
echo.

:: ── Step 1: Build ──
if "%DO_BUILD%"=="1" (
    echo [1/4] Building Release...
    if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
    pushd "%BUILD_DIR%"
    cmake .. -DCMAKE_BUILD_TYPE=Release
    cmake --build . --config Release
    popd
    if not exist "%BUILD_DIR%\Release\%EXE_NAME%" (
        if not exist "%BUILD_DIR%\%EXE_NAME%" (
            echo ERROR: Build failed - %EXE_NAME% not found
            exit /b 1
        )
    )
    echo [OK] Build complete
) else (
    echo [SKIP] Build
)

:: ── Step 2: Deploy (windeployqt) ──
if "%DO_DEPLOY%"=="1" (
    echo [2/4] Deploying with windeployqt...
    if exist "%DEPLOY_DIR%" rmdir /s /q "%DEPLOY_DIR%"
    mkdir "%DEPLOY_DIR%"

    :: Copy the exe
    if exist "%BUILD_DIR%\Release\%EXE_NAME%" (
        copy /y "%BUILD_DIR%\Release\%EXE_NAME%" "%DEPLOY_DIR%\" >nul
    ) else (
        copy /y "%BUILD_DIR%\%EXE_NAME%" "%DEPLOY_DIR%\" >nul
    )

    :: Run windeployqt
    "%QT_BIN%\windeployqt.exe" ^
        --release ^
        --no-opengl-sw ^
        --no-system-d3d-compiler ^
        --no-compiler-runtime ^
        "%DEPLOY_DIR%\%EXE_NAME%"

    :: Copy VC++ redist if available
    if exist "%VCToolsRedistDir%\vc_redist.x64.exe" (
        copy /y "%VCToolsRedistDir%\vc_redist.x64.exe" "%DEPLOY_DIR%\" >nul
        echo    Bundled VC++ Redistributable
    )

    echo [OK] Deploy complete - %DEPLOY_DIR%
) else (
    echo [SKIP] Deploy
)

:: ── Step 3: Installer (Inno Setup) ──
if "%DO_INSTALLER%"=="1" (
    echo [3/4] Creating installer...
    if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"

    set "ISCC="
    if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" set "ISCC=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
    if exist "C:\Program Files\Inno Setup 6\ISCC.exe" set "ISCC=C:\Program Files\Inno Setup 6\ISCC.exe"

    if defined ISCC (
        "!ISCC!" "%ROOT%\installer\setup.iss"
        if exist "%DIST_DIR%\%APP_NAME%_Setup_%APP_VERSION%.exe" (
            echo [OK] Installer created: dist\%APP_NAME%_Setup_%APP_VERSION%.exe
        ) else (
            echo WARNING: Installer compilation may have failed
        )
    ) else (
        echo WARNING: Inno Setup 6 not found. Install from https://jrsoftware.org/isinfo.php
        echo    Then run: "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\setup.iss
    )
) else (
    echo [SKIP] Installer
)

:: ── Step 4: Portable single-exe (7-Zip SFX) ──
if "%DO_PORTABLE%"=="1" (
    echo [4/4] Creating portable exe...
    if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"

    set "SEVENZIP="
    if exist "C:\Program Files\7-Zip\7z.exe" set "SEVENZIP=C:\Program Files\7-Zip\7z.exe"
    if exist "C:\Program Files (x86)\7-Zip\7z.exe" set "SEVENZIP=C:\Program Files (x86)\7-Zip\7z.exe"

    if defined SEVENZIP (
        :: Create 7z archive from deploy folder
        "!SEVENZIP!" a -t7z -mx=9 -mf=BCJ2 "%DIST_DIR%\%APP_NAME%_temp.7z" "%DEPLOY_DIR%\*" >nul

        :: Create SFX config (auto-extract + run)
        (
            echo ;!@Install@!UTF-8!
            echo Title="ADAMV TWEAKS"
            echo BeginPrompt="Launch ADAMV TWEAKS?"
            echo RunProgram="%EXE_NAME%"
            echo ExtractDialogText="Extracting ADAMV TWEAKS..."
            echo ExtractPathText="Temporary folder"
            echo ExtractTitle="ADAMV TWEAKS"
            echo GUIFlags="8+32+64+4096"
            echo GUIMode="1"
            echo OverwriteMode="2"
            echo ;!@InstallEnd@!
        ) > "%DIST_DIR%\sfx_config.txt"

        :: Find 7-Zip SFX module
        set "SFX_MODULE="
        if exist "C:\Program Files\7-Zip\7zSD.sfx" set "SFX_MODULE=C:\Program Files\7-Zip\7zSD.sfx"
        if exist "C:\Program Files (x86)\7-Zip\7zSD.sfx" set "SFX_MODULE=C:\Program Files (x86)\7-Zip\7zSD.sfx"

        if defined SFX_MODULE (
            :: Combine: SFX module + config + archive = single exe
            copy /b "!SFX_MODULE!" + "%DIST_DIR%\sfx_config.txt" + "%DIST_DIR%\%APP_NAME%_temp.7z" "%DIST_DIR%\%APP_NAME%_Portable_%APP_VERSION%.exe" >nul
            del "%DIST_DIR%\%APP_NAME%_temp.7z" >nul 2>&1
            del "%DIST_DIR%\sfx_config.txt" >nul 2>&1
            echo [OK] Portable exe: dist\%APP_NAME%_Portable_%APP_VERSION%.exe
        ) else (
            echo WARNING: 7zSD.sfx not found. The portable exe requires 7-Zip Extra.
            echo    Download from: https://7-zip.org/download.html (7-Zip Extra)
            ren "%DIST_DIR%\%APP_NAME%_temp.7z" "%APP_NAME%_Portable_%APP_VERSION%.7z"
            echo    Created .7z archive instead: dist\%APP_NAME%_Portable_%APP_VERSION%.7z
        )
    ) else (
        echo WARNING: 7-Zip not found. Install from https://7-zip.org
    )
) else (
    echo [SKIP] Portable
)

echo.
echo  ══════════════════════════════════════
echo  Done! Check the dist\ folder:
if exist "%DIST_DIR%\%APP_NAME%_Setup_%APP_VERSION%.exe" echo    Installer: %APP_NAME%_Setup_%APP_VERSION%.exe
if exist "%DIST_DIR%\%APP_NAME%_Portable_%APP_VERSION%.exe" echo    Portable:  %APP_NAME%_Portable_%APP_VERSION%.exe
echo  ══════════════════════════════════════
echo.

endlocal
