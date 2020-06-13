param([Parameter(Mandatory=$false)] [string] $resourceGroup = "AKS-rg",
        [Parameter(Mandatory=$false)] [string] $clusterName = "cio-poc-cluster",
        [Parameter(Mandatory=$false)] [string] $acrName = "ciopocacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "cio-poc-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "nextgenlabs-vnet",
        [Parameter(Mandatory=$false)] [string] $ingControllerIPAddress = "10.14.52.127",
        [Parameter(Mandatory=$false)] [string] $baseFolderPath = "/Users/monojitdattams/Development/Projects/Workshops/Mphasis_Workshop/AKS-POC/Deployments")

$projectName = "cio-poc"
$acrSPIdName = $acrName + "-sp-id"
$acrSPSecretName = $acrName + "-sp-secret"
$yamlFilePath = "$baseFolderPath/YAMLs"
$devNamespace = $projectName + "-dev"
$qaNamespace = $projectName + "-qa"
$ingControllerName = $projectName + "-ing"
$ingControllerNSName = $ingControllerName + "-ns"
$ingControllerFileName = "internal-ingress"
$yamlFilePath = "$baseFolderPath/YAMLs"

$acrInfo = Get-AzContainerRegistry -ResourceGroupName $resourceGroup -Name $acrName
if (!$acrInfo)
{

    Write-Host "Error creating Service Principal"
    return;

}

Write-Host $acrInfo.Id

$acrUserName = Get-AzKeyVaultSecret -VaultName $keyVaultName `
-Name $acrSPIdName
if (!$acrUserName)
{

    Write-Host "Error fetching Service Principal Id"
    return;

}

$acrPassword = Get-AzKeyVaultSecret -VaultName $keyVaultName `
-Name $acrSPSecretName
if (!$acrPassword)
{

    Write-Host "Error fetching Service Principal Password"
    return;

}

$dockerServer = $acrInfo.LoginServer
$dockerUserName = $acrUserName.SecretValueText
$dockerPassword = $acrPassword.SecretValueText

# Switch Cluster context
$kbctlContextCommand = "az aks get-credentials --resource-group $resourceGroup --name $clusterName --overwrite-existing --admin"
Invoke-Expression -Command $kbctlContextCommand

# Docker Login command
$dockerLoginCommand = "docker login $dockerServer --username $dockerUserName --password $dockerPassword"
Invoke-Expression -Command $dockerLoginCommand

# Configure ILB file
$ipReplaceCommand = "sed -e 's|<ILB_IP>|$ingControllerIPAddress|' $yamlFilePath/Common/$ingControllerFileName.yaml > $yamlFilePath/Common/tmp.$ingControllerFileName.yaml"
Invoke-Expression -Command $ipReplaceCommand
# Remove temp ILB file
$removeTempFileCommand = "mv $yamlFilePath/Common/tmp.$ingControllerFileName.yaml $yamlFilePath/Common/$ingControllerFileName.yaml"
Invoke-Expression -Command $removeTempFileCommand

# Create Namespaces
# DEV NS
$namespaceCommand = "kubectl create ns $devNamespace"
Invoke-Expression -Command $namespaceCommand

# QA NS
$namespaceCommand = "kubectl create ns $qaNamespace"
Invoke-Expression -Command $namespaceCommand

# nginx NS
$nginxNSCommand = "kubectl create namespace $ingControllerNSName"
Invoke-Expression -Command $nginxNSCommand

# Install nginx as ILB using Helm
$nginxILBCommand = "helm install $ingControllerName stable/nginx-ingress --namespace $ingControllerNSName -f $yamlFilePath/Common/$ingControllerFileName.yaml --set controller.replicaCount=2 --set nodeSelector.""beta.kubernetes.io/os""=linux"
Invoke-Expression -Command $nginxILBCommand

Write-Host "Post-Config Successfully Done!"
