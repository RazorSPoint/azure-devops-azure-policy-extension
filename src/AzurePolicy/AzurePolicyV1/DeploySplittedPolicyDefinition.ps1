[CmdletBinding(DefaultParameterSetName='Subscription')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$PolicyFilePath,
    [Parameter(Mandatory=$true, ParameterSetName='Subscription')]
    [string]$SubscriptionId,
    [Parameter(Mandatory=$true, ParameterSetName='ManagementGroup')]
    [string]$ManagementGroupId
)

$policyDef = Get-Content -Path $PolicyFilePath | Out-String | ConvertFrom-Json

$policyRule = $policyDef.properties.policyRule | ConvertTo-Json -Depth 30 -Compress
$policyParameters = $policyDef.properties.parameters | ConvertTo-Json -Depth 30 -Compress

$name = $policyDef.name
$displayName = $policyDef.properties.displayName
$description = $policyDef.properties.description
$metadata = $policyDef.properties.metadata | ConvertTo-Json -Depth 30 -Compress
$mode = $policyDef.properties.mode

if($PSCmdlet.ParameterSetName -eq "Subscription"){

    $policy = $null
    try{
        $policy= Get-AzureRmPolicyDefinition -Name $name -SubscriptionId $SubscriptionId -ErrorAction SilentlyContinue
    }catch{}  

    if($policy){
        $policy = Set-AzureRmPolicyDefinition -SubscriptionId $SubscriptionId -Policy $policyRule -Name $name -DisplayName $displayName -Description $description -Mode $mode -Metadata $metadata -Parameter $policyParameters
    }else{
        $policy = New-AzureRmPolicyDefinition -SubscriptionId $SubscriptionId -Policy $policyRule -Name $name -DisplayName $displayName -Description $description -Mode $mode -Metadata $metadata -Parameter $policyParameters
    }

}else{

    $policy = $null
    try{
        $policy= Get-AzureRmPolicyDefinition -Name $name -ManagementGroupName $ManagementGroupId -ErrorAction SilentlyContinue
    }catch{}

    if($policy){
        $policy = Set-AzureRmPolicyDefinition -ManagementGroupName $ManagementGroupId -Policy $policyRule -Name $name -DisplayName $displayName -Description $description -Mode $mode -Metadata $metadata -Parameter $policyParameters
    }else{
        $policy = New-AzureRmPolicyDefinition -ManagementGroupName $ManagementGroupId -Policy $policyRule -Name $name -DisplayName $displayName -Description $description -Mode $mode -Metadata $metadata -Parameter $policyParameters
    }
}

Write-Verbose ($policy | ConvertTo-Json)