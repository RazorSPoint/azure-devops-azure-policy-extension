function Update-ReleaseNotes($shouldPatch){

	$changelogEntries = Get-ChangeLogMap
	$publisherTags = git tag
}

function Get-ChangeLogMap(){
	$jsonString = (Get-Content -Path "./../CHANGELOG.json").ToString();

	$changelog = ConvertFrom-Json -InputObject $jsonString

	$map = @{}
	$count = 0

	$changelog.entries | foreach {
		$entry = $_
		$entry.name = $changelog.name
		$map.Add($entry.tag,$entry)

		$count++
	}
	
	Write-Host "found $count tags"

	return $map
}


function Create-ReleaseNotes($currentPath){

	$readmeContent = Get-Content "$currentPath\..\README.md", "$currentPath\..\wiki\CHANGELOG.md"
	
	$readmeContent = $readmeContent.Replace("../src/","").Replace("src/","")
	
	$readmeContent | Set-Content "$currentPath/../src/overview.md"

}


Create-ReleaseNotes $PSScriptRoot
