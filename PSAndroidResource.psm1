#Requires -Version 5.1

$PublicFunction = @(Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1" -File -ErrorAction SilentlyContinue)
$PrivateFunction = @(Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1" -File -ErrorAction SilentlyContinue)

foreach ($import in @($PublicFunction + $PrivateFunction)) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error "Failed to import preloaded script '$($import.FullName)': $_"
    }
}


. "$PSScriptRoot/ArgumentCompleter.ps1"


Export-ModuleMember -Function $PublicFunction.BaseName
