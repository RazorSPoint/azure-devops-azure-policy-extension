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
    $tmpInlineJsonFileName = [System.IO.Path]::GetRandomFileName() + ".json"

    [string]$GovernanceType = Get-VstsInput -Name GovernanceType

    [string]$DefinitionLocation = Get-VstsInput -Name DefinitionLocation

    [string]$SubscriptionId = Get-VstsInput -Name SubscriptionId

    [string]$ManagementGroupName = Get-VstsInput -Name ManagementGroupName

    [string]$DeploymentType = Get-VstsInput -Name DeploymentType

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
            $JsonFilePath = "$agentTmpPath/$tmpInlineJsonFileName"
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
    Write-VstsTaskWarning -Message "`$DefinitionLocation :$DefinitionLocation"
    Write-VstsTaskWarning -Message "`$SubscriptionId :$SubscriptionId"
    Write-VstsTaskWarning -Message "`$ManagementGroupName :$ManagementGroupName"
    Write-VstsTaskWarning -Message "`$DeploymentType :$DeploymentType"
    Write-VstsTaskWarning -Message "`$FileOrInline :$FileOrInline"

    #init azure connection
    Initialize-Azure


    $splattedArgs =     @{
        PolicyFilePath = $JsonFilePath
    }

    if ($DefinitionLocation -eq "Subscription") {
        $splattedArgs | Add-Member "SubscriptionId" $SubscriptionId
    }elseif ($DefinitionLocation -eq "ManagementGroupName") {
        $splattedArgs | Add-Member "ManagementGroupId" $ManagementGroupName
    }


    if($DeploymentType -eq "Full"){
        
    }elseif ($DeploymentType -eq "Splitted") {
        
    }

    $ScriptTypeToRun = "Deploy$DeploymentType$GovernanceType"

    Write-VstsTaskWarning "Trying to run $ScriptTypeToRun.ps1"

    . "$PSScriptRoot\$ScriptTypeToRun.ps1" @splattedArgs
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
    
