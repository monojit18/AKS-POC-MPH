param([Parameter(Mandatory=$false)] [string] $resourceGroup = "AKS-rg",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aks-mphasis-poc-cluster",
        [Parameter(Mandatory=$false)] [string] $spIdName = "aks-mphasis-sp-id",
        [Parameter(Mandatory=$false)] [string] $acrName = "aksmphasisacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-mphasis-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-mphasis-vnet",
        [Parameter(Mandatory=$false)] [string] $applicationGatewayName = "aks-mphasis-poc-appgw",    
        [Parameter(Mandatory=$false)] [string] $subscriptionId = "76012eff-9c0f-4669-bf1b-c50d98038f68")

$publicIpAddressName = "$applicationGatewayName-pip"

$loginCommand = "az login"
$logoutCommand = "az logout"
$subscriptionCommand = "az account set -s $subscriptionId"

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

az aks delete --name $clusterName --resource-group $resourceGroup

Remove-AzApplicationGateway -Name $applicationGatewayName `
-ResourceGroupName $resourceGroup -Force

Remove-AzPublicIpAddress -Name $publicIpAddressName `
-ResourceGroupName $resourceGroup

Remove-AzContainerRegistry -Name $acrName -ResourceGroupName $resourceGroup

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup -VaultName $keyVaultName
if ($keyVault)
{

    $spAppId = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $spIdName
    if ($spAppId)
    {

        Remove-AzADServicePrincipal -ApplicationId $spAppId.SecretValueText -Force
        
    }

    Remove-AzKeyVault -InputObject $keyVault -Force

}

Disconnect-AzAccount
Invoke-Expression -Command $logoutCommand

