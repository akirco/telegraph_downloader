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
        <# Action to perform if the condition is true #>
        $URLS = Get-Content -Path .\TEMP -Delimiter ":"
        $Target = @()
        $EndPrefix = "?return_content=true"
        $StratPrefix = "https://telegra.ph"
        $URLS | ForEach-Object {
            if ($_.StartsWith("//")) {
                if ($_.contains('"text":')) {
                    $Target += [string]$_.replace('"text":', "").replace('//telegra.ph', "https://api.telegra.ph/getPage").replace('"', "") + $EndPrefix
                }
                if ($_.contains('"href":')) {
                    $Target += [string]$_.replace('"href":', "").replace('//telegra.ph', "https://api.telegra.ph/getPage").replace('"', "") + $EndPrefix
                }
            }
        }
        $Target | ForEach-Object {
            $WebJSONData = Invoke-WebRequest -Uri $_ -Method Get -ContentType "application/json; charset=utf-8" -ErrorAction SilentlyContinue
            $Images = (ConvertFrom-Json $WebJSONData.Content).result.content
            $Title = (ConvertFrom-Json $WebJSONData.Content).result.title
            $StorePath = ".\\Images\\$Title"
            if(Test-Path $StorePath){
                Write-Host "Path is exist."
            }else{
                New-Item -ItemType Directory -Path $StorePath
            }
            Write-Host $Title
            $Images | ForEach-Object {
                if ($null -eq $_.children -or $_.children.Length -eq 0) {
                    Write-Host "Null file..." -ForegroundColor Red
                }
                else {
                    $ImageUrl = $_.children[0].attrs.src
                    if ($ImageUrl) {
                        $ImageName = $ImageUrl.replace("/file/", "")
                        Write-Host "即将下载:" $StratPrefix$ImageUrl -ForegroundColor Magenta
                        Invoke-WebRequest -Uri $StratPrefix$ImageUrl -OutFile $StorePath\$ImageName -ErrorAction SilentlyContinue 
                    }
                    else {
                        Write-Host "Null file..." -ForegroundColor Red
                    }
                }   
            }
        }
    }
    else {
        Write-Host "Please check named `TEMP` file is available..."
    }
}

DownTelegraph

