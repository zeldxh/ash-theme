# Installs the Ash theme into VS Code by copying it to the extensions folder.
# Re-run after editing the theme, then run "Developer: Reload Window" in VS Code.
$pkg  = Get-Content "$PSScriptRoot\package.json" -Raw | ConvertFrom-Json
$exts = Join-Path $HOME '.vscode\extensions'
$dest = Join-Path $exts "$($pkg.publisher).$($pkg.name)-$($pkg.version)"

# Old copies of this theme, including the one from before the rename (alacritty-theme)
Get-ChildItem $exts -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "$($pkg.publisher).$($pkg.name)-*" -or $_.Name -like "$($pkg.publisher).alacritty-theme-*" } |
    Remove-Item -Recurse -Force

New-Item -ItemType Directory -Force $dest | Out-Null
Copy-Item "$PSScriptRoot\package.json" $dest
Copy-Item "$PSScriptRoot\themes" $dest -Recurse
Write-Host "Installed to $dest"
Write-Host 'Then set "workbench.colorTheme": "Ash" (or pick it with Ctrl+K Ctrl+T).'
