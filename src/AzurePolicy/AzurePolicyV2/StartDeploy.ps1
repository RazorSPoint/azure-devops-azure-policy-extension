. $PSScriptRoot\ps_modules\CommonScripts\GovernanceUtility.ps1

$JsonFilePath = $null

[string]$DefinitionLocation = Get-VstsInput -Name DefinitionLocation
[string]$SubscriptionId = Get-VstsInput -Name SubscriptionId
[string]$ManagementGroupName = Get-VstsInput -Name ManagementGroupName
[string]$DeploymentType = Get-VstsInput -Name DeploymentType

$parameters = @{ }

try {

    . $PSScriptRoot\ps_modules\CommonScripts\ModuleUtility.ps1

    $serviceName = Get-VstsInput -Name ConnectedServiceName -Require
    $endpointObject = Get-VstsEndpoint -Name $serviceName -Require
    $endpoint = ConvertTo-Json $endpointObject

    . $PSScriptRoot\ps_modules\CommonScripts\CoreAz.ps1 -endpoint "$endpoint"  

    # get the tmp path of the agent
    $agentTmpPath = "$($env:AGENT_RELEASEDIRECTORY)\_temp"

    $parameters = Get-GovernanceDeploymentParameters -GovernanceType PolicyDefinition -TempPath $agentTmpPath

    . "$PSScriptRoot\DeploySplittedPolicyDefinition.ps1" @parameters
}
catch {
    Write-GovernanceError -Exception $_ 
}
finally {
    Clear-GovernanceEnvironment -TemporaryFilePath $JsonFilePath

    Import-Module $PSScriptRoot\..\VstsAzureHelpers_
    Remove-EndpointSecrets
    Disconnect-AzureAndClearContext -ErrorAction SilentlyContinue
}

