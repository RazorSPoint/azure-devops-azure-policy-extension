param(
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$AgentToolPath = "C:\temp"
)

$currentPath = (Split-Path -Parent $MyInvocation.MyCommand.Path)
. $currentPath\..\ps_modules\CommonScripts\Utility.ps1



if($AgentToolPath -eq $null){
 $AgentToolPath = "$($env:AGENT_RELEASEDIRECTORY)\_temp"
}

Describe 'Utility Tests' {

    Context -Name "My Test"{

        It -Name "Given valid -Name <Environment>, it returns '<Expected>'"  -TestCases @(
            @{Environment = "TestData"; Expected = $true}
        ){
            param ($Environment, $Expected)            

            $isLoaded = $true

            $isLoaded | Should -Be $Expected
        }      

    }   

}