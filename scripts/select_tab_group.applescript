on run argv
	if (count of argv) = 0 then error "Missing group name"
	set needle to item 1 of argv

	tell application "Safari" to activate
	delay 0.2

	tell application "System Events"
		tell process "Safari"
			-- Ensure sidebar is visible
			try
				click menu item "Show Sidebar" of menu "View" of menu bar 1
				delay 0.2
			end try

			-- Find UI element whose AXTitle contains the group name (case-insensitive)
			set w to window 1
			set hit to my findByTitleContains(w, my lower(needle))
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
end run

on findByTitleContains(uiObj, needleLower)
	try
		set t to value of attribute "AXTitle" of uiObj
		if t is not missing value then
			if my lower(t) contains needleLower then return uiObj
		end if
	end try

	try
		set kids to UI elements of uiObj
	on error
		return missing value
	end try

	repeat with k in kids
		set hit to my findByTitleContains(k, needleLower)
		if hit is not missing value then return hit
	end repeat

	return missing value
end findByTitleContains

on lower(t)
	return do shell script "python3 -c \"import sys; print(sys.argv[1].lower())\" " & quoted form of t
end lower
