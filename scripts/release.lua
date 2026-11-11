-- Cut a release: bump the version, date the changelog, commit and tag.
-- Usage: lua scripts/release.lua <patch|minor|major|X.Y.Z> (from the repository root).
-- Pushing stays a separate, explicit step; the command to run is printed.

package.path = "scripts/?.lua;" .. package.path
local clay = require("clay")

local function die(msg, ...)
  io.stderr:write("release: " .. msg:format(...) .. "\n")
  os.exit(1)
end

local function run(cmd)
  print("$ " .. cmd)
  if not os.execute(cmd) then
    die("command failed: %s", cmd)
  end
end

local function write(path, text)
  local f = assert(io.open(path, "wb"))
  f:write(text)
  f:close()
end

local arg1 = arg[1]
if not arg1 or arg1 == "" then
  die("usage: make release VERSION=<patch|minor|major|X.Y.Z>")
end

local current = clay.plugin_version()
if not clay.parse_version(current) then
  die("%s has version %q, not MAJOR.MINOR.PATCH", clay.PLUGIN_JSON, tostring(current))
end

local latest = clay.latest_release()
local version
if arg1 == "patch" or arg1 == "minor" or arg1 == "major" then
  -- Bump from the last release; before the first release, from plugin.json.
  version = clay.bump(latest or current, arg1)
else
  version = arg1
end
if not clay.parse_version(version) then
  die("%q is not MAJOR.MINOR.PATCH", version)
end

if latest and clay.compare_versions(version, latest) <= 0 then
  die("%s is not newer than the last release %s", version, latest)
end
if clay.compare_versions(version, current) < 0 then
  die("%s is older than %s in %s", version, current, clay.PLUGIN_JSON)
end
local tag = clay.tag(version)
local _, exists = clay.sh("git rev-parse -q --verify refs/tags/" .. tag)
if exists then
  die("tag %s already exists", tag)
end

local dirty = clay.sh("git status --porcelain")
if dirty ~= "" then
  die("working tree is not clean; commit or stash first:\n%s", dirty)
end

local changelog = clay.read(clay.CHANGELOG) or die("%s not found", clay.CHANGELOG)
local unreleased = clay.changelog_section(changelog, "Unreleased")
if not unreleased then
  die("%s has no `## [Unreleased]` section", clay.CHANGELOG)
end
if not unreleased:find("%S") then
  die("`## [Unreleased]` in %s is empty; describe the changes first", clay.CHANGELOG)
end

-- Verify before touching any file, so a failed check leaves the tree clean.
run("lua scripts/check.lua")

-- Bump plugin.json (the only place the version lives).
if version ~= current then
  local text = clay.read(clay.PLUGIN_JSON)
  local updated, n = text:gsub('("version":%s*")[^"]*(")', "%1" .. version .. "%2", 1)
  assert(n == 1)
  write(clay.PLUGIN_JSON, updated)
end

-- Turn the Unreleased notes into the release section; leave Unreleased empty.
local date = os.date("%Y-%m-%d")
write(
  clay.CHANGELOG,
  (changelog:gsub("\n## %[Unreleased%]\n", "\n## [Unreleased]\n\n## [" .. version .. "] - " .. date .. "\n", 1))
)

run("git add " .. clay.PLUGIN_JSON .. " " .. clay.CHANGELOG)
run(("git commit -q -m 'chore(release): %s'"):format(version))
-- Validates that plugin.json and the marketplace entry agree, then tags.
run(("%s plugin tag -m '%s %%s' ."):format(os.getenv("CLAUDE") or "claude", clay.plugin_name()))

print(("\nReleased %s as %s. Publish it with:\n\n  git push origin HEAD %s\n"):format(version, tag, tag))
