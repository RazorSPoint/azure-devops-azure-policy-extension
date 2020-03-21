[CmdletBinding()]
param(
	#output path of the build module
    [string]$extensionPath,
    [string]$outputPath
)

$extensionFileJson = Get-Content -Path "$extensionPath\vss-extension.json" | Out-String | ConvertFrom-Json

#copy only to used extension paths
$extensionIds = $extensionFileJson.contributions.properties.name

$extensionIds | ForEach-Object {

    $taskIdName = $_

    $taskFolder = "$extensionPath\$taskIdName"

    $subfolders = Get-ChildItem -Path $taskFolder -Directory -Force -ErrorAction SilentlyContinue | Select-Object FullName

    $subfolders | ForEach-Object {

        $taskVersionFolder = "$($_.FullName)\ps_modules"
    
        #remove any content from those folder, as they are temporary
        Remove-Item -Path $taskVersionFolder -Recurse -Force -ErrorAction SilentlyContinue
        #copy and overwrite all
        Copy-Item -Path "$extensionPath\ps_modules" -Destination $taskVersionFolder -Recurse -Force

    }



}
