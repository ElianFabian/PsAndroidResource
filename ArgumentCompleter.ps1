Register-ArgumentCompleter -CommandName @(
    "Get-AndroidResourceValue"
) `
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
    Get-ChildItem -Path $projectPathFullName -Filter "build.gradle*" -Recurse `
    | Where-Object { $_.FullName -ne $projectPathFullName } `
    | ForEach-Object {
        if ($_.Directory.FullName -eq $projectPathFullName) {
            return
        }
        $directory = $_.Directory
        if ($directory.Parent.FullName -eq $projectPathFullName) {
            $directory.Name
        }
        else {
            "$($directory.Parent.Name):$($directory.Name)" 
        }
    } `
    | Where-Object {
        $_ -like "$wordToComplete*"
    }
}


Register-ArgumentCompleter -CommandName @(
    "Get-AndroidResourceValue"
) `
    -ParameterName SourceSet -ScriptBlock {

    param(
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    $projectPath = $fakeBoundParameters['ProjectPath']
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

    Get-ChildItem -Path $modulePathFullName -Filter "src" -Recurse `
    | ForEach-Object {
        $_.GetDirectories().Name
    } `
    | Where-Object {
        $_ -like "$wordToComplete*"
    }
}
