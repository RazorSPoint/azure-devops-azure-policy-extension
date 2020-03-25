function Add-TemporaryJsonFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $JsonInline,
        [Parameter(Mandatory = $true)]
        [String]
        $TempPath,
        [Parameter(Mandatory = $true)]
        [String]
        $FileName
    )
        
    process {

        $JsonObject = New-Object -TypeName "PSCustomObject"
        try {
            $JsonFilePath = ("$TempPath/$FileName").Replace('/', '\')

            #if path not exists, create it!
            if (-not (Test-Path -Path $TempPath)) {
                $null = New-Item -ItemType Directory -Force -Path $TempPath
            }
            $JsonObject = ConvertFrom-Json -InputObject $JsonInline
            $null = $JsonObject | ConvertTo-Json -depth 100 -Compress | Out-File $JsonFilePath

            Write-Output $JsonFilePath
        }
        catch [System.ArgumentException] {
            Write-VstsTaskError -Message "$($_.toString())"
        }

    }
    
}

function Get-TemporaryFileName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [String]
        [ValidateSet("xml", "json")]
        $FileExtension = "json"
    )
    process {
        #get random temporary file name
        Write-Output ([System.IO.Path]::GetRandomFileName() + ".$FileExtension")
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
        if (-not (Test-Path $FilePath)) {
            Write-VstsTaskError -Message "`nFile path '$FilePath' for $FileContext does not exist.`n"
            Write-VstsSetResult -Result 'Failed' -Message "Error detected" -DoNotThrow
        }
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

function Get-GovernanceFullDeploymentParameters {
    [CmdletBinding()]
    [CmdletBinding(DefaultParameterSetName = 'Subscription')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Subscription')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ManagementGroup')]
        [string]$GovernanceFilePath,
        [Parameter(Mandatory = $true, ParameterSetName = 'Subscription')]
        [string]$SubscriptionId,
        [Parameter(Mandatory = $true, ParameterSetName = 'ManagementGroup')]
        [string]$ManagementGroupId,
        [Parameter(Mandatory = $true, ParameterSetName = 'Subscription')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ManagementGroup')]
        [ValidateSet("PolicyDefinition", "PolicyInitiative")]
        [String]
        $GovernanceType
    )
    process {

        Confirm-FileExists -FilePath $GovernanceFilePath -FileContext "the policy"
 
        $governanceContent = Get-Content -Path $GovernanceFilePath -Raw | Out-String | ConvertFrom-Json
        $parameters = @{ }

        switch ($GovernanceType) {
            "PolicyDefinition" { 
                $parameters = @{
                    Name        = $governanceContent.name
                    DisplayName = $governanceContent.properties.displayName
                    Description = $governanceContent.properties.description
                    Metadata    = $governanceContent.properties.metadata | ConvertTo-Json -Depth 30 -Compress
                    Mode        = $governanceContent.properties.mode
                    Parameters  = $governanceContent.properties.parameters | ConvertTo-Json -Depth 30 -Compress
                    PolicyRule  = $governanceContent.properties.policyRule | ConvertTo-Json -Depth 30 -Compress
                }
            }
            "PolicyInitiative" { 
                $parameters = @{
                    PolicyDefinition = $governanceContent.properties.policyDefinitions | ConvertTo-Json -Depth 30 -Compress
                    Name             = $governanceContent.name
                    DisplayName      = $governanceContent.properties.displayName
                    Description      = $governanceContent.properties.description
                    Metadata         = $governanceContent.properties.metadata | ConvertTo-Json -Depth 30 -Compress 
                    Parameter        = $governanceContent.properties.parameters | ConvertTo-Json -Depth 30 -Compress
                }
            }
            Default { }
        }  

        if ($PSCmdlet.ParameterSetName -eq "Subscription") {    
            $parameters.SubscriptionId = $SubscriptionId    
        }
        elseif ($PSCmdlet.ParameterSetName -eq "ManagementGroup") {    
            $parameters.ManagementGroupId = $ManagementGroupId    
        }  

        Write-Output $parameters
               
    }
}
function Get-GovernanceDeploymentParameters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("PolicyDefinition", "PolicyInitiative")]
        [String]
        $GovernanceType,
        [Parameter(Mandatory = $true)]
        [String]
        $TempPath,
        [Parameter(Mandatory = $true)]
        [String]
        $TempFileName  
    )

    process {

        $parameters = @{ }

        [string]$DefinitionLocation = Get-VstsInput -Name DefinitionLocation
        [string]$DeploymentType = Get-VstsInput -Name DeploymentType
          
        if ($DefinitionLocation -eq "Subscription") {
            $parameters.SubscriptionId = Get-VstsInput -Name SubscriptionId
        }
        elseif ($DefinitionLocation -eq "ManagementGroup") {
            $parameters.ManagementGroupId = Get-VstsInput -Name ManagementGroupName
        }

        if ($DeploymentType -eq "Full") {

            [string]$FileOrInline = Get-VstsInput -Name FileOrInline
    
            if ($FileOrInline -eq "File") {
                [string]$JsonFilePath = Get-VstsInput -Name JsonFilePath
                Confirm-FileExists -FilePath $JsonFilePath -FileContext "parameter JsonFilePath"
            }
            else {            
                [string]$JsonInline = (Get-VstsInput -Name JsonInline)
                $JsonFilePath = Add-TemporaryJsonFile -JsonInline $JsonInline -TempPath $TempPath -FileName $TempFileName
            }
       
            $parameters.GovernanceFilePath = $JsonFilePath 

            $parameters = Get-GovernanceFullDeploymentParameters @parameters -GovernanceType $GovernanceType
        }
        elseif ($DeploymentType -eq "Splitted") {       
            [string]$ParametersFilePath = Get-VstsInput -Name ParametersFilePath
            Confirm-FileExists -FilePath $ParametersFilePath -FileContext "Parameters"

            [string]$Category = Get-VstsInput -Name Category

            $parameters = @{
                Name        = Get-VstsInput -Name Name            
                DisplayName = Get-VstsInput -Name DisplayName
                Description = Get-VstsInput -Name Description
                Metadata    = "{ 'category': '$Category' }"
                Parameters  =  Get-Content -Path $ParametersFilePath -Raw | Out-String
            }

            if ($GovernanceType -eq "PolicyInitiative") {
                [string]$InitiativePolicyDefinitionsFilePath = Get-VstsInput -Name InitiativePolicyDefinitionsFilePath    
                Confirm-FileExists -FilePath $InitiativePolicyDefinitionsFilePath -FileContext "Policy Rule"
    
                $parameters.PolicyDefinition = Get-Content -Path $InitiativePolicyDefinitionsFilePath -Raw | Out-String   
            }
            else {
                [string]$PolicyRuleFilePath = Get-VstsInput -Name PolicyRuleFilePath
                Confirm-FileExists -FilePath $PolicyRuleFilePath -FileContext "Policy Rule"
    
                $parameters.Mode = Get-VstsInput -Name Mode
                $parameters.PolicyRule = Get-Content -Path $PolicyRuleFilePath -Raw | Out-String 
            }
        }

        return $parameters
    }

}

