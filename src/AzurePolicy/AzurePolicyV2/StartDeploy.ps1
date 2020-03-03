. $PSScriptRoot\ps_modules\CommonScripts\GovernanceUtility.ps1

$JsonFilePath = $null

[string]$DefinitionLocation = Get-VstsInput -Name DefinitionLocation
[string]$SubscriptionId = Get-VstsInput -Name SubscriptionId
[string]$ManagementGroupName = Get-VstsInput -Name ManagementGroupName
[string]$DeploymentType = Get-VstsInput -Name DeploymentType

$parameters = @{ }

try {

    if ($DefinitionLocation -eq "Subscription") {
        $parameters.SubscriptionId = $SubscriptionId
    }
    elseif ($DefinitionLocation -eq "ManagementGroup") {
        $parameters.ManagementGroupId = $ManagementGroupName
    }

    . $PSScriptRoot\ps_modules\CommonScripts\ModuleUtility.ps1

    $serviceName = Get-VstsInput -Name ConnectedServiceName -Require
    $endpointObject = Get-VstsEndpoint -Name $serviceName -Require
    $endpoint = ConvertTo-Json $endpointObject

    . $PSScriptRoot\ps_modules\CommonScripts\CoreAz.ps1 -endpoint "$endpoint"  


    if ($DeploymentType -eq "Full") {

        [string]$FileOrInline = Get-VstsInput -Name FileOrInline
    
        if ($FileOrInline -eq "File") {
            [string]$JsonFilePath = Get-VstsInput -Name JsonFilePath
            Confirm-FileExists -FilePath $JsonFilePath -FileContext "parameter JsonFilePath"
        }
        else {
            [string]$JsonInline = (Get-VstsInput -Name JsonInline)
            $JsonFilePath = Add-TemporaryJsonFile -JsonInline $JsonInline          
        }
        
        $parameters.GovernanceFilePath = $JsonFilePath  
        
        $parameters = Get-GovernanceFullDeploymentParameters @parameters -GovernanceType Policy

    }
    elseif ($DeploymentType -eq "Splitted") {       
        [string]$ParametersFilePath = Get-VstsInput -Name ParametersFilePath
        Confirm-FileExists -FilePath $ParametersFilePath -FileContext "Parameters"

        [string]$Category = Get-VstsInput -Name Category

        $parameters = @{
            Name        = Get-VstsInput -Name Name            
            DisplayName = Get-VstsInput -Name DisplayName
            Description = Get-VstsInput -Name Description
            Metadata    = "{ 'category': '$Category' }"
            Parameters  = Get-Content -Path $ParametersFilePath | Out-String
        }

        [string]$PolicyRuleFilePath = Get-VstsInput -Name PolicyRuleFilePath
        Confirm-FileExists -FilePath $PolicyRuleFilePath -FileContext "Policy Rule"

        $parameters.Mode = Get-VstsInput -Name Mode
        $parameters.PolicyRule = Get-Content -Path $PolicyRuleFilePath | Out-String 

    }

    . "$PSScriptRoot\..\..\DeploySplittedPolicyDefinition.ps1" @parameters
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

