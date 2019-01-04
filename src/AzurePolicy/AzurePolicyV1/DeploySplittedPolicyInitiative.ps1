[CmdletBinding(DefaultParameterSetName='Subscription')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$PolicyFilePath,
    [Parameter(Mandatory=$true, ParameterSetName='Subscription')]
    [string]$SubscriptionId,
    [Parameter(Mandatory=$true, ParameterSetName='ManagementGroup')]
    [string]$ManagementGroupId
)

$policy = Get-Content -Path $PolicyFilePath | Out-String | ConvertFrom-Json

$policyJsonString = $policy | ConvertTo-Json -Depth 30 -Compress
$policydefinitions = $policy.properties.policyDefinitions | ConvertTo-Json -Depth 30 -Compress
$policysetparameters = $policy.properties.parameters | ConvertTo-Json -Depth 30 -Compress


$name = $policy.name
$displayName = $policy.properties.displayName
$description = $policy.properties.description
$metadata = $policy.properties.metadata | ConvertTo-Json -Depth 30 -Compress

if($PSCmdlet.ParameterSetName -eq "Subscription"){

    $policyset= Get-AzureRmPolicySetDefinition -Name $name -SubscriptionId $SubscriptionId

    if($policyset){
        $policyset = Set-AzureRmPolicySetDefinition -SubscriptionId $SubscriptionId -PolicyDefinition $policydefinitions -Name $name -Parameter $policysetparameters -DisplayName $displayName -Description $description -Metadata $metadata
    }else{
        $policyset = New-AzureRmPolicySetDefinition -SubscriptionId $SubscriptionId -PolicyDefinition $policydefinitions -Name $name -Parameter $policysetparameters -DisplayName $displayName -Description $description -Metadata $metadata
    }

}else{

    $policyset= Get-AzureRmPolicySetDefinition -Name $name -ManagementGroupName $ManagementGroupId

    if($policyset){
        $policyset = Set-AzureRmPolicySetDefinition -ManagementGroupName $ManagementGroupId -PolicyDefinition $policydefinitions -Name $name -Parameter $policysetparameters -DisplayName $displayName -Description $description -Metadata $metadata
    }else{
        $policyset = New-AzureRmPolicySetDefinition -ManagementGroupName $ManagementGroupId -PolicyDefinition $policydefinitions -Name $name -Parameter $policysetparameters -DisplayName $displayName -Description $description -Metadata $metadata
    }
}

Write-Verbose ($policyset | ConvertTo-Json)