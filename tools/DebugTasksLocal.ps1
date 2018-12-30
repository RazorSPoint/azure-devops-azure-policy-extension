Import-Module .\ps_modules\VstsTaskSdk

# Input 'MyInput':
$env:INPUT_FileOrInline = "File"
$env:INPUT_JsonInline = "Write-Host 'Test!!'"
$env:AGENT_TEMPDIRECTORY = "C:\temp\"

Invoke-VstsTaskScript -ScriptBlock { . .\..\src\AzurePolicy\AzurePolicyV1\StartDeploy.ps1 }

Exit