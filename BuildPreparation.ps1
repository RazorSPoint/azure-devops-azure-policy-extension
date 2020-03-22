#parts of the script are taken from the VSTeam module https://github.com/RazorSPoint/vsteam
[CmdletBinding(DefaultParameterSetName = "All")]
param(
    #output path of the build module
    [Parameter(ParameterSetName = "All")]
    [Parameter(ParameterSetName = "UnitTest")]
    [string]$outputDir = './dist',

    # run the scripts with the PS script analyzer
    [Parameter(ParameterSetName = "All")]
    [Parameter(ParameterSetName = "UnitTest")]
    [switch]$analyzeScript,

    # runs the unit tests
    [Parameter(ParameterSetName = "UnitTest", Mandatory = $true)]
    [Parameter(ParameterSetName = "All")]
    [switch]$runTests,

    # can be used to filter the unit test parts that should be run
    # see also: https://github.com/pester/Pester/wiki/Invoke%E2%80%90Pester#testname-alias-name
    [Parameter(ParameterSetName = "UnitTest")]
    [string]$testName,

    # outputs the code coverage
    [Parameter(ParameterSetName = "UnitTest")]
    [switch]$codeCoverage
)

$sourcePath = "./src"
 
if ([System.IO.Path]::IsPathRooted($outputDir)) {
    $output = $outputDir
}
else {
    $output = Join-Path (Get-Location) $outputDir
}
 
$output = [System.IO.Path]::GetFullPath($output)

. ./tools/PrepareExtension.ps1 -sourcePath $sourcePath -outputDir $outputDir

Write-Output "Publish complete to $outputDir"

# run the unit tests with Pester
if ($runTests.IsPresent) {
    if ($null -eq $(Get-Module -Name Pester)) {
        Install-Module -Name Pester -Repository PSGallery -Force -Scope CurrentUser -AllowClobber -SkipPublisherCheck
    }
 
    $pesterArgs = @{
        Script       = '.\unit'  
        OutputFile   = 'test-results.xml'
        OutputFormat = 'NUnitXml'
        Show         = 'Fails'
        Strict       = $true
    }
 
    if ($codeCoverage.IsPresent) {
        $pesterArgs.CodeCoverage = "$outputDir\*.ps1"
        $pesterArgs.CodeCoverageOutputFile = "coverage.xml"
        $pesterArgs.CodeCoverageOutputFileFormat = 'JaCoCo'
    }
    else {
        $pesterArgs.PassThru = $true
    }
 
    if ($testName) {
 
        $pesterArgs.TestName = $testName
 
        #passthru must be activated according to Pester docs
        $pesterArgs.PassThru = $true
    }
 
    Invoke-Pester @pesterArgs 
}
 
# Run this last so the results can be seen even if tests were also run
# if not the results scroll off and my not be in the buffer.
# run PSScriptAnalyzer
if ($analyzeScript.IsPresent) {
    Write-Output "Starting static code analysis..."
    if ($null -eq $(Get-Module -Name PSScriptAnalyzer)) {
        Install-Module -Name PSScriptAnalyzer -Repository PSGallery -Force -Scope CurrentUser
    }
 
    $r = Invoke-ScriptAnalyzer -Path $output -Recurse
    $r | ForEach-Object { Write-Host "##vso[task.logissue type=$($_.Severity);sourcepath=$($_.ScriptPath);linenumber=$($_.Line);columnnumber=$($_.Column);]$($_.Message)" }
    Write-Output "Static code analysis complete."
}