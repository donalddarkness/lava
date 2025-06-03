# Script to update Swift to version 6.2 using Scoop

Write-Host "[Swift] Checking current Swift version..."
swift --version

Write-Host "[Swift] Updating Swift using Scoop..."
scoop update swift

Write-Host "[Swift] Verifying Swift version after update..."
swift --version

Write-Host "[Swift] Done."
