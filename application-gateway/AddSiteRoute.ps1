<#
 .SYNOPSIS
    Adds a Azure Web Site or External URI route to an existing Application Gateway

 .PARAMETER resourceGroupName
    The resource group where the Application Gateway and the Web Site are deployed

 .PARAMETER applicationGatewayName
    The Application Gateway name

 .PARAMETER webSiteName
    The Azure web site name

 .PARAMETER webSiteResourceGroupName
    The resource group where the webSite is located. If empty will take the value of resourceGroupName parameter

 .PARAMETER externalURI
    The external URI to be mapped

 .PARAMETER paths
    The paths that will match the APIs. Example "/api/myresource","/api/myresource/*"
#>

param(
 [Parameter(Mandatory=$True)]
 [string]  $resourceGroupName,

 [Parameter(Mandatory=$True)]
 [string] $applicationGatewayName,

 
 [string] $externalURI,
 [string] $webSiteResourceGroupName,
 [string] $webSiteName,

 [Parameter(Mandatory=$True)]
 [string[]] $paths,

 [ValidateSet("first","last","secondLast")]
 [string] $routePosition = "first"
)

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"

# auto-select subscription
$subscriptionId = (Get-AzureRmContext).Subscription.Id;

if (!$subscriptionId)
{
    Connect-AzureRmAccount
    #Write-Host "Could not resolve Azure Subscription ID. Make sure your are logged-in 'Connect-AzureRmAccount'"
    $subscriptionId = (Get-AzureRmContext).Subscription.Id;
}

# retrieve the Web Site
$backendFqns = $externalURI
$backendPoolName = ""
$ruleName = ""
if ($webSiteName)
{
    if (!$webSiteResourceGroupName)
    {
        $webSiteResourceGroupName = $resourceGroupName
    }

    $webSite = Get-AzureRmWebApp -ResourceGroupName $webSiteResourceGroupName -Name $webSiteName
    $backendFqns = $webSite.HostNames

    $backendPoolName = $webSite.Name
    $backEndPoolName += "BackendPool"
    $ruleName = $webSite.Name
    $ruleName += "Rule"
}
else 
{    
    $safeNameFromExternalURI = $externalURI -replace '[^a-zA-Z0-9]', ''
    $ruleName = $safeNameFromExternalURI
    $ruleName += "Rule"

    $backendPoolName = $safeNameFromExternalURI
    $backendPoolName += "BackendPool"
}



# retrieve the Application Gateway
$appGateway = Get-AzureRmApplicationGateway -ResourceGroupName $resourceGroupName -Name $applicationGatewayName


# create new backendPool
$appGateway = Add-AzureRmApplicationGatewayBackendAddressPool -ApplicationGateway $appGateway -Name $backEndPoolName -BackendFqdns $backendFqns

# get backend http settings to use (for now get the first)
$backendHttpSetting = $appGateway.BackendHttpSettingsCollection[0]

# create path rule
$pathRule = New-AzureRmApplicationGatewayPathRuleConfig -Name $ruleName -Paths $paths -BackendAddressPool $appGateway.BackendAddressPools[-1] -BackendHttpSettings $backendHttpSetting

# add the rule based on $routeAddAction
if ($routeAddAction -and $routeAddAction -eq "last")
{
    # insert at the start
    $appGateway.UrlPathMaps[0].PathRules += $pathRule
}
elseif ($routeAddAction -and $routeAddAction -eq "secondLast")
{
    # insert at the start
    $temp = $appGateway.UrlPathMaps[0].PathRules    
    $appGateway.UrlPathMaps[0].PathRules = $temp[0..($temp.Length-1)],$pathRule,$temp[$temp.Length-1]     
}
else 
{
    # insert at the start
    $appGateway.UrlPathMaps[0].PathRules = , $pathRule + $appGateway.UrlPathMaps[0].PathRules
}


# apply application gateway changes
Write-Host "Applying application gateway changes. It might take a while..." -NoNewline
$appGateway = Set-AzureRmApplicationGateway -ApplicationGateway $appGateway
Write-Host "done!"