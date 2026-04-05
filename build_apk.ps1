# AuraPlan AI -- Fully Automated Setup & APK Builder
# Installs Flutter SDK, JDK 21, Android SDK automatically -- no manual steps
# Usage:  .\build_apk.ps1   (run from D:\Planner APP\)
# Tip:    .\build_apk.ps1 -Force    to re-download tools even if already present

param([switch]$Force)

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# -- Paths -------------------------------------------------------------------
$FLUTTER_DIR     = "C:\flutter"
$JDK_DIR         = "C:\jdk21"
$ANDROID_SDK_DIR = "C:\android-sdk"
$PROJECT_DIR     = "D:\Planner APP\auraplan_flutter"
$FLUTTER_EXE     = "$FLUTTER_DIR\bin\flutter.bat"
$SDKMANAGER      = "$ANDROID_SDK_DIR\cmdline-tools\latest\bin\sdkmanager.bat"

# -- Helpers -----------------------------------------------------------------
function Write-Step([string]$msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-OK([string]$msg)   { Write-Host "    $msg" -ForegroundColor Green }
function Write-Warn([string]$msg) { Write-Host "    WARNING: $msg" -ForegroundColor Yellow }
function Fail([string]$msg)       { Write-Host "`n    ERROR: $msg" -ForegroundColor Red; exit 1 }

function Add-ToPath([string]$dir) {
    if ($env:Path -notlike "*$dir*") { $env:Path = "$dir;$env:Path" }
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$dir*") {
        [Environment]::SetEnvironmentVariable("Path", "$dir;$userPath", "User")
    }
}

function Download-File([string]$url, [string]$dest, [string]$label) {
    Write-Host "    Downloading $label ..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest $url -OutFile $dest -TimeoutSec 900
    } catch {
        Fail "Download of $label failed: $_"
    }
    Write-OK "Download complete: $label"
}

# -- Banner ------------------------------------------------------------------
Write-Host ""
Write-Host "================================================" -ForegroundColor Magenta
Write-Host "   AuraPlan AI  --  Auto Setup + APK Builder   " -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  This script will automatically install:" -ForegroundColor White
Write-Host "    Flutter SDK 3.41.6  (~700 MB)" -ForegroundColor Gray
Write-Host "    Amazon Corretto JDK 21  (~190 MB)" -ForegroundColor Gray
Write-Host "    Android SDK + build tools  (~400 MB)" -ForegroundColor Gray
Write-Host ""
Write-Host "  Total download: ~1.3 GB  (skipped if already installed)" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# STEP 1 -- Flutter SDK
# ============================================================================
Write-Step "STEP 1/8 -- Flutter SDK"

if ($Force -or -not (Test-Path $FLUTTER_EXE)) {
    $flutterZip = "$env:TEMP\flutter_sdk.zip"
    Download-File `
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.41.6-stable.zip" `
        $flutterZip "Flutter 3.41.6 SDK"

    Write-Host "    Extracting Flutter to C:\ (may take ~2 min)..." -ForegroundColor Yellow
    if (Test-Path $FLUTTER_DIR) { Remove-Item $FLUTTER_DIR -Recurse -Force }
    Expand-Archive $flutterZip -DestinationPath "C:\" -Force
    Remove-Item $flutterZip -ErrorAction SilentlyContinue
    Write-OK "Flutter installed at $FLUTTER_DIR"
} else {
    Write-OK "Flutter already installed -- skipping download"
}

Add-ToPath "$FLUTTER_DIR\bin"

# ============================================================================
# STEP 2 -- JDK 21 (Amazon Corretto)
# ============================================================================
Write-Step "STEP 2/8 -- JDK 21 (Amazon Corretto)"

if ($Force -or -not (Test-Path "$JDK_DIR\bin\java.exe")) {
    $jdkZip = "$env:TEMP\corretto21.zip"
    Download-File `
        "https://corretto.aws/downloads/latest/amazon-corretto-21-x64-windows-jdk.zip" `
        $jdkZip "Amazon Corretto JDK 21"

    Write-Host "    Extracting JDK..." -ForegroundColor Yellow
    $tmpJdk = "$env:TEMP\jdk21_tmp"
    if (Test-Path $tmpJdk) { Remove-Item $tmpJdk -Recurse -Force }
    Expand-Archive $jdkZip -DestinationPath $tmpJdk -Force

    $innerDir = Get-ChildItem $tmpJdk -Directory | Select-Object -First 1
    if (-not $innerDir) { Fail "JDK extraction failed - inner directory not found" }

    if (Test-Path $JDK_DIR) { Remove-Item $JDK_DIR -Recurse -Force }
    Move-Item $innerDir.FullName $JDK_DIR -Force
    Remove-Item $jdkZip          -ErrorAction SilentlyContinue
    Remove-Item $tmpJdk -Recurse -ErrorAction SilentlyContinue
    Write-OK "JDK 21 installed at $JDK_DIR"
} else {
    Write-OK "JDK 21 already installed -- skipping download"
}

