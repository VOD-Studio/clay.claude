# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Claude Code plugin (`.claude-plugin/`) that ships two custom themes, Clay Dark and Clay Light (`themes/clay-{dark,light}.json`). The theme JSON files are **generated** from Lua sources; never edit them by hand. The README documents install, usage and the color mapping table.

## Commands

Run from the repository root (scripts load `palette.lua`/`mapping.lua` and `scripts/` by relative path). Requires `lua` 5.4 (uses `io.read("a")`).

```sh
make build                 # regenerate themes/ from palette.lua + mapping.lua
make check                 # verify themes (freshness, key coverage, design checklist)
make preview               # run claude with this plugin and Clay Dark, session-only
make preview VARIANT=light
```

`make check` has no single-test selector; it runs every `test(...)` in `scripts/check.lua` and prints PASS/FAIL/SKIP. The key-coverage test compares against the installed Claude Code binary (override with `CLAUDE_BIN`) and skips if it cannot be found.

## Architecture

- `palette.lua`: the single source of color values (vendored from clay.nvim's `lua/clay/palette.lua`, not read from a sibling checkout). Has `dark` and `light` tables keyed by role (`bg`, `fg`, `clay`, `secondary`, …).
- `mapping.lua`: ordered list of `{ claude_code_key, color }` covering all 72 Claude Code theme keys. `color` is a palette role, or `{ "shimmer", role }` / `{ "dim", role }` derived colors. Also sets theme `name` and `base` (`dark-ansi`/`light-ansi`, chosen so code/diff highlighting uses the terminal's ANSI colors). Key order follows Claude Code's built-in themes.
- `scripts/clay.lua`: shared helpers (palette/mapping loading, hex math, `resolve`, `theme_json` serialization).
- `scripts/build.lua`: writes both theme JSON files. `scripts/check.lua`: byte-compares committed themes with a fresh build, checks key coverage against the installed Claude Code, and enforces the Clay design checklist (only gray/Clay/`string` hues, contrast thresholds, ordered surfaces).

## Workflow notes

- After changing `palette.lua` or `mapping.lua`, run `make build` then `make check`, and commit regenerated themes together with the change that produced them.
- After upgrading Claude Code, run `make check`; new theme keys need an entry in `mapping.lua` (missing keys fall back to colorful base values, unknown keys are silently ignored).
- Design rules (documented in `mapping.lua` header): hierarchy by brightness, status by brightness rather than hue, Clay (`#d97757`) reserved for focus (brand, current mode, permission prompt, selected suggestion).
- Commit once per completed feature point (one logical change per commit, with its regenerated themes), rather than batching several changes into one commit.
- Bump `version` in `.claude-plugin/plugin.json` for releases.
