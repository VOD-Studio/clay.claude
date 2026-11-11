-- Generate themes/clay-{dark,light}.json from clay.nvim's palette and
-- mapping.lua. Usage: lua scripts/build.lua (from the repository root).

package.path = "scripts/?.lua;" .. package.path
local clay = require("clay")

local palette = clay.load_palette()
local mapping = clay.load_mapping()

for _, variant in ipairs(clay.variants) do
  local path = clay.theme_path(variant)
  local f = assert(io.open(path, "wb"))
  f:write(clay.theme_json(clay.theme(palette, mapping, variant)))
  f:close()
  print("wrote " .. path)
end
