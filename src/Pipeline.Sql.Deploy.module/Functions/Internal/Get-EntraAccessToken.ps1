function Get-EntraAccessToken {
    [CmdletBinding()]
    param($TenantID,
        $clientId,
        $clientSecret,
        $clientSecretSecure)

    $resource = 'https://database.windows.net/'
 
    if ($clientSecretSecure) {
        
        $clientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecretSecure))
    }
    $GetToken = Invoke-RestMethod -Method Post -UseBasicParsing `
        -Uri "https://login.windows.net/$($TenantID)/oauth2/token" `
        -Body @{
        resource      = $resource
        client_id     = $clientId
        grant_type    = 'client_credentials'
        client_secret = $clientSecret
    } -ContentType 'application/x-www-form-urlencoded'
 
    if ($GetToken) {
        Write-debug "Access token type is $($GetToken.token_type), expires $($GetToken.expires_on)"
        return  $GetToken
    }
    else {
        throw "Failed to obtain access token from Entra AD. Please check your tenant ID, client ID, and client secret."
    }

}