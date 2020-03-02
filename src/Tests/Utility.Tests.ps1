
$currentPath = (Split-Path -Parent $MyInvocation.MyCommand.Path)
. $currentPath\Common\SetEnvironment.ps1
Import-Module "$currentPath\..\ps_modules\VstsTaskSdk" -ErrorAction SilentlyContinue

. $currentPath\..\ps_modules\CommonScripts\GovernanceUtility.ps1

Describe 'Governance Utility Tests' {

    $fullPolicySample = Get-Content -Path "$currentPath/testfiles/Policies/azurepolicy.json"  -Raw
    $fullInitiativeSample = Get-Content -Path "$currentPath/testfiles/Policies/policyset.json"  -Raw

    Mock Write-VstsTaskError{
        return $Message
    }

    Context "Get-GovernanceFullDeploymentParameters" {

        Mock Get-Content {
            if ($Path -eq "azurepolicy.json") {
                return $fullPolicySample 
            }
            else {
                return $fullInitiativeSample 
            }
        }

        Mock Confirm-FileExists { }

        It -Name "Get parameters for the GovernanceType='<GovernanceType>' on subscription scope with file path '<GovernanceFilePath>'"  -TestCases @(
            @{GovernanceType = "Policy"; GovernanceFilePath = "azurepolicy.json" }
            @{GovernanceType = "Initiative"; GovernanceFilePath = "policyset.json" }
        ) {
            param ($GovernanceType, $GovernanceFilePath)            

            $subscriptionId = "450ea969-5877-4111-adde-73ef483c6a3a"
            $parameters = Get-GovernanceFullDeploymentParameters `
                -GovernanceType $GovernanceType `
                -SubscriptionId $subscriptionId `
                -GovernanceFilePath $GovernanceFilePath

            $parameters["SubscriptionId"] | Should -Be $subscriptionId

            if ($GovernanceType -eq "Policy") {
                $parameters.ContainsKey("PolicyRule") | Should -Be $true
                $parameters.ContainsKey("Mode") | Should -Be $true
            }
            elseif ($GovernanceType -eq "Initiative") {
                $parameters.ContainsKey("PolicyDefinition") | Should -Be $true
            }
        }
    }

    Context "Confirm-FileExists" {
        
        Mock Test-Path {
            if($Path -eq "C:/MyPath/MyFile.txt"){
                return $true
            }else{
                return $false
            }
        }

        It -Name "Should throw exception when non existing FilePath with FileContext '<FileContext>'"  -TestCases @(
            @{FilePath = "C:/Some/NonExistingFile.txt"; FileContext= "initiative test"}
            @{FilePath = "C:/Some/NonExistingFile.txt"; FileContext= "policy test"}
        ) {
            param ($FilePath, $FileContext)            

            $errorMessage = Confirm-FileExists -FilePath $FilePath -FileContext $FileContext

            $errorMessage | Should -BeLike "* $FileContext *"
            $errorMessage | Should -BeLike "* '$FilePath' *"
        }

        It -Name "Should not throw exception when existing FilePath"  -TestCases @(
            @{FilePath = "C:/MyPath/MyFile.txt"}
        ) {
            param ($FilePath)
            {Confirm-FileExists -FilePath $FilePath -FileContext "my context"} | Should -Not -Throw
        }
    }

    Context "Write-GovernanceError" {

        It -Name "Should throw an error message"{

            $errorMessage = "Some error"
            $fullErrorMessage = ""
            try{
                throw $errorMessage
            }
            catch{
                $fullErrorMessage = Write-GovernanceError $_
            }

            $fullErrorMessage | Should -BeLike "*The error message was: $errorMessage*"
        }

    }
}