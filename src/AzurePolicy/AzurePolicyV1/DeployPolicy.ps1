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

$policyDef = Get-Content -Path $PolicyFilePath | Out-String | ConvertFrom-Json

$policyRule = $policyDef.properties.policyRule | ConvertTo-Json -Depth 30 -Compress
$policyParameters = $policyDef.properties.parameters | ConvertTo-Json -Depth 30 -Compress


$name = $policyDef.name
$displayName = $policyDef.properties.displayName
$description = $policyDef.properties.description
$metadata = $policyDef.properties.metadata | ConvertTo-Json -Depth 30 -Compress
$mode = $policyDef.properties.mode

$securePassword = $Password | ConvertTo-SecureString  -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $User, $securePassword

$connection = Connect-AzureRmAccount -Credential $cred -TenantId $Tenant

Write-Verbose ($connection | Format-List | Out-String) 



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

#$scope = "/subscriptions/77ae0e00-49e5-4c5a-b5af-5aebad01508f/resourcegroups/RG_EU_abc_DEV"

#New-AzureRmPolicyAssignment -PolicySetDefinition $policyset -Name "MyAssignment" -Scope $scope -costCenterValue 1234456 -productNameValue myproduct -Sku @{"Name"="A1";"Tier"="Standard"}