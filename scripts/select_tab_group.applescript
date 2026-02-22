on run argv
	if (count of argv) = 0 then error "Missing group name"
	set needle to item 1 of argv

	tell application "Safari" to activate
	delay 0.3

	tell application "System Events"
		tell process "Safari"
			-- Ensure sidebar is visible
			try
				click menu item "Show Sidebar" of menu "View" of menu bar 1
				delay 1.0
			end try

			-- Search only within window 1, with a depth cap to avoid
			-- crawling into web content or deep toolbar hierarchies.
			set w to window 1
			set hit to my findByTitleContains(w, needle, 20)
			if hit is missing value then
				error "Could not find a Tab Group matching: " & needle
			end if

			try
				perform action "AXPress" of hit
			on error
				click hit
			end try
		end tell
	end tell
	return ""
end run

on findByTitleContains(uiObj, needle, depthLeft)
	if depthLeft ≤ 0 then return missing value

	tell application "System Events"
		-- Check this element's title (case-insensitive, no shell overhead)
		try
			set t to value of attribute "AXTitle" of uiObj
			if t is not missing value then
				ignoring case
					if t contains needle then return uiObj
				end ignoring
			end if
		end try

		-- Skip known heavy subtrees that can never contain tab groups.
		-- AXRole "AXWebArea" is Safari's web content; "AXToolbar" is the nav bar.
		try
			set r to value of attribute "AXRole" of uiObj
			if r is "AXWebArea" then return missing value
			if r is "AXToolbar" then return missing value
		end try

		try
			set kids to UI elements of uiObj
		on error
			return missing value
		end try

		repeat with k in kids
			set hit to my findByTitleContains(k, needle, depthLeft - 1)
			if hit is not missing value then return hit
		end repeat
	end tell

	return missing value
end findByTitleContains

