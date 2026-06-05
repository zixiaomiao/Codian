$ErrorActionPreference = "Stop"

$RepoUrl = if ($env:CODIA_REPO) { $env:CODIA_REPO } else { "https://github.com/zixiaomiao/codian.git" }
$PluginName = "codian"
$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }
$SkillDir = if ($env:CODIA_SKILL_DIR) { $env:CODIA_SKILL_DIR } else { Join-Path $CodexHome "skills\$PluginName" }
$MarketplacePath = if ($env:CODIA_MARKETPLACE) { $env:CODIA_MARKETPLACE } else { Join-Path $env:USERPROFILE ".agents\plugins\marketplace.json" }
$SourcePath = $SkillDir

function Require-Command($Name) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Missing required command: $Name"
  }
}

Require-Command git
Require-Command python

New-Item -ItemType Directory -Force -Path (Split-Path $SkillDir) | Out-Null

if (Test-Path (Join-Path $SkillDir ".git")) {
  git -C $SkillDir pull --ff-only
} elseif (Test-Path $SkillDir) {
  Remove-Item -Recurse -Force $SkillDir
  git clone $RepoUrl $SkillDir
} else {
  git clone $RepoUrl $SkillDir
}

New-Item -ItemType Directory -Force -Path (Split-Path $MarketplacePath) | Out-Null

$RegisterScript = @'
import json
import sys
from pathlib import Path

marketplace_path = Path(sys.argv[1]).expanduser()
plugin_name = sys.argv[2]
plugin_dir = Path(sys.argv[3]).expanduser()

if marketplace_path.exists():
    data = json.loads(marketplace_path.read_text(encoding="utf-8"))
else:
    data = {
        "name": "personal",
        "interface": {"displayName": "Personal"},
        "plugins": [],
    }

data.setdefault("name", "personal")
data.setdefault("interface", {}).setdefault("displayName", "Personal")
plugins = data.setdefault("plugins", [])

entry = {
    "name": plugin_name,
    "source": {
        "source": "local",
        "path": str(plugin_dir),
    },
    "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL",
    },
    "category": "Productivity",
}

for index, item in enumerate(plugins):
    if item.get("name") == plugin_name:
        plugins[index] = entry
        break
else:
    plugins.append(entry)

marketplace_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"Registered {plugin_name} in {marketplace_path}")
'@

$RegisterScript | python - $MarketplacePath $PluginName $SourcePath

if ($env:OBSIDIAN_VAULT) {
  python (Join-Path $SkillDir "scripts\obsidian_memory.py") init --vault $env:OBSIDIAN_VAULT
}

Write-Host ""
Write-Host "Installed $PluginName at:"
Write-Host "  $SkillDir"
Write-Host ""
Write-Host "Next, configure your Obsidian vault if you have not already:"
Write-Host "  python `"$SkillDir\scripts\obsidian_memory.py`" init --vault `"D:\path\to\your\Obsidian vault`""
Write-Host ""
Write-Host "Then enable `"Codian`" in Codex."
