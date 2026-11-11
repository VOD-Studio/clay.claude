-- Shared helpers: load the palette and mapping, resolve colors, write JSON.
-- Run scripts from the repository root.

local M = {}

M.variants = { "dark", "light" }

function M.load_palette()
  return dofile("palette.lua")
end

function M.load_mapping()
  return dofile("mapping.lua")
end

function M.parse_hex(hex)
  local r, g, b = hex:match("^#(%x%x)(%x%x)(%x%x)$")
  if not r then
    error("not a #rrggbb color: " .. tostring(hex), 0)
  end
  return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

function M.to_hex(r, g, b)
  return string.format("#%02x%02x%02x", r, g, b)
end

-- Blend `a` toward `b` by `t` (0 keeps a, 1 gives b).
function M.mix(a, b, t)
  local ar, ag, ab = M.parse_hex(a)
  local br, bg, bb = M.parse_hex(b)
  local function ch(x, y)
    return math.floor(x + (y - x) * t + 0.5)
  end
  return M.to_hex(ch(ar, br), ch(ag, bg), ch(ab, bb))
end

M.SHIMMER = 0.35

local function lookup(palette, variant, key)
  local color = palette[variant][key]
  if not color then
    error(("palette.%s has no key %q"):format(variant, key), 0)
  end
  return color
end

-- Resolve one mapping value to a color for a variant.
function M.resolve(palette, variant, spec)
  if type(spec) == "string" then
    return lookup(palette, variant, spec)
  end
  local op, key = spec[1], spec[2]
  local color = lookup(palette, variant, key)
  if op == "shimmer" then
    local toward = variant == "dark" and "bright" or "bg"
    return M.mix(color, lookup(palette, variant, toward), M.SHIMMER)
  elseif op == "dim" then
    return M.mix(color, lookup(palette, variant, "bg"), 0.5)
  end
  error("unknown mapping op: " .. tostring(op), 0)
end

-- Build the theme table for a variant, preserving mapping order.
function M.theme(palette, mapping, variant)
  local overrides = {}
  for _, entry in ipairs(mapping.keys) do
    overrides[#overrides + 1] = { entry[1], M.resolve(palette, variant, entry[2]) }
  end
  return { name = mapping.name[variant], base = mapping.base[variant], overrides = overrides }
end

function M.theme_json(theme)
  local lines = {
    "{",
    ('  "name": "%s",'):format(theme.name),
    ('  "base": "%s",'):format(theme.base),
    '  "overrides": {',
  }
  for i, kv in ipairs(theme.overrides) do
    local sep = i < #theme.overrides and "," or ""
    lines[#lines + 1] = ('    "%s": "%s"%s'):format(kv[1], kv[2], sep)
  end
  lines[#lines + 1] = "  }"
  lines[#lines + 1] = "}"
  return table.concat(lines, "\n") .. "\n"
end

function M.theme_path(variant)
  return "themes/clay-" .. variant .. ".json"
end

function M.read(path)
  local f = io.open(path, "rb")
  if not f then
    return nil
  end
  local s = f:read("a")
  f:close()
  return s
end

-- Versions and releases ------------------------------------------------------

M.PLUGIN_JSON = ".claude-plugin/plugin.json"
M.MARKETPLACE_JSON = ".claude-plugin/marketplace.json"
M.CHANGELOG = "CHANGELOG.md"

-- Paths whose changes reach users and therefore need a version bump.
M.SHIPPED = { "themes", M.PLUGIN_JSON }

function M.plugin_name()
  return assert(M.read(M.PLUGIN_JSON)):match('"name":%s*"([^"]*)"')
end

function M.plugin_version()
  return assert(M.read(M.PLUGIN_JSON)):match('"version":%s*"([^"]*)"')
end

-- Tag format used by `claude plugin tag`: <name>--v<version>.
function M.tag(version)
  return M.plugin_name() .. "--v" .. version
end

-- MAJOR.MINOR.PATCH only; returns the three numbers or nil.
function M.parse_version(v)
  local a, b, c = tostring(v):match("^(%d+)%.(%d+)%.(%d+)$")
  if not a then
    return nil
  end
  for _, part in ipairs({ a, b, c }) do
    if #part > 1 and part:sub(1, 1) == "0" then
      return nil
    end
  end
  return tonumber(a), tonumber(b), tonumber(c)
end

-- -1, 0 or 1 as a < b, a == b, a > b.
function M.compare_versions(a, b)
  local x, y = { M.parse_version(a) }, { M.parse_version(b) }
  for i = 1, 3 do
    if x[i] ~= y[i] then
      return x[i] < y[i] and -1 or 1
    end
  end
  return 0
end

function M.bump(version, part)
  local a, b, c = M.parse_version(version)
  if part == "major" then
    return ("%d.0.0"):format(a + 1)
  elseif part == "minor" then
    return ("%d.%d.0"):format(a, b + 1)
  elseif part == "patch" then
    return ("%d.%d.%d"):format(a, b, c + 1)
  end
end

-- Run a shell command; return its trimmed stdout and whether it succeeded.
function M.sh(cmd)
  local p = assert(io.popen(cmd .. " 2>/dev/null"))
  local out = p:read("a")
  local ok = p:close()
  return (out:gsub("%s+$", "")), ok == true
end

-- Highest released version among <name>--v* tags, or nil.
function M.latest_release()
  local out = M.sh("git tag --list '" .. M.plugin_name() .. "--v*'")
  local best
  for tag in out:gmatch("[^\n]+") do
    local v = tag:match("%-%-v(.+)$")
    if v and M.parse_version(v) and (not best or M.compare_versions(v, best) > 0) then
      best = v
    end
  end
  return best
end

-- Body of a `## [heading]` section in the changelog, or nil.
function M.changelog_section(text, heading)
  local pattern = "\n## %[" .. heading:gsub("%p", "%%%0") .. "%][^\n]*\n"
  local _, stop = text:find(pattern)
  if not stop then
    return nil
  end
  local next_start = text:find("\n## ", stop, true)
  return text:sub(stop + 1, next_start and next_start - 1 or #text)
end

return M
