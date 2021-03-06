[CmdletBinding()]
param
(
    [String] [Parameter(Mandatory = $true)]
    $endpoint,

    [String] [Parameter(Mandatory = $false)]
    $targetAzurePs
)

Import-Module "$PSScriptRoot\..\VstsTaskSdk" -ArgumentList @{ NonInteractive = $true }
#Import-VstsLocStrings -LiteralPath "$PSScriptRoot\..\..\task.json"

# Update PSModulePath for hosted agent
. "$PSScriptRoot\ModuleUtility.ps1"
CleanUp-PSModulePathForHostedAgent
Update-PSModulePathForHostedAgent -targetAzurePs $targetAzurePs

$endpointObject =  ConvertFrom-Json  $endpoint
Import-Module $PSScriptRoot\..\VstsAzureHelpers_
Initialize-AzModule -Endpoint $endpointObject -azVersion $targetAzurePs