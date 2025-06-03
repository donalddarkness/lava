# Script to check Swift installation details

Write-Host "Swift Version Information:"
swift --version

Write-Host "`nSDK Root Environment Variable:"
Write-Host $env:SDKROOT

Write-Host "`nScoop Swift Installation Details:"
scoop info swift

Write-Host "`nSwift Platforms Directory:"
Get-ChildItem 'C:\Users\cbksh\AppData\Local\Programs\Swift\Platforms' -Recurse -Depth 1

Write-Host "`nSDK Locations:"
$platform0 = "C:\Users\cbksh\AppData\Local\Programs\Swift\Platforms\0.0.0\Windows.platform\Developer\SDKs\Windows.sdk"
$platform61 = "C:\Users\cbksh\AppData\Local\Programs\Swift\Platforms\6.1.0\Windows.platform\Developer\SDKs\Windows.sdk"

Write-Host "0.0.0 SDK exists: $(Test-Path $platform0)"
Write-Host "6.1.0 SDK exists: $(Test-Path $platform61)"

Write-Host "`nTrying to use the newer SDK path explicitly:"
$env:SDKROOT = $platform61
Write-Host "SDKROOT now set to: $env:SDKROOT"

Write-Host "`nChecking Swift configuration:"
swift package config
