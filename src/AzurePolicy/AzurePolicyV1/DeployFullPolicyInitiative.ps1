[CmdletBinding(DefaultParameterSetName='Subscription')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$InitiativeFilePath,
    [Parameter(Mandatory=$true, ParameterSetName='Subscription')]
    [string]$SubscriptionId,
    [Parameter(Mandatory=$true, ParameterSetName='ManagementGroup')]
    [string]$ManagementGroupId
)

if (-not (Test-Path $InitiativeFilePath)) {
    throw "`nFile path '$InitiativeFilePath' for the initiative does not exist.`n"
}else{

    $initiative = Get-Content -Path $InitiativeFilePath | Out-String | ConvertFrom-Json

    $initiativeParameters =  @{
        PolicyDefinition =  $initiative.properties.policyDefinitions | ConvertTo-Json -Depth 30 -Compress
        Name = $initiative.name
        DisplayName = $initiative.properties.displayName
        Description = $initiative.properties.description
        Metadata = $initiative.properties.metadata | ConvertTo-Json -Depth 30 -Compress 
        Parameter = $initiative.properties.parameters | ConvertTo-Json -Depth 30 -Compress
    }

    if ($PSCmdlet.ParameterSetName -eq "Subscription") {

        $initiativeParameters.SubscriptionId = $SubscriptionId

    }elseif ($PSCmdlet.ParameterSetName -eq "ManagementGroup") {

        $initiativeParameters.ManagementGroupId = $ManagementGroupName

    }

    . "$PSScriptRoot\DeploySplittedPolicyInitiative.ps1" @initiativeParameters
}