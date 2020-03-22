. $PSScriptRoot\ps_modules\CommonScripts\GovernanceUtility.ps1
. $PSScriptRoot\ps_modules\CoreScripts\ModuleUtility.ps1

$parameters = @{ }

try {
    $serviceName = Get-VstsInput -Name ConnectedServiceName -Require
    $endpointObject = Get-VstsEndpoint -Name $serviceName -Require
    $endpoint = ConvertTo-Json $endpointObject

    . $PSScriptRoot\ps_modules\CoreScripts\CoreAz.ps1 -endpoint "$endpoint"  

    # get the tmp path of the agent
    $agentTmpPath = "$($env:AGENT_RELEASEDIRECTORY)\_temp"
    $tempFileName = Get-TemporaryFileName

    $parameters = Get-GovernanceDeploymentParameters -GovernanceType PolicyDefinition -TempPath $agentTmpPath -TempFileName $tempFileName

    Publish-SplittedPolicyDefinition @parameters
}
catch {
    Write-GovernanceError -Exception $_ 
}
finally {
    if (Test-Path -LiteralPath "$agentTmpPath/$tempFileName") {
        Remove-Item -LiteralPath "$agentTmpPath/$tempFileName" -ErrorAction 'SilentlyContinue'
    }

    Import-Module $PSScriptRoot\..\VstsAzureHelpers_
    Remove-EndpointSecrets
    Disconnect-AzureAndClearContext -ErrorAction SilentlyContinue
}

