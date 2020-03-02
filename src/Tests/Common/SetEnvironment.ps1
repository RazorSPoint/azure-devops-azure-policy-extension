Set-StrictMode -Version Latest

function _clearEnvironment {
    [CmdletBinding()]
    param()
    process{
        
        $environmentVariables = Get-ChildItem -Path Env:AGENT_?*,Env:ENDPOINT_?*, Env:INPUT_?*, Env:SECRET_?*, Env:SECUREFILE_?*

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
        $env:AGENT_RELEASEDIRECTORY = "C:"
        $env:AGENT_VERSION = "2.165.0"
        $env:AGENT_PROXYURL = "https://my.proxy.url"
        $env:AGENT_PROXYUSERNAME = "ProxyUserName"
        $env:AGENT_PROXYPASSWORD = "ProxyPassword"
        $env:AGENT_PROXYBYPASSLIST =  ("http://myserver", "http://companysite" ) | ConvertTo-Json
    }
}

function _setEndPointEnvironment {
    [CmdletBinding()]
    param ()    
    process {        
        $env:INPUT_CONNECTEDSERVICENAMESELECTOR = "7586afbf-35b7-43e2-abab-4fad05be50de"
        $env:INPUT_DEPLOYMENTENVIRONMENTNAME = "7586afbf-35b7-43e2-abab-4fad05be50de"

        # another way of setting environment variable
        New-Item -Path "Env:INPUT_$env:INPUT_DEPLOYMENTENVIRONMENTNAME" -Value "ConnectionInput"

        Get-Content -Path "$currentPath/testfiles/ReturnData/authSchemeAzure.json"  -Raw | ConvertFrom-Json
    }
}

function _setGovernanceEnvironment {
    [CmdletBinding()]
    param ()    
    process {
        
        $env:INPUT_SubscriptionId = "2b53247c-fb65-469e-a711-46e0c29d15a1"
        $env:INPUT_ManagementGroupName = "40c38f6e-28c8-4fed-a4bb-af9c951b17ab"

    }
}

_clearEnvironment

_setAgentEnvironment
$endPoint = _setEndPointEnvironment
_setGovernanceEnvironment