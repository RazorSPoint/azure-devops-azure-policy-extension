Trace-VstsEnteringInvocation $MyInvocation


Import-VstsLocStrings "$PSScriptRoot/task.json"

$JsonFilePath = $null

# get the tmp path of the agent
$agentTmpPath = "$($env:AGENT_RELEASEDIRECTORY)\_temp"
    
[string]$DefinitionLocation = Get-VstsInput -Name DefinitionLocation
[string]$SubscriptionId = Get-VstsInput -Name SubscriptionId
[string]$ManagementGroupName = Get-VstsInput -Name ManagementGroupName
[string]$DeploymentType = Get-VstsInput -Name DeploymentType
  
$splattedArgs = @{ }
  
try {
  
    if ($DeploymentType -eq "Full") {

        [string]$FileOrInline = Get-VstsInput -Name FileOrInline
    
        if ($FileOrInline -eq "File") {
            [string]$JsonFilePath = Get-VstsInput -Name JsonFilePath
            if (-not (Test-Path $JsonFilePath)) {
                Write-VstsTaskError -Message "`nFile path '$JsonFilePath' for parameter JsonFilePath does not exist.`n"
            }
        }
        else {
            #get random temporary file name
            $tmpInlineJsonFileName = [System.IO.Path]::GetRandomFileName() + ".json"

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

        $splattedArgs = @{ }
        
        $splattedArgs.InitiativeFilePath = $JsonFilePath       

    }
    elseif ($DeploymentType -eq "Splitted") {       
        [string]$ParametersFilePath = Get-VstsInput -Name ParametersFilePath

        if (-not (Test-Path -LiteralPath $ParametersFilePath)) {
            
            Write-VstsTaskError -Message "`nFile path '$ParametersFilePath' for the Parameters does not exist.`n"
        }

        [string]$Category = Get-VstsInput -Name Category

        $splattedArgs = @{
            Name        = Get-VstsInput -Name Name            
            DisplayName = Get-VstsInput -Name DisplayName
            Description = Get-VstsInput -Name Description
            Metadata    = "{ 'category': '$Category' }"
            Parameters  = Get-Content -Path $ParametersFilePath | Out-String
        }



        [string]$InitiativePolicyDefinitionsFilePath = Get-VstsInput -Name InitiativePolicyDefinitionsFilePath
    
        if (-not (Test-Path -LiteralPath $InitiativePolicyDefinitionsFilePath)) {
            Write-VstsTaskError -Message "`nFile path '$InitiativePolicyDefinitionsFilePath' for the Policy Rule does not exist.`n"
        }
    
        $splattedArgs.PolicyDefinition = Get-Content -Path $InitiativePolicyDefinitionsFilePath | Out-String  
    }

    if ($DefinitionLocation -eq "Subscription") {
        $splattedArgs.SubscriptionId = $SubscriptionId
    }
    elseif ($DefinitionLocation -eq "ManagementGroup") {
        $splattedArgs.ManagementGroupId = $ManagementGroupName
    }
    
    . $PSScriptRoot\ps_modules\CommonScripts\Utility.ps1

    $serviceName = Get-VstsInput -Name ConnectedServiceName -Require
    $endpointObject = Get-VstsEndpoint -Name $serviceName -Require
    $endpoint = ConvertTo-Json $endpointObject

    . $PSScriptRoot\ps_modules\CommonScripts\CoreAz.ps1 -endpoint "$endpoint"  
    ## Real things are happening here
    . "$PSScriptRoot\Deploy$($DeploymentType)PolicyInitiative.ps1" @splattedArgs
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-VstsTaskError -Message "`nAn Error occured. The error message was: $ErrorMessage. `n Stackstace `n $($_.ScriptStackTrace)`n"
    Write-VstsSetResult -Result 'Failed' -Message "Error detected" -DoNotThrow
}
finally {
    #clean up tmp path
    if ($FileOrInline -eq 'Inline' -and (Test-Path -LiteralPath $JsonFilePath)) {
        Remove-Item -LiteralPath $JsonFilePath -ErrorAction 'SilentlyContinue'
    }

    Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
    Remove-EndpointSecrets
    Disconnect-AzureAndClearContext -authScheme $authScheme -ErrorAction SilentlyContinue
}