$env:JAVA_HOME = $JDK_DIR
[Environment]::SetEnvironmentVariable("JAVA_HOME", $JDK_DIR, "User")
Add-ToPath "$JDK_DIR\bin"

# ============================================================================
# STEP 3 -- Android cmdline-tools
# ============================================================================
Write-Step "STEP 3/8 -- Android SDK command-line tools"

if ($Force -or -not (Test-Path $SDKMANAGER)) {
    $toolsZip = "$env:TEMP\android_cmdtools.zip"
    Download-File `
        "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip" `
        $toolsZip "Android cmdline-tools"

    Write-Host "    Extracting Android tools..." -ForegroundColor Yellow
    $tmpTools = "$env:TEMP\cmdtools_tmp"
    if (Test-Path $tmpTools) { Remove-Item $tmpTools -Recurse -Force }
    Expand-Archive $toolsZip -DestinationPath $tmpTools -Force

    $latestDir = "$ANDROID_SDK_DIR\cmdline-tools\latest"
    New-Item -ItemType Directory -Force -Path $latestDir | Out-Null
    Copy-Item "$tmpTools\cmdline-tools\*" $latestDir -Recurse -Force
    Remove-Item $toolsZip          -ErrorAction SilentlyContinue
    Remove-Item $tmpTools -Recurse -ErrorAction SilentlyContinue
    Write-OK "Android cmdline-tools installed at $ANDROID_SDK_DIR"
} else {
    Write-OK "Android cmdline-tools already installed -- skipping download"
}

$env:ANDROID_HOME     = $ANDROID_SDK_DIR
$env:ANDROID_SDK_ROOT = $ANDROID_SDK_DIR
[Environment]::SetEnvironmentVariable("ANDROID_HOME",     $ANDROID_SDK_DIR, "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $ANDROID_SDK_DIR, "User")
Add-ToPath "$ANDROID_SDK_DIR\cmdline-tools\latest\bin"
Add-ToPath "$ANDROID_SDK_DIR\platform-tools"

# ============================================================================
# STEP 4 -- Accept Android licenses + install SDK packages
# ============================================================================
Write-Step "STEP 4/8 -- Android SDK packages (platform-tools, android-34, build-tools)"

$needPackages = $Force -or -not (Test-Path "$ANDROID_SDK_DIR\platforms\android-34")
if ($needPackages) {
    Write-Host "    Writing Android SDK license files..." -ForegroundColor Yellow

    $licDir = "$ANDROID_SDK_DIR\licenses"
    New-Item -ItemType Directory -Force -Path $licDir | Out-Null
    Set-Content "$licDir\android-sdk-license"         "`n24333f8a63b6825ea9c5514f83c2829b004d1fee`n8933bad161af4178b1185d1a37fbf41ea5269c55"
    Set-Content "$licDir\android-sdk-preview-license" "`n84831b9409646a918e30573bab4c9c91346d8abd"
    Set-Content "$licDir\intel-android-extra-license"  "`nd975f751698a77b662f1254ddbeed3901e976f5a"

    Write-Host "    Installing platform-tools, android-34, build-tools 34.0.0..." -ForegroundColor Yellow
    & $SDKMANAGER --sdk_root="$ANDROID_SDK_DIR" "platform-tools" "platforms;android-34" "build-tools;34.0.0" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "sdkmanager returned non-zero -- will try to continue"
    }
    Write-OK "Android SDK packages installed."
} else {
    Write-OK "Android SDK packages already present -- skipping"
}

# ============================================================================
# STEP 5 -- Configure Flutter + accept Flutter Android licenses
# ============================================================================
Write-Step "STEP 5/8 -- Configuring Flutter for Android SDK"

& $FLUTTER_EXE config --android-sdk "$ANDROID_SDK_DIR" --no-analytics 2>&1 | Out-Null
"y`ny`ny`ny`ny`n" | & $FLUTTER_EXE doctor --android-licenses 2>&1 | Out-Null
Write-OK "Flutter configured."

# ============================================================================
# STEP 6 -- Create Flutter project skeleton (android/ folder)
# ============================================================================
Write-Step "STEP 6/8 -- Flutter project init"

