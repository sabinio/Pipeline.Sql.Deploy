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

```
Invoke-DatabaseDacpacDeploy [-dacpacfile] <String> [-sqlpackagePath] <String> [-action] <String>
 [-scriptParentPath] <String> [-TargetServerName] <String> [-TargetDatabaseName] <String>
 [[-TargetUser] <String>] [[-TargetPasswordSecure] <SecureString>] [[-TargetIntegratedSecurity] <String>]
 [[-ServiceObjective] <String>] [[-PublishFile] <String>] [-OutputDeployScript] [-Variables] <Object>
 [-TargetTimeout] <Object> [-CommandTimeout] <Object> [<CommonParameters>]
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

### -CommandTimeout
{{ Fill CommandTimeout Description }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 13
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
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ServiceObjective
{{ Fill ServiceObjective Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetDatabaseName
{{ Fill TargetDatabaseName Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
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
Position: 8
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
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetServerName
{{ Fill TargetServerName Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
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
Position: 12
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
Position: 6
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
Position: 11
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
Position: 2
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
Position: 0
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
Position: 3
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
Position: 1
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
