param([Parameter(Mandatory=$false)] [string] $resourceGroup = "AKS-rg",
        [Parameter(Mandatory=$false)] [string] $clusterName = "cio-poc-cluster",
        [Parameter(Mandatory=$false)] [string] $acrName = "ciopocacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "cio-poc-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "cio-poc-vnet",
        [Parameter(Mandatory=$false)] [string] $logWorkspaceName = "cio-poc-lw",
        [Parameter(Mandatory=$false)] [string] $subscriptionId = "76012eff-9c0f-4669-bf1b-c50d98038f68")

$aksSPIdName = $clusterName + "-sp-id"
$subscriptionCommand = "az account set -s $subscriptionId"

# PS Select Subscriotion
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion
Invoke-Expression -Command $subscriptionCommand

az aks delete --name $clusterName --resource-group $resourceGroup --yes

Remove-AzContainerRegistry -Name $acrName `
-ResourceGroupName $resourceGroup

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup `
-VaultName $keyVaultName
if ($keyVault)
{

    $spAppId = Get-AzKeyVaultSecret -VaultName $keyVaultName `
    -Name $aksSPIdName
    if ($spAppId)
    {

        Remove-AzADServicePrincipal `
        -ApplicationId $spAppId.SecretValueText -Force
        
    }

    Remove-AzKeyVault -InputObject $keyVault -Force

}

Remove-AzOperationalInsightsWorkspace `
-ResourceGroupName $resourceGroup `
-Name $logWorkspaceName -Force

Write-Host "Remove Successfully Done!"