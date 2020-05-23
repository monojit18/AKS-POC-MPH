param([Parameter(Mandatory=$true)] [string] $mode,
        [Parameter(Mandatory=$false)] [string] $resourceGroup = "AKS-rg",
        [Parameter(Mandatory=$false)] [string] $location = "southindia",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aks-mphasis-poc-cluster",
        [Parameter(Mandatory=$false)] [string] $spIdName = "aks-mphasis-sp-id",
        [Parameter(Mandatory=$false)] [string] $spSecretName = "aks-mphasis-sp-secret",
        [Parameter(Mandatory=$false)] [string] $acrName = "aksmphasisacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-mphasis-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "nextgenlabs-vnet", # "aks-mphasis-vnet",
        [Parameter(Mandatory=$false)] [string] $aksSubnetName = "pvtsub-aks", # "aks-mphasis-subnet",
        [Parameter(Mandatory=$false)] [string] $version = "1.14.8",
        [Parameter(Mandatory=$false)] [string] $addons = "monitoring",
        [Parameter(Mandatory=$false)] [string] $nodeCount = 2,
        [Parameter(Mandatory=$false)] [string] $minNodeCount = 2,
        [Parameter(Mandatory=$false)] [string] $maxNodeCount = 60,
        [Parameter(Mandatory=$false)] [string] $maxPods = 50,
        [Parameter(Mandatory=$false)] [string] $vmSetType = "VirtualMachineScaleSets",
        [Parameter(Mandatory=$false)] [string] $nodeVMSize = "Standard_DS2_v2",
        [Parameter(Mandatory=$false)] [string] $networkPlugin = "azure",
        [Parameter(Mandatory=$false)] [string] $networkPolicy = "azure",
        [Parameter(Mandatory=$false)] [string] $nodePoolName = "aksmphpool",
        [Parameter(Mandatory=$false)] [string] $inqmiPoolName = "aksinqmipool")

$vnetResourceGroup = "infraservices-nextgen-rg"

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup -VaultName $keyVaultName
if (!$keyVault)
{

    Write-Host "Error fetching KeyVault"
    return;

}

$spAppId = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $spIdName
if (!$spAppId)
{

    Write-Host "Error fetching Service Principal Id"
    return;

}

$spPassword = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $spSecretName
if (!$spPassword)
{

    Write-Host "Error fetching Service Principal Password"
    return;

}

$aksWorkshopVnet = Get-AzVirtualNetwork -Name $aksVNetName -ResourceGroupName $vnetResourceGroup
if (!$aksWorkshopVnet)
{

    Write-Host "Error fetching Vnet"
    return;

}

$aksWorkshopSubnet = Get-AzVirtualNetworkSubnetConfig -Name $aksSubnetName `
-VirtualNetwork $aksWorkshopVnet
if (!$aksWorkshopSubnet)
{

    Write-Host "Error fetching Subnet"
    return;

}

if ($mode -eq "create")
{

    az aks create --name $clusterName --resource-group $resourceGroup `
    --kubernetes-version $version --location $location `
    --vnet-subnet-id $aksWorkshopSubnet.Id --node-vm-size $nodeVMSize `
    --node-count $nodeCount --max-pods $maxPods `
    --service-principal $spAppId.SecretValueText `
    --client-secret $spPassword.SecretValueText `
    --network-plugin $networkPlugin --network-policy $networkPolicy `
    --nodepool-name $nodePoolName --vm-set-type $vmSetType `
    --generate-ssh-keys
    
}
elseif ($mode -eq "update")
{

    az aks nodepool update --cluster-name $clusterName --resource-group $resourceGroup `
    --enable-cluster-autoscaler --min-count $minNodeCount --max-count $maxNodeCount `
    --name $nodePoolName

    az aks nodepool add --name $inqmiPoolName --cluster-name $clusterName `
    --resource-group $resourceGroup --kubernetes-version $version `
    --node-vm-size $nodeVMSize --node-count $nodeCount --max-pods $maxPods `
    --enable-cluster-autoscaler --min-count $minNodeCount --max-count $maxNodeCount `
    --vnet-subnet-id $aksWorkshopSubnet.Id

    az aks update --name $clusterName --resource-group $resourceGroup `
    --attach-acr $acrName
    
}
# elseif ($mode -eq "scale")
# {

#     az aks nodepool scale --cluster-name $clusterName --resource-group $resourceGroup `
#     --node-count $nodeCount --name $nodePoolName
    
# }

Write-Host "Cluster done"

