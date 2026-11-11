LUA ?= lua

.PHONY: build check

# Regenerate themes from ../clay.nvim (override with CLAY_NVIM=/path).
build:
	$(LUA) scripts/build.lua

# Verify themes are fresh, cover the installed Claude Code, and follow the
# design checklist.
check:
	$(LUA) scripts/check.lua
