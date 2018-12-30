[CmdletBinding()]
param()



# For more information on the VSTS Task SDK:
# https://github.com/Microsoft/vsts-task-lib

Trace-VstsEnteringInvocation $MyInvocation

try {
    Import-VstsLocStrings "$PSScriptRoot/task.json"
	
    . "$PSScriptRoot/ps_modules/CommonScripts/Utility.ps1"
    # get the tmp path of the agent
    $agentTmpPath = "$($env:AGENT_RELEASEDIRECTORY)\_temp"
    $tmpInlineXmlFileName = [System.IO.Path]::GetRandomFileName() + ".json"


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
    
