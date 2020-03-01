
$currentPath = (Split-Path -Parent $MyInvocation.MyCommand.Path)

$extensionFileJson = Get-Content -Path "$currentPath\..\src\vss-extension.json" | Out-String | ConvertFrom-Json

#copy only to used extension paths
$extensionIds = $extensionFileJson.contributions.properties.name

$extensionIds | ForEach-Object {

    $taskIdName = $_

    $taskFolder = "$currentPath\..\src\$taskIdName"

    $subfolders = Get-ChildItem -Path $taskFolder -Directory -Force -ErrorAction SilentlyContinue | Select-Object FullName

    $subfolders | ForEach-Object {

        $taskVersionFolder = "$($_.FullName)\ps_modules"
    
        #remove any content from those folder, as they are temporary
        Remove-Item -Path $taskVersionFolder -Recurse -Force -ErrorAction SilentlyContinue
        #copy and overwrite all
        Copy-Item -Path "$currentPath\..\src\ps_modules" -Destination $taskVersionFolder -Recurse -Force

    }



}
