#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance Force
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
\::
	Send ^{Click Right}
	Sleep 50
	; Send {Click}{Click}{Click}{Click}{Click}{Click}{Click}{Click}{Click}{Click}{Click}
return

|::
	Send +^{Click}
	Sleep 100
	; Send {Click}{Click}{Click}{Click}{Click}{Click}{Click}{Click}{Click}{Click}{Click}
return

F11::
	MouseGetPos, ttx, tty
	ToolTip, %ttx%`n%tty%
return
