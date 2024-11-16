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

    $PSBoundParameters.Add('Type', 'layout')

    return Get-AndroidResourceFile @PSBoundParameters
}
