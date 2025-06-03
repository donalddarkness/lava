# Script to set correct Swift environment variables for testing

Write-Host "[Swift] Setting up environment for Swift 6.1..."

# Set the SDKROOT to use the 6.1.0 platform
$env:SDKROOT = "C:\Users\cbksh\AppData\Local\Programs\Swift\Platforms\6.1.0\Windows.platform\Developer\SDKs\Windows.sdk"

Write-Host "[Swift] SDKROOT now set to: $env:SDKROOT"

# Try running the tests with the updated environment
Write-Host "[Swift] Attempting to run tests..."
Set-Location -Path "d:\Projects\lava"
swift test --filter OuroLangCoreTests/SemanticAnalyzerTests

Write-Host "[Swift] Done."
