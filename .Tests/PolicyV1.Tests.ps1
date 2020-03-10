Set-StrictMode -Version Latest



$currentPath = (Split-Path -Parent $MyInvocation.MyCommand.Path)
. $currentPath\Common\SetEnvironment.ps1
Import-Module "$currentPath\..\src\ps_modules\VstsTaskSdk" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

. $currentPath\..\src\ps_modules\CommonScripts\GovernanceUtility.ps1

Describe 'Azure Policy V1 Tests' {

    Mock Get-VstsEndpoint {       
        return _getEndPointEnvironment
    }

    # Input 'MyInput':
    $env:INPUT_FileOrInline = "File"
    $env:INPUT_JsonInline = "Write-Host 'Test!!'"
    $env:INPUT_JsonInline = ""
    $env:INPUT_GovernanceType = "PolicyDefinition"
    $env:INPUT_DefinitionLocation = "ManagementGroup"
    $env:INPUT_ManagementGroupName = "59cf60f8-334f-4935-8668-2fba5c648985"    
    $env:INPUT_SubscriptionId = "5bf5b02f-4f35-4922-a882-041de0c78047"

    $env:INPUT_DeploymentType = "Splitted"
    $env:INPUT_ParametersFilePath = "$currentPath/testfiles/Policies/azurepolicy.Audit-PIP.parameters.json"
    $env:INPUT_PolicyRuleFilePath = "$currentPath/testfiles/Policies/azurepolicy.Audit-PIP.json"
    $env:INPUT_Category = "RazorSPoint"
    $env:INPUT_Name = "Audit-PIP"
    $env:INPUT_DisplayName = "Audit PIP"
    $env:INPUT_Mode = "all"
    $env:INPUT_Description = "Audit PIP Description"

    Context -Name "StartDeploy.ps1" {

        It -Name "Deploy Policy V1 does not throw errors" {           

            { Invoke-VstsTaskScript -ScriptBlock { 
                    #. $currentPath\..\src\AzurePolicy\AzurePolicyV1\StartDeploy.ps1
                } -ErrorAction Stop
            } | Should -Not -Throw
        }      

    }

    Context -Name "DeployFullPolicyDefinition.ps1" {

    }

    Context -Name "DeployFullPolicyInitiative.ps1" {
        
    }

    Context -Name "DeploySplittedPolicyDefinition.ps1" {
        
    }

    Context -Name "DeploySplittedPolicyInitiative.ps1" {
        
    }
}