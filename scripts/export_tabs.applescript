-- export_tabs.applescript
-- Exports all tabs from Safari's front window as a JSON array.
-- Each element: {"title": "...", "url": "..."}
-- Output goes to stdout via `do shell script`.

on run
	tell application "Safari"
		if (count of windows) is 0 then return "[]"
		set w to front window
		set tabCount to count of tabs of w
		if tabCount is 0 then return "[]"

		-- Collect tab data as paired lines: title\nurl\ntitle\nurl\n...
		-- This avoids all quoting/escaping issues with AppleScript string building.
		set lines_ to {}
		repeat with t in (tabs of w)
			set end of lines_ to (name of t)
			set end of lines_ to (URL of t)
		end repeat
	end tell

	-- Join with newline
	set AppleScript's text item delimiters to linefeed
	set blob to lines_ as text
	set AppleScript's text item delimiters to ""

	-- Let Python handle JSON encoding (correctly escapes all special chars)
	set pyScript to "
import json, sys

lines = sys.stdin.read().split('\\n')
tabs = []
for i in range(0, len(lines) - 1, 2):
    tabs.append({'title': lines[i], 'url': lines[i+1]})
print(json.dumps(tabs))
"
	return do shell script "echo " & quoted form of blob & " | python3 -c " & quoted form of pyScript
end run
