param([Parameter(Mandatory=$false)] [string] $resourceGroup = "AKS-rg",
        [Parameter(Mandatory=$false)] [string] $spIdName = "aks-mphasis-sp-id",
        [Parameter(Mandatory=$false)] [string] $spSecretName = "aks-mphasis-sp-secret",
        [Parameter(Mandatory=$false)] [string] $acrName = "aksmphasisacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-mphasis-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "nextgenlabs-vnet", # "aks-mphasis-vnet",
        [Parameter(Mandatory=$false)] [string] $aksSubnetName = "pvtsub-aks", # "aks-mphasis-subnet",
        [Parameter(Mandatory=$false)] [string] $certSecretName = "aks-mphasis-appgw-secret",
        [Parameter(Mandatory=$false)] [string] $subscriptionId = "76012eff-9c0f-4669-bf1b-c50d98038f68",
        [Parameter(Mandatory=$false)] [string] $objectId = "c3667b2f-d9a0-4493-b466-6ac799e990e4",
        [Parameter(Mandatory=$false)] [string] $baseFolderPath = "/Users/monojitdattams/Development/Projects/Workshops/Mphasis_Workshop/AKS-POC/Deployments")

$vnetResourceGroup = "infraservices-nextgen-rg"
$vnetRole = "Network Contributor"

$templatesFolderPath = $baseFolderPath + "/Templates"
$certPFXFilePath = $baseFolderPath + "/Certs/uniaccess.pfx"

$loginCommand = "az login"
$logoutCommand = "az logout"
$subscriptionCommand = "az account set -s $subscriptionId"

$acrDeployCommand = "/ACR/aksmph-acr-deploy.ps1 -rg $resourceGroup -fpath $templatesFolderPath -acrName $acrName"
$keyVaultDeployCommand = "/KeyVault/aksmph-keyvault-deploy.ps1 -rg $resourceGroup -fpath $templatesFolderPath -keyVaultName $keyVaultName -objectId $objectId"

# PS Logout
Disconnect-AzAccount

# CLI Logout
Invoke-Expression -Command $logoutCommand

# PS Login
Connect-AzAccount

# CLI Login
Invoke-Expression -Command $loginCommand

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
Invoke-Expression -Command $subscriptionCommand

$acrDeployPath = $templatesFolderPath + $acrDeployCommand
Invoke-Expression -Command $acrDeployPath

$servicePrinciple = New-AzADServicePrincipal -SkipAssignment
if (!$servicePrinciple)
{

    Write-Host "Error creating Service Principal"
    return;

}

$secretBSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($servicePrinciple.Secret)
$secret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($secretBSTR)
Write-Host $servicePrinciple.DisplayName
Write-Host $servicePrinciple.Id
Write-Host $servicePrinciple.ApplicationId
Write-Host $secret

$spObjectId = ConvertTo-SecureString $servicePrinciple.ApplicationId `
-AsPlainText -Force
$keyVaultDeployPath = $templatesFolderPath + $keyVaultDeployCommand
Invoke-Expression -Command $keyVaultDeployPath

$certBytes = [System.IO.File]::ReadAllBytes($certPFXFilePath)
$certContents = [Convert]::ToBase64String($certBytes)
$certContentsSecure = ConvertTo-SecureString -String $certContents -AsPlainText -Force

$spObjectId = ConvertTo-SecureString -String $servicePrinciple.ApplicationId `
-AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $spIdName -SecretValue $spObjectId

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $spSecretName `
-SecretValue $servicePrinciple.Secret

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $certSecretName `
-SecretValue $certContentsSecure

$aksVnet = Get-AzVirtualNetwork -Name $aksVNetName -ResourceGroupName $vnetResourceGroup
if ($aksVnet)
{

    New-AzRoleAssignment -ApplicationId $servicePrinciple.ApplicationId `
    -Scope $aksVnet.Id -RoleDefinitionName $vnetRole

}

Write-Host "Pre-Config done"
