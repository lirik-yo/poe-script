#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance Force


ListMessage := []
TimeLastShow := A_TickCount
TimeMilisecondPeriodShow := 1300
TimeMilisecondPeriodShow := 10
MaxMessages := 5
MaxLengthMessage := 200


ShowMessages(addNew){
	global ListMessage
	global TimeLastShow
	global MaxMessages
	finalMsg := ""
	for k, msg in ListMessage{
		if (A_Index > 1)
			finalMsg .= "`n * * * `n"
		finalMsg .= msg
		if (A_Index > MaxMessages - 1)
			break
	}	
	ToolTip, %finalMsg%, 0, 0
	if (!addNew){
		ListMessage.RemoveAt(1)
	}
	TimeLastShow := A_TickCount
}

AddMessage(msg){
	if (msg="test"){
		AddMessage("убрать функцию телетекста/субтитров в отдельную функцию-файл, подключать его. Возvожо через класс, чтобы не пересекаться похожиvи названияvи`nПометки времени в логах")
		return false
	}
	global ListMessage
	global MaxLengthMessage
	global MaxMessages
	
	if (StrLen(msg) > MaxLengthMessage){
		msg := SubStr(msg, 1, MaxLengthMessage - 3)
		msg := msg . "..."
	}
	
	ListMessage.Push(msg)
	if (ListMessage.Count() <= MaxMessages)
		ShowMessages(true)
}

CleanMessageAndSetTimeout(newTime = -1)
{
	global ListMessage
	global TimeMilisecondPeriodShow
	ListMessage := []
	if (newTime > 0)
		TimeMilisecondPeriodShow := newTime
	ShowMessages(true)
}

CheckAndShowToolTip(){
	global TimeLastShow
	global TimeMilisecondPeriodShow
	checkTime := A_TickCount - TimeMilisecondPeriodShow	
	
	if (checkTime>TimeLastShow)
		ShowMessages(false)		
}
SetTimer, CheckAndShowToolTip, 1