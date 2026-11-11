LUA ?= lua
CLAUDE ?= claude
VARIANT ?= dark

.PHONY: build check preview

# Regenerate themes from ../clay.nvim (override with CLAY_NVIM=/path).
build:
	$(LUA) scripts/build.lua

# Verify themes are fresh, cover the installed Claude Code, and follow the
# design checklist.
check:
	$(LUA) scripts/check.lua

# Open Claude Code with this plugin and a Clay theme for this session only;
# user settings are not changed. VARIANT=light for the light theme.
preview:
	$(CLAUDE) --plugin-dir "$(CURDIR)" --settings '{"theme":"custom:clay:clay-$(VARIANT)"}'
