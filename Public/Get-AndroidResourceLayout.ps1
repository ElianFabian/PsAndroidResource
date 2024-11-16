function Get-AndroidResourceLayout {

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
    $layoutPath = "$androidResourcePath/layout$actualQualifier"
    $layoutPathExits = Test-Path -Path $layoutPath
    if (-not $layoutPathExits) {
        return
    }

    if (-not $Qualifier -and -not $Default) {
        return Get-Item -Path "$layoutPath*" `
        | Where-Object { $_.PSIsContainer } `
        | ForEach-Object {
            $currentQualifier = $_.Name.Replace('layout-', '').Replace('layout', '')

            $layouts = if ($currentQualifier) {
                Get-AndroidResourceLayout -ProjectPath $ProjectPath -Module $Module -SourceSet $SourceSet -Qualifier $currentQualifier
            }
            else {
                Get-AndroidResourceLayout -ProjectPath $ProjectPath -Module $Module -SourceSet $SourceSet -Default
            }
            if (-not $layouts) {
                return
            }
            
            $qualifierName = if ($currentQualifier) { $currentQualifier } else { 'default' }

            [PSCustomObject]@{
                Qualifier = $qualifierName
                Layouts = $layouts
            }
        }
    }

    return Get-Item -Path "$layoutPath/*.xml"
}
