$commands = @(
    "Get-AndroidResourceValue"
    "Get-AndroidResourceFile"
)

function GetBuildGradlePath {
    param (
        [Parameter(Mandatory)]
        [string] $LiteralProjectPath,

        [Parameter(Mandatory)]
        [string] $LiteralCurrentPath
    )

    $trimmedPath = (Resolve-Path $LiteralCurrentPath.TrimEnd('/').TrimEnd('\')).Path
    $trimmedProjectPath = (Resolve-Path $LiteralProjectPath.TrimEnd('/').TrimEnd('\')).Path

    foreach ($item in (Get-ChildItem -LiteralPath $trimmedPath | Sort-Object -Property { $_.PSIsContainer })) {
        if ($item.PSIsContainer -and ($item.Name -eq 'build' -or $item.Name -eq '.gradle' -or $item.Name -eq '.idea')) {
            continue
        }

        if ($item.PSIsContainer) {
            $buildGradlePath = GetBuildGradlePath -LiteralProjectPath $LiteralProjectPath -LiteralCurrentPath $item.FullName
            if ($buildGradlePath) {
                $buildGradlePath
            }
        }
        else {
            if ($item.Name -like 'build.gradle*') {
                if ($item.Directory.FullName -eq $trimmedProjectPath) {
                    continue
                }
                $item
                break
            }
        }
    }
}

Register-ArgumentCompleter -CommandName $commands `
    -ParameterName Module -ScriptBlock {

    param(
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    $projectPath = $fakeBoundParameters['ProjectPath'].TrimEnd('/').TrimEnd('\')

    if (-not $projectPath) {
        return
    }

    $projectPathExits = Test-Path -Path $projectPath
    if (-not $projectPathExits) {
        return
    }

    $projectPathFullName = (Resolve-Path $projectPath).Path

    $buildGradlePath = GetBuildGradlePath -LiteralProjectPath $projectPathFullName -LiteralCurrentPath $projectPathFullName

    $buildGradlePath | Split-Path -Parent `
    | ForEach-Object {
        ($_.Replace('\', '/') -replace $projectPathFullName.Replace('\', '/'), '' ).Trim('/').Replace('/', ':')
    } `
    | Sort-Object
}

Register-ArgumentCompleter -CommandName $commands `
    -ParameterName SourceSet -ScriptBlock {

    param(
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    $projectPath = $fakeBoundParameters['ProjectPath'].TrimEnd('/').TrimEnd('\')
    $module = $fakeBoundParameters['Module']

    if (-not $projectPath -or -not $module) {
        return
    }

    $projectPathExits = Test-Path -Path $projectPath
    if (-not $projectPathExits) {
        return
    }

    $projectPathFullName = (Resolve-Path $projectPath).Path

    $modulePath = "$projectPathFullName/$($module.Replace(':', '/'))"
    $modulePathExits = Test-Path -Path $modulePath
    if (-not $modulePathExits) {
        return
    }

    $modulePathFullName = (Resolve-Path $modulePath).Path

    Get-ChildItem -Path $modulePathFullName -Filter "src" `
    | ForEach-Object {
        $_.GetDirectories().Name
    } `
    | Where-Object {
        $_ -like "$wordToComplete*"
    }
}

Register-ArgumentCompleter -CommandName $commands `
    -ParameterName Qualifier -ScriptBlock {

    param(
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    $projectPath = $fakeBoundParameters['ProjectPath'].TrimEnd('/').TrimEnd('\')

    if (-not $projectPath) {
        return
    }

    $androidResourcePath = Get-AndroidResourcePath -ProjectPath $projectPath -Module $fakeBoundParameters['Module'] -SourceSet $fakeBoundParameters['SourceSet']

    $folderName = switch ($commandName) {
        'Get-AndroidResourceValue' { 'values' }
        'Get-AndroidResourceFile' { $fakeBoundParameters['Type'] }
    }

    $resourceFolderPath = "$androidResourcePath/$folderName"
    $resourceFolderPathExits = Test-Path -Path "$resourceFolderPath-*"
    if (-not $resourceFolderPathExits) {
        return
    }

    Get-Item -Path "$resourceFolderPath-*" `
    | Where-Object { $_.PSIsContainer } `
    | ForEach-Object {
        $_.Name.Replace("$folderName-", '').Replace($folderName, '')
    } `
    | Where-Object {
        $_ -like "$wordToComplete*"
    }
}