function Publish-SplittedPolicyDefinition {
    [CmdletBinding(DefaultParameterSetName = 'Subscription')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Subscription')]
        [string]$SubscriptionId,
        [Parameter(Mandatory = $true, ParameterSetName = 'ManagementGroup')]
        [string]$ManagementGroupId,
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$DisplayName,
        [Parameter(Mandatory = $true, Position = 2)]
        [string]$Description,
        [Parameter(Mandatory = $true, Position = 3)]
        [string]$Metadata,
        [Parameter(Mandatory = $true, Position = 4)]
        [ValidateSet("all", "indexed")]
        [string]$Mode,
        [Parameter(Mandatory = $true, Position = 5)]
        [string]$Parameters,
        [Parameter(Mandatory = $true, Position = 6)]
        [string]$PolicyRule
    )

    process {

        $policyParameter = @{
            Policy      = $PolicyRule 
            Name        = $Name 
            DisplayName = $DisplayName 
            Description = $Description 
            Metadata    = $Metadata 
            Parameter   = $Parameters
        }

        $scope = @{ }

        if ($PSCmdlet.ParameterSetName -eq "Subscription") {
            $scope = @{ SubscriptionId = $SubscriptionId }
        }
        elseif ($PSCmdlet.ParameterSetName -eq "ManagementGroup") {
            $scope = @{ ManagementGroupName = $ManagementGroupId }   
        }

        $policy = $null
        try {
            Write-Output "Checking if the policy '$Name' already exists."
            $policy = Get-AzPolicyDefinition -Name $Name @scope -ErrorAction SilentlyContinue    
        }
        catch { }  

        if ($policy) {
            Write-Output "Policy '$Name' exists and will be updated."
            $policy = Set-AzPolicyDefinition @scope @policyParameter
        }
        else {
            Write-Output "Policy '$Name' does not exist and will be created."
            $policyParameter.Mode = $Mode 
            $policy = New-AzPolicyDefinition @scope @policyParameter
        }

        Write-VstsTaskVerbose ($policy | ConvertTo-Json)
    }
}

function Publish-SplittedPolicyInitiative {
    [CmdletBinding(DefaultParameterSetName = 'Subscription')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Subscription')]
        [string]$SubscriptionId,
        [Parameter(Mandatory = $true, ParameterSetName = 'ManagementGroup')]
        [string]$ManagementGroupId,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$DisplayName,
        [Parameter(Mandatory = $true)]
        [string]$Description,
        [Parameter(Mandatory = $true)]
        [string]$Metadata,
        [Parameter(Mandatory = $true)]
        [string]$Parameters,
        [Parameter(Mandatory = $true)]
        [string]$PolicyDefinition
    )
    process {
        $initiativeParameters = @{
            PolicyDefinition = $PolicyDefinition
            Name             = $Name
            DisplayName      = $DisplayName
            Description      = $Description
            Metadata         = $Metadata
            Parameter        = $Parameters
        }

        $scope = @{ }

        if ($PSCmdlet.ParameterSetName -eq "Subscription") {
            $scope = @{ SubscriptionId = $SubscriptionId }
        }
        elseif ($PSCmdlet.ParameterSetName -eq "ManagementGroup") {
            $scope = @{ ManagementGroupName = $ManagementGroupId }   
        }

        $policy = $null
        try {
            Write-Output "Checking if the policy set (Intiative) '$Name' already exists."
            $policy = Get-AzPolicySetDefinition -Name $Name @scope -ErrorAction SilentlyContinue
        }
        catch { }  

        if ($policy) {
            Write-Output "Policy set (Intiative) '$Name' exists and will be updated."
            $policy = Set-AzPolicySetDefinition @scope @initiativeParameters
        }
        else {
            Write-Output "Policy set (Intiative) '$Name' does not exist and will be created."
            $policy = New-AzPolicySetDefinition @scope @initiativeParameters
        }

        Write-VstsTaskVerbose ($policy | ConvertTo-Json)
    }
}