[CmdletBinding(DefaultParameterSetName='Subscription')]
param(
    [Parameter(Mandatory=$true, ParameterSetName='Subscription')]
    [string]$SubscriptionId,
    [Parameter(Mandatory=$true, ParameterSetName='ManagementGroup')]
    [string]$ManagementGroupId,
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Name,
    [Parameter(Mandatory=$true, Position=1)]
    [string]$DisplayName,
    [Parameter(Mandatory=$true, Position=2)]
    [string]$Description,
    [Parameter(Mandatory=$true, Position=3)]
    [string]$Metadata,
    [Parameter(Mandatory=$true, Position=4)]
    [ValidateSet("all","indexed")]
    [string]$Mode,
    [Parameter(Mandatory=$true, Position=5)]
    [string]$Parameters,
    [Parameter(Mandatory=$true, Position=6)]
    [string]$PolicyRule
)

if($PSCmdlet.ParameterSetName -eq "Subscription"){

    $policy = $null
    try{
        $policy= Get-AzureRmPolicyDefinition -Name $Name -SubscriptionId $SubscriptionId -ErrorAction SilentlyContinue
    }catch{}  

    if($policy){
        $policy = Set-AzureRmPolicyDefinition -SubscriptionId $SubscriptionId -Policy $PolicyRule -Name $Name -DisplayName $DisplayName -Description $Description -Mode $Mode -Metadata $Metadata -Parameter $Parameters
    }else{
        $policy = New-AzureRmPolicyDefinition -SubscriptionId $SubscriptionId -Policy $PolicyRule -Name $Name -DisplayName $DisplayName -Description $Description -Mode $Mode -Metadata $Metadata -Parameter $Parameters
    }

}elseif($PSCmdlet.ParameterSetName -eq "ManagementGroup"){

    $policy = $null
    try{
        $policy= Get-AzureRmPolicyDefinition -Name $Name -ManagementGroupName $ManagementGroupId -ErrorAction SilentlyContinue
    }catch{}

    if($policy){
        $policy = Set-AzureRmPolicyDefinition -ManagementGroupName $ManagementGroupId -Policy $PolicyRule -Name $Name -DisplayName $DisplayName -Description $Description -Mode $Mode -Metadata $Metadata -Parameter $Parameters
    }else{
        $policy = New-AzureRmPolicyDefinition -ManagementGroupName $ManagementGroupId -Policy $PolicyRule -Name $Name -DisplayName $DisplayName -Description $Description -Mode $Mode -Metadata $Metadata -Parameter $Parameters
    }
}

Write-VstsTaskVerbose ($policy | ConvertTo-Json)