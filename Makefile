LUA ?= lua
CLAUDE ?= claude
VARIANT ?= dark

.PHONY: build check preview release

# Regenerate themes from palette.lua and mapping.lua.
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

# Cut a release: VERSION=patch|minor|major|X.Y.Z. Bumps plugin.json, dates the
# changelog's Unreleased notes, commits and tags <name>--v<version>. Does not push.
release:
	CLAUDE="$(CLAUDE)" $(LUA) scripts/release.lua "$(VERSION)"
