[CmdletBinding()]
param()



# For more information on the VSTS Task SDK:
# https://github.com/Microsoft/vsts-task-lib

Trace-VstsEnteringInvocation $MyInvocation

try {

    Import-VstsLocStrings "$PSScriptRoot/task.json"

    $JsonFilePath = $null

    # get the tmp path of the agent
    $agentTmpPath = "$($env:AGENT_RELEASEDIRECTORY)\_temp"
    
    [string]$GovernanceType = Get-VstsInput -Name GovernanceType

    [string]$DefinitionLocation = Get-VstsInput -Name DefinitionLocation

    [string]$SubscriptionId = Get-VstsInput -Name SubscriptionId

    [string]$ManagementGroupName = Get-VstsInput -Name ManagementGroupName

    [string]$DeploymentType = Get-VstsInput -Name DeploymentType
  
    $splattedArgs = @{}
  
    
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

        $splattedArgs =     @{}

        if ($GovernanceType -eq "PolicyDefinition") {
            $splattedArgs.PolicyFilePath = $JsonFilePath
        }elseif ($GovernanceType -eq "PolicyInitiative") {
            $splattedArgs.InitiativeFilePath = $JsonFilePath
        }
        

    }elseif ($DeploymentType -eq "Splitted") {       
        [string]$ParametersFilePath = Get-VstsInput -Name ParametersFilePath

        if (-not (Test-Path -LiteralPath $ParametersFilePath)) {
            
            Write-VstsTaskError -Message "`nFile path '$ParametersFilePath' for the Parameters does not exist.`n"
        }

        [string]$Category = Get-VstsInput -Name Category

        $splattedArgs =     @{
            Name = Get-VstsInput -Name Name            
            DisplayName = Get-VstsInput -Name DisplayName
            Description = Get-VstsInput -Name Description
            Metadata =  "{ 'category': '$Category' }"
            Parameters = Get-Content -Path $ParametersFilePath | Out-String
        }

        if ($GovernanceType -eq "PolicyDefinition") {

            [string]$PolicyRuleFilePath = Get-VstsInput -Name PolicyRuleFilePath
    
            if (-not (Test-Path -LiteralPath $PolicyRuleFilePath)) {
                Write-VstsTaskError -Message "`nFile path '$PolicyRuleFilePath' for the Policy Rule does not exist.`n"
            }
    
            $splattedArgs.Mode = Get-VstsInput -Name Mode
            $splattedArgs.PolicyRule = Get-Content -Path $PolicyRuleFilePath | Out-String 
    
        } elseif ($GovernanceType -eq "PolicyInitiative") {
    
            [string]$InitiativePolicyDefinitionsFilePath = Get-VstsInput -Name InitiativePolicyDefinitionsFilePath
    
            if (-not (Test-Path -LiteralPath $InitiativePolicyDefinitionsFilePath)) {
                Write-VstsTaskError -Message "`nFile path '$InitiativePolicyDefinitionsFilePath' for the Policy Rule does not exist.`n"
            }
    
            $splattedArgs.PolicyDefinition = Get-Content -Path $InitiativePolicyDefinitionsFilePath | Out-String  
        }
    }

    if ($DefinitionLocation -eq "Subscription") {
        $splattedArgs.SubscriptionId = $SubscriptionId
    }elseif ($DefinitionLocation -eq "ManagementGroupName") {
        $splattedArgs.ManagementGroupId = $ManagementGroupName
    }
    
    . "$PSScriptRoot\ps_modules\CommonScripts\Utility.ps1"
    $targetAzurePs = Get-RollForwardVersion -azurePowerShellVersion $targetAzurePs

    $authScheme = ''
    try
    {
        $serviceNameInput = Get-VstsInput -Name ConnectedServiceNameSelector -Default 'ConnectedServiceName'
        $serviceName = Get-VstsInput -Name $serviceNameInput -Default (Get-VstsInput -Name DeploymentEnvironmentName)
        if (!$serviceName)
        {
                Get-VstsInput -Name $serviceNameInput -Require
        }
    
        $endpoint = Get-VstsEndpoint -Name $serviceName -Require
    
        if($endpoint)
        {
            $authScheme = $endpoint.Auth.Scheme 
        }
    
         Write-Verbose "AuthScheme $authScheme"
    }
    catch
    {
       $error = $_.Exception.Message
       Write-Verbose "Unable to get the authScheme $error" 
    }

    ## Real things are happening here

    Update-PSModulePathForHostedAgent -targetAzurePs $targetAzurePs -authScheme $authScheme

    #init azure connection
    Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
    Initialize-Azure -azurePsVersion $targetAzurePs -strict
 
    #Use Options DeploymentType and GovernanceType to generate the correct script to call
    $ScriptTypeToRun = "Deploy$DeploymentType$GovernanceType"

    Write-Output ""

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
    if ($FileOrInline -eq 'Inline' -and (Test-Path -LiteralPath $JsonFilePath)) {
        Remove-Item -LiteralPath $JsonFilePath -ErrorAction 'SilentlyContinue'
    }

    Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
    Remove-EndpointSecrets
    Disconnect-AzureAndClearContext -authScheme $authScheme -ErrorAction SilentlyContinue
}

