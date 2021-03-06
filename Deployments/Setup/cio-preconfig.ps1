param([Parameter(Mandatory=$false)] [string] $resourceGroup = "cio-aks-dev-rg",
        [Parameter(Mandatory=$false)] [string] $vnetResourceGroup = "cio-aks-infra-dev-rg",
        [Parameter(Mandatory=$false)] [string] $clusterName = "cio-aks-cluster",
        [Parameter(Mandatory=$false)] [string] $primaryOwnerKey = "primary_owner",
        [Parameter(Mandatory=$false)] [string] $primaryOwnerValue = "Jagath.M@mphasis.com",
        [Parameter(Mandatory=$false)] [string] $secondaryOwnerKey = "secondary_owner",
        [Parameter(Mandatory=$false)] [string] $secondaryOwnerValue = "guruprasad.bm@mphasis.com",
        [Parameter(Mandatory=$false)] [string] $projectCodeKey = "project_code",
        [Parameter(Mandatory=$false)] [string] $projectCodeValue = "98203",
        [Parameter(Mandatory=$false)] [string] $projectNameKey = "project_name",
        [Parameter(Mandatory=$false)] [string] $projectNameValue = "CIO_Cloud_CSP",
        [Parameter(Mandatory=$false)] [string] $location = "southindia",
        [Parameter(Mandatory=$false)] [string] $userEmail = "prakash.rawat@mphasis.com",
        [Parameter(Mandatory=$false)] [string] $acrName = "acrdev",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "keyvault-dev",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-dev-vnet",
        [Parameter(Mandatory=$false)] [string] $acrTemplateFileName = "cio-acr-deploy",
        [Parameter(Mandatory=$false)] [string] $keyVaultTemplateFileName = "cio-keyvault-deploy",
        [Parameter(Mandatory=$false)] [string] $subscriptionId = "359f292b-8fe1-45ba-8b0f-e1295e7eb9ef",
        [Parameter(Mandatory=$false)] [string] $baseFolderPath = "<Praksh_to_Fillup>")

$projectName = "cio-poc"
$vnetRole = "Network Contributor"
$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"
$acrSPIdName = $acrName + "-sp-id"
$acrSPSecretName = $acrName + "-sp-secret"
$logWorkspaceName = $projectName + "-lw"
$logWorkspaceLocation = "centralindia"
$templatesFolderPath = $baseFolderPath + "/Templates"

# Assuming Logged In

# GET ObjectID
$loggedInUser = Get-AzADUser -UserPrincipalName $userEmail
$objectId = $loggedInUser.Id
Write-Host "ObjectId:$objectId"

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
$subscriptionCommand = "az account set -s $subscriptionId"
Invoke-Expression -Command $subscriptionCommand

$resourceG = Get-AzResourceGroup -Name $resourceGroup -Location $location
if (!$resourceG)
{
   
   $tagRef = @{$primaryOwnerKey=$primaryOwnerValue; $projectCodeKey=$projectCodeValue; $projectNameKey=$projectNameValue;}
   $resourceG = New-AzResourceGroup -Name $resourceGroup `
   -Location $location -Tag $tagRef
   if (!$resourceG)
   {
        Write-Host "Error creating Resource Group"
        return;
   }

}

$logWorkspace = Get-AzOperationalInsightsWorkspace `
-ResourceGroupName $resourceGroup `
-Name $logWorkspaceName 
if (!$logWorkspace)
{
   
   $logWorkspace = New-AzOperationalInsightsWorkspace `
   -ResourceGroupName $resourceGroup `
   -Location $logWorkspaceLocation -Name $logWorkspaceName
   if (!$logWorkspace)
   {
        Write-Host "Error creating Resource Group"
        return;
   }
}

$aksSP = New-AzADServicePrincipal -SkipAssignment
if (!$aksSP)
{

    Write-Host "Error creating Service Principal for AKS"
    return;

}

Write-Host $aksSP.DisplayName
Write-Host $aksSP.Id
Write-Host $aksSP.ApplicationId

$acrSP = New-AzADServicePrincipal -SkipAssignment
if (!$acrSP)
{

    Write-Host "Error creating Service Principal for ACR"
    return;

}

Write-Host $acrSP.DisplayName
Write-Host $acrSP.Id
Write-Host $acrSP.ApplicationId

# Deploy ACR
$acrDeployCommand = "/ACR/$acrTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $acrTemplateFileName -acrName $acrName"
$acrDeployPath = $templatesFolderPath + $acrDeployCommand
Invoke-Expression -Command $acrDeployPath

# Deploy KeyVault
$keyVaultDeployCommand = "/KeyVault/$keyVaultTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $keyVaultTemplateFileName -keyVaultName $keyVaultName -objectId $objectId"
$keyVaultDeployPath = $templatesFolderPath + $keyVaultDeployCommand
Invoke-Expression -Command $keyVaultDeployPath

$aksSPObjectId = ConvertTo-SecureString -String $aksSP.ApplicationId `
-AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPIdName `
-SecretValue $aksSPObjectId

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPSecretName `
-SecretValue $aksSP.Secret

$acrSPObjectId = ConvertTo-SecureString -String $acrSP.ApplicationId `
-AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $acrSPIdName `
-SecretValue $acrSPObjectId

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $acrSPSecretName `
-SecretValue $acrSP.Secret

$aksVnet = Get-AzVirtualNetwork -Name $aksVNetName `
-ResourceGroupName $vnetResourceGroup
if ($aksVnet)
{

    Write-Host "AKS Id:$aksVnet.Id"
    New-AzRoleAssignment -ApplicationId $aksSP.ApplicationId `
    -Scope $aksVnet.Id -RoleDefinitionName $vnetRole

}

$acrInfo = Get-AzContainerRegistry -Name $acrName `
-ResourceGroupName $resourceGroup
if ($acrInfo)
{

    Write-Host "ACR Id:$acrInfo.Id"
    New-AzRoleAssignment -ApplicationId $acrSP.ApplicationId `
    -Scope $acrInfo.Id -RoleDefinitionName acrpush

}

Write-Host "Pre-Config Successfully Done!"
