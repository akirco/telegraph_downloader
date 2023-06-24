# Specifies a path to one or more locations.

param (
    [Parameter(Mandatory = $False)]
    [String] $PaserFile
)    

function DownTelegraph {
    if ($PaserFile) {
        Select-String -Path $PaserFile -Pattern "https://telegra.ph/" -AllMatches  | 
        Select-Object Line -Unique | 
        Format-Table -HideTableHeaders | 
        Out-String | 
        Set-Content .\TEMP
    }
    else {
        <# Action when all if and elseif conditions are false #>
        Write-Host "Please enter the named `Result` json file path..." -ForegroundColor DarkCyan
    } 
    if (Test-Path .\TEMP) {
        $URLS = (Get-Content -Path .\TEMP).Split("\n").Trim()

        $Target = @()
        $EndPrefix = "?return_content=true"
        
        $URLS | ForEach-Object {
    
            if ($_.contains('"text":')) {
                $Target += $_.replace('"text":', "").replace('telegra.ph', "api.telegra.ph/getPage").replace('"', "") + $EndPrefix
            }

            if ($_.contains('"href":')) {
                $Target += $_.replace('"href":', "").replace('telegra.ph', "api.telegra.ph/getPage").replace('"', "") + $EndPrefix
            }

        }
        # Download images in parallel using -AsJob
        $Target | ForEach-Object -Parallel {
            $url = $_
            # Suppress error messages
            $ErrorActionPreference = 'SilentlyContinue'

            # Download JSON data from URL
            $WebJSONData = Invoke-WebRequest -Uri $url -ErrorAction SilentlyContinue -UseBasicParsing

            # Extract title and image URLs from JSON data
            $Title = (ConvertFrom-Json $WebJSONData.Content).result.title
            $Images = (ConvertFrom-Json $WebJSONData.Content).result.content | Where-Object { $_.children[0].tag -eq "img" }
            $Count = $Images | Measure-Object | Select-Object -ExpandProperty Count

            Write-Host "Downloading: title:"$Title "total:"$Count

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
                $ImgObject = $_.children | Where-Object { $_.tag -eq "img" }
                if ($null -eq $ImgObject) {
                    Write-Host "No image found..." -ForegroundColor Red
                }
                else {
                    $ImageUrl = $ImgObject.attrs.src
                    if ($ImageUrl) {
                        $ImageName = $ImageUrl.replace("/file/", "")
                        $OUTPUT = Join-Path $StorePath $ImageName
                        # Get current image index and total count
                        $Index = $Images.IndexOf($_) + 1
                        $Progress = "$Index/$Count"
                        Write-Host "Downloading: [$Progress]  $Title   $StratPrefix$ImageUrl" -ForegroundColor Magenta            
                        # Download image using Invoke-WebRequest and -OutBuffer
                        try {
                            $ProgressPreference = 'SilentlyContinue'
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
        } -ThrottleLimit 10

        # Wait for all jobs to complete and receive results
        Get-Job | Wait-Job | Receive-Job
    }
    else {
        Write-Host "Please check named `TEMP` file is available..."
    }
}

DownTelegraph

