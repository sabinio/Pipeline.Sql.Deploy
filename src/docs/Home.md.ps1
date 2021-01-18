@"
#SentryOne.Configure wiki

Welcome to the $($settings.ProjectName).Configure wiki!


To install S1 you need to download the S1Installer bu using `Install-S1EPI`

#Once installed you need to restart powershell to get the path to so defined 

Turn on analyse fragementation
Blocking over 3 seconds





Logon to the server with the client as the monitoring service account (or an account that has access to the Target)



C:\Users\<username>\AppData\Local\temp
and

C:\Users\<username>\AppData\Local\temp\sqlsentry

Complete list of cmdlets is as follows.
|Module|Description|
|-|-|
$(($modules| ForEach-Object{
    Write-output ("|[{0}]({1}){2}" -f $_.function, $_.functionlink, $_.description)
} )-join "`n")
"@