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
		-- SECURITY: Strip newlines and carriage returns from titles to prevent
		-- injection attacks. A malicious page could set its <title> to include
		-- a newline, which would break the line-pairing and allow injecting
		-- arbitrary URLs into the output.
		set lines_ to {}
		repeat with t in (tabs of w)
			set rawTitle to (name of t)
			-- Replace newlines and carriage returns with spaces
			set sanitizedTitle to my replaceChars(rawTitle, linefeed, " ")
			set sanitizedTitle to my replaceChars(sanitizedTitle, return, " ")
			set end of lines_ to sanitizedTitle
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

-- Replace all occurrences of findChar in sourceText with replaceWith
on replaceChars(sourceText, findChar, replaceWith)
	set AppleScript's text item delimiters to findChar
	set pieces to text items of sourceText
	set AppleScript's text item delimiters to replaceWith
	set cleaned to pieces as text
	set AppleScript's text item delimiters to ""
	return cleaned
end replaceChars
