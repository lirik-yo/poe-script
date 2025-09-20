#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance Force

SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include json.ahk
#Include PoeConstSettings.ahk

SetTitleMatchMode, 2

GetUrlStash(league, tabN){
	return "https://www.pathofexile.com/character-window/get-stash-items?league=" . league . "&tabs=1&tabIndex=" . tabN . "&accountName=lirik_yo"
}

GetFileNameForStash(league, tabN){
	return A_ScriptDir . "\StashDat\get-stash-items-" . league . "-" . tabN . "-" . A_DD . "-" . A_MM . ".json"
}
CreateDirForData(){
	if !FileExist("StashDat")
		FileCreateDir, StashDat
}


CheckAndDownload(league, tabN){	
	fileName := GetFileNameForStash(league, tabN)
	if FileExist(fileName)
		return
	oldclipboard := clipboard
	linkStash := GetUrlStash(league, tabN)
	Run chrome.exe %linkStash%	
	WinActivate, Chrome
	WinWaitActive, Chrome,, 1
	if ErrorLevel
	{
		clipboard := fileName		
		MsgBox, Can't active chrome. Save yourself, then press OK
		clipboard := oldclipboard		
	}else{
		Sleep 1200
		Send ^s
		Sleep 500
		Send %fileName%
		Sleep 50
		Send {Enter}
		Sleep 600
		Send ^w
	}
}

GetTabCount(league){
	fileName := GetFileNameForStash(league, 0)
	dbFile	:=	FileOpen(fileName, "r")
	dbFileText	:=	dbFile.Read()
	dbJSON	:=	JSON.Load(dbFileText)
	
	return dbJSON["numTabs"]
}

CreateDirForData()

GetAllStashesInLeague(league){
	CheckAndDownload(league, 0)
	TabsCount := GetTabCount(league)
	
	Loop, %TabsCount%
	{
		if (A_Index = TabsCount)
			break
		CheckAndDownload(league, A_Index)
	}
}

For keyLeague, league in Leagues
	GetAllStashesInLeague(league)

; `::
		; Send ^s
; return

; STD
; https://www.pathofexile.com/character-window/get-stash-items?league=Standard&tabs=1&tabIndex=0&accountName=
; Sanctum
; https://www.pathofexile.com/character-window/get-stash-items?league=Sanctum&tabs=1&tabIndex=0&accountName=
; Hardcore
; https://www.pathofexile.com/character-window/get-stash-items?league=Hardcore&tabs=1&tabIndex=0&accountName=
; Sanctum Hardcore
; https://www.pathofexile.com/character-window/get-stash-items?league=Hardcore%20Sanctum&tabs=1&tabIndex=0&accountName=