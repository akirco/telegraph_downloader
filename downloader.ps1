# Define function to download images
function DownloadImages($url) {
    # Suppress error messages
    $ErrorActionPreference = 'SilentlyContinue'

    # Download JSON data from URL
    $WebJSONData = Invoke-WebRequest -Uri $url -ErrorAction SilentlyContinue -UseBasicParsing

    # Extract title and image URLs from JSON data
    $Title = (ConvertFrom-Json $WebJSONData.Content).result.title
    $Images = (ConvertFrom-Json $WebJSONData.Content).result.content

    # Create directory for images
    $StorePath = ".\Images\$Title"
    
    $StratPrefix = "https://telegra.ph"
    if (Test-Path $StorePath) {
        return
    }
    else {
        New-Item -ItemType Directory -Path $StorePath > $null
    }

    # Download images
    $Images | ForEach-Object {
        if ($null -eq $_.children -or $_.children.Length -eq 0) {
            Write-Host "Null file..." -ForegroundColor Red
        }
        else {
            $ImageUrl = $_.children[0].attrs.src
            if ($ImageUrl) {
                $ImageName = $ImageUrl.replace("/file/", "")
                $OUTPUT = Join-Path $StorePath $ImageName
                Write-Host "downloading:" $StratPrefix$ImageUrl -ForegroundColor Magenta -NoNewline 
                Write-Host "  |Path to: $OUTPUT" -ForegroundColor DarkGreen

                # Download image using Invoke-WebRequest and -OutBuffer
                try {
                    Invoke-WebRequest -Uri $StratPrefix$ImageUrl -OutFile "$OUTPUT" -ErrorAction Stop -UseBasicParsing -OutBuffer 65536
                }
                catch {
                    Write-Host "Error downloading image: $_" -ForegroundColor Red
                }
            }
            else {
                Write-Host "Null file..." -ForegroundColor Red
            }
        }

    }
}