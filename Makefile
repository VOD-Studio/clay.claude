LUA ?= lua

.PHONY: build

# Regenerate themes from ../clay.nvim (override with CLAY_NVIM=/path).
build:
	$(LUA) scripts/build.lua
