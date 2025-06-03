# PowerShell script to fully clean and rebuild the Lava workspace on Windows
# Usage: ./clean-build.ps1

Write-Host "[Lava] Terminating Swift and SourceKit processes..."
# force-stop any running SwiftPM, compiler or language server processes
Stop-Process -Name swiftc, swift, sourcekit-lsp -Force -ErrorAction SilentlyContinue

Write-Host "[Lava] Removing workspace .build directory..."
Remove-Item -Recurse -Force .\.build -ErrorAction SilentlyContinue

Write-Host "[Lava] Clearing global SwiftPM cache..."
Remove-Item -Recurse -Force "$env:USERPROFILE\.swiftpm" -ErrorAction SilentlyContinue

Write-Host "[Lava] Rebuilding project in debug configuration..."
swift build -c debug
Write-Host "[Lava] Build complete." 