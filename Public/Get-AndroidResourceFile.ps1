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

        [Parameter(ParameterSetName = 'Qualifier')]
        [string[]] $Qualifier,

        [Parameter(ParameterSetName = 'Qualifier-Default')]
        [switch] $Default
    )

    $androidResourcePath = Get-AndroidResourcePath -ProjectPath $ProjectPath -Module $Module -SourceSet $SourceSet

    # To force enter the list at least once, even if no value was given, it means we return all available qualifiers.
    if (-not $Qualifier) {
        $Qualifier = $null
    }

    $Qualifier | ForEach-Object {
        $actualQualifier = if (-not [string]::IsNullOrWhiteSpace($_)) { "-$_" } else { '' }
        $resourceTypePath = "$androidResourcePath/$Type$actualQualifier"
        $resourceTypePathExits = Test-Path -Path "$resourceTypePath*"
        if (-not $resourceTypePathExits) {
            return
        }

        if (-not $_ -and -not $Default) {
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

        Get-Item -Path "$resourceTypePath/*"
    }
}
