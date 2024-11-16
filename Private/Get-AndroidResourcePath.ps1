function Get-AndroidResourcePath {
    param (
        [Parameter(Mandatory)]
        [string] $ProjectPath,

        [Parameter(Mandatory)]
        [string] $Module,

        [Parameter(Mandatory)]
        [string] $SourceSet
    )

    if (-not (Test-Path -Path $ProjectPath)) {
        throw "The provided path '$ProjectPath' does not exist."
    }

    if (-not (Test-Path -Path "$ProjectPath/build.gradle*") -or -not (Test-Path -Path "$ProjectPath/settings.gradle*")) {
        throw "The provided path '$ProjectPath' is not a valid Android project. It should contain 'build.gradle' and 'settings.gradle' files."
    }

    $actualModulePath = "$ProjectPath/$($Module.Replace(':', '/'))"
    if (-not (Test-Path -Path "$actualModulePath/build.gradle*")) {
        throw "The module '$Module' is not a valid Android module. It should contain a 'build.gradle' file."
    }

    if (-not (Test-Path -Path $actualModulePath)) {
        throw "The module '$Module' is not present in the project."
    }

    $actualSourceSetPath = "$actualModulePath/src/$SourceSet"
    if (-not (Test-Path -Path $actualSourceSetPath)) {
        throw "The source set '$SourceSet' is not present in the module '$Module'."
    }

    return "$actualSourceSetPath/res"
}
