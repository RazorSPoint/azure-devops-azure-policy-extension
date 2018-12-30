function Install-ZipFolderResource {
    param
    (
        [string]$ZipPath,
        [string]$ZipFileName,    
        [string]$Out
    )

    #is used to unpack the zips if they are not extracted already
    #unpacked DLLs are 10 times higher than packed.
    #this saves up- and download time.

    $zipFolderName = [io.path]::GetFileNameWithoutExtension($ZipFileName)

    if ((Test-Path "$ZipPath/$zipFolderName/") -eq $false) {

        Add-Type -AssemblyName System.IO.Compression.FileSystem

        [System.IO.Compression.ZipFile]::ExtractToDirectory("$ZipPath/$ZipFileName", $Out)
    }
}

