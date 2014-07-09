-- Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
-- for details. All rights reserved. Use of this source code is governed by a
-- BSD-style license that can be found in the LICENSE file.

tell application "Safari" to activate

delay 3.0

tell application "System Events"

        keystroke "n" using command down

        delay 1.0

        keystroke "l" using command down

        keystroke "http://localhost:8080/"
        -- Simulate Enter key.
        key code 36

        delay 5.0

        keystroke "l" using command down
        -- Simulate Tab key.
        key code 48
        key code 48

        delay 0.2

        -- Simulate Down.
        key code 125

        delay 0.2

        -- Simulate Down.
        key code 125

        delay 0.2

        -- Simulate Enter key.
        key code 36

        delay 0.2

        -- Simulate Tab key.
        key code 48

        -- Simulate Cmd-Up.
        key code 126 using command down

        -- Simulate Down.
        key code 125
        key code 125
        key code 125
        key code 125
        key code 125

        -- Simulate Cmd-Right.
        key code 124 using command down

        -- Simulate Delete
        key code 51

        delay 0.1
        keystroke "a" using command down
        delay 0.2
        keystroke "c" using command down

        delay 0.2
        set clipboardData to (the clipboard as text)

        if ("main() {" is in (clipboardData as string)) then
                error "main() { in clipboardData"
        end if

        if ("main() " is not in (clipboardData as string)) then
                error "main() is not in clipboardData"
        end if

        keystroke "l" using command down
        delay 0.2

        keystroke "http://localhost:8080/"
        -- Simulate Enter key.
        key code 36

        delay 5.0

        keystroke "l" using command down
        -- Simulate Tab key.
        key code 48
        key code 48

        delay 0.2

        -- Simulate Down.
        key code 125

        delay 0.2

        -- Simulate Down.
        key code 125

        delay 0.2

        -- Simulate Enter key.
        key code 36

        delay 0.2

        -- Simulate Tab key.
        key code 48

        -- Simulate Cmd-Down.
        key code 125 using command down

        repeat 203 times
                -- Simulate Delete
               key code 51
        end repeat
        delay 5.0
        repeat 64 times
                -- Simulate Delete
               key code 51
        end repeat


        delay 0.1
        keystroke "a" using command down
        delay 0.5
        keystroke "c" using command down

        delay 0.5
        set clipboardData to (the clipboard as text)

        if ("/" is not (clipboardData as string)) then
                error "/ is not clipboardData"
        end if

end tell

tell application "Safari" to quit

display notification "Test passed" with title "Safari test" sound name "Glass"
