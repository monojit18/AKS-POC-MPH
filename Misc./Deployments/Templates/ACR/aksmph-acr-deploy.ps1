param([Parameter(Mandatory=$true)] [string] $rg,
        [Parameter(Mandatory=$true)] [string] $fpath,
        [Parameter(Mandatory=$true)] [string] $acrName)

Test-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/ACR/aksmph-acr-deploy.json" `
-acrName $acrName

New-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/ACR/aksmph-acr-deploy.json" `
-acrName $acrName