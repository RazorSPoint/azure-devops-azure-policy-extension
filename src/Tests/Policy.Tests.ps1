Set-StrictMode -Version Latest



$currentPath = (Split-Path -Parent $MyInvocation.MyCommand.Path)
. $currentPath\Common\SetEnvironment.ps1
Import-Module "$currentPath\..\ps_modules\VstsTaskSdk" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

Mock Get-VstsEndpoint {       
    return $endPoint 
}

. $currentPath\..\ps_modules\CommonScripts\GovernanceUtility.ps1


Describe 'Azure Policy Tests' {

    Mock Get-VstsEndpoint {       
        return $endPoint 
    }

    # Input 'MyInput':
    $env:INPUT_FileOrInline = "File"
    $env:INPUT_JsonInline = "Write-Host 'Test!!'"
    $env:INPUT_JsonInline = ""
    $env:INPUT_GovernanceType = "PolicyDefinition"
    $env:INPUT_DefinitionLocation = "ManagementGroup"

    $env:INPUT_DeploymentType = "Splitted"
    $env:INPUT_ParametersFilePath = "$currentPath/testfiles/Policies/azurepolicy.Audit-PIP.parameters.json"
    $env:INPUT_PolicyRuleFilePath = "$currentPath/testfiles/Policies/azurepolicy.Audit-PIP.json"
    $env:INPUT_Category = "RazorSPoint"
    $env:INPUT_Name = "Audit-PIP"
    $env:INPUT_DisplayName = "Audit PIP"
    $env:INPUT_Mode = "all"
    $env:INPUT_Description = "Audit PIP Description"

    Context -Name "Version 1 Tests" {

        It -Name "Deploy Policy V1 does not throw errors" {           

            { Invoke-VstsTaskScript -ScriptBlock { 
                    . $currentPath\..\AzurePolicy\AzurePolicyV1\StartDeploy.ps1
                } -ErrorAction Stop
            } | Should -Not -Throw
        }      

    }   

}