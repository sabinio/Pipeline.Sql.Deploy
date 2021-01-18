# Introduction

Powershell module for Deploying SQL Server.

## Usage  

For usage of the module checkout the [docs](./docs/Home.md)

## Contributing

Obtain a PAT token from Azure DevOps that has scopes of package management.

Obtain the config setting for the pat token. This will create an entry in the [base config file](.build\config\base\config.json).
Copy the entry to your personal localdev config file in ```.build\config\personal\<user>-localdev.json```

``` powershell
Set-SecureSetting -ConfigRootPath .\.build\config\ -Name PowershellRepositoryKey -Value "<pat token>"
```

## Build, Test and Publish tasks

Activity|Command
-|-
Install tools and modules|```.build\pipeline-tasks.ps1 -install```
Build <br>(currently doesn't do much for PS Modules)|```.build\pipeline-tasks.ps1 -build```
Test|```.build\pipeline-tasks.ps1 -Test```
Package|```.build\pipeline-tasks.ps1 -package```
Publish|```.build\pipeline-tasks.ps1 -publish```

### Environments

configuraiton environments are used to group settings and allow publishing to different locations

Environment|Description
-|-|
localdev|Use to develop locally, publish to Azure DevOps Artifact feed, packages published as prerelease
ci|used for PR and CI stages, publish to Powershell gallery as prerelease
prod|Use to publish to powershell galley without prerelease setting

### Version numbers

For CI, PR and Prod version numbers are managed by AzureDevops build counters using a base version number.
For localdev the version number is 0.0.\<time\> where time is a combination of days since 2020 and elapsed minutes in the day. 
The prelrelease tag is defined based on config. Developers should specify their own prerelease setting 

### Testing

Pester tests are located in [TestFolder](.\src\Pipeline.Tools.Tests)

Each test should start with the following to ensure the test can be run on local source and downloaded modules

``` powershell
param($ModulePath)
$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")

if (-not $ModulePath){ $ModulePath = "$PSScriptRoot\..\SentryOne.Configure.module"}
. $ModulePath\Functions\$CommandName.ps1
```

## PSScriptAnalyser

All modules are analysed against PSScriptAnalyser rules using this [pester test](.\src\pipeline.Tools.tests\PSScript-Analyse.Tests.ps1)

## Documentation

Docs are generated to [docs folder](\docs\Home.md) using ```platyps```
