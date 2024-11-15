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

        [Parameter(ParameterSetName = 'Qualifier-Default')]
        [switch] $Default,

        [Parameter(ParameterSetName = 'Qualifier')]
        [string] $Qualifier = $null
    )

    $projectPathExits = Test-Path -Path $ProjectPath
    if (-not $projectPathExits) {
        throw "The provided path '$ProjectPath' does not exist."
        return
    }

    $isProjectBuildGradlePresent = Test-Path -Path "$ProjectPath/build.gradle*"
    $isProjectSettingsGradlePresent = Test-Path -Path "$ProjectPath/settings.gradle*"
    $isAValidAndroidProject = $isProjectBuildGradlePresent -and $isProjectSettingsGradlePresent
    if (-not $isAValidAndroidProject) {
        throw "The provided path '$ProjectPath' is not a valid Android project. It should contain 'build.gradle' and 'settings.gradle' files."
        return
    }

    $actualModulePath = "$ProjectPath/$($Module.Replace(':', '/'))"
    $isAValidModule = Test-Path -Path "$actualModulePath/build.gradle*"
    if (-not $isAValidModule) {
        throw "The module '$Module' is not a valid Android module. It should contain a 'build.gradle' file."
        return
    }

    $isModulePresent = Test-Path -Path $actualModulePath
    if (-not $isModulePresent) {
        throw "The module '$Module' is not present in the project."
        return
    }

    $actualSourceSetPath = "$actualModulePath/src/$SourceSet"
    $isSourceSetPresent = Test-Path -Path $actualSourceSetPath
    if (-not $isSourceSetPresent) {
        throw "The source set '$SourceSet' is not present in the module '$Module'."
        return
    }

    $actualQualifier = if (-not [string]::IsNullOrWhiteSpace($Qualifier)) { "-$Qualifier" } else { '' }
    $valuesPath = "$actualSourceSetPath/res/values$actualQualifier"
    $valuesPathExits = Test-Path -Path $valuesPath
    if (-not $valuesPathExits) {
        return
    }

    if (-not $Qualifier -and -not $Default) {
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

            $actualQualifier = if (-not [string]::IsNullOrWhiteSpace($currentQualifier)) { $currentQualifier } else { 'default' }

            [PSCustomObject]@{
                Qualifier = $actualQualifier
                Values    = $values
            }
        }
    }

    return Select-Xml -Path "$valuesPath/*.xml" -XPath "//$Type" | ForEach-Object { $_.Node }
}
