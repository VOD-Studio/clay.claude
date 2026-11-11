# clay.claude

Clay themes for [Claude Code](https://code.claude.com), packaged as a Claude
Code plugin: **Clay Dark** and **Clay Light**.

Colors follow the Clay design system from clay.nvim
(`design/clay-design-system.md`): hierarchy by brightness, neutral grays, one
Clay accent (`#d97757`) reserved for focus.

## Install

```sh
claude plugin marketplace add VOD-Studio/clay.claude
claude plugin install clay@clay
```

To pick up a new release later:

```sh
claude plugin marketplace update clay
claude plugin update clay@clay
```

Restart Claude Code to apply the update.

Then pick **Clay Dark** or **Clay Light** in `/theme`, or set it in
`~/.claude/settings.json`:

```json
{ "theme": "custom:clay:clay-dark" }
```

Plugin themes are named `custom:<plugin>:<file>`. Custom themes do not follow
`auto`; switch between dark and light yourself.

To try a theme without installing or touching your settings:

```sh
make preview                # Clay Dark
make preview VARIANT=light  # Clay Light
```

### Pair with a Clay terminal

Both themes use the ANSI built-ins (`dark-ansi`, `light-ansi`) as their base.
Claude Code picks the syntax highlighter from the base, so code blocks and diff
tokens are drawn with the terminal's 16 ANSI colors. Use the terminal table from
the design system (for example the Omarchy `clay` theme) and code stays
grayscale; with another terminal palette, code takes that palette's colors.

Inside tmux, Claude Code limits itself to 256 colors. Set
`CLAUDE_CODE_TMUX_TRUECOLOR=1` (with tmux RGB support) for exact colors.

## How colors are chosen

`mapping.lua` maps each of Claude Code's 72 theme keys to a Clay palette role;
`scripts/build.lua` resolves them against `palette.lua`, the single source of
color values (taken from clay.nvim's `lua/clay/palette.lua`).

| Claude Code                                                                                 | Clay                                                                                              |
| ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| text, inverse text                                                                          | `fg`, `bg`                                                                                        |
| inactive, subtle text                                                                       | `comment`, `subtle`                                                                               |
| brand, current mode (plan, auto-accept, bash, fast), permission prompt, selected suggestion | `clay`                                                                                            |
| other accents (IDE, skills, background tasks, …)                                            | `secondary`                                                                                       |
| error / warning / success                                                                   | `bright` / `secondary` / `fg`                                                                     |
| prompt border                                                                               | `float_border`                                                                                    |
| diff lines added / removed                                                                  | `diff_add` / `diff_delete`                                                                        |
| diff words added / removed                                                                  | `selection` / `diff_change`                                                                       |
| user, bash and memory messages / hover                                                      | `float` / `cursorline`                                                                            |
| selection                                                                                   | `selection`                                                                                       |
| subagent colors                                                                             | eight distinct steps: `clay`, `bright`, `fg`, `secondary`, `string`, `muted`, `comment`, `subtle` |
| ultrathink rainbow                                                                          | `clay`                                                                                            |

Values the design system does not define are derived:

- **Shimmer** (animated highlight): 35% toward `bright` in dark, toward `bg` in
  light, so it is always the lighter frame.
- **Dimmed diff lines**: halfway between the diff line color and `bg`.

## Development

```sh
make build   # regenerate themes/ from palette.lua and mapping.lua
make check   # verify the themes
```

`make check` verifies that:

- `themes/` matches a fresh build;
- the themes cover exactly the keys of the installed Claude Code. Missing keys
  would fall back to colorful base values, and unknown keys are silently
  ignored. Set `CLAUDE_BIN` if the executable is not found;
- the design checklist holds: only gray, Clay and `string` hues, contrast
  (text ≥ 7, inactive ≥ 4), related states distinct, surfaces ordered away
  from `bg`.

Run `make check` after upgrading Claude Code; new theme keys need an entry in
`mapping.lua`.

Commit generated themes together with the mapping change that produced them.
