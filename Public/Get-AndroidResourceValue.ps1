function Get-AndroidResourceValue {

    [OutputType([System.Xml.XmlLinkedNode[]], ParameterSetName = 'Qualifier')]
    [OutputType([System.Xml.XmlLinkedNode[]], ParameterSetName = 'Qualifier-Default')]
    [OutputType([PSCustomObject[]], ParameterSetName = 'Default')]
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory)]
        [string] $ProjectPath,

        [Parameter(Mandatory)]
        [string] $Module,

        [Parameter(Mandatory)]
        [string] $SourceSet,

        [ValidateSet(
            'array',
            'attr',
            'bool',
            'color',
            'declare-styleable',
            'dimen',
            'drawable',
            'fraction',
            'integer',
            'integer-array',
            'plurals',
            'string',
            'string-array',
            'style'
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
        $valuesPath = "$androidResourcePath/values$actualQualifier"
        $valuesPathExits = Test-Path -Path $valuesPath
        if (-not $valuesPathExits) {
            return
        }

        if (-not $_ -and -not $Default) {
            return Get-Item -Path "$valuesPath*" `
            | Where-Object { $_.PSIsContainer } `
            | ForEach-Object {
                $currentQualifier = $_.Name.Replace('values-', '').Replace('values', '')

                $values = if ($currentQualifier) {
                    Get-AndroidResourceValue -ProjectPath $ProjectPath -Module $Module -SourceSet $SourceSet -Type $Type -Qualifier $currentQualifier
                }
                else {
                    Get-AndroidResourceValue -ProjectPath $ProjectPath -Module $Module -SourceSet $SourceSet -Type $Type -Default
                }
                if (-not $values) {
                    return
                }

                $qualifierName = if (-not [string]::IsNullOrWhiteSpace($currentQualifier)) { $currentQualifier } else { 'default' }

                [PSCustomObject]@{
                    Qualifier = $qualifierName
                    Values    = $values
                }
            }
        }

        Select-Xml -Path "$valuesPath/*.xml" -XPath "//$Type" | ForEach-Object { $_.Node }
    }
}
