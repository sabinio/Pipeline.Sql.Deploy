# TargetTrustServerCert Parameter Example

This example demonstrates how to use the new `TargetTrustServerCert` parameter in the `Invoke-DatabaseDacpacDeploy` function.

## Before (using Variables array):
```powershell
# Old way - passing through Variables array (DriftReport only)
Invoke-DatabaseDacpacDeploy `
    -dacpacfile "MyDatabase.dacpac" `
    -sqlpackagePath "sqlpackage" `
    -action "DriftReport" `
    -scriptParentPath "C:\Deploy\Scripts" `
    -TargetServerName "myserver.database.windows.net" `
    -TargetDatabaseName "MyDatabase" `
    -Variables @("/TargetTrustServerCertificate:true") `
    -TargetTimeout 30 `
    -CommandTimeout 300
```

## After (using dedicated parameter):
```powershell
# New way - using dedicated parameter (works with all actions)
Invoke-DatabaseDacpacDeploy `
    -dacpacfile "MyDatabase.dacpac" `
    -sqlpackagePath "sqlpackage" `
    -action "Publish" `
    -scriptParentPath "C:\Deploy\Scripts" `
    -TargetServerName "myserver.database.windows.net" `
    -TargetDatabaseName "MyDatabase" `
    -TargetTrustServerCert `
    -Variables @() `
    -TargetTimeout 30 `
    -CommandTimeout 300

# Also works with Script action
Invoke-DatabaseDacpacDeploy `
    -dacpacfile "MyDatabase.dacpac" `
    -sqlpackagePath "sqlpackage" `
    -action "Script" `
    -scriptParentPath "C:\Deploy\Scripts" `
    -TargetServerName "myserver.database.windows.net" `
    -TargetDatabaseName "MyDatabase" `
    -TargetTrustServerCert `
    -Variables @() `
    -TargetTimeout 30 `
    -CommandTimeout 300

# And with DriftReport action
Invoke-DatabaseDacpacDeploy `
    -dacpacfile "MyDatabase.dacpac" `
    -sqlpackagePath "sqlpackage" `
    -action "DriftReport" `
    -scriptParentPath "C:\Deploy\Scripts" `
    -TargetServerName "myserver.database.windows.net" `
    -TargetDatabaseName "MyDatabase" `
    -TargetTrustServerCert `
    -Variables @() `
    -TargetTimeout 30 `
    -CommandTimeout 300
```

## Benefits:
1. **Cleaner syntax**: Dedicated parameter instead of embedding in Variables array
2. **Works with all actions**: Not limited to DriftReport only
3. **Better IntelliSense**: IDE can provide parameter completion
4. **Type safety**: Switch parameter prevents typos
5. **Self-documenting**: Clear intent from parameter name

## What happens behind the scenes:
When `-TargetTrustServerCert` is specified, the function automatically adds `-TargetTrustServerCertificate:True` to the sqlpackage command line arguments.