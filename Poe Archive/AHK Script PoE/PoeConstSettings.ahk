#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance Force

SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

Leagues := ["Standard", "Crucible", "Hardcore", "Hardcore%20Crucible"]
Leagues := ["Standard", "Hardcore"]
Leagues := ["Ancestral"]

CurrentLeague := "Ancestor"
; CurrentLeague := "Standard"