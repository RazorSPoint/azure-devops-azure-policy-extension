Set-StrictMode -Version Latest

$currentPath = (Split-Path -Parent $MyInvocation.MyCommand.Path)
. $currentPath\Common\SetEnvironment.ps1

Import-Module "$currentPath\..\ps_modules\VstsTaskSdk" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

. $currentPath\..\ps_modules\CommonScripts\GovernanceUtility.ps1

Describe 'Azure Policy V2 Tests' {

    $policyParameters = Get-Content -Path "$currentPath/testfiles/Policies/azurepolicy.parameters.json" | ConvertFrom-Json
    $policyRule = Get-Content -Path "$currentPath/testfiles/Policies/azurepolicy.json" | ConvertFrom-Json
    $policyFromPortal = Get-Content -Path "$currentPath/testfiles/Policies/azurepolicy.fromPortal.json" | ConvertFrom-Json

    $policy = @{
        Name        = "DenyCostCenterFromRg"       
        DisplayName = "Deny if cost center tag value from parent resource group not valid"       
        Description = "Enforces the required tag 'CC' (cost center) value from the parent resource groups to the child resource."       
        Metadata    = "{ 'category': 'SHH Tagging' }"
        Parameters  = $policyParameters | Out-String
        Mode        = "indexed"
        PolicyRule  = $policyRule | Out-String
    }

    Mock Get-VstsEndpoint {     
        return _getEndPointEnvironment    
    }

    Mock Get-VstsInput {
        #return only env varaible initialized at the beginning
        $path = "Env:INPUT_$Name"
        return (Get-Item -LiteralPath $path).Value
    }

    Mock Get-AzPolicyDefinition {
        if ($Name -eq "DenyCostCenterFromRg") {
            return $policyFromPortal 
        }
        else {
            return $null
        }
    }

    Mock Set-AzPolicyDefinition { return $policyFromPortal }

    Mock New-AzPolicyDefinition { return $policyFromPortal }

    Mock Write-VstsTaskVerbose { return $null }

    Context -Name "DeploySplittedPolicyDefinition.ps1" {
        It -Name "It does not throw errors for scope <Scope> and policy IsExisting = <IsExisting>" -TestCases @(
            @{Scope = "Subscription"; IsExisting = $true }
            @{Scope = "Subscription"; IsExisting = $false }
            @{Scope = "ManagementGroup"; IsExisting = $true }
            @{Scope = "ManagementGroup"; IsExisting = $false }
        ) {
            param ($Scope, $IsExisting)            

            $tmpPolicy = $null
            
            $tmpPolicy = New-Object Hashtable
            $policy.Keys | ForEach-Object {
                $tmpPolicy[$_] = $policy[$_]
            }
            
            if (!$IsExisting) {
                $tmpPolicy.Name = "NonExistingPolicy"
            }

            if ($Scope -eq "Subscription") {
                $tmpPolicy.SubscriptionId = "84756c8c-14a5-44c4-bf3b-e1592fbfcf38"                    
            }
            elseif ($Scope -eq "ManagementGroup") {
                $tmpPolicy.ManagementGroupId = "8e769067-5d7d-4eb7-8b6f-ff47e4f3e8c1"
            }

            {
                $null = . $currentPath\..\AzurePolicy\AzurePolicyV2\DeploySplittedPolicyDefinition.ps1 @tmpPolicy -ErrorAction Stop
            } | Should -Not -Throw

        }
    }
}