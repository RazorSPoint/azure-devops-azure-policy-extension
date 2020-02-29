. $PSScriptRoot\ps_modules\CommonScripts\GovernanceUtility.ps1

$JsonFilePath = $null
    
[string]$DefinitionLocation = Get-VstsInput -Name DefinitionLocation
[string]$SubscriptionId = Get-VstsInput -Name SubscriptionId
[string]$ManagementGroupName = Get-VstsInput -Name ManagementGroupName
[string]$DeploymentType = Get-VstsInput -Name DeploymentType
  
$splattedArgs = @{ }
  
try {
  
    if ($DefinitionLocation -eq "Subscription") {
        $splattedArgs.SubscriptionId = $SubscriptionId
    }
    elseif ($DefinitionLocation -eq "ManagementGroup") {
        $splattedArgs.ManagementGroupId = $ManagementGroupName
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
            $JsonFilePath = Add-TemporaryJsonFile -JsonInline $JsonInline
        }
       
        $splattedArgs.GovernanceFilePath = $JsonFilePath 
        
        Invoke-GovernanceFullDeployment @splattedArgs -GovernanceType Initiative

    }
    elseif ($DeploymentType -eq "Splitted") {       
        [string]$ParametersFilePath = Get-VstsInput -Name ParametersFilePath
        Confirm-FileExists -FilePath $ParametersFilePath -FileContext "Parameters"

        [string]$Category = Get-VstsInput -Name Category

        $splattedArgs = @{
            Name        = Get-VstsInput -Name Name            
            DisplayName = Get-VstsInput -Name DisplayName
            Description = Get-VstsInput -Name Description
            Metadata    = "{ 'category': '$Category' }"
            Parameters  = Get-Content -Path $ParametersFilePath | Out-String
        }

        [string]$InitiativePolicyDefinitionsFilePath = Get-VstsInput -Name InitiativePolicyDefinitionsFilePath    
        Confirm-FileExists -FilePath $InitiativePolicyDefinitionsFilePath -FileContext "Policy Rule"
    
        $splattedArgs.PolicyDefinition = Get-Content -Path $InitiativePolicyDefinitionsFilePath | Out-String  

        . "$PSScriptRoot\DeploySplittedPolicyInitiative.ps1" @splattedArgs
    }
}
catch {
    Write-GovernanceError -Exception $_ 
}
finally {
   Clear-GovernanceEnvironment -TemporaryFilePath $JsonFilePath
}