if (-not (Test-Path "$PROJECT_DIR\android")) {
    Write-Host "    Running flutter create to generate android/ folder..." -ForegroundColor Yellow
    $savedDir = $PWD
    Set-Location "D:\Planner APP"
    & $FLUTTER_EXE create --org com.auraplan --project-name auraplan_ai --platforms android auraplan_flutter_temp 2>&1

    if (-not (Test-Path "auraplan_flutter_temp\android")) {
        Fail "flutter create failed. Run: & '$FLUTTER_EXE' doctor -v"
    }
    Copy-Item -Recurse -Force "auraplan_flutter_temp\android" "$PROJECT_DIR\android"
    if (Test-Path "auraplan_flutter_temp\test") {
        Copy-Item -Recurse -Force "auraplan_flutter_temp\test" "$PROJECT_DIR\test"
    }
    Remove-Item -Recurse -Force "auraplan_flutter_temp"
    Set-Location $savedDir
    Write-OK "Flutter android/ folder created."
} else {
    Write-OK "Flutter project already has android/ folder -- skipping"
}

# ============================================================================
# STEP 7 -- Copy assets, patch AndroidManifest + build.gradle
# ============================================================================
Write-Step "STEP 7/8 -- Copying assets & patching project files"

# Assets
New-Item -ItemType Directory -Force "$PROJECT_DIR\assets" | Out-Null
$htmlSrc = "D:\Planner APP\stitch_planner_app\index.html"
$logoSrc = "D:\Planner APP\stitch_planner_app\logo.png"

if (Test-Path $htmlSrc) {
    Copy-Item -Force $htmlSrc "$PROJECT_DIR\assets\index.html"
    Write-OK "Copied index.html"
} else { Fail "index.html not found at $htmlSrc" }

if (Test-Path $logoSrc) {
    Copy-Item -Force $logoSrc "$PROJECT_DIR\assets\logo.png"
    Write-OK "Copied logo.png"
}

# AndroidManifest
$manifestDest = "$PROJECT_DIR\android\app\src\main\AndroidManifest.xml"
$manifestSrc  = "$PROJECT_DIR\android_manifest_replace\AndroidManifest.xml"
if (Test-Path $manifestSrc) {
    Copy-Item -Force $manifestSrc $manifestDest
    Write-OK "AndroidManifest.xml replaced"
} else { Write-Warn "Custom AndroidManifest not found -- using default" }

# build.gradle -- minSdk 21, targetSdk 34
$gradlePath = "$PROJECT_DIR\android\app\build.gradle"
if (Test-Path $gradlePath) {
    $g = Get-Content $gradlePath -Raw
    $g = $g -replace 'minSdkVersion\s+\d+',     'minSdkVersion 21'
    $g = $g -replace 'targetSdkVersion\s+\d+',  'targetSdkVersion 34'
    $g = $g -replace 'compileSdkVersion\s+\d+', 'compileSdkVersion 34'
    $g = $g -replace 'minSdk\s*=\s*\d+',     'minSdk = 21'
    $g = $g -replace 'targetSdk\s*=\s*\d+',  'targetSdk = 34'
    $g = $g -replace 'compileSdk\s*=\s*\d+', 'compileSdk = 34'
    Set-Content $gradlePath $g -NoNewline
    Write-OK "build.gradle patched (minSdk=21, targetSdk=34)"
} else { Write-Warn "build.gradle not found -- the build may still work" }

# ============================================================================
# STEP 8 -- flutter pub get + build APK
# ============================================================================
Write-Step "STEP 8/8 -- Building APK"

Set-Location $PROJECT_DIR

Write-Host "    Running flutter pub get..." -ForegroundColor Yellow
& $FLUTTER_EXE pub get 2>&1
if ($LASTEXITCODE -ne 0) { Fail "flutter pub get failed. Check internet and try again." }

Write-Host ""
Write-Host "    Building release APK (first build downloads Gradle ~5 min)..." -ForegroundColor Yellow
Write-Host ""
& $FLUTTER_EXE build apk --release --split-per-abi 2>&1

if ($LASTEXITCODE -eq 0) {
    $apkPath = "$PROJECT_DIR\build\app\outputs\flutter-apk"
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "   SUCCESS!  APKs built successfully           " -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Location: $apkPath" -ForegroundColor White
    Write-Host ""
    Write-Host "  app-arm64-v8a-release.apk    <- modern phones (recommended)" -ForegroundColor Cyan
    Write-Host "  app-armeabi-v7a-release.apk  <- older 32-bit phones" -ForegroundColor Cyan
    Write-Host "  app-x86_64-release.apk       <- emulators / Intel CPUs" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Install on a connected phone:" -ForegroundColor Yellow
    Write-Host "  adb install `"$apkPath\app-arm64-v8a-release.apk`""
    Write-Host ""
    if (Test-Path $apkPath) { explorer $apkPath }
} else {
    Write-Host ""
    Write-Host "  Build failed. Run flutter doctor for details:" -ForegroundColor Red
    Write-Host "  & '$FLUTTER_EXE' doctor -v" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Common fixes:" -ForegroundColor Yellow
    Write-Host "    - Re-run with -Force to re-install tools"
    Write-Host "    - Make sure you are connected to the internet"
    exit 1
}