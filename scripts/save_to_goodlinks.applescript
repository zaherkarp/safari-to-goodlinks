-- save_to_goodlinks.applescript
-- Saves a URL to GoodLinks via its x-callback-url scheme.
-- Usage: osascript save_to_goodlinks.applescript <url> <tag1 tag2 ...>

on run argv
	if (count of argv) < 1 then error "Usage: save_to_goodlinks.applescript <url> [tags...]"

	set theURL to item 1 of argv
	set theTags to ""
	if (count of argv) > 1 then
		set theTags to item 2 of argv
	end if

	-- URL-encode using python
	set encodedURL to do shell script "python3 -c \"import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))\" " & quoted form of theURL
	set encodedTags to do shell script "python3 -c \"import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))\" " & quoted form of theTags

	set glURL to "goodlinks://x-callback-url/save?quick=1&url=" & encodedURL & "&tags=" & encodedTags
	do shell script "open " & quoted form of glURL
end run
