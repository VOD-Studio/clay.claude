-- Claude Code theme keys mapped to Clay palette roles.
--
-- Each entry is { claude_code_key, color }, where color is one of:
--   "key"                  a key of palette.lua
--   { "shimmer", "key" }   the animated highlight of a color: 35% toward
--                          `bright` in dark, 35% toward `bg` in light, so it
--                          is always the lighter frame, as in the built-ins
--   { "dim", "key" }       halfway between a surface and `bg`
--
-- Rules from design/clay-design-system.md applied here:
--   * every colored slot maps back to the gray ladder; only Clay and `string`
--     carry hue, and Clay marks focus: the brand, the current mode, the
--     permission question, the selected suggestion
--   * status by brightness, not hue: error `bright`, warning `secondary`,
--     success `fg` (the diagnostics table)
--   * surfaces only move away from `bg`; hover sits nearer than selection
--
-- Order follows Claude Code's built-in themes so the generated JSON diffs
-- cleanly against them.

local M = {}

-- Custom themes resolve to their base for syntax highlighting. The ANSI bases
-- color code and diff tokens with the terminal palette, which Clay's ANSI table
-- keeps grayscale; the dark/light bases would use Monokai or GitHub colors.
M.base = { dark = "dark-ansi", light = "light-ansi" }

M.name = { dark = "Clay Dark", light = "Clay Light" }

M.keys = {
  -- Modes and focus
  { "autoAccept", "clay" },
  { "autoAcceptShimmer", { "shimmer", "clay" } },
  { "skill", "secondary" },
  { "bashBorder", "clay" },
  { "claude", "clay" },
  { "claudeShimmer", { "shimmer", "clay" } },
  { "claudeBlue_FOR_SYSTEM_SPINNER", "secondary" },
  { "claudeBlueShimmer_FOR_SYSTEM_SPINNER", { "shimmer", "secondary" } },
  { "permission", "clay" },
  { "permissionShimmer", { "shimmer", "clay" } },
  { "planMode", "clay" },
  { "ide", "secondary" },
  { "promptBorder", "float_border" },
  { "promptBorderShimmer", { "shimmer", "float_border" } },

  -- Text
  { "text", "fg" },
  { "inverseText", "bg" },
  { "inactive", "comment" },
  { "inactiveShimmer", { "shimmer", "comment" } },
  { "subtle", "subtle" },
  { "suggestion", "clay" },
  { "remember", "secondary" },
  { "background", "secondary" },

  -- Status: brightness steps, as in the diagnostics table
  { "success", "fg" },
  { "error", "bright" },
  { "warning", "secondary" },
  { "merged", "muted" },
  { "warningShimmer", { "shimmer", "secondary" } },

  -- Diff backgrounds: whole lines, then changed words
  { "diffAdded", "diff_add" },
  { "diffRemoved", "diff_delete" },
  { "diffAddedDimmed", { "dim", "diff_add" } },
  { "diffRemovedDimmed", { "dim", "diff_delete" } },
  { "diffAddedWord", "selection" },
  { "diffRemovedWord", "diff_change" },

  -- Subagent labels: eight distinct steps, Clay where the hue matches
  { "red_FOR_SUBAGENTS_ONLY", "bright" },
  { "blue_FOR_SUBAGENTS_ONLY", "secondary" },
  { "green_FOR_SUBAGENTS_ONLY", "fg" },
  { "yellow_FOR_SUBAGENTS_ONLY", "string" },
  { "purple_FOR_SUBAGENTS_ONLY", "muted" },
  { "orange_FOR_SUBAGENTS_ONLY", "clay" },
  { "pink_FOR_SUBAGENTS_ONLY", "comment" },
  { "cyan_FOR_SUBAGENTS_ONLY", "subtle" },

  { "professionalBlue", "secondary" },
  { "chromeYellow", "secondary" },

  -- Mascot
  { "clawd_body", "clay" },
  { "clawd_background", "bg" },

  -- Surfaces
  { "userMessageBackground", "float" },
  { "userMessageBackgroundHover", "cursorline" },
  { "composerSidebarBackground", "sidebar" },
  { "selectionBg", "selection" },
  { "bashMessageBackgroundColor", "float" },
  { "memoryBackgroundColor", "float" },

  -- Usage meter: informational, not focus
  { "rate_limit_fill", "secondary" },
  { "rate_limit_empty", "selection" },

  { "fastMode", "clay" },
  { "fastModeShimmer", { "shimmer", "clay" } },
  { "effortUltra", "clay" },
  { "briefLabelYou", "secondary" },
  { "briefLabelClaude", "clay" },

  -- Rainbow keyword highlight (ultrathink): one Clay word, not a rainbow
  { "rainbow_red", "clay" },
  { "rainbow_orange", "clay" },
  { "rainbow_yellow", "clay" },
  { "rainbow_green", "clay" },
  { "rainbow_blue", "clay" },
  { "rainbow_indigo", "clay" },
  { "rainbow_violet", "clay" },
  { "rainbow_red_shimmer", { "shimmer", "clay" } },
  { "rainbow_orange_shimmer", { "shimmer", "clay" } },
  { "rainbow_yellow_shimmer", { "shimmer", "clay" } },
  { "rainbow_green_shimmer", { "shimmer", "clay" } },
  { "rainbow_blue_shimmer", { "shimmer", "clay" } },
  { "rainbow_indigo_shimmer", { "shimmer", "clay" } },
  { "rainbow_violet_shimmer", { "shimmer", "clay" } },
}

return M
