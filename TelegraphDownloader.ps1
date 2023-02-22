# Specifies a path to one or more locations.

function DownTelegraph {
    param (
        [Parameter(Mandatory = $True, Position = 0)]
        [String] $PaserFile
    )
    if($PaserFile){
        Select-String -Path $PaserFile -Pattern "https://telegra.ph/" -AllMatches  | 
        Select-Object Line -Unique | 
        Format-Table -HideTableHeaders | 
        Out-String | 
        Set-Content .\TEMP
    }   else {
        <# Action when all if and elseif conditions are false #>
        Write-Host "Please enter the named `Result` json file path..." -ForegroundColor DarkCyan
    } 
    if (Test-Path .\TEMP) {
        <# Action to perform if the condition is true #>
        $URLS= Get-Content -Path .\TEMP -Delimiter ":"
        $Target = @()
        $EndPrefix ="?return_content=true"
        $StratPrefix = "https://telegra.ph"
        $URLS | ForEach-Object{
            if($_.StartsWith("//")){
                if($_.contains('"text":')){
                $Target+=[string]$_.replace('"text":',"").replace('//telegra.ph',"https://api.telegra.ph/getPage").replace('"',"")+$EndPrefix
                }
                if($_.contains('"href":')){
                $Target+=[string]$_.replace('"href":',"").replace('//telegra.ph',"https://api.telegra.ph/getPage").replace('"',"")+$EndPrefix
                }
            }
        }
        $Target | ForEach-Object{
        $WebJSONData = Invoke-WebRequest -Uri $_ -ErrorAction SilentlyContinue
        $Images = (ConvertFrom-Json $WebJSONData).result.content
        $Images | ForEach-Object {
            $ImageUrl=$_.children[0].attrs.src
            if($ImageUrl){
                $ImageName= $ImageUrl.replace("/file/","")
                Write-Host "即将下载:" $StratPrefix$ImageUrl -ForegroundColor Magenta
                Invoke-WebRequest -Uri $StratPrefix$ImageUrl -OutFile .\Images\$ImageName -ErrorAction SilentlyContinue 
            }else{
                Write-Host "Null file" -ForegroundColor Red
            }
        }
        }
    }else{
        Write-Host "Please check named `TEMP` file is available..."
    }
}

DownTelegraph

