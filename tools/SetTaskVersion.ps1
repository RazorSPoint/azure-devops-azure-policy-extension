[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateRange(0, [int]::MaxValue)]
    [string]
    $Major,
    [Parameter(Mandatory=$true)]
    [ValidateRange(0, [int]::MaxValue)]
    [string]
    $Minor,
    [Parameter(Mandatory=$true)]
    [ValidateRange(0, [int]::MaxValue)]
    [string]
    $Patch
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

        $taskJson.version.Major = $Major
        $taskJson.version.Minor = $Minor
        $taskJson.version.Patch = $Patch

        $taskJson | Set-Content "$($_.FullName)\task.json" -
    }



}