function Add-TemporaryJsonFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $JsonInline
    )
        
    process {
        
        # get the tmp path of the agent
        $agentTmpPath = "$($env:AGENT_RELEASEDIRECTORY)\_temp"

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

            Write-Output $JsonFilePath
        }
        catch [System.ArgumentException] {
            Write-VstsTaskError -Message "$($_.toString())"
        }

    }
    
}

function Clear-GovernanceEnvironment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $TemporaryFilePath
    )
    
    process {
        #clean up tmp path
        if ($FileOrInline -eq 'Inline' -and (Test-Path -LiteralPath $TemporaryFilePath)) {
            Remove-Item -LiteralPath $TemporaryFilePath -ErrorAction 'SilentlyContinue'
        }
    
        Import-Module $PSScriptRoot\..\VstsAzureHelpers_
        Remove-EndpointSecrets
        Disconnect-AzureAndClearContext -ErrorAction SilentlyContinue
    }

}

function Write-GovernanceError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Object]
        $Exception
    )
    
    process {        
        $ErrorMessage = $Exception.Exception.Message
        Write-VstsTaskError -Message "`nAn Error occured. The error message was: $ErrorMessage. `n Stackstace `n $($Exception.ScriptStackTrace)`n"
        Write-VstsSetResult -Result 'Failed' -Message "Error detected" -DoNotThrow
    }
}

function Confirm-FileExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $FilePath,
        [Parameter(Mandatory = $true)]
        [String]
        $FileContext
    )
    process {
        if (-not (Test-Path $JsonFilePath)) {
            Write-VstsTaskError -Message "`nFile path '$JsonFilePath' for $FileContext does not exist.`n"
        }
    }
}

function Invoke-GovernanceFullDeployment {
    [CmdletBinding()]
    [CmdletBinding(DefaultParameterSetName = 'Subscription')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$GovernanceFilePath,
        [Parameter(Mandatory = $true, ParameterSetName = 'Subscription')]
        [string]$SubscriptionId,
        [Parameter(Mandatory = $true, ParameterSetName = 'ManagementGroup')]
        [string]$ManagementGroupId,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Policy", "Initiative")]
        [String]
        $GovernanceType
    )
    process {  
        if (-not (Test-Path $GovernanceFilePath)) {
            throw "`nFile path '$GovernanceFilePath' for the policy does not exist.`n"
        }
        else {
    
            $governanceContent = Get-Content -Path $GovernanceFilePath | Out-String | ConvertFrom-Json
            $parameters = @{ }
            $fileName = ""
    
            switch ($GovernanceType) {
                "Policy" { 
                    $parameters = @{
                        Name        = $governanceContent.name
                        DisplayName = $governanceContent.properties.displayName
                        Description = $governanceContent.properties.description
                        Metadata    = $governanceContent.properties.metadata | ConvertTo-Json -Depth 30 -Compress
                        Mode        = $governanceContent.properties.mode
                        Parameters  = $governanceContent.properties.parameters | ConvertTo-Json -Depth 30 -Compress
                        PolicyRule  = $governanceContent.properties.policyRule | ConvertTo-Json -Depth 30 -Compress
                    }
                    $fileName = "DeploySplittedPolicyDefinition.ps1"
                }
                "Initiative" { 
                    $parameters = @{
                        PolicyDefinition = $governanceContent.properties.policyDefinitions | ConvertTo-Json -Depth 30 -Compress
                        Name             = $governanceContent.name
                        DisplayName      = $governanceContent.properties.displayName
                        Description      = $governanceContent.properties.description
                        Metadata         = $governanceContent.properties.metadata | ConvertTo-Json -Depth 30 -Compress 
                        Parameter        = $governanceContent.properties.parameters | ConvertTo-Json -Depth 30 -Compress
                    }
                    $fileName = "DeploySplittedPolicyInitiative.ps1"
                }
                Default { }
            }  
    
            if ($PSCmdlet.ParameterSetName -eq "Subscription") {    
                $parameters.SubscriptionId = $SubscriptionId    
            }
            elseif ($PSCmdlet.ParameterSetName -eq "ManagementGroup") {    
                $parameters.ManagementGroupId = $ManagementGroupName    
            }  
    
            . "$PSScriptRoot\..\..\$fileName" @parameters
        }        
    }
}