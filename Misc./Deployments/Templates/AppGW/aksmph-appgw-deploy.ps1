param([Parameter(Mandatory=$true)] [string] $rg,
        [Parameter(Mandatory=$true)] [string] $fpath,
        [Parameter(Mandatory=$true)] [string] $vnetName,
        [Parameter(Mandatory=$true)] [string] $subnetName,
        [Parameter(Mandatory=$true)] [string] $vnetResourceGroupName)

Test-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/AppGW/aksmph-appgw-deploy.json" `
-TemplateParameterFile "$fpath/AppGW/aksmph-appgw-deploy.parameters.json" `
-vnetName $vnetName -subnetName $subnetName `
-vnetResourceGroupName $vnetResourceGroupName

New-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/AppGW/aksmph-appgw-deploy.json" `
-TemplateParameterFile "$fpath/AppGW/aksmph-appgw-deploy.parameters.json" `
-vnetName $vnetName -subnetName $subnetName `
-vnetResourceGroupName $vnetResourceGroupName