
[CmdletBinding()]
param(
	#output path of the build module
	[string]$outputFilePath,
	[string]$readmeFilePath,
	[string]$changelogFilePath
)

$content = Get-Content $readmeFilePath, $changelogFilePath
$content = $content.Replace("../src/", "").Replace("src/", "")

$distPath = Split-Path -Path $outputFilePath
If(!(test-path $distPath))
{
    $null = New-Item -ItemType Directory -Force -Path $distPath
}

$content | Set-Content $outputFilePath
