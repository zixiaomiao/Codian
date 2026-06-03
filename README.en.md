# Obsidian Codex Memory

[中文说明](README.md)

Use an Obsidian vault as long-term memory for Codex.

This is a **Codex plugin**, not an Obsidian community plugin. It lets Codex read a compact memory note, append session summaries, and optionally sync the memory note through a Git-backed Obsidian vault.

For the future optimization plan, see [ROADMAP.md](ROADMAP.md).

## Current status

The current version has completed **Stage 2: Memory categories**.

Completed:

- Basic long-term memory workflow: read, append, and compactly retrieve `Codex/Codex 会话总结.md`.
- Stage 1 Project Summary: generate and prioritize `Codex/project-summary.md`.
- Stage 2 Memory categories: generate `Codex/memory/Project.md`, `Decision.md`, `Todo.md`, `Bug.md`, and `User-Preference.md`.
- Keyword-based reads that load matching category files before startup rules and a few matched history blocks.
- Conservative GitHub sync: only Codex memory files are synced; the plugin does not manage the whole Obsidian vault.
- Verified parity between local source, installed Codex plugin cache, and GitHub `main`.

Not finished yet:

- Stage 3 Decision Log: dedicated records for why decisions were made.
- Stage 4 Auto-summary and archive: compress old logs to prevent unbounded memory growth.
- Stage 5 Memory quality: duplicate detection, similar-memory merging, and importance scoring.
- Stage 6 Generate Context: create standard context files for Codex, Claude Code, Cursor, and similar coding tools.

## What it does

- Reads `Codex/Codex 会话总结.md` from your Obsidian vault.
- Generates `Codex/project-summary.md` from the session summary.
- Generates categorized memory files under `Codex/memory/`.
- Creates a generic startup memory template during initialization when the memory note is missing.
- Prioritizes the project summary; with keywords, reads matching categories before startup rules, reading strategy, indexes, and fixed paths instead of expanding full history.
- Retrieves 1-3 relevant history blocks by keyword to save tokens.
- Appends compact Codex session summaries.
- Supports any vault path through `OBSIDIAN_VAULT` or a saved local config.
- Can selectively sync Codex memory files to GitHub.
- Avoids recording credentials or secrets by design; you should still review summaries before syncing sensitive work.

## One-line install

### Download from Releases and double-click

If you do not want to copy commands, download the installer for your system:

