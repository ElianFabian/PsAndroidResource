function Get-AndroidResourceFile {

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

        [ValidateSet(
            'color',
            'drawable',
            'layout',
            'mipmap'
        )]
        [Parameter(Mandatory)]
        [string] $Type,

        [Parameter(ParameterSetName = 'Qualifier-Default')]
        [switch] $Default,

        [Parameter(ParameterSetName = 'Qualifier')]
        [string] $Qualifier = $null
    )

    $androidResourcePath = Get-AndroidResourcePath -ProjectPath $ProjectPath -Module $Module -SourceSet $SourceSet

    $actualQualifier = if (-not [string]::IsNullOrWhiteSpace($Qualifier)) { "-$Qualifier" } else { '' }
    $resourceTypePath = "$androidResourcePath/$Type$actualQualifier"
    $resourceTypePathExits = Test-Path -Path "$resourceTypePath*"
    if (-not $resourceTypePathExits) {
        return
    }

    if (-not $Qualifier -and -not $Default) {
        return Get-Item -Path "$resourceTypePath*" `
        | Where-Object { $_.PSIsContainer } `
        | ForEach-Object {
            $currentQualifier = $_.Name.Replace("$Type-", '').Replace($Type, '')

            $values = if ($currentQualifier) {
                Get-AndroidResourceFile -ProjectPath $ProjectPath -Module $Module -SourceSet $SourceSet -Qualifier $currentQualifier -Type $Type
            }
            else {
                Get-AndroidResourceFile -ProjectPath $ProjectPath -Module $Module -SourceSet $SourceSet -Default -Type $Type
            }

            if (-not $values) {
                return
            }

            $qualifierName = if ($currentQualifier) { $currentQualifier } else { 'default' }

            [PSCustomObject]@{
                Qualifier = $qualifierName
                Values    = $values
            }
        }
    }

    return Get-Item -Path "$resourceTypePath/*"
}
