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
        Write-Host "即将下载..."$StratPrefix$ImageUrl -ForegroundColor Magenta
        Invoke-WebRequest -Uri $StratPrefix$ImageUrl -OutFile .\Images\$ImageName -ErrorAction SilentlyContinue 
    }else{
        Write-Host "Null file"
    }
 }
}



