-- Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
-- for details. All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE file.

-- This: 'tell application "Firefox" to activate' doesn't seem to bring
-- application in focus if it's not already open.
do shell script "open -a Firefox"

delay 3.0

tell application "System Events"
	--- Open Incognito window to avoid effect of caching of pages.
	keystroke "p" using {command down, shift down}
	
	delay 1.0
	
	keystroke "l" using command down
	
	keystroke "http://localhost:8080/"
	-- Simulate Enter key.
	key code 36
	
	delay 10.0
	
	-- Refresh the page to reload the scripts
	keystroke "r" using command down
	
	keystroke "l" using command down
	
	delay 1.0
	
	-- Simulate Tab key to get to 'Pick an example' dropdown
	repeat 8 times
		key code 48
	end repeat
	
	-- Simulate Down then Enter to select Hello, World
	key code 125
	key code 36
	
	delay 1.0
	
	keystroke "l" using command down
	
	delay 1.0
	
	-- Simulate Tab key to get to Code editor.
	repeat 9 times
		key code 48
	end repeat
	
	-- Simulate sequence of Down keys to get to "print(greeting);" line
	repeat 8 times
		key code 125
	end repeat
	
	-- Simulate Cmd-Right.
	key code 124 using command down
	
	keystroke "print('c');"
	
	-- Simulate Left*11 to get to the beginning of "print('c');"
	repeat 11 times
		key code 123
	end repeat
	
	-- Simulate Enter to split lines
	key code 36
	
	-- Simulate Delete to join lines
	key code 51
	
	-- Simulate Enter to split lines
	key code 36
	
	-- Simulate Right*8 to get to right after the c in "print('c');"
	repeat 8 times
		key code 124
	end repeat
	
	keystroke "d"
	
	delay 0.1
	keystroke "a" using command down
	delay 0.2
	keystroke "c" using command down
	
	delay 1
	set clipboardData to (the clipboard as text)
	
	if ("print('cd')" is not in (clipboardData as string)) then
		error "print('cd')  is not in clipboardData: "
	end if
end tell

tell application "Firefox" to quit

display notification "Test passed" with title "Firefox test" sound name "Glass"