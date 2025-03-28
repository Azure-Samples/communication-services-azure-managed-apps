Connect-AzAccount -Tenant <tenantId> -Subscription <subscriptionId>

Get-AzSubscription -SubscriptionName <SubscriptionName> | Select-AzSubscription

# Run the pre-requisite RegisterResourceProviders.ps1 script if Resource Providers are not already registered
#Register-AzResourceProvider -ProviderNamespace Microsoft.Storage
#Register-AzResourceProvider -ProviderNamespace Microsoft.Communication
#Register-AzResourceProvider -ProviderNamespace Microsoft.CognitiveServices
#Register-AzResourceProvider -ProviderNamespace Microsoft.EventGrid
#Register-AzResourceProvider -ProviderNamespace Microsoft.Solutions

# Create ResourceGroup for the Storage
New-AzResourceGroup -Name acsManagedAppsPkgStorageGroup -Location westus

$pkgstorageparms = @{
  ResourceGroupName = "acsManagedAppsPkgStorageGroup"
  Name = "stacsmanagedapps"
  Location = "westus"
  SkuName = "Standard_LRS"
  Kind = "StorageV2"
  MinimumTlsVersion = "TLS1_2"
  AllowBlobPublicAccess = $true
  AllowSharedKeyAccess = $false
  EnableHttpsTrafficOnly = $true
}


# Create new Storage account and Blob container
$pkgstorageaccount = New-AzStorageAccount @pkgstorageparms

$userId = (Get-AzADUser -UserPrincipalName (Get-AzContext).Account).Id

New-AzRoleAssignment -ObjectID $userId -RoleDefinitionName 'Storage Blob Data Contributor' -Scope $pkgstorageaccount.Id

$pkgstoragecontext = New-AzStorageContext -StorageAccountName $pkgstorageaccount.StorageAccountName -UseConnectedAccount

New-AzStorageContainer -Name appcontainer -Context $pkgstoragecontext

$blobparms = @{
  File = "managedcommunicationservices.zip"
  Container = "appcontainer"
  Blob = "managedcommunicationservices.zip"
  Context = $pkgstoragecontext
}

Set-AzStorageBlobContent @blobparms

# Create a new resourcegroup to deploy ManagedApp definition

New-AzResourceGroup -Name AcsManagedAppDefinitionGroup -Location westus

$blob = Get-AzStorageBlob -Container appcontainer -Blob managedcommunicationservices.zip -Context $pkgstoragecontext

$tmpStart = Get-Date
$tmpEnd = $tmpStart.AddDays(1)

$Starttime = ($tmpStart).ToString("yyyy-MM-ddTHH:mm:ssZ")
$EndTime = ($tmpEnd).ToString("yyyy-MM-ddTHH:mm:ssZ")

# Get SASToken with 1 day expiry to access the zip file
$SASToken = New-AzStorageBlobSASToken -Blob "managedcommunicationservices.zip" -Container "appcontainer" -Context $pkgstoragecontext -Permission racwd -StartTime $StartTime -ExpiryTime $EndTime -FullURI


# Define the roles to assign
$roleid=(Get-AzRoleDefinition -Name Owner).Id
$roleid2=(Get-AzRoleDefinition -Name "EventGrid Data Sender").Id

# Get the ServicePrincipal Id
$principalid=(Get-AzADServicePrincipal -DisplayName <ServicePrincipalName>).Id

# Publish ManagedApplication and assign the SP roles defined above.
$publishparms = @{
  Name = "AcsManagedApplication"
  Location = "westus"
  ResourceGroupName = "AcsManagedAppDefinitionGroup"
  LockLevel = "ReadOnly"
  DisplayName = "ACS managed application"
  Description = "ACS managed application that deploys Azure Communication Services"
  Authorization = "${principalid}:$roleid", "${principalid}:$roleid2"
  PackageFileUri =  $SASToken
}

# Create a ManagedApplication Definition
New-AzManagedApplicationDefinition @publishparms
