property appName : "ClipboardManager"
property panelWidth : 420
property settingsWidth : 520
property hotkeyKeyCode : 41

on run
    set results to {}
    tell application "System Events"
        if not (exists application process appName) then
            do shell script "open -a " & appName
            delay 2.5
        end if
    end tell
    my closeEverything()

    my pressHotkey()
    set end of results to my check("hotkey opens the panel", my panelExists())

    my pressHotkey()
    set end of results to my check("hotkey again keeps the panel open", my panelExists())

    my pressEscape()
    set end of results to my check("Esc closes the panel", not (my panelExists()))

    my pressHotkey()
    tell application "Finder" to activate
    delay 0.8
    set end of results to my check("panel stays open after switching apps", my panelExists())

    set end of results to my check("close button hides the panel", my clickPanelCloseButton() and not (my panelExists()))

    my openSettings()
    set end of results to my check("Settings opens from the menu bar", my settingsWindow() is not missing value)

    my pressHotkey()
    set end of results to my check("hotkey works while Settings is open", my panelExists())
    my pressEscape()

    set end of results to my check("recorder rejects a macOS system shortcut", my recorderRejectsSystemShortcut())
    set end of results to my check("recorder keeps the current shortcut after Esc", my recorderLabel() is "⌘;")

    my closeEverything()
    set end of results to my check("hotkey still works after closing Settings", my panelExists() or my openAndCheckPanel())
    my pressEscape()

    set AppleScript's text item delimiters to linefeed
    return results as text
end run

on check(label, passed)
    if passed then return "PASS  " & label
    return "FAIL  " & label
end check

on pressHotkey()
    tell application "System Events" to key code hotkeyKeyCode using {command down}
    delay 1
end pressHotkey

on pressEscape()
    tell application "System Events" to key code 53
    delay 0.7
end pressEscape

on openAndCheckPanel()
    my pressHotkey()
    return my panelExists()
end openAndCheckPanel

on windowWithWidth(width)
    tell application "System Events"
        tell application process appName
            repeat with w in windows
                set sz to size of w
                if (item 1 of sz) = width then return w
            end repeat
        end tell
    end tell
    return missing value
end windowWithWidth

on panelExists()
    return my windowWithWidth(panelWidth) is not missing value
end panelExists

on settingsWindow()
    return my windowWithWidth(settingsWidth)
end settingsWindow

on findElement(e, wantedRole, wantedDesc, depth)
    tell application "System Events"
        try
            if (role of e as text) is wantedRole and (description of e as text) is wantedDesc then return e
        end try
        if depth < 9 then
            try
                repeat with c in (UI elements of e)
                    set f to my findElement(c, wantedRole, wantedDesc, depth + 1)
                    if f is not missing value then return f
                end repeat
            end try
        end if
    end tell
    return missing value
end findElement

on staticTexts(e, depth)
    set out to ""
    tell application "System Events"
        try
            if (role of e as text) is "AXStaticText" then set out to (value of e as text) & linefeed
        end try
        if depth < 9 then
            try
                repeat with c in (UI elements of e)
                    set out to out & my staticTexts(c, depth + 1)
                end repeat
            end try
        end if
    end tell
    return out
end staticTexts

on clickPanelCloseButton()
    set w to my windowWithWidth(panelWidth)
    if w is missing value then return false
    set b to my findElement(w, "AXButton", "close button", 0)
    if b is missing value then return false
    tell application "System Events" to click b
    delay 0.8
    return true
end clickPanelCloseButton

on openSettings()
    tell application "System Events"
        tell application process appName
            click menu bar item 1 of menu bar 2
            delay 0.6
            click menu item "Settings…" of menu 1 of menu bar item 1 of menu bar 2
            delay 1.5
        end tell
    end tell
end openSettings

on recorderField()
    set w to my settingsWindow()
    if w is missing value then return missing value
    return my findElement(w, "AXButton", "Keyboard shortcut", 0)
end recorderField

on recorderLabel()
    set field to my recorderField()
    if field is missing value then return ""
    tell application "System Events" to return value of static text 1 of field as text
end recorderLabel

on recorderRejectsSystemShortcut()
    set field to my recorderField()
    if field is missing value then return false
    tell application "System Events"
        tell application process appName
            set frontmost to true
            delay 0.4
            click field
            delay 0.6
            key code 49 using {control down, command down}
            delay 0.9
        end tell
    end tell
    set texts to my staticTexts(my settingsWindow(), 0)
    my pressEscape()
    return texts contains "used by macOS"
end recorderRejectsSystemShortcut

on closeEverything()
    repeat 3 times
        set w to my settingsWindow()
        if w is missing value then exit repeat
        set b to my findElement(w, "AXButton", "close button", 0)
        if b is missing value then exit repeat
        tell application "System Events" to click b
        delay 0.6
    end repeat
    if my panelExists() then my clickPanelCloseButton()
end closeEverything
