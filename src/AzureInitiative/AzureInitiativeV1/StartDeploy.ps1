. $PSScriptRoot\ps_modules\CommonScripts\GovernanceUtility.ps1
. $PSScriptRoot\ps_modules\CommonScripts\ModuleUtility.ps1

$parameters = @{ }
  
try {
    $serviceName = Get-VstsInput -Name ConnectedServiceName -Require
    $endpointObject = Get-VstsEndpoint -Name $serviceName -Require
    $endpoint = ConvertTo-Json $endpointObject

    . $PSScriptRoot\ps_modules\CommonScripts\CoreAz.ps1 -endpoint "$endpoint"  

    # get the tmp path of the agent
    $agentTmpPath = "$($env:AGENT_RELEASEDIRECTORY)\_temp"
    $tempFileName = Get-TemporaryFileName
  
    $parameters = Get-GovernanceDeploymentParameters -GovernanceType PolicyInitiative -TempPath $agentTmpPath -TempFileName $tempFileName

    Publish-SplittedPolicyInitiative @parameters
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

