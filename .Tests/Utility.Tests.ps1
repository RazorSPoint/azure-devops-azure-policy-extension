Set-StrictMode -Version Latest

$WarningPreference = "SilentlyContinue"
$currentPath = (Split-Path -Parent $MyInvocation.MyCommand.Path)
. $currentPath\Common\SetEnvironment.ps1
Import-Module "$currentPath\..\src\ps_modules\VstsTaskSdk" -ErrorAction SilentlyContinue

. $currentPath\..\src\ps_modules\CommonScripts\GovernanceUtility.ps1
$WarningPreference = "Continue"

Describe 'Governance Utility Tests' {

    $fullPolicySample = Get-Content -Path "$currentPath/testfiles/Policies/azurepolicy.json"  -Raw
    $fullInitiativeSample = Get-Content -Path "$currentPath/testfiles/Policies/policyset.json"  -Raw

    Mock Write-VstsTaskError {
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
            @{GovernanceType = "PolicyDefinition"; GovernanceFilePath = "azurepolicy.json" }
            @{GovernanceType = "PolicyInitiative"; GovernanceFilePath = "policyset.json" }
        ) {
            param ($GovernanceType, $GovernanceFilePath)            

            $subscriptionId = "450ea969-5877-4111-adde-73ef483c6a3a"
            $parameters = Get-GovernanceFullDeploymentParameters `
                -GovernanceType $GovernanceType `
                -SubscriptionId $subscriptionId `
                -GovernanceFilePath $GovernanceFilePath

            $parameters["SubscriptionId"] | Should -Be $subscriptionId

            if ($GovernanceType -eq "PolicyDefinition") {
                $parameters.ContainsKey("PolicyRule") | Should -Be $true
                $parameters.ContainsKey("Mode") | Should -Be $true
            }
            elseif ($GovernanceType -eq "PolicyInitiative") {
                $parameters.ContainsKey("PolicyDefinition") | Should -Be $true
            }
        }
    }

    Context "Get-GovernanceDeploymentParameters" {

        $policy = (Get-Content -Path "$currentPath\testfiles\Policies\azurepolicy.json" -Raw | ConvertFrom-Json)

        Mock Get-VstsInput {
            #return only env varaible initialized at the beginning
            $path = "Env:INPUT_$Name"
            return (Get-Item -LiteralPath $path).Value
        }

        Mock Confirm-FileExists { }

        Mock Get-GovernanceFullDeploymentParameters{

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
                Get-GovernanceDeploymentParameters -GovernanceType $governanceType -TempPath "C:\_temp"
            } | Should -Not -Throw
        }

        It -Name "Get parameters for the from test case file '<TestDataFile>' should match returning parameters"  -TestCases @(
            @{TestDataFile = "policy.managementgroup.Full-File" }
            @{TestDataFile = "policy.subscription.Full-File" }
            @{TestDataFile = "policy.subscription.Full-Inline" }
            @{TestDataFile = "policy.managementgroup.Full-Inline" }
            
        ) {
            param ($TestDataFile) 
            _setGovernanceEnvironment -Path "$currentPath\testfiles\TestCases\$TestDataFile.json"
            
            $governanceType = (Get-Content -Path "$currentPath\testfiles\TestCases\$TestDataFile.json" -Raw | ConvertFrom-Json)."GovernanceType"            
            $expectedParameters = (Get-Content -Path "$currentPath\testfiles\ReturnData\$TestDataFile.return.json" -Raw | ConvertFrom-Json)

            $ouputParameters = Get-GovernanceDeploymentParameters -GovernanceType $governanceType -TempPath "C:\_temp"

            $expectedParamNames = ($expectedParameters | Get-Member -MemberType NoteProperty).Name
            foreach ($parameterName in $expectedParamNames) {
                
                $ouputParameters.ContainsKey($parameterName) `
                 -and $ouputParameters[$parameterName] -eq $expectedParameters."$parameterName" `
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

        Mock Write-VstsSetResult {}

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

    Context "Clear-GovernanceEnvironment" {

        It -Name "Temporary file should not exist anymore" {

            $tmpInlineJsonFileName = "$PSScriptRoot/$([System.IO.Path]::GetRandomFileName()).json"
            "{}" | Out-File $tmpInlineJsonFileName

            Clear-GovernanceEnvironment -TemporaryFilePath $tmpInlineJsonFileName

            $tmpInlineJsonFileName | Should -Not -Exist
        }

        It -Name "Non existing temporary file should not throw" {

            $tmpInlineJsonFileName = "$PSScriptRoot/$([System.IO.Path]::GetRandomFileName()).json"

            { Clear-GovernanceEnvironment -TemporaryFilePath $tmpInlineJsonFileName } | Should -Not -Throw

        }

    }

    Context "Add-TemporaryJsonFile" {

        Mock Write-VstsTaskError {
            #Write-Host $args
            return ""
        }

        $json = '{"JsonProp":"JsonVal"}'
        $env:AGENT_RELEASEDIRECTORY = $PSScriptRoot

        It -Name "File created has been created" {
            $filePath = Add-TemporaryJsonFile -JsonInline $json -TempPath "C:\_temp"
            $filePath | Should -Exist

            Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue   
        }

        It -Name "File with JSON should be like input JSON" { 

            $filePath = Add-TemporaryJsonFile -JsonInline $json -TempPath "C:\_temp"
            $fileContent = Get-Content -Path $filePath -Raw
            $fileContent | Should -BeLike "*$json*"

            Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue           
        }

        It -Name "Wrong JSON should return error message" { 

            $json = '{JsonProp":"JsonVal"}'

            $null = Add-TemporaryJsonFile -JsonInline $json -TempPath "C:\_temp"

            Assert-MockCalled Write-VstsTaskError -Exactly -Scope It -Times 1 -ParameterFilter {
                $Message -like "Invalid object passed in*"
            }
           
        }

    }
}