[CmdletBinding()]
param(
	[string]$sourcePath,
    [string]$outputDir    
)

. ./tools/GenerateChangelog.ps1 `
    -outputFilePath "$outputDir/overview.md" `
    -readmeFilePath "./README.md" `
    -changelogFilePath "./docs/CHANGELOG.md"

# copy files to dist folder without modules
$excludes = @("ps_modules")
Get-ChildItem $sourcePath -Directory | 
Where-Object { $_.Name -notin $excludes } | 
Copy-Item -Destination $outputDir -Recurse -Force
Copy-Item -Path "$sourcePath\vss-extension.json" -Destination $outputDir -Recurse -Force

$extensionFileJson = Get-Content -Path "$outputDir\vss-extension.json" | Out-String | ConvertFrom-Json

#copy only to used extension paths
$extensionIds = $extensionFileJson.contributions.properties.name

$extensionIds | ForEach-Object {

    $taskIdName = $_

    $taskFolder = "$outputDir\$taskIdName"

    $subfolders = Get-ChildItem -Path $taskFolder -Directory -Force -ErrorAction SilentlyContinue | Select-Object FullName

    $subfolders | ForEach-Object {

        $taskVersionFolder = "$($_.FullName)\ps_modules"
    
        #remove any content from those folder, as they are temporary
        Remove-Item -Path $taskVersionFolder -Recurse -Force -ErrorAction SilentlyContinue
        #copy and overwrite all
        Copy-Item -Path "$sourcePath\ps_modules" -Destination $taskVersionFolder -Recurse -Force

        #save module into the extension folders
        Save-Module -Name VstsTaskSdk -Repository PSGallery -Force -Path "$taskVersionFolder\ps_modules" -AcceptLicense
    }
}


