$ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition

Import-Module "$ScriptPath\..\src\ps_modules\VstsTaskSdk"

# Input 'MyInput':
$env:INPUT_FileOrInline = "File"
$env:INPUT_JsonInline = "Write-Host 'Test!!'"
$env:AGENT_TEMPDIRECTORY = "C:\temp\"
$env:AGENT_RELEASEDIRECTORY = "C:"
$env:INPUT_JsonInline = ""
$env:INPUT_GovernanceType = "PolicyDefinition"
$env:INPUT_DefinitionLocation = "ManagementGroup"
$env:INPUT_SubscriptionId = "2b53247c-fb65-469e-a711-46e0c29d15a1"
$env:INPUT_ManagementGroupName = "40c38f6e-28c8-4fed-a4bb-af9c951b17ab"
$env:INPUT_DeploymentType = "Splitted"
$env:INPUT_ParametersFilePath = "$ScriptPath/testfiles/azurepolicy.Audit-PIP.parameters.json"
$env:INPUT_PolicyRuleFilePath = "$ScriptPath/testfiles/azurepolicy.Audit-PIP.json"
$env:INPUT_Category = "RazorSPoint"
$env:INPUT_Name = "Audit-PIP"
$env:INPUT_DisplayName = "Audit PIP"
$env:INPUT_Mode = "all"
$env:INPUT_Description = "Audit PIP Description"


Invoke-VstsTaskScript -ScriptBlock { . $ScriptPath\..\src\AzurePolicy\AzurePolicyV1\StartDeploy.ps1 }

Exit