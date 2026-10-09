#!/usr/bin/env bash
# Installs the Ash theme into VS Code by copying it to the extensions folder.
# Re-run after editing the theme, then run "Developer: Reload Window" in VS Code.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
read -r publisher name version < <(sed -nE 's/^  "(publisher|name|version)": "([^"]+)".*/\1 \2/p' "$here/package.json" |
    awk '{v[$1]=$2} END {print v["publisher"], v["name"], v["version"]}')
exts=~/.vscode/extensions
dest="$exts/$publisher.$name-$version"

# Old copies of this theme, including the one from before the rename (alacritty-theme)
rm -rf "$exts/$publisher.$name-"* "$exts/$publisher.alacritty-theme-"*

mkdir -p "$dest"
cp "$here/package.json" "$dest/"
cp -r "$here/themes" "$dest/"
echo "Installed to $dest"
echo 'Then set "workbench.colorTheme": "Ash" (or pick it with Ctrl+K Ctrl+T).'
