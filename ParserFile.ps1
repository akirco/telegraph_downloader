param (
    [Parameter(Mandatory = $False)]
    [String]$ParserFile
)
function ParserFile {
    if($PaserFile){
        Select-String -Path $ParserFile -Pattern "telegra.ph/" -AllMatches  | 
        Select-Object Line -Unique | 
        Format-Table -HideTableHeaders | 
        Out-String | 
        Set-Content .\TEMP
    }   else {
        <# Action when all if and elseif conditions are false #>
        Write-Host "Please enter the named `Result` json file path..." -ForegroundColor DarkCyan
    } 
}
PaserFile $ParserFile

