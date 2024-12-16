# Input file containing URLs (one per line)
$filePath = "C:\data\NPX_TEST\urls.txt"

# Output file for the results
$outputPath = "C:\data\NPX_TEST\output2.csv"
# Error log file
$errorLogPath = "C:\data\NPX_TEST\error.log"

# Prepare output array
$results = @()

# Check if the input file exists
if (-Not (Test-Path -Path $filePath)) {
    Write-Host "Input file not found at $filePath" -ForegroundColor Red
    exit
}

# Clear existing error log
if (Test-Path -Path $errorLogPath) {
    Clear-Content -Path $errorLogPath
}

Write-Host "Processing URLs from $filePath..."

# Read and validate each URL from the file
$urls = Get-Content -Path $filePath | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
$validatedUrls = $urls | Sort-Object -Unique | Where-Object { $_ -match "^(https?:\/\/)?[a-zA-Z0-9.-]+(\.[a-zA-Z]{2,})+$" }

# Log invalid URLs
$invalidUrls = $urls | Where-Object { $_ -notin $validatedUrls }
if ($invalidUrls) {
    $invalidUrls | ForEach-Object { Add-Content -Path $errorLogPath -Value "Invalid URL: $_" }
    Write-Host "Invalid URLs found. Check $errorLogPath for details." -ForegroundColor Yellow
}

# Process each validated URL
foreach ($url in $validatedUrls) {
    Write-Host "Processing URL: $url" -ForegroundColor Cyan
    try {
        # Resolve the URL to an IP address
        $ipRecords = Resolve-DnsName -Name $url -ErrorAction Stop | Where-Object { $_.QueryType -eq 'A' -or $_.QueryType -eq 'CNAME' }

        if ($ipRecords) {
            foreach ($record in $ipRecords) {
                $ipAddress = $record.IPAddress
                $ttl = $record.TTL
                $cname = if ($record.QueryType -eq 'CNAME') { $record.CName } else { 'N/A' }

                # Ping the IP address (if applicable)
                if ($ipAddress) {
                    $pingResult = Test-Connection -ComputerName $ipAddress -Count 1 -Quiet
                    $status = if ($pingResult) { "Reachable" } else { "Unreachable" }
                } else {
                    $ipAddress = "N/A"
                    $status = "CNAME Only"
                }

                # Add result to output array
                $results += [PSCustomObject]@{
                    URL        = $url
                    IPAddress  = $ipAddress
                    Status     = $status
                    TTL        = $ttl
                    CNAME      = $cname
                }
            }
        } else {
            $results += [PSCustomObject]@{
                URL        = $url
                IPAddress  = "N/A"
                Status     = "No IP Found"
                TTL        = "N/A"
                CNAME      = "N/A"
            }
        }
    } catch {
        # Handle errors
        $errorMessage = $_.Exception.Message
        $results += [PSCustomObject]@{
            URL        = $url
            IPAddress  = "Error"
            Status     = "Error: $errorMessage"
            TTL        = "N/A"
            CNAME      = "N/A"
        }
        Add-Content -Path $errorLogPath -Value "Error processing URL: $url - $errorMessage"
        Write-Host "Error processing URL: $url - $errorMessage" -ForegroundColor Yellow
    }
}

# Export results to CSV
$results | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8

Write-Host "Process completed. Results saved to $outputPath" -ForegroundColor Green
if (Test-Path -Path $errorLogPath) {
    Write-Host "Check $errorLogPath for any errors." -ForegroundColor Yellow
}
