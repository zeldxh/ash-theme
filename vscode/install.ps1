# Installs the Ash theme into VS Code. Packs this folder into a .vsix and installs it with the
# `code` CLI: VS Code only loads extensions registered in its extensions.json, so copying the
# folder into ~/.vscode/extensions is not enough (it gets marked obsolete and ignored).
# Re-run after editing the theme, then run "Developer: Reload Window" in VS Code.
$ErrorActionPreference = 'Stop'
if (-not (Get-Command code -ErrorAction SilentlyContinue)) { Write-Warning 'VS Code (code) not found, skipping the Ash theme.'; return }

$pkg  = Get-Content "$PSScriptRoot\package.json" -Raw | ConvertFrom-Json
$id   = "$($pkg.publisher).$($pkg.name)"
$exts = Join-Path $HOME '.vscode\extensions'
$work = Join-Path ([IO.Path]::GetTempPath()) "ash-vsix-$PID"
$vsix = "$work.vsix"

# Leftovers from the old folder-copy installer (also under the pre-rename name, alacritty-theme):
# unregistered folders and their entries in .obsolete, which would make VS Code drop the new install
Get-ChildItem $exts -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "$($pkg.publisher).alacritty-theme-*" } |
    ForEach-Object { [IO.Directory]::Delete($_.FullName, $true) }
$obsolete = Join-Path $exts '.obsolete'
if (Test-Path $obsolete) {
    $o = Get-Content $obsolete -Raw | ConvertFrom-Json -AsHashtable
    $stale = @($o.Keys | Where-Object { $_ -like "$id-*" -or $_ -like "$($pkg.publisher).alacritty-theme-*" })
    foreach ($k in $stale) {
        $o.Remove($k)
        $dir = Join-Path $exts $k
        if (Test-Path $dir) { [IO.Directory]::Delete($dir, $true) }
    }
    if ($stale) { [IO.File]::WriteAllText($obsolete, ($o | ConvertTo-Json -Compress)) }
}

New-Item -ItemType Directory -Force "$work\extension" | Out-Null
Copy-Item "$PSScriptRoot\package.json" "$work\extension"
Copy-Item "$PSScriptRoot\themes" "$work\extension" -Recurse

# The two metadata files every .vsix carries
$types = '<?xml version="1.0" encoding="utf-8"?>' +
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
    '<Default Extension=".json" ContentType="application/json"/>' +
    '<Default Extension=".vsixmanifest" ContentType="text/xml"/></Types>'
[IO.File]::WriteAllText((Join-Path $work '[Content_Types].xml'), $types)

$manifest = @"
<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="$($pkg.name)" Version="$($pkg.version)" Publisher="$($pkg.publisher)"/>
    <DisplayName>$($pkg.displayName)</DisplayName>
    <Description xml:space="preserve">$($pkg.description)</Description>
    <Categories>Themes</Categories>
    <Properties><Property Id="Microsoft.VisualStudio.Code.Engine" Value="$($pkg.engines.vscode)"/></Properties>
  </Metadata>
  <Installation><InstallationTarget Id="Microsoft.VisualStudio.Code"/></Installation>
  <Dependencies/>
  <Assets><Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/></Assets>
</PackageManifest>
"@
[IO.File]::WriteAllText((Join-Path $work 'extension.vsixmanifest'), $manifest)

Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path $vsix) { [IO.File]::Delete($vsix) }
[IO.Compression.ZipFile]::CreateFromDirectory($work, $vsix)

code --install-extension $vsix --force
[IO.Directory]::Delete($work, $true)
[IO.File]::Delete($vsix)
Write-Host 'Ash installed. Set "workbench.colorTheme": "Ash" (or pick it with Ctrl+K Ctrl+T).'
