[CmdletBinding(DefaultParameterSetName='Subscription')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$PolicyFilePath,
    [Parameter(Mandatory=$true, Position=1)]
    [string]$Tenant,
    [Parameter(Mandatory=$true, ParameterSetName='Subscription')]
    [string]$SubscriptionId,
    [Parameter(Mandatory=$true, ParameterSetName='ManagementGroup')]
    [string]$ManagementGroupId,
    [Parameter(Mandatory=$true, Position=2)]    
    [string]$User,
    [Parameter(Mandatory=$true, Position=3)]
    [string]$Password
)

$policy = Get-Content -Path $PolicyFilePath | Out-String | ConvertFrom-Json

$policyJsonString = $policy | ConvertTo-Json -Depth 30 -Compress
$policydefinitions = $policy.properties.policyDefinitions | ConvertTo-Json -Depth 30 -Compress
$policysetparameters = $policy.properties.parameters | ConvertTo-Json -Depth 30 -Compress


$name = $policy.name
$displayName = $policy.properties.displayName
$description = $policy.properties.description
$metadata = $policy.properties.metadata | ConvertTo-Json -Depth 30 -Compress
$mode = $policy

$securePassword = $Password | ConvertTo-SecureString  -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $User, $securePassword

$connection = Connect-AzureRmAccount -Credential $cred -TenantId $Tenant

Write-Verbose ($connection | Format-List | Out-String) 



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

#$scope = "/subscriptions/77ae0e00-49e5-4c5a-b5af-5aebad01508f/resourcegroups/RG_EU_abc_DEV"

#New-AzureRmPolicyAssignment -PolicySetDefinition $policyset -Name "MyAssignment" -Scope $scope -costCenterValue 1234456 -productNameValue myproduct -Sku @{"Name"="A1";"Tier"="Standard"}