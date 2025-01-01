# Execute check_env.ps1 and capture its return code
./build/check_env.ps1
$returnCode = $LASTEXITCODE

# Check if the return code indicates failure
if ($returnCode -ne 0) {
    Write-Host "ERROR: Environment check failed. Exiting." -ForegroundColor Red
    exit $returnCode
}

# Proceed if check_env.ps1 succeeded
./build/apply_phase_1.ps1
./build/apply_phase_2.ps1
./build/apply_phase_3.ps1

Write-Host "NOTE: Validating Build"
./validate.ps1
