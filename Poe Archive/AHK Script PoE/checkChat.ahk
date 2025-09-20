#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance Force
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

LastLine := 0
FirstRun := 0


check(){
	global LastLine
	global FirstRun
	file := "D:\Steam\steamapps\common\Path of Exile\logs\Client.txt"
	; "free,exp", "exp,leech", "coward,kirac,free", "breach,free", "Rota,Free", "way,Free", "Rota,Maven", "Free,Paradise", "Harbinger,free", "Kirac,free", "Kirak,free", "Coward,free", "Perfect,Ascension", "free,paradi", "breachhead", "bestiary,bos", "Colos,Lith",
	; arr := ["Unholy,Adver", "Pinnacle,Pressure", "Cortex,Wormhole,Slam", "Cortex,Slam", "Eater,Doom", "Maven,Punishment", "Shaper,Anomal", "Sirus,Desolation", "Searing,Exarch,Searing,Rune", "Uber,Vortex"] ;Нужные слова отделять запятыми без пробелов
	; arr := ["free,exp", "exp,leech", "coward,kirac,free", "breach,free", "Rota,Free", "way,Free", "Rota,Maven", "Free,Paradise", "Harbinger,free", "Kirac,free", "Kirak,free", "Coward,free","untain,paradi"] ;Нужные слова отделять запятыми без пробелов
	
	arr := []
	
	
	arr.Push("Just run maps with modify") ;30 Arduous Atlas	Alch each map Solo - Just run maps with modify
	
		
	; 40 Gear Grinding Goals
	; arr.Push("Each map - run with Maven or other God's") ; 40 Gear Grinding Goals Activate Eldritch Altars or defeat Witnessed Map Bosses x 400
	arr.Push("Run many T17 maps") ; 40 Gear Grinding Goals Complete Tier 17 maps x 50
	arr.Push("Make rare T14 maps for my runners(regal use?)") ;40 Gear Grinding Goals Claim rewards from Rare, Tier 14 or higher Maps successfully completed by your Atlas Runners x 200
	; Scarab of Bisection - buy. 
	; Buy Horned Scarab of Nemeses - for more modifier
	; Buy Scarab Of Bisection - simplify T17
	
	
	; arr.Push("Make citizien max(10)") ; After Challenge. Make citizien max(10)
	; arr.Push("rota,harbinger", "rota,breachhead", "Free,Paradise", "Untain,Paradise", "Harbinger,free", "Kirac,free", "Kirak,free", "Coward,free", "way,Free", "coward,kirac,free", "breach,free", "exp,leech") ; After Challenge. Catch Experience
	arr.Push("Hierophant Build", "Necromancer Build", "Ascendant Build", "Berserk Build", "Gladiator Build", "Warden Build") ;Target of my try hero

	;"","Putrid","Vinktar","Twilight","Divin,Dominat,free","way,free","Delirium,gree","Simula,Free","Sanctum,Free","Cross Contamination","Maestro,Mastery","Vaal,Omnitect","Syndicate,Free","Syndicate,Mastermind","Carcass,Storm","Cold,River,without","Sunken,City,Laser","Kitava,Fire,Breath","Reef,Nassar","Revered,Revenge,Retold","Engaging,Echoes","Memory,Free","Cruel,Custodian,Crucible","Insane,Invitations","80%,Incandescent","80%,Screaming","80%,Forgotten","80%,Formed","80%,Hidden","Hinekora,Harrowing,Hall","Sirus,Free","Venarius,Free","Shaper,Free","Maven,Free","Feared,Free","Antagonistic,Adversaries,83","Abyss,83","Lich,83","Izaro,83","Lab,83","Lycia,83","Sanctum,83","Olroth,83","Oshabi,83","Expedition,83","Trialmaster,83","Vox,Twin,83","Predicated,Pinacle,Powers","Cortex,Void","Cortex,Pylon","Elder,Shaper","Sirus,Beam","Sirus,Spinning","Eater,World,Tentac","Maven,Punishment","Searing,Exarch","Shaper,Attack","Vaal,Side","Vaal,Area"]
	Loop , read, %file%
	{
		if (FirstRun = 0)
		{
			LastLine := A_Index
			continue
		}
		if (A_Index<= LastLine)
			continue
		OutIndex := A_Index
		sizeN := arr.Length()
		Loop, %sizeN%
		{
			needle := arr[A_Index]
			haveNo := false
			Loop, parse, needle, `,
			{				
				if (RegExMatch(A_LoopReadLine, "i)" . A_LoopField ) <= 0 )
					haveNo := true
			}
			if (!haveNo)
			{
				LastLine := OutIndex
				SoundBeep
				SetTimer, RemoveToolTip, Delete
				ToolTip, %A_LoopReadLine%, 0, 0
				SetTimer, RemoveToolTip, -30000
				return
			}
		}
		; if (RegExMatch(A_LoopReadLine, "i)" . A_LoopField ) > 0 )
		; {
		; }
	}
	FirstRun := 1
}

SetTimer, check, 1000

\::
	Send ^{Click}
	; Send {Click}{Click}{Click}{Click}{Click}{Click}{Click}{Click}{Click}{Click}{Click}
return


RemoveToolTip:
	ToolTip
return