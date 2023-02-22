function PaserFile {
    param (
        [String]$PaserFile
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
}


