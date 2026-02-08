---
external help file: Pipeline.Sql.Deploy-help.xml
Module Name: Pipeline.Sql.Deploy
online version:
schema: 2.0.0
---

# Invoke-DatabaseDacpacDeploy

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### IndividualTarget
```
Invoke-DatabaseDacpacDeploy -dacpacfile <String> -sqlpackagePath <String> -action <String>
 -scriptParentPath <String> -TargetServerName <String> -TargetDatabaseName <String> [-TargetUser <String>]
 [-TargetPasswordSecure <SecureString>] [-TargetIntegratedSecurity <String>] [-TargetTrustServerCert]
 [-ServiceObjective <Object>] [-AccessToken <String>] [-AccessTokenSecure <SecureString>] [-TenantId <String>]
 [-ClientId <String>] [-ClientSecret <String>] [-ClientSecretSecure <SecureString>] [-PublishFile <String>]
 [-OutputDeployScript] -Variables <Object> -TargetTimeout <Object> -CommandTimeout <Object>
 [-SettingsToCheck <Object>] [-DBScriptPrefix <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### ConnectionStringTarget
```
Invoke-DatabaseDacpacDeploy -dacpacfile <String> -sqlpackagePath <String> -action <String>
 -scriptParentPath <String> [-TargetUser <String>] [-TargetPasswordSecure <SecureString>]
 [-TargetIntegratedSecurity <String>] [-TargetTrustServerCert] -TargetConnectionString <String>
 [-ServiceObjective <Object>] [-AccessToken <String>] [-AccessTokenSecure <SecureString>] [-TenantId <String>]
 [-ClientId <String>] [-ClientSecret <String>] [-ClientSecretSecure <SecureString>] [-PublishFile <String>]
 [-OutputDeployScript] -Variables <Object> -TargetTimeout <Object> -CommandTimeout <Object>
 [-SettingsToCheck <Object>] [-DBScriptPrefix <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -AccessToken
{{ Fill AccessToken Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AccessTokenSecure
{{ Fill AccessTokenSecure Description }}

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientId
{{ Fill ClientId Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientSecret
{{ Fill ClientSecret Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientSecretSecure
{{ Fill ClientSecretSecure Description }}

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CommandTimeout
{{ Fill CommandTimeout Description }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DBScriptPrefix
{{ Fill DBScriptPrefix Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputDeployScript
{{ Fill OutputDeployScript Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PublishFile
{{ Fill PublishFile Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ServiceObjective
{{ Fill ServiceObjective Description }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SettingsToCheck
{{ Fill SettingsToCheck Description }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetConnectionString
{{ Fill TargetConnectionString Description }}

```yaml
Type: String
Parameter Sets: ConnectionStringTarget
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetDatabaseName
{{ Fill TargetDatabaseName Description }}

```yaml
Type: String
Parameter Sets: IndividualTarget
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetIntegratedSecurity
{{ Fill TargetIntegratedSecurity Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetPasswordSecure
{{ Fill TargetPasswordSecure Description }}

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetServerName
{{ Fill TargetServerName Description }}

```yaml
Type: String
Parameter Sets: IndividualTarget
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetTimeout
{{ Fill TargetTimeout Description }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetTrustServerCert
{{ Fill TargetTrustServerCert Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetUser
{{ Fill TargetUser Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TenantId
{{ Fill TenantId Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Variables
{{ Fill Variables Description }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -action
{{ Fill action Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -dacpacfile
{{ Fill dacpacfile Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -scriptParentPath
{{ Fill scriptParentPath Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -sqlpackagePath
{{ Fill sqlpackagePath Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