- macOS: download [`install-macos.command`](https://raw.githubusercontent.com/zixiaomiao/obsidian-codex-memory/main/release-assets/install-macos.command), then double-click it
- Windows: download [`install-windows.cmd`](https://raw.githubusercontent.com/zixiaomiao/obsidian-codex-memory/main/release-assets/install-windows.cmd), then double-click it

The installer downloads the plugin and registers it in the Codex personal marketplace.

You can also download versioned assets from [Releases](https://github.com/zixiaomiao/obsidian-codex-memory/releases).

### Copy-and-paste install

macOS or Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/zixiaomiao/obsidian-codex-memory/main/install.sh | bash
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/zixiaomiao/obsidian-codex-memory/main/install.ps1 | iex
```

Then configure your vault:

```bash
python3 ~/plugins/obsidian-codex-memory/scripts/obsidian_memory.py init --vault "/path/to/your/Obsidian vault"
```

On Windows:

```powershell
python "$env:USERPROFILE\plugins\obsidian-codex-memory\scripts\obsidian_memory.py" init --vault "D:\path\to\your\Obsidian vault"
```

You can also skip local config and set `OBSIDIAN_VAULT` in your shell environment.

## Usage

Read compact memory:

```bash
python3 ~/plugins/obsidian-codex-memory/scripts/obsidian_memory.py read
```

Generate or refresh the project summary:

```bash
python3 ~/plugins/obsidian-codex-memory/scripts/obsidian_memory.py project-summary
```

Generate or refresh categorized memory:

```bash
python3 ~/plugins/obsidian-codex-memory/scripts/obsidian_memory.py memory-categories
```

Read relevant history by keywords, up to 3 blocks by default:

```bash
python3 ~/plugins/obsidian-codex-memory/scripts/obsidian_memory.py read --query "obsidian sync git/github"
```

Read the full memory note:

```bash
python3 ~/plugins/obsidian-codex-memory/scripts/obsidian_memory.py read --full
```

Append a summary:

```bash
python3 ~/plugins/obsidian-codex-memory/scripts/obsidian_memory.py append --summary "5-8 lines of durable session memory"
```

Preview GitHub sync:

```bash
python3 ~/plugins/obsidian-codex-memory/scripts/obsidian_memory.py sync-github --dry-run
```

Run GitHub sync:

```bash
python3 ~/plugins/obsidian-codex-memory/scripts/obsidian_memory.py sync-github
```

## Expected Obsidian note

The default memory note is:

```text
Codex/Codex 会话总结.md
```

The default project summary is:

```text
Codex/project-summary.md
```

The default categorized memory directory is:

```text
Codex/memory/
```

It contains:

- `Project.md`
- `Decision.md`
- `Todo.md`
- `Bug.md`
- `User-Preference.md`

Inside the vault, this means:

```text
<your-vault>/Codex/Codex 会话总结.md
```

You can change it when initializing:

```bash
python3 ~/plugins/obsidian-codex-memory/scripts/obsidian_memory.py init --vault "/path/to/vault" --memory-rel "Codex/My Memory.md"
```

If the note does not exist, `init` creates a generic template with:

- Startup rules
- Reading strategy
- Task retrieval index
- Fixed path index
- History archive notes
- Session logs

The template does not hard-code another user's local paths. It records the current computer's configured vault path.

## Token-saving strategy

The plugin defaults to this reading logic:

- Ordinary tasks: read `Codex/project-summary.md` first, then startup rules and the current user message.
- Category tasks: read matching files under `Codex/memory/` by keyword.
- Obsidian/GitHub/sync tasks: also query `obsidian`, `sync`, `git/github`, `github-sync`, and similar terms.
- Plugin/memory tasks: also query `codex/plugin`, `codex/memory`, `obsidian-codex-memory`, and similar terms.
- Retrospectives: read only 1-3 matched history blocks.
- Never expand the whole session summary unless explicitly requested.

## Token and cache impact

For a session summary around 18,000 characters, reading the full file may cost roughly 9k-16k tokens. With this plugin, the default startup read is usually around 1k-2k tokens; adding 1-3 keyword-matched history blocks is usually around 2k-4k tokens.

After Stage 2, the normal read path is more stable: read the project summary first, then matching category files, then only a few history blocks when needed. This keeps long-term memory context in the low-thousands of tokens while making stable content more cache-friendly.

| Scenario | Read content | Estimated tokens | Compared with full read |
| --- | --- | --- | --- |
| No memory read | No long-term memory | 0 | Cheapest, but no memory benefit |
| Default plugin read | Project Summary, startup rules, reading strategy, indexes, fixed paths | About 1k-2k | Saves about 80%-90% |
| Plugin + category read | Default read + one matching category file | About 1.5k-3k | Saves about 70%-90% |
| Plugin + category + keyword search | Default read + matching categories + 1-3 relevant history blocks | About 2k-4k | Saves about 65%-85% |
| Full session summary read | Entire memory file | About 9k-16k | Baseline |

Cache-wise, Project Summary, startup rules, and category files are more stable than the full log and are more likely to be reused. Keyword-matched history varies by task, so its cache hit rate is more moderate. Full reads contain stable parts too, but ongoing log appends and larger payloads can reduce practical cache benefit.

In short: this is not meant to compete with reading no memory at all. It reduces the cost of long-term memory from tens of thousands of tokens to a few thousand while preserving useful context.

## How installation works

The install scripts:

- clone or update this repository into `~/plugins/obsidian-codex-memory`
- create or update `~/.agents/plugins/marketplace.json`
- register the plugin as available in Codex

After installation, open Codex and enable **Obsidian Codex Memory** from the personal marketplace.

## GitHub sync behavior

`sync-github` is intentionally conservative.

- Allowed local-over-remote memory files:
  - `Codex/Codex 会话总结.md`
  - `Codex/project-summary.md`
  - `Codex/memory/Project.md`
  - `Codex/memory/Decision.md`
  - `Codex/memory/Todo.md`
  - `Codex/memory/Bug.md`
  - `Codex/memory/User-Preference.md`
  - `Codex/MACOS_CODEX_OBSIDIAN_MEMORY.md`
- The plugin is focused on Codex memory files. It is not a full Obsidian vault manager.
- The vault must already be a Git repository with `origin` configured.

Always run `sync-github --dry-run` before real sync when using a new vault.

## Requirements

- Codex desktop or Codex environment with plugin support
- Python 3
- Git, if using one-line install or GitHub sync
- Obsidian vault on local disk

## License

MIT
