#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${CODIA_REPO:-https://github.com/zixiaomiao/codian.git}"
PLUGIN_NAME="codian"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
SKILL_DIR="${CODIA_SKILL_DIR:-$CODEX_HOME/skills/$PLUGIN_NAME}"
MARKETPLACE_PATH="${CODIA_MARKETPLACE:-$HOME/.agents/plugins/marketplace.json}"
SOURCE_PATH="$SKILL_DIR"

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

need git
need python3

mkdir -p "$(dirname "$SKILL_DIR")"

if [ -d "$SKILL_DIR/.git" ]; then
  git -C "$SKILL_DIR" pull --ff-only
elif [ -d "$SKILL_DIR" ]; then
  echo "Refreshing existing Codin directory: $SKILL_DIR"
  rm -rf "$SKILL_DIR"
  git clone "$REPO_URL" "$SKILL_DIR"
else
  git clone "$REPO_URL" "$SKILL_DIR"
fi

mkdir -p "$(dirname "$MARKETPLACE_PATH")"

python3 - "$MARKETPLACE_PATH" "$PLUGIN_NAME" "$SOURCE_PATH" <<'PY'
import json
import sys
from pathlib import Path

marketplace_path = Path(sys.argv[1]).expanduser()
plugin_name = sys.argv[2]
source_path = sys.argv[3]

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
        "path": source_path,
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
PY

if [ -n "${OBSIDIAN_VAULT:-}" ]; then
  python3 "$SKILL_DIR/scripts/obsidian_memory.py" init --vault "$OBSIDIAN_VAULT"
fi

cat <<EOF

Installed $PLUGIN_NAME at:
  $SKILL_DIR

Next, configure your Obsidian vault if you have not already:
  python3 "$SKILL_DIR/scripts/obsidian_memory.py" init --vault "/path/to/your/Obsidian vault"

Then enable "Codin" in Codex.
EOF
