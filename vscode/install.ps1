# Installs the Alacritty theme into VS Code by copying it to the extensions folder.
# Re-run after editing the theme, then run "Developer: Reload Window" in VS Code.
$pkg  = Get-Content "$PSScriptRoot\package.json" -Raw | ConvertFrom-Json
$dest = Join-Path $HOME ".vscode\extensions\$($pkg.publisher).$($pkg.name)-$($pkg.version)"

Get-ChildItem "$HOME\.vscode\extensions" -Directory -Filter "$($pkg.publisher).$($pkg.name)-*" |
    Remove-Item -Recurse -Force

New-Item -ItemType Directory -Force $dest | Out-Null
Copy-Item "$PSScriptRoot\package.json" $dest
Copy-Item "$PSScriptRoot\themes" $dest -Recurse
Write-Host "Installed to $dest"
Write-Host 'Then set "workbench.colorTheme": "Alacritty" (or pick it with Ctrl+K Ctrl+T).'
