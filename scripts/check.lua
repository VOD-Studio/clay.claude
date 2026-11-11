-- Check the generated themes against the palette, the installed Claude Code,
-- and the Clay design checklist.
-- Usage: lua scripts/check.lua (from the repository root).
-- Set CLAUDE_BIN to the Claude Code executable if it is not found.

package.path = "scripts/?.lua;" .. package.path
local clay = require("clay")

local passed, failed, skipped = 0, 0, 0

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok and err == "skip" then
    skipped = skipped + 1
    print("SKIP " .. name)
  elseif ok then
    passed = passed + 1
    print("PASS " .. name)
  else
    failed = failed + 1
    print("FAIL " .. name .. "\n     " .. tostring(err))
  end
end

local function fail(msg, ...)
  error(msg:format(...), 0)
end

-- Themes as committed, parsed from JSON (flat string values only).
local themes = {}
for _, variant in ipairs(clay.variants) do
  local text = assert(clay.read(clay.theme_path(variant)), "missing " .. clay.theme_path(variant))
  local theme = { overrides = {}, order = {} }
  theme.name = text:match('"name":%s*"([^"]*)"')
  theme.base = text:match('"base":%s*"([^"]*)"')
  local body = text:match('"overrides":%s*(%b{})')
  for k, v in body:gmatch('"([%w_]+)":%s*"([^"]*)"') do
    if theme.overrides[k] then
      fail("%s: duplicate key %s", variant, k)
    end
    theme.overrides[k] = v
    theme.order[#theme.order + 1] = k
  end
  themes[variant] = theme
end

local mapping = clay.load_mapping()
local palette = clay.load_palette()

-- Color math -----------------------------------------------------------------

local function linear(c)
  c = c / 255
  return c <= 0.04045 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4
end

local function luminance(hex)
  local r, g, b = clay.parse_hex(hex)
  return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
end

local function contrast(a, b)
  local la, lb = luminance(a), luminance(b)
  if la < lb then
    la, lb = lb, la
  end
  return (la + 0.05) / (lb + 0.05)
end

local function lightness(hex)
  local y = luminance(hex)
  local f = y > 216 / 24389 and y ^ (1 / 3) or (24389 / 27 * y + 16) / 116
  return 116 * f - 16
end

local function distance(a, b)
  return math.abs(lightness(a) - lightness(b))
end

-- Generated output -----------------------------------------------------------

test("themes match a fresh build", function()
  for _, variant in ipairs(clay.variants) do
    local want = clay.theme_json(clay.theme(palette, mapping, variant))
    if clay.read(clay.theme_path(variant)) ~= want then
      fail("%s is stale; run `make build`", clay.theme_path(variant))
    end
  end
end)

test("themes use the configured names and ANSI bases", function()
  for _, variant in ipairs(clay.variants) do
    local t = themes[variant]
    if t.name ~= mapping.name[variant] then
      fail("%s: name %q", variant, tostring(t.name))
    end
    if t.base ~= mapping.base[variant] or not t.base:find("^" .. variant .. "%-") then
      fail("%s: base %q must be a %s-* built-in", variant, tostring(t.base), variant)
    end
  end
end)

test("every override is a #rrggbb color", function()
  for _, variant in ipairs(clay.variants) do
    for k, v in pairs(themes[variant].overrides) do
      if not v:match("^#%x%x%x%x%x%x$") then
        fail("%s.%s = %q", variant, k, v)
      end
    end
  end
end)

-- Coverage against the installed Claude Code ---------------------------------

local function find_claude_bin()
  local home = os.getenv("HOME") or ""
  local candidates = { os.getenv("CLAUDE_BIN") }
  local function add_cmd(cmd)
    local p = io.popen("(" .. cmd .. ") 2>/dev/null")
    if p then
      for line in p:lines() do
        candidates[#candidates + 1] = line
      end
      p:close()
    end
  end
  add_cmd("readlink -f " .. home .. "/.local/share/mise/installs/claude/latest/claude")
  add_cmd("ls -t " .. home .. "/.local/share/claude/versions/* | head -1")
  add_cmd("readlink -f \"$(command -v claude)\"")
  for _, path in ipairs(candidates) do
    if path and path ~= "" then
      local f = io.open(path, "rb")
      if f then
        local size = f:seek("end")
        f:close()
        if size and size > 10 * 1024 * 1024 then
          return path
        end
      end
    end
  end
end

-- Key names of the built-in dark theme object embedded in the executable.
local function builtin_keys(path)
  local data = clay.read(path)
  local start = 1
  while true do
    local i = data:find('{autoAccept:"', start, true)
    if not i then
      return nil
    end
    local j = data:find("}", i, true)
    local obj = data:sub(i, j)
    if obj:find('briefLabelClaude:"', 1, true) then
      local keys = {}
      for k in obj:gmatch('([%w_]+):"') do
        keys[#keys + 1] = k
      end
      return keys
    end
    start = j
  end
end

test("themes cover exactly the installed Claude Code theme keys", function()
  local bin = find_claude_bin()
  if not bin then
    print("     Claude Code executable not found; set CLAUDE_BIN")
    return "skip"
  end
  local keys = builtin_keys(bin)
  if not keys then
    fail("no built-in theme found in %s", bin)
  end
  local known = {}
  for _, k in ipairs(keys) do
    known[k] = true
  end
  for _, variant in ipairs(clay.variants) do
    local o = themes[variant].overrides
    local missing, extra = {}, {}
    for _, k in ipairs(keys) do
      if not o[k] then
        missing[#missing + 1] = k
      end
    end
    for _, k in ipairs(themes[variant].order) do
      if not known[k] then
        extra[#extra + 1] = k
      end
    end
    if #missing > 0 or #extra > 0 then
      fail(
        "%s (%s): missing [%s] (they fall back to base colors); unknown [%s] (ignored by Claude Code)",
        variant,
        bin,
        table.concat(missing, ", "),
        table.concat(extra, ", ")
      )
    end
  end
  print(("     %d keys, %s"):format(#keys, bin))
end)

-- Design checklist -----------------------------------------------------------

local function each(fn)
  for _, variant in ipairs(clay.variants) do
    fn(variant, themes[variant].overrides, palette[variant])
  end
end

test("colors are neutral gray, Clay, string, or a Clay shimmer", function()
  return each(function(variant, o, p)
    local allowed = {
      [p.clay] = true,
      [p.string] = true,
      [clay.resolve(palette, variant, { "shimmer", "clay" })] = true,
    }
    for k, v in pairs(o) do
      local r, g, b = clay.parse_hex(v)
      if not (r == g and g == b) and not allowed[v] then
        fail("%s.%s = %s carries hue", variant, k, v)
      end
    end
  end)
end)

test("text contrast: text >= 7, inactive >= 4, dark Clay >= 4.5", function()
  return each(function(variant, o, p)
    local checks = { { "text", 7 }, { "inactive", 4 } }
    if variant == "dark" then
      checks[#checks + 1] = { "claude", 4.5 }
    elseif o.claude ~= "#d97757" then
      fail("light Clay must stay the brand color #d97757, got %s", o.claude)
    end
    for _, c in ipairs(checks) do
      local ratio = contrast(o[c[1]], p.bg)
      if ratio < c[2] then
        fail("%s.%s contrast %.2f < %.1f", variant, c[1], ratio, c[2])
      end
    end
  end)
end)

local function distinct(variant, o, keys)
  local seen = {}
  for _, k in ipairs(keys) do
    local v = o[k]
    if seen[v] then
      fail("%s: %s and %s share %s", variant, seen[v], k, v)
    end
    seen[v] = k
  end
end

test("related states are distinguishable", function()
  return each(function(variant, o)
    distinct(variant, o, { "success", "error", "warning" })
    distinct(variant, o, { "diffAdded", "diffRemoved" })
    distinct(variant, o, { "diffAddedWord", "diffRemovedWord" })
    distinct(variant, o, { "diffAddedDimmed", "diffRemovedDimmed" })
    distinct(variant, o, { "text", "inactive", "subtle" })
    distinct(variant, o, { "selectionBg", "userMessageBackground", "userMessageBackgroundHover" })
    distinct(variant, o, {
      "red_FOR_SUBAGENTS_ONLY",
      "blue_FOR_SUBAGENTS_ONLY",
      "green_FOR_SUBAGENTS_ONLY",
      "yellow_FOR_SUBAGENTS_ONLY",
      "purple_FOR_SUBAGENTS_ONLY",
      "orange_FOR_SUBAGENTS_ONLY",
      "pink_FOR_SUBAGENTS_ONLY",
      "cyan_FOR_SUBAGENTS_ONLY",
    })
  end)
end)

test("surfaces move away from bg: dimmed < line < word, message < hover < selection", function()
  return each(function(variant, o, p)
    local chains = {
      { "diffAddedDimmed", "diffAdded", "diffAddedWord" },
      { "diffRemovedDimmed", "diffRemoved", "diffRemovedWord" },
      { "userMessageBackground", "userMessageBackgroundHover", "selectionBg" },
    }
    for _, chain in ipairs(chains) do
      local prev = 0
      for _, k in ipairs(chain) do
        local d = distance(o[k], p.bg)
        if d <= prev then
          fail("%s.%s is not farther from bg than the previous step", variant, k)
        end
        prev = d
      end
    end
  end)
end)

test("every shimmer differs from its base color", function()
  for _, variant in ipairs(clay.variants) do
    local o = themes[variant].overrides
    for k, v in pairs(o) do
      local base = k:match("^(.-)Shimmer$") or k:match("^(.-)_shimmer$")
      if base and o[base] and o[base] == v then
        fail("%s.%s equals %s", variant, k, base)
      end
    end
  end
end)

-- Versioning -----------------------------------------------------------------

local version = clay.plugin_version()

test("version is MAJOR.MINOR.PATCH and lives only in plugin.json", function()
  if not clay.parse_version(version) then
    fail("%s: version %q is not MAJOR.MINOR.PATCH", clay.PLUGIN_JSON, tostring(version))
  end
  -- plugin.json wins silently over a marketplace entry's version, so keep one.
  local plugins = assert(clay.read(clay.MARKETPLACE_JSON)):match('"plugins":%s*(%b[])')
  if plugins and plugins:find('"version"', 1, true) then
    fail("%s: remove `version` from the plugin entry; plugin.json is the source", clay.MARKETPLACE_JSON)
  end
end)

test("changelog has an Unreleased section and one for each release", function()
  local text = clay.read(clay.CHANGELOG)
  if not text then
    fail("%s is missing", clay.CHANGELOG)
  end
  if not clay.changelog_section(text, "Unreleased") then
    fail("%s has no `## [Unreleased]` section", clay.CHANGELOG)
  end
  local out = clay.sh("git tag --list '" .. clay.plugin_name() .. "--v*'")
  for tag in out:gmatch("[^\n]+") do
    local v = tag:match("%-%-v(.+)$")
    if not clay.changelog_section(text, v) then
      fail("%s has no `## [%s]` section for tag %s", clay.CHANGELOG, v, tag)
    end
  end
end)

-- Users only receive a change when the version string changes, so shipped
-- changes since the last release must be released with a new version.
test("version is not behind the last release", function()
  local _, in_git = clay.sh("git rev-parse --git-dir")
  if not in_git then
    return "skip"
  end
  local latest = clay.latest_release()
  if not latest then
    print(("     no release tag yet; first release: make release VERSION=%s"):format(version))
    return
  end
  local cmp = clay.compare_versions(version, latest)
  if cmp < 0 then
    fail("plugin.json %s is older than the last release %s", version, latest)
  end
  local _, same = clay.sh(
    ("git diff --quiet %s -- %s"):format(clay.tag(latest), table.concat(clay.SHIPPED, " "))
  )
  if cmp == 0 and not same then
    print(("     unreleased changes to %s since %s; users get them after `make release`"):format(
      table.concat(clay.SHIPPED, ", "),
      clay.tag(latest)
    ))
  end
end)

print(("\n%d passed, %d failed, %d skipped"):format(passed, failed, skipped))
os.exit(failed == 0 and 0 or 1)
