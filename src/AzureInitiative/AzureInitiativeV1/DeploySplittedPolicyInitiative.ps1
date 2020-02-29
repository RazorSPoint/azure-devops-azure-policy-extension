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
    [Parameter(Mandatory=$true, Position=5)]
    [string]$Parameters,
    [Parameter(Mandatory=$true, Position=6)]
    [string]$PolicyDefinition
)

$initiativeParameters =  @{
    PolicyDefinition =  $PolicyDefinition
    Name = $Name
    DisplayName = $DisplayName
    Description = $Description
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
    Write-Output "Checking if the policy set (Intiative) '$Name' already exists."
    $policy= Get-AzPolicySetDefinition -Name $Name @scope -ErrorAction SilentlyContinue
}catch{}  

if($policy){
    Write-Output "Policy set (Intiative) '$Name' exists and will be updated."
    $policy = Set-AzPolicySetDefinition @scope @initiativeParameters
}else{
    Write-Output "Policy set (Intiative) '$Name' does not exist and will be created."
    $policy = New-AzPolicySetDefinition @scope @initiativeParameters
}

Write-VstsTaskVerbose ($policy | ConvertTo-Json)