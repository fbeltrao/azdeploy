# Application Gateway

This template will deploy an Application Gateway using by default a Path-based routing instead of the "Basic" created by Azure Portal.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ffbeltrao%2Fazdeploy%2Fmaster%2Fapplication-gateway%2Ftemplate.json" target="_blank">
    <img src="https://azuredeploy.net/deploybutton.png"/>
</a>

## Adding WebSites

To add web sites and url/routing to the application gateway use the provided PowerShell script

### Adding a Azure web site

```powershell
.\AddSiteRoute.ps1 -resourceGroupName MyResourceGroup -applicationGatewayName MyAppGateway -webSiteName "MyCustomersApi" -paths "/api/customers","/api/customers/*"
```

This will route &lt;applicationGateway-ip-or-fqdns&gt;/api/customers to "MyCustomersApi.azurewebsites.net/api/customers"

### Adding an external web site

```powershell
AddSiteRoute.ps1 -resourceGroupName MyResourceGroup -applicationGatewayName MyAppGateway -externalURI "thecatapi.com" -paths "/api/categories","/api/categories/*"
```

This will route the &lt;applicationGateway-ip-or-fqdns&gt;/api/categories/list to http://thecatapi.com/api/categories/list

### Defining where the path will be added
The path rules will be solved in the order in which they are defined. To control where the path rule is added use the parameter "routePosition" with possible values

- "first": will add in the top of the list (default behavior)
- "last": will add to the end of the list
- "secondLast": will add before the last element (in cases where the last element handles all missing cases)