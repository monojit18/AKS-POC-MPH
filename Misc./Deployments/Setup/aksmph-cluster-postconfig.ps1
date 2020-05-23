param([Parameter(Mandatory=$false)] [string] $resourceGroup = "AKS-rg",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aks-mphasis-poc-cluster",
        [Parameter(Mandatory=$false)] [string] $acrName = "aksmphasisacr",        
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "nextgenlabs-vnet", # "aks-mphasis-vnet",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-mphasis-kv",
        [Parameter(Mandatory=$false)] [string] $certPwdName = "aks-mphasis-appgw-password",
        # [Parameter(Mandatory=$false)] [string] $appgwSubnetName = "aks-mphasis-appgw-subnet",
        [Parameter(Mandatory=$false)] [string] $helmReleaseName = "internal-nginx",
        [Parameter(Mandatory=$false)] [string] $ingressNSName = "internal-nginx-ns",
        [Parameter(Mandatory=$false)] [string] $baseFolderPath = "/Users/monojitdattams/Development/Projects/Workshops/Mphasis_Workshop/AKS-POC/Deployments")

# $vnetResourceGroupName = "infraservices-nextgen-rg"
# $templatesFolderPath = $baseFolderPath + "/Templates"

$yamlFilePath = "$baseFolderPath/YAMLs"

# $networkNames = "-vnetName $aksVNetName -subnetName $appgwSubnetName -vnetResourceGroupName $vnetResourceGroupName"
# $appgwDeployCommand = "/AppGW/aksmph-appgw-deploy.ps1 -rg $resourceGroup -fpath $templatesFolderPath $networkNames"

$kbctlContextCommand = "az aks get-credentials --resource-group $resourceGroup --name $clusterName"

$nginxNSCommand = "kubectl create namespace $ingressNSName"
$nginxILBCommand = "helm install $helmReleaseName stable/nginx-ingress --namespace $ingressNSName -f $yamlFilePath/Common/internal-ingress.yaml --set controller.replicaCount=2 --set nodeSelector.""beta.kubernetes.io/os""=linux"

$acrDetails = Get-AzContainerRegistry -ResourceGroupName $resourceGroup -Name $acrName
$acrCredentials = Get-AzContainerRegistryCredential -ResourceGroupName $resourceGroup `
                    -Name $acrName

$dockerSecretName = "aks-poc-secret"
$dockerServer = $acrDetails.LoginServer
$dockerUserName = $acrCredentials.Username
$dockerPassword = $acrCredentials.Password
                    
$dockerSecretCommand = "kubectl create secret docker-registry $dockerSecretName --docker-server=$dockerServer --docker-username=$dockerUserName --docker-password=$dockerPassword"
$dockerLoginCommand = "docker login $dockerServer --username $dockerUserName --password $dockerPassword"

$securePassword = Read-Host "SSL Cert Password " -AsSecureString
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $certPwdName -SecretValue $securePassword

# Switch Cluster context
Invoke-Expression -Command $kbctlContextCommand

# Create ACR secret
Invoke-Expression -Command $dockerSecretCommand

# Create namespace for nginx
Invoke-Expression -Command $nginxNSCommand

# Install nginx as ILB using Helm
Invoke-Expression -Command $nginxILBCommand

# Docker Login command
Invoke-Expression -Command $dockerLoginCommand

# # Install AppGW
# $appgwDeployPath = $templatesFolderPath + $appgwDeployCommand
# Invoke-Expression -Command $appgwDeployPath

Write-Host "Post config done"
