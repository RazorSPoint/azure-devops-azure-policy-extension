
[CmdletBinding()]
param(
	#output path of the build module
	[string]$outputPath,
	[string]$readmeFilePath,
	[string]$changelogFilePath
)

$content = Get-Content "$currentPath\..\README.md", "$currentPath\..\wiki\CHANGELOG.md"
$content = $content.Replace("../src/", "").Replace("src/", "")
$content | Set-Content "$currentPath/../src/overview.md"

New-ReleaseNotes $PSScriptRoot
