Set-StrictMode -Version Latest

function _clearEnvironment {
    [CmdletBinding()]
    param()
    process {
        
        $environmentVariables = Get-ChildItem -Path Env:AGENT_?*, Env:ENDPOINT_?*, Env:INPUT_?*, Env:SECRET_?*, Env:SECUREFILE_?*

        $environmentVariables | ForEach-Object {
            $variable = $_
            Remove-Item -LiteralPath "Env:$($variable.Name)"          
        }

    }
}

function _setAgentEnvironment {
    [CmdletBinding()]
    param ()    
    process {        
        $env:SYSTEM_CULTURE = "en-us"
        $env:AGENT_TEMPDIRECTORY = "C:\temp\"
        $env:AGENT_VERSION = "2.165.0"
        $env:AGENT_PROXYURL = "https://my.proxy.url"
        $env:AGENT_PROXYUSERNAME = "ProxyUserName"
        $env:AGENT_PROXYPASSWORD = "ProxyPassword"
        $env:AGENT_PROXYBYPASSLIST = ("http://myserver", "http://companysite" ) | ConvertTo-Json
    }
}

function _getEndPointEnvironment {
    [CmdletBinding()]
    param ()    
    process {  
        return Get-Content -Path "$PSScriptRoot/../testfiles/ReturnData/authSchemeAzure.json"  -Raw | ConvertFrom-Json
    }
}

function _setGovernanceEnvironment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Path  
    )    
    process {
        
        $parameters = Get-Content -Path $Path -Raw | ConvertFrom-Json

        $env:INPUT_CONNECTEDSERVICENAMESELECTOR = $parameters.ConnectedServiceNameSelector
        $env:INPUT_DEPLOYMENTENVIRONMENTNAME = $parameters.DeploymentEnvironmentName
        
                # another way of setting environment variable
        $null = New-Item -Path "Env:INPUT_$env:INPUT_DEPLOYMENTENVIRONMENTNAME" -Value "ConnectionInput" -Force

        _setGovernanceVariable -Name SubscriptionId -Parameters $parameters
        _setGovernanceVariable -Name ManagementGroupName -Parameters $parameters
        _setGovernanceVariable -Name ConnectedServiceName -Parameters $parameters
        _setGovernanceVariable -Name FileOrInline -Parameters $parameters
        _setGovernanceVariable -Name JsonInline -Parameters $parameters
        _setGovernanceVariable -Name GovernanceType -Parameters $parameters
        _setGovernanceVariable -Name DefinitionLocation -Parameters $parameters
        _setGovernanceVariable -Name DeploymentType -Parameters $parameters 
        _setGovernanceVariable -Name JsonFilePath -Parameters $parameters
        _setGovernanceVariable -Name ParametersFilePath -Parameters $parameters
        _setGovernanceVariable -Name PolicyRuleFilePath -Parameters $parameters
        _setGovernanceVariable -Name Category -Parameters $parameters
        _setGovernanceVariable -Name Name -Parameters $parameters
        _setGovernanceVariable -Name DisplayName -Parameters $parameters
        _setGovernanceVariable -Name Mode -Parameters $parameters
        _setGovernanceVariable -Name Description -Parameters $parameters
    }
}

function _setGovernanceVariable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,
        [Parameter(Mandatory = $false)]
        [PSCustomObject]
        $Parameters = $null
    )

    $propertyExists =  [bool]($Parameters.PSobject.Properties | Where-Object {$_.Name -eq $Name })
    if($propertyExists){
        $null = New-Item -Path "Env:INPUT_$Name" -Value $Parameters."$Name" -Force      
    }
} 

_clearEnvironment
_setAgentEnvironment