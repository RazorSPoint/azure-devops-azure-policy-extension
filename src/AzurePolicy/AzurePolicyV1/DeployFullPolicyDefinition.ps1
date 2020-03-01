[CmdletBinding(DefaultParameterSetName='Subscription')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$PolicyFilePath,
    [Parameter(Mandatory=$true, ParameterSetName='Subscription')]
    [string]$SubscriptionId,
    [Parameter(Mandatory=$true, ParameterSetName='ManagementGroup')]
    [string]$ManagementGroupId
)

if (-not (Test-Path $PolicyFilePath)) {
    throw "`nFile path '$PolicyFilePath' for the policy does not exist.`n"
}else{

    $policyDef = Get-Content -Path $PolicyFilePath | Out-String | ConvertFrom-Json

    $splattedArgs = @{
        Name = $policyDef.name
        DisplayName = $policyDef.properties.displayName
        Description = $policyDef.properties.description
        Metadata = $policyDef.properties.metadata | ConvertTo-Json -Depth 30 -Compress
        Mode = $policyDef.properties.mode
        Parameters = $policyDef.properties.parameters | ConvertTo-Json -Depth 30 -Compress
        PolicyRule = $policyDef.properties.policyRule | ConvertTo-Json -Depth 30 -Compress
    }

    if ($PSCmdlet.ParameterSetName -eq "Subscription") {

        $splattedArgs.SubscriptionId = $SubscriptionId

    }elseif ($PSCmdlet.ParameterSetName -eq "ManagementGroup") {

        $splattedArgs.ManagementGroupId = $ManagementGroupName

    }  

    . "$PSScriptRoot\DeploySplittedPolicyDefinition.ps1" @splattedArgs
}