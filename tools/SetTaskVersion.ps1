[CmdletBinding()]
param (
    [Parameter(Mandatory = $false,ParameterSetName="Patch")]
    [Parameter(Mandatory = $false,ParameterSetName="CommitsSinceVersionSource")]
    [ValidateRange(-1, [int]::MaxValue)]
    [string]
    $Major = -1,
    [Parameter(Mandatory = $false,ParameterSetName="Patch")]
    [Parameter(Mandatory = $false,ParameterSetName="CommitsSinceVersionSource")]
    [ValidateRange(-1, [int]::MaxValue)]
    [string]
    $Minor = -1,
    [Parameter(Mandatory = $false,ParameterSetName="Patch")]
    [ValidateRange(-1, [int]::MaxValue)]
    [string]
    $Patch = -1,
    [Parameter(Mandatory = $false,ParameterSetName="CommitsSinceVersionSource")]
    [ValidateRange(-1, [int]::MaxValue)]
    [string]
    $CommitsSinceVersionSource = -1
)

$currentPath = (Split-Path -Parent $MyInvocation.MyCommand.Path)

$extensionFileJson = Get-Content -Path "$currentPath\..\src\vss-extension.json" | Out-String | ConvertFrom-Json

#copy only to used extension paths
$extensionIds = $extensionFileJson.contributions.properties.name

$extensionIds | ForEach-Object {

    $taskIdName = $_

    $taskFolder = "$currentPath\..\src\$taskIdName"

    $subfolders = Get-ChildItem -Path $taskFolder -Directory -Force -ErrorAction SilentlyContinue | Select-Object FullName

    $subfolders | ForEach-Object {

        $taskJsonFilePath = "$($_.FullName)\task.json"
    
        $taskJson = Get-Content -Path $taskJsonFilePath | ConvertFrom-Json

        if ($Major -gt -1) {
            $taskJson.version.Major = $Major
        }
        if ($Minor -gt -1) {
            $taskJson.version.Minor = $Minor
        }
        if ($Patch -gt -1) {
            $taskJson.version.Patch = $Patch
        }else{
            $taskJson.version.Patch = $CommitsSinceVersionSource
        }

        Set-Content -Path "$($_.FullName)\task.json" -Value $taskJson
    }



}