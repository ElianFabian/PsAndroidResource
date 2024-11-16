function Get-AndroidResourceColor {

    [OutputType([PSCustomObject[]], ParameterSetName = 'Default')]
    [OutputType([System.IO.FileInfo[]], ParameterSetName = 'Qualifier')]
    [OutputType([System.IO.FileInfo[]], ParameterSetName = 'Qualifier-Default')]
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory)]
        [string] $ProjectPath,

        [Parameter(Mandatory)]
        [string] $Module,

        [Parameter(Mandatory)]
        [string] $SourceSet,

        [Parameter(ParameterSetName = 'Qualifier-Default')]
        [switch] $Default,

        [Parameter(ParameterSetName = 'Qualifier')]
        [string] $Qualifier = $null
    )

    $androidResourcePath = Get-AndroidResourcePath -ProjectPath $ProjectPath -Module $Module -SourceSet $SourceSet

    $actualQualifier = if (-not [string]::IsNullOrWhiteSpace($Qualifier)) { "-$Qualifier" } else { '' }
    $colorPath = "$androidResourcePath/color$actualQualifier"
    $colorPathExits = Test-Path -Path $colorPath
    if (-not $colorPathExits) {
        return
    }

    if (-not $Qualifier -and -not $Default) {
        return Get-Item -Path "$colorPath*" `
        | Where-Object { $_.PSIsContainer } `
        | ForEach-Object {
            $currentQualifier = $_.Name.Replace('color-', '').Replace('color', '')

            $colors = if ($currentQualifier) {
                Get-AndroidResourceColor -ProjectPath $ProjectPath -Module $Module -SourceSet $SourceSet -Qualifier $currentQualifier
            }
            else {
                Get-AndroidResourceColor -ProjectPath $ProjectPath -Module $Module -SourceSet $SourceSet -Default
            }
            if (-not $colors) {
                return
            }
            
            $qualifierName = if ($currentQualifier) { $currentQualifier } else { 'default' }

            [PSCustomObject]@{
                Qualifier = $qualifierName
                Colors = $colors
            }
        }
    }

    return Get-Item -Path "$colorPath/*"
}
