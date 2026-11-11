-- Shared helpers: load the palette and mapping, resolve colors, write JSON.
-- Run scripts from the repository root.

local M = {}

M.variants = { "dark", "light" }

function M.clay_nvim_dir()
  return os.getenv("CLAY_NVIM") or "../clay.nvim"
end

function M.load_palette()
  local path = M.clay_nvim_dir() .. "/lua/clay/palette.lua"
  local chunk, err = loadfile(path)
  if not chunk then
    error("cannot load " .. path .. " (set CLAY_NVIM to the clay.nvim checkout): " .. err, 0)
  end
  return chunk()
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

return M
