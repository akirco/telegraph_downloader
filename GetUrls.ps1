$URLS = (Get-Content -Path .\TEMP).Split("\n").Trim()

$Target = @()
$EndPrefix = "?return_content=true"
$StratPrefix = "https://telegra.ph"

$URLS | ForEach-Object {
    
    if ($_.contains('"text":')) {
        $Target += $_.replace('"text":', "").replace('telegra.ph', "api.telegra.ph/getPage").replace('"', "") + $EndPrefix
    }

    if ($_.contains('"href":')) {
        $Target += $_.replace('"href":', "").replace('telegra.ph', "api.telegra.ph/getPage").replace('"', "") + $EndPrefix
    }

}

$Target | ForEach-Object -Parallel{
    # Suppress error messages
    $ErrorActionPreference = 'SilentlyContinue'

    $WebJSONData = Invoke-WebRequest -Uri $_ -ErrorAction SilentlyContinue
    # $Images = (ConvertFrom-Json $WebJSONData.Content).result.content

    $Images = (ConvertFrom-Json $WebJSONData.Content).result.content | Where-Object { $_.children[0].tag -eq "img" }
    $Count =  $Images | Measure-Object | Select-Object -ExpandProperty Count

    Write-Host "Downloading: title:"$Title "total:"$Count

    $Title = (ConvertFrom-Json $WebJSONData.Content).result.title
    $StorePath = ".\Images\$Title"
    
    Write-Host $StorePath
    if (Test-Path $StorePath) {
        return
    }
    else {
        New-Item -ItemType Directory -Path $StorePath
    }
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
                $Index = $Images.IndexOf($_) + 1
                $Progress = "$Index/$Count"
                Write-Host "Downloading: [$Progress]  $Title   $StratPrefix$ImageUrl" -ForegroundColor Magenta   
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri $StratPrefix$ImageUrl -OutFile "$OUTPUT" -ErrorAction SilentlyContinue -UseBasicParsing
            }
            else {
                Write-Host "Null file..." -ForegroundColor Red
            }
        }

    }
} -ThrottleLimit 10

# Wait for all jobs to complete and receive results
Get-Job | Wait-Job | Receive-Job



