Connect-AzAccount -Tenant <tenantId> -Subscription <subscriptionId>

Get-AzSubscription -SubscriptionName <SubscriptionName> | Select-AzSubscription

# Register Resource Providers if not already registered
Register-AzResourceProvider -ProviderNamespace Microsoft.Storage
Register-AzResourceProvider -ProviderNamespace Microsoft.Communication
Register-AzResourceProvider -ProviderNamespace Microsoft.CognitiveServices
Register-AzResourceProvider -ProviderNamespace Microsoft.EventGrid
Register-AzResourceProvider -ProviderNamespace Microsoft.Solutions