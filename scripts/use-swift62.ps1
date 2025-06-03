# Script to switch to Swift 6.2 environment for building and testing

Write-Host "[Swift] Setting up environment for Swift 6.2..."

# Set the SDKROOT to use the 6.2.0 platform
$env:SDKROOT = "C:\Users\cbksh\AppData\Local\Programs\Swift\Platforms\6.2.0\Windows.platform\Developer\SDKs\Windows.sdk"

Write-Host "[Swift] SDKROOT now set to: $env:SDKROOT"

# Clean previous build artifacts
Write-Host "[Swift] Cleaning previous build artifacts..."
Remove-Item -Recurse -Force .\.build -ErrorAction SilentlyContinue

# Try a clean build
Write-Host "[Swift] Building with Swift 6.2..."
if ($args.Count -eq 0) {
    # Default to building
    swift build
} else {
    # Pass through any arguments
    swift $args
}

Write-Host "[Swift] Done."
