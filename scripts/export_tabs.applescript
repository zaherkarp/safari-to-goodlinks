on run
	tell application "Safari"
		if (count of windows) is 0 then return "[]"
		set w to front window
		set out to {}
		repeat with t in (tabs of w)
			set end of out to {title:(name of t), url:(URL of t)}
		end repeat
	end tell

	-- Convert to JSON using python for correctness
	set py to "python3 -c \"
import json, sys
items=" & my toPythonLiteral(out) & "
print(json.dumps(items))
\""
	return do shell script py
end run

on toPythonLiteral(asRecords)
	-- Minimal conversion for our list of simple records
	set chunks to "["
	repeat with r in asRecords
		set chunks to chunks & "{'title':" & quoted form of (title of r) & ",'url':" & quoted form of (url of r) & "},"
	end repeat
	set chunks to chunks & "]"
	return chunks
end toPythonLiteral
