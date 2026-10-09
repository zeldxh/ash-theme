#!/usr/bin/env bash
# Installs the Ash theme into VS Code. Packs this folder into a .vsix and installs it with the
# `code` CLI: VS Code only loads extensions registered in its extensions.json, so copying the
# folder into ~/.vscode/extensions is not enough (it gets marked obsolete and ignored).
# Re-run after editing the theme, then run "Developer: Reload Window" in VS Code.
set -euo pipefail
command -v code >/dev/null || { echo "VS Code (code) not found, skipping the Ash theme."; exit 0; }

here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# The theme's name before the rename, if VS Code has it registered
old=$(sed -nE 's/^  "publisher": "([^"]+)".*/\1/p' "$here/package.json").alacritty-theme
if code --list-extensions | grep -qx "$old"; then code --uninstall-extension "$old"; fi

# Builds the .vsix next to $work and cleans up leftovers of the old folder-copy installer (also
# under the pre-rename name, alacritty-theme): unregistered folders and their entries in
# .obsolete, which would make VS Code drop the new install.
python3 - "$here" "$work" <<'EOF'
import json, os, shutil, sys, zipfile
here, work = sys.argv[1], sys.argv[2]
pkg = json.load(open(os.path.join(here, "package.json")))
pub, name = pkg["publisher"], pkg["name"]

exts = os.path.expanduser("~/.vscode/extensions")
stale = (f"{pub}.{name}-", f"{pub}.alacritty-theme-")
obsolete = os.path.join(exts, ".obsolete")
if os.path.isfile(obsolete):
    o = json.load(open(obsolete))
    keep = {k: v for k, v in o.items() if not k.startswith(stale)}
    for k in set(o) - set(keep):
        shutil.rmtree(os.path.join(exts, k), ignore_errors=True)
    json.dump(keep, open(obsolete, "w"))
if os.path.isdir(exts):
    for d in os.listdir(exts):
        if d.startswith(stale[1]):
            shutil.rmtree(os.path.join(exts, d), ignore_errors=True)

types = ('<?xml version="1.0" encoding="utf-8"?>'
         '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
         '<Default Extension=".json" ContentType="application/json"/>'
         '<Default Extension=".vsixmanifest" ContentType="text/xml"/></Types>')
manifest = f"""<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="{name}" Version="{pkg['version']}" Publisher="{pub}"/>
    <DisplayName>{pkg['displayName']}</DisplayName>
    <Description xml:space="preserve">{pkg['description']}</Description>
    <Categories>Themes</Categories>
    <Properties><Property Id="Microsoft.VisualStudio.Code.Engine" Value="{pkg['engines']['vscode']}"/></Properties>
  </Metadata>
  <Installation><InstallationTarget Id="Microsoft.VisualStudio.Code"/></Installation>
  <Dependencies/>
  <Assets><Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/></Assets>
</PackageManifest>
"""
with zipfile.ZipFile(os.path.join(work, "ash.vsix"), "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("[Content_Types].xml", types)
    z.writestr("extension.vsixmanifest", manifest)
    z.write(os.path.join(here, "package.json"), "extension/package.json")
    for f in os.listdir(os.path.join(here, "themes")):
        z.write(os.path.join(here, "themes", f), f"extension/themes/{f}")
EOF

code --install-extension "$work/ash.vsix" --force
echo 'Ash installed. Set "workbench.colorTheme": "Ash" (or pick it with Ctrl+K Ctrl+T).'
