# Check if the script is run with an argument
if ($args.Count -ne 1) {
    Write-Host "Usage: .\test_candidates.ps1 <base_url>"
    exit 1
}

# Get the base URL from the command line argument
$base_url = $args[0]

# Ensure the base_url starts with "http:" or "https:"
if (-not ($base_url -like "http:*" -or $base_url -like "https:*")) {
    $base_url = "http://$base_url"
}

function Test-Endpoint {
    param (
        [string]$Url,
        [string]$SuccessMessage,
        [string]$ErrorMessage,
        [string]$Method = "GET",
        [string]$Body = $null
    )

    try {
        # Set up request parameters
        $params = @{
            Uri         = $Url
            Method      = $Method
            ErrorAction = "Stop"
        }

        # Only include -Body for non-GET methods
        if ($Method -ne "GET" -and $Body) {
            $params.Body = $Body
        }

        # Make the request
        $response = Invoke-WebRequest @params

        if ($response.StatusCode -eq 200) {
            Write-Host "$SuccessMessage" -ForegroundColor Green
        } else {
            throw "HTTP Status Code: $($response.StatusCode)"
        }
    } catch {
        # Capture server response if available
        $errorContent = $_.Exception.Response.Content
        if ($errorContent) {
            Write-Host "${ErrorMessage}: $errorContent" -ForegroundColor Red
        } else {
            Write-Host "${ErrorMessage}: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Test the /gtg endpoint
Test-Endpoint -Url "$base_url/gtg" `
              -SuccessMessage "good to go passed" `
              -ErrorMessage "good to go failed"

# Test the /candidate/John%20Smith endpoint with POST method
Test-Endpoint -Url "$base_url/candidate/John%20Smith" `
              -Method "POST" `
              -SuccessMessage "insert passed" `
              -ErrorMessage "insert failed"

# Test the /candidate/John%20Smith endpoint with GET method
Test-Endpoint -Url "$base_url/candidate/John%20Smith" `
              -SuccessMessage "verification passed" `
              -ErrorMessage "verification failed"

# Test the /candidates endpoint
Test-Endpoint -Url "$base_url/candidates" `
              -SuccessMessage "candidate list passed" `
              -ErrorMessage "candidate list failed"
