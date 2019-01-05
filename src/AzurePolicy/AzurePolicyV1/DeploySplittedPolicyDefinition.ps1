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

$policyParameter =  @{
    Policy = $PolicyRule 
    Name = $Name 
    DisplayName = $DisplayName 
    Description = $Description 
    Mode = $Mode 
    Metadata = $Metadata 
    Parameter = $Parameters
}

$scope = @{}

if($PSCmdlet.ParameterSetName -eq "Subscription"){

    $scope = @{ SubscriptionId = $SubscriptionId }   

}elseif($PSCmdlet.ParameterSetName -eq "ManagementGroup"){

    $scope = @{ ManagementGroupName = $ManagementGroupId }   
}

$policy = $null
try{
    $policy= Get-AzureRmPolicyDefinition -Name $Name @scope -ErrorAction SilentlyContinue
}catch{}  

if($policy){
    $policy = Set-AzureRmPolicyDefinition @scope @policyParameter
}else{
    $policy = New-AzureRmPolicyDefinition @scope @policyParameter
}

Write-VstsTaskVerbose ($policy | ConvertTo-Json)