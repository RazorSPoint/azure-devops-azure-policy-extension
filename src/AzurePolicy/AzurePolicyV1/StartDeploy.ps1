[CmdletBinding()]
param()



# For more information on the VSTS Task SDK:
# https://github.com/Microsoft/vsts-task-lib

Trace-VstsEnteringInvocation $MyInvocation

try {

    Import-VstsLocStrings "$PSScriptRoot/task.json"

    Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_    
    . "$PSScriptRoot\ps_modules\CommonScripts\Utility.ps1"

    # get the tmp path of the agent
    $agentTmpPath = "$($env:AGENT_RELEASEDIRECTORY)\_temp"
    $tmpInlineJaonFileName = [System.IO.Path]::GetRandomFileName() + ".json"

    [string]$GovernanceType = Get-VstsInput -Name GovernanceType

    [string]$FileOrInline = Get-VstsInput -Name FileOrInline

    if ($FileOrInline -eq "File") {
        [string]$JsonFilePath = Get-VstsInput -Name JsonFilePath
        if (-not (Test-Path $JsonFilePath)) {
            Write-VstsTaskError -Message "`nFile path '$JsonFilePath' for parameter JsonFilePath does not exist.`n"
        }
    }
    else {

        #get json string and check for valid json
        [string]$JsonInline = (Get-VstsInput -Name JsonInline)
		
        $JsonObject = New-Object -TypeName "PSCustomObject"
        try {
            $JsonFilePath = "$agentTmpPath/$tmpInlineJaonFileName"
            #if path not exists, create it!
            if (-not (Test-Path -Path $agentTmpPath)) {
                New-Item -ItemType Directory -Force -Path $agentTmpPath
            }
            $JsonObject = ConvertFrom-Json -InputObject $JsonInline
            $JsonObject | ConvertTo-Json -depth 100 | Out-File $JsonFilePath
        }
        catch [System.ArgumentException] {
            Write-VstsTaskError -Message "$($_.toString())"
        }
    }

    Write-VstsTaskWarning -Message "`$JsonObject: $JsonObject"
    Write-VstsTaskWarning -Message "`$JsonFilePath :$JsonFilePath"
    Write-VstsTaskWarning -Message "`$GovernanceType :$GovernanceType"

    #init azure connection
    Initialize-Azure


}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-VstsTaskError -Message "`nAn Error occured. The error message was: $ErrorMessage. `n Stackstace `n $($_.ScriptStackTrace)`n"
    Write-VstsSetResult -Result 'Failed' -Message "Error detected" -DoNotThrow
}
finally {
    Trace-VstsLeavingInvocation $MyInvocation

    #clean up tmp path
    if ($FileOrInline -eq 'Inline' -and (Test-Path $agentTmpPath)) {
        Remove-Item $agentTmpPath -Recurse       
    }
}
    
