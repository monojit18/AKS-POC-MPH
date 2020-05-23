param([Parameter(Mandatory=$true)] [string] $mode,
        [Parameter(Mandatory=$false)] [string] $resourceGroup = "AKS-rg",
        [Parameter(Mandatory=$false)] [string] $vnetResourceGroup = "infraservices-nextgen-rg",
        [Parameter(Mandatory=$false)] [string] $clusterName = "cio-poc-cluster",
        [Parameter(Mandatory=$false)] [string] $primaryOwnerKey = "primary_owner",
        [Parameter(Mandatory=$false)] [string] $primaryOwnerValue = "Jagath.M@mphasis.com",
        [Parameter(Mandatory=$false)] [string] $secondaryOwnerKey = "secondary_owner",
        [Parameter(Mandatory=$false)] [string] $secondaryOwnerValue = "guruprasad.bm@mphasis.com",
        [Parameter(Mandatory=$false)] [string] $projectCodeKey = "project_code",
        [Parameter(Mandatory=$false)] [string] $projectCodeValue = "98203",
        [Parameter(Mandatory=$false)] [string] $projectNameKey = "project_name",
        [Parameter(Mandatory=$false)] [string] $projectNameValue = "CIO_Cloud_CSP",
        [Parameter(Mandatory=$false)] [string] $location = "southindia",
        [Parameter(Mandatory=$false)] [string] $userEmail = "cloud.test@mphasis.com",
        [Parameter(Mandatory=$false)] [string] $acrName = "ciopocacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "cio-poc-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "nextgenlabs-vnet",        
        [Parameter(Mandatory=$false)] [string] $aksSubnetName = "pvtsub-aks",
        [Parameter(Mandatory=$false)] [string] $version = "1.15.10",
        [Parameter(Mandatory=$false)] [string] $addons = "monitoring",
        [Parameter(Mandatory=$false)] [string] $nodeCount = 3,
        [Parameter(Mandatory=$false)] [string] $minNodeCount = 3,
        [Parameter(Mandatory=$false)] [string] $maxNodeCount = 10,
        [Parameter(Mandatory=$false)] [string] $maxPods = 40,
        [Parameter(Mandatory=$false)] [string] $vmSetType = "VirtualMachineScaleSets",
        [Parameter(Mandatory=$false)] [string] $nodeVMSize = "Standard_DS3_v2",
        [Parameter(Mandatory=$false)] [string] $networkPlugin = "azure",
        [Parameter(Mandatory=$false)] [string] $networkPolicy = "azure",
        [Parameter(Mandatory=$false)] [string] $nodePoolName = "ciopocpool",
        [Parameter(Mandatory=$false)] [string] $aadServerAppID = "c06dcfeb-2507-4653-acca-452c8ed9ce84",
        [Parameter(Mandatory=$false)] [string] $aadServerAppSecret = "AL8995Y-4df5CcSzAz9~Ve2mx2A-E_ATb4",
        [Parameter(Mandatory=$false)] [string] $aadClientAppID = "7d650c9a-1803-43d4-859c-02109d0a1966",
        [Parameter(Mandatory=$false)] [string] $aadTenantID = "665b6c62-7310-4d39-9abb-32a0cbc3b90f")

$projectName = "cio-poc"
$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"
$logWorkspaceName = $projectName + "-lw"

$tags = "$primaryOwnerKey=$primaryOwnerValue $projectCodeKey=$projectCodeValue $projectNameKey=$projectNameValue"
Write-Host $tags

$logWorkspace = Get-AzOperationalInsightsWorkspace `
-ResourceGroupName $resourceGroup `
-Name $logWorkspaceName
if (!$logWorkspace)
{

    Write-Host "Error fetching Log Workspace"
    return;

}

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup `
-VaultName $keyVaultName
if (!$keyVault)
{

    Write-Host "Error fetching KeyVault"
    return;

}

$spAppId = Get-AzKeyVaultSecret -VaultName $keyVaultName `
-Name $aksSPIdName
if (!$spAppId)
{

    Write-Host "Error fetching Service Principal Id"
    return;

}

$spPassword = Get-AzKeyVaultSecret -VaultName $keyVaultName `
-Name $aksSPSecretName
if (!$spPassword)
{

    Write-Host "Error fetching Service Principal Password"
    return;

}

$aksVnet = Get-AzVirtualNetwork -Name $aksVNetName `
-ResourceGroupName $vnetResourceGroup
if (!$aksVnet)
{

    Write-Host "Error fetching Vnet"
    return;

}

$aksSubnet = Get-AzVirtualNetworkSubnetConfig -Name $aksSubnetName `
-VirtualNetwork $aksVnet
if (!$aksSubnet)
{

    Write-Host "Error fetching Subnet"
    return;

}

if ($mode -eq "create")
{

    az aks create --name $clusterName --resource-group $resourceGroup `
    --kubernetes-version $version --enable-addons $addons --location $location `
    --vnet-subnet-id $aksSubnet.Id --node-vm-size $nodeVMSize `
    --node-count $nodeCount --max-pods $maxPods `
    --service-principal $spAppId.SecretValueText `
    --client-secret $spPassword.SecretValueText `
    --network-plugin $networkPlugin --network-policy $networkPolicy `
    --nodepool-name $nodePoolName --vm-set-type $vmSetType `
    --generate-ssh-keys `
    --aad-client-app-id $aadClientAppID `
    --aad-server-app-id $aadServerAppID `
    --aad-server-app-secret $aadServerAppSecret `
    --aad-tenant-id $aadTenantID `
    --tags $tags `
    --workspace-resource-id $logWorkspace.ResourceId
    
}
elseif ($mode -eq "update")
{

    # az aks nodepool update --cluster-name $clusterName `
    # --resource-group $resourceGroup --enable-cluster-autoscaler `
    # --min-count $minNodeCount --max-count $maxNodeCount `
    # --name $nodePoolName

    az aks update-credentials --name $clusterName `
    --resource-group $resourceGroup --reset-aad `
    --aad-client-app-id $aadClientAppID `
    --aad-server-app-id $aadServerAppID `
    --aad-server-app-secret $aadServerAppSecret `
    --aad-tenant-id $aadTenantID

    
}
# elseif ($mode -eq "scale")
# {

#     az aks nodepool scale --cluster-name $clusterName --resource-group $resourceGroup `
#     --node-count $nodeCount --name $nodePoolName
    
# }

Write-Host "Cluster Successfully Done!"