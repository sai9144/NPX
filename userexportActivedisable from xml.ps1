# Define file paths
$inputFilePath = "C:\data\NPX_TEST\users.xml"  # Replace with your file path
$outputFilePath = "C:\data\NPX_TEST\output.csv"  # Replace with your desired output CSV path

# Load the XML file
[xml]$xmlContent = Get-Content -Path $inputFilePath

# Create an empty array to store the user data
$userData = @()

# Loop through each <webUser> element
foreach ($webUser in $xmlContent.webUsers.webUser) {
    # Extract the 'name' and 'enabled' values
    $name = $webUser.name
    $isActive = $webUser.enabled -eq "true"

    # Add the extracted data to the array
    $userData += [PSCustomObject]@{
        Name        = $name
        IsActive    = $isActive
    }
}

# Export the data to a CSV file
$userData | Export-Csv -Path $outputFilePath -NoTypeInformation -Encoding UTF8

Write-Host "Data exported to $outputFilePath successfully."
