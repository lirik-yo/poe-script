#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance Force
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

DefaultLeague := "Standard"
DirConfig := "Configs\"

class ConfigClass{
	startLeague:=20231209
	endLeague:=""
	defaultBuy:=0.8
	defaultSell:=1.05
	
	SaveToFile(){
	
	}
	
	LoadFileOrCreate(NameFile){
		if (!FileExist(DirConfig + NameFile + ".json"))
			MsgBox, Ещё нет такого конфига %NameFile%
		MsgBox, Работаем с конфигом %NameFile%
		; if (!FileExist(NameDBFile))
	}
	
	__New(NameConfig){
		this.LoadFileOrCreate(NameConfig)
	}	
}

MsgBox, Test
MsgBox, Выбери лигу. Потом мы либо загрузим её данные, либо создадим дефолтные настройки. При Cancel - выбираем Default League
InputBox, ChoosedLeague, Choose league, which league you run now?
if ErrorLevel
	ChoosedLeague := DefaultLeague
Config := new ConfigClass(ChoosedLeague)
MsgBox, You choose %ChoosedLeague%


