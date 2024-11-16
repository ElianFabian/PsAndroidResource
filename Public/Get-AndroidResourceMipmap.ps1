function Get-AndroidResourceMipmap {

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
    $mipmapPath = "$androidResourcePath/mipmap$actualQualifier"
    $mipmapPathExits = Test-Path -Path $mipmapPath
    if (-not $mipmapPathExits) {
        return
    }

    if (-not $Qualifier -and -not $Default) {
        return Get-Item -Path "$mipmapPath*" `
        | Where-Object { $_.PSIsContainer } `
        | ForEach-Object {
            $currentQualifier = $_.Name.Replace('mipmap-', '').Replace('mipmap', '')

            $mipmaps = if ($currentQualifier) {
                Get-AndroidResourceMipmap -ProjectPath $ProjectPath -Module $Module -SourceSet $SourceSet -Qualifier $currentQualifier
            }
            else {
                Get-AndroidResourceMipmap -ProjectPath $ProjectPath -Module $Module -SourceSet $SourceSet -Default
            }
            if (-not $mipmaps) {
                return
            }
            
            $qualifierName = if ($currentQualifier) { $currentQualifier } else { 'default' }

            [PSCustomObject]@{
                Qualifier = $qualifierName
                Mipmaps   = $mipmaps
            }
        }
    }

    return Get-Item -Path "$mipmapPath/*"
}
