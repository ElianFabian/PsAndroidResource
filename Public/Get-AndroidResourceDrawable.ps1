function Get-AndroidResourceDrawable {

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
    $drawablePath = "$androidResourcePath/drawable$actualQualifier"
    $drawablePathExits = Test-Path -Path $drawablePath
    if (-not $drawablePathExits) {
        return
    }

    if (-not $Qualifier -and -not $Default) {
        return Get-Item -Path "$drawablePath*" `
        | Where-Object { $_.PSIsContainer } `
        | ForEach-Object {
            $currentQualifier = $_.Name.Replace('drawable-', '').Replace('drawable', '')

            $drawables = if ($currentQualifier) {
                Get-AndroidResourceDrawable -ProjectPath $ProjectPath -Module $Module -SourceSet $SourceSet -Qualifier $currentQualifier
            }
            else {
                Get-AndroidResourceDrawable -ProjectPath $ProjectPath -Module $Module -SourceSet $SourceSet -Default
            }
            if (-not $drawables) {
                return
            }
            
            $qualifierName = if ($currentQualifier) { $currentQualifier } else { 'default' }

            [PSCustomObject]@{
                Qualifier = $qualifierName
                Drawables = $drawables
            }
        }
    }

    return Get-Item -Path "$drawablePath/*"
}
