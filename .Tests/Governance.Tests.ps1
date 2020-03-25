Set-StrictMode -Version Latest

$currentPath = (Split-Path -Parent $MyInvocation.MyCommand.Path)
. $currentPath\Common\SetEnvironment.ps1

if ($null -eq $(Get-Module -Name VstsTaskSdk)) {
    Install-Module -Name VstsTaskSdk -Repository PSGallery -Force -Scope CurrentUser -AllowClobber -SkipPublisherCheck  
    Import-Module VstsTaskSdk  
}

Import-Module "$currentPath\ps_modules\VstsTaskSdk" -ErrorAction SilentlyContinue

. $currentPath\..\src\ps_modules\CommonScripts\GovernanceUtility.ps1

Describe 'Governance Utility Tests' {

    $fullPolicySample = Get-Content -Path "$currentPath/testfiles/Policies/azurepolicy.json"  -Raw
    $fullInitiativeSample = Get-Content -Path "$currentPath/testfiles/Policies/policyset.json"  -Raw

    Mock Write-VstsTaskError {
        return $Message
    }

    Mock Get-VstsInput {
        #return only env varaible initialized at the beginning
        $path = "Env:INPUT_$Name"
        return (Get-Item -LiteralPath $path).Value
    }

    Mock Get-VstsEndpoint {     
        return _getEndPointEnvironment    
    }

    Mock Write-VstsTaskVerbose { return $null }

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

        It -Name "Get parameters for the GovernanceType='<GovernanceType>' on <Scope> scope with file path '<GovernanceFilePath>'"  -TestCases @(
            @{GovernanceType = "PolicyDefinition"; GovernanceFilePath = "azurepolicy.json"; Scope = "ManagementGroupId" }
            @{GovernanceType = "PolicyInitiative"; GovernanceFilePath = "policyset.json"; Scope = "ManagementGroupId" }
            @{GovernanceType = "PolicyDefinition"; GovernanceFilePath = "azurepolicy.json"; Scope = "SubscriptionId" }
            @{GovernanceType = "PolicyInitiative"; GovernanceFilePath = "policyset.json"; Scope = "SubscriptionId" }
        ) {
            param ($GovernanceType, $GovernanceFilePath, $Scope)            

            $guid = "450ea969-5877-4111-adde-73ef483c6a3a"

            $parameters = @{
                GovernanceType     = $GovernanceType
                GovernanceFilePath = $GovernanceFilePath
                "$Scope"           = $guid
            } 

            $resultParameters = Get-GovernanceFullDeploymentParameters @parameters
            $resultParameters[$Scope] | Should -Be $guid           
            
            if ($GovernanceType -eq "PolicyDefinition") {
                $resultParameters.ContainsKey("PolicyRule") | Should -Be $true
                $resultParameters.ContainsKey("Mode") | Should -Be $true
            }
            elseif ($GovernanceType -eq "PolicyInitiative") {
                $resultParameters.ContainsKey("PolicyDefinition") | Should -Be $true
            }
        }
    }

    Context "Get-GovernanceDeploymentParameters" {

        $policy = (Get-Content -Path "$currentPath\testfiles\Policies\azurepolicy.json" -Raw | ConvertFrom-Json)

        Mock Confirm-FileExists { }

        Mock Get-GovernanceFullDeploymentParameters {

            #Write-Host $args

            return  @{
                Name        = $policy.name
                DisplayName = $policy.properties.displayName
                Description = $policy.properties.description
                Metadata    = $policy.properties.metadata | ConvertTo-Json -Depth 30 -Compress
                Mode        = $policy.properties.mode
                Parameters  = $policy.properties.parameters | ConvertTo-Json -Depth 30 -Compress
                PolicyRule  = $policy.properties.policyRule | ConvertTo-Json -Depth 30 -Compress
            }
        }

        It -Name "Get parameters for the from test case file '<TestDataFile>' should not throw exception"  -TestCases @(
            @{TestDataFile = "policy.managementgroup.Full-File.json" }
            @{TestDataFile = "policy.subscription.Full-File.json" }            
            @{TestDataFile = "policy.subscription.Full-Inline.json" }
            @{TestDataFile = "policy.managementgroup.Full-Inline.json" }
        ) {
            param ($TestDataFile) 
            _setGovernanceEnvironment -Path "$currentPath\testfiles\TestCases\$TestDataFile"
            $governanceType = (Get-Content -Path "$currentPath\testfiles\TestCases\$TestDataFile" -Raw | ConvertFrom-Json)."GovernanceType"
            {                 
                Get-GovernanceDeploymentParameters -GovernanceType $governanceType -TempPath "C:\_temp" -TempFileName "12bed85d-f556-479c-86a6-78239d6a8c96.json"
            } | Should -Not -Throw
        }

        It -Name "Get parameters for the from test case file '<TestDataFile>' should match returning parameters"  -TestCases @(
            @{TestDataFile = "policy.managementgroup.Full-File" }
            @{TestDataFile = "policy.managementgroup.Full-Inline" }
            @{TestDataFile = "policy.managementgroup.Splitted-File" }
            @{TestDataFile = "policy.managementgroup.Splitted-Inline" }
            @{TestDataFile = "policy.subscription.Full-File" }
            @{TestDataFile = "policy.subscription.Full-Inline" }
            @{TestDataFile = "policy.subscription.Splitted-File" }
            @{TestDataFile = "policy.subscription.Splitted-Inline" }
            
        ) {
            param ($TestDataFile) 
            _setGovernanceEnvironment -Path "$currentPath\testfiles\TestCases\$TestDataFile.json"
            
            $governanceType = (Get-Content -Path "$currentPath\testfiles\TestCases\$TestDataFile.json" -Raw | ConvertFrom-Json)."GovernanceType"            
            $expectedParameters = (Get-Content -Path "$currentPath\testfiles\ReturnData\$TestDataFile.return.json" -Raw | ConvertFrom-Json)

            $ouputParameters = Get-GovernanceDeploymentParameters -GovernanceType $governanceType -TempPath "C:\_temp" -TempFileName "12bed85d-f556-479c-86a6-78239d6a8c96.json"

            $expectedParamNames = ($expectedParameters | Get-Member -MemberType NoteProperty).Name

            $expectedParamNames.Count -eq $ouputParameters.Keys.Count | Should -Be $true
            foreach ($parameterName in $expectedParamNames) {
                $ouputParameters.ContainsKey($parameterName) `
                | Should -Be $true
            }
        }
    }

    Context "Confirm-FileExists" {
        
        Mock Test-Path {
            if ($Path -eq "C:/MyPath/MyFile.txt") {
                return $true
            }
            else {
                return $false
            }
        }
        Mock Write-VstsTaskError {
            #Write-Host $args
            return ""
        }

        Mock Write-VstsSetResult {
            #Write-Host $args
            return ""
        }

        It -Name "Should throw Write-VstsTaskError when non existing FilePath with FileContext '<FileContext>'"  -TestCases @(
            @{FilePath = "C:/Some/NonExistingFile.txt"; FileContext = "initiative test" }
            @{FilePath = "C:/Some/NonExistingFile.txt"; FileContext = "policy test" }
        ) {
            param ($FilePath, $FileContext)            

            Confirm-FileExists -FilePath $FilePath -FileContext $FileContext
            
            Assert-MockCalled Write-VstsTaskError -Exactly -Scope It -Times 1 -ParameterFilter {
                $Message -like "*File path '$FilePath' for $FileContext does not exist*"
            }

            Assert-MockCalled Write-VstsSetResult -Exactly -Scope It -Times 1 -ParameterFilter {
                $Result -like "*Failed*" -and
                $Message -like "*Error detected*"
            }
        }

        It -Name "Should not throw exception when existing FilePath"  -TestCases @(
            @{FilePath = "C:/MyPath/MyFile.txt" }
        ) {
            param ($FilePath)
            { Confirm-FileExists -FilePath $FilePath -FileContext "my context" } | Should -Not -Throw
        }
    }

    Context "Write-GovernanceError" {

        Mock Write-VstsSetResult { }

        Mock Write-VstsTaskError {
            return "MyErrorMessage $Exception."
        }

        It -Name "Should throw an error message" {

            $errorMessage = "Some error"
            $fullErrorMessage = ""
            try {
                throw $errorMessage
            }
            catch {
                $fullErrorMessage = Write-GovernanceError -Exception $_
            }
            $fullErrorMessage | Should -BeLike "*MyErrorMessage $errorMessage.*"
        }

    }    

    Context "Add-TemporaryJsonFile" {

        Mock Write-VstsTaskError {
            #Write-Host $args
            return ""
        }

        Mock New-Item { 
            #Write-Host $args
        }

        Mock Out-File {
            #Write-Host $args
        }

        Mock Test-Path {
            # expect that the path must always be created
            return $false
        }

        $json = '{"JsonProp":"JsonVal"}'
        $env:AGENT_RELEASEDIRECTORY = $PSScriptRoot

        It -Name "File with json file path should be like expected path" { 

            $filePath = Add-TemporaryJsonFile -JsonInline $json -TempPath "C:\_temp" -FileName "dd4e2c93-891d-4698-a7a6-9d497eceebad.json"
            $filePath | Should -Be "C:\_temp\dd4e2c93-891d-4698-a7a6-9d497eceebad.json"
        }

        It -Name "Wrong JSON should return error message" { 

            $json = '{JsonProp":"JsonVal"}'

            $null = Add-TemporaryJsonFile -JsonInline $json -TempPath "C:\_temp" -FileName "1755dc5e-3935-4783-9aaf-11d69435d1e4.json"

            Assert-MockCalled Write-VstsTaskError -Exactly -Scope It -Times 1 -ParameterFilter {
                $Message -like "Invalid object passed in*"
            }
           
        }

    }    

    Context -Name "DeploySplittedPolicyDefinition.ps1" {


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
                $null = Publish-SplittedPolicyDefinition @tmpPolicy -ErrorAction Stop
            } | Should -Not -Throw

        }
    }

    Context -Name "Get-TemporaryFileName" {

        It -Name "create random file name with <Extension> extension" -TestCases @(
            @{Extension = "json" }
            @{Extension = "xml" }
        ) {
            param (
                $Extension
            )

            $tempFile = Get-TemporaryFileName -FileExtension $Extension
            $tempFile | Should -BeLike "*.$Extension"
        }

        It -Name "create random file with not supported extension" {

            { Get-TemporaryFileName -FileExtension "html" } | Should Throw  'The argument "html" does not belong to the set "xml,json" specified by the ValidateSet attribute'
        }
    }
}