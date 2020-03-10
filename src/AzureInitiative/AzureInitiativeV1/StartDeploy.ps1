. $PSScriptRoot\ps_modules\CommonScripts\GovernanceUtility.ps1

$JsonFilePath = $null
    

$parameters = @{ }
  
try {
      
    . $PSScriptRoot\ps_modules\CommonScripts\ModuleUtility.ps1

    $serviceName = Get-VstsInput -Name ConnectedServiceName -Require
    $endpointObject = Get-VstsEndpoint -Name $serviceName -Require
    $endpoint = ConvertTo-Json $endpointObject

    . $PSScriptRoot\ps_modules\CommonScripts\CoreAz.ps1 -endpoint "$endpoint"  

    $parameters = Get-GovernanceDeploymentParameters -GovernanceType PolicyInitiative

    . "$PSScriptRoot\DeploySplittedPolicyInitiative.ps1" @parameters
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

