#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance Force

SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include json.ahk

; ---------------
; Блок констант
; ---------------

; Ограничения для красивого вывода отладочной информации
MaxMessages := 5
MaxLengthMessage := 200

; ---------------
; Блок глобальных переменных
; ---------------

; Переменные для вывода отладочной информации во время работы скрипта
ListMessage := []
TimeLastShow := A_TickCount
TimeMilisecondPeriodShow := 10 ; Сколько минимально времени мы ждём перед тем как сдвинуть на следующее сообщение

; ---------------
; Блок самотладки скрипта
; ---------------

ListTestedFunc := []
ListTestedFunc.Push("CreateNotePrice")
ListTestedFunc.Push("AddMessage")

; Прогоняем наш скрипт через написанные функции, что они корректно работают
CheckAllFunc(){
	global ListTestedFunc
	for k, func in ListTestedFunc{
		; Если на тестовый запрос функция возвращает true - ничего не выводим
		if (%func%("test")){
		}else{
			; Подробности о не работе функции не выводим, только сам факт не работы функции
			AddMessage("Function " . func . " doesn't work")
		}
	}	
}

; Функция, показывающая накопленные сообщения
; Разделитель сообщения - новая строка со звёздочками
; addNew выставляется в true, если мы только что добавили сообщение
ShowMessages(addNew){
	global ListMessage
	global TimeLastShow
	global MaxMessages
	finalMsg := ""
	for k, msg in ListMessage{
		if (A_Index > 1)
			finalMsg .= "`n * * * `n" ; Добавляем разделитель
		finalMsg .= msg
		if (A_Index > MaxMessages - 1)
			break
	}	
	; Вывод на экран сообщения
	ToolTip, %finalMsg%, 0, 0
	if (!addNew){
		; Мы убираем первое сообщение по принципу очереди, если ничего не добавляли
		ListMessage.RemoveAt(1)
	}
	; Сбрасываем, когда мы в последний раз показывали сообщения
	TimeLastShow := A_TickCount
}

; Функция добавляет новое сообщение в пул сообщений, обрабатывая его по максимальной длине
AddMessage(msg){
	if (msg="test"){
		AddMessage("убрать функцию телетекста/субтитров в отдельную функцию-файл, подключать его. Возможо через класс, чтобы не пересекаться похожими названиями`nПометки времени в логах")
		return false
	}
	global ListMessage
	global MaxLengthMessage
	global MaxMessages
	
	; Обрезаем конец сообщения, если он слишком длинный
	if (StrLen(msg) > MaxLengthMessage){
		msg := SubStr(msg, 1, MaxLengthMessage - 3)
		msg := msg . "..."
	}
	
	ListMessage.Push(msg)
	if (ListMessage.Count() <= MaxMessages)
		; Вызываем показ только, если новое сообщение не за пределами уже показываемых сообщений. А то они никогда не сдвинутся.
		ShowMessages(true)
}

; Функция зачистки всего что было раньше в сообщениях
; И при необходимости - установка нового таймера
CleanMessageAndSetTimeout(newTime = -1)
{
	global ListMessage
	global TimeMilisecondPeriodShow
	ListMessage := []
	if (newTime > 0)
		TimeMilisecondPeriodShow := newTime
	; Вызываем показ сообщений с пустым списком сообщений и пометкой, что добавили новое, чтобы очистить то, что было на экране и сбросить таймер
	ShowMessages(true)
}

; Функция вывода сообщений с учётом времени последнего добавленного сообщения
CheckAndShowToolTip(){
	global TimeLastShow
	global TimeMilisecondPeriodShow
	checkTime := A_TickCount - TimeMilisecondPeriodShow	
	
	if (checkTime>TimeLastShow)
		ShowMessages(false)		
}
; Задаём таймер на вывод сообщений - каждую секунду
SetTimer, CheckAndShowToolTip, 1

; ----------------------------
; Блок щелчков мышкой, работы по координатам, специальная отправка клавиш
; ----------------------------

; Функция: выполняет серию кликов, пока цвет пикселя не изменится или таймаут не истечёт
; Применяем для открытия меню в окне примечаний в PoE
ClickUntilOpenNoteInput(clickX, clickY, checkX, checkY) {
	; Задаём изначальное время ожидания до открытия меню
	leftTime = 1000 
    ; Получаем исходный цвет пикселя
    PixelGetColor, beforeColor, %checkX%, %checkY%
    while (leftTime > 0) {
        Sleep, 140  ; короткая задержка перед кликом
        Click, %clickX%, %clickY%  ; клик в указанной позиции
        Sleep, 100  ; задержка после клика
        PixelGetColor, afterColor, %checkX%, %checkY%  ; проверяем цвет снова
        if (beforeColor = afterColor) {
            leftTime -= 240  ; уменьшаем оставшееся время ожидания
        } else {
            return true  ; цвет изменился — выходим из цикла
        }
    }
	return false ; мы так и не дождались изменения - что-то не так
}
; Посылаем серию нажатий клавиш, чтобы перелистнуть на поле с вводом строки
ChangeMenuToSimpleNote(){
	Send {Down}{Up}{Up}{Up}{Up}
	Sleep 100
	Send {Enter}
	Sleep 100
	Send {Home}
	Sleep 100
	Send +{End}
	Sleep 100
}

; ----------------------------
; Блок вычислений
; ----------------------------

; Рассчитываем какой текст должен быть на конце примечания, чтобы скрипт опознавал, что уже обрабатывал предмет
CurrentPostfix(){
	global CurrentLeague
	if (CurrentLeague = "Standard"){
		return SubStr(A_YWeek, -1) + 40
	}else{
		return A_DD
	}
}

; ----------------------------
; Блок конечных функций, которые можно вызывать самостоятельно
; ----------------------------

; Для предмета под курсором раскрываем меню и пишем в примечания переданный текст
CreateNotePrice(text){
	if (text="test")
	{
		AddMessage("Если попадаем не в левый нижний угол предмета, то менюшка не раскрывается.")
		AddMessage("Если работаем на мелкой сетке - идёт ошибка с попаданием")
		return false
	}
	MouseGetPos origX, origY
	Click, Rel 0, 0 Right
	
	; Готовим координаты, где мы будем пробовать открыть меню, 
	; и где мы будем проверять, что меню открыто
	
	; Если мы сделали щелчок близко к левому краю экрана - это надо учесть 
	; и сдвигаться не слишком сильно влево
	ClickX := origX<140 ? 40 : origX-100
	ClickY := origY+80
	; Проверять что цвет поменялся будем немного левее и ниже
	ClickXCheck := ClickX-10
	ClickYCheck := ClickY+20
		
	; Открываем меню предмета
	if (!ClickUntilOpenNoteInput(ClickX, ClickY, ClickXCheck, ClickYCheck))
	{
		AddMessage("Can't open set price" . text . " in clipboard")
		clipboard := text
		return	
	}	
	
	; Посылаем серию нажатий клавиш, чтобы перелистнуть на поле с вводом строки
	ChangeMenuToSimpleNote()
	; Пишем в поле примечаний заготовленный нами текст
	Send, %text%
	Sleep, 100
	Send {Enter}

	; Возвращаем мышку как было
	MouseMove,  origX, origY

	AddMessage("Complete!")
}

; ----------------------------
; Не разобранный код
; ----------------------------


CurrentLeague := "Standard"
CurrentLeague := "Mercenaries"
ListCurrencyOverview := ["Currency", "Fragment"]
ListItemOverview := ["Invitation", "Incubator", "Tattoo", "DivinationCard", "DeliriumOrb", "Scarab", "Fossil", "Oil", "Essence", "AllflameEmber", "Resonator", "Artifact", "Runegraft", "Omen"]
PoeNinjaAPIUrl := "https://poe.ninja/api/data/"
StablePriced := ["Currency", "Fragments", "Misc Map Items"]

StartDate := 20250614
NowAndDiff := A_Now
EnvSub, NowAndDiff, %StartDate%, Days
; baseMinPriceDefine := Max(10, NowAndDiff / 4)
; baseMinPriceDefine := Min(13, NowAndDiff / 3)
baseMinPriceDefine := NowAndDiff
; baseMinPriceDefine := 13
KalandraPrice := 100000 - 250* NowAndDiff
listPriceChaos := [baseMinPriceDefine, baseMinPriceDefine * (SQRT(5)+1) / 2]
listPriceExalted := [1, 1.2, 1.5, 1.7]
listFibb := [1, 1, 2]

Loop, 40
{
	lengthFib := listPriceChaos.Length()
	newFib := listPriceChaos[lengthFib] + listPriceChaos[lengthFib-1]
	listPriceChaos.Push(newFib)
	lengthFib := listPriceExalted.Length()
	newFib := listPriceExalted[lengthFib-3] + listPriceExalted[lengthFib-1]
	listPriceExalted.Push(newFib)
	
	lengthFib := listFibb.Length()
	newFib := listFibb[lengthFib] + listFibb[lengthFib-1]
	listFibb.Push(newFib)
	listFibb.Push(newFib + listFibb[lengthFib])
}

PoeNinjaJSONUrl := []
For keyCurrency, typeCurrency in ListCurrencyOverview
	PoeNinjaJSONUrl.Push(PoeNinjaAPIUrl . "CurrencyOverview?league=" . CurrentLeague . "&type=" . typeCurrency)
For keyCurrency, typeCurrency in ListItemOverview
	PoeNinjaJSONUrl.Push(PoeNinjaAPIUrl . "itemoverview?league=" . CurrentLeague . "&type=" . typeCurrency)

MinChaosProfit := false
MaxChaos := false
MaxExalt := false
; CapitalChaos := 40
CapitalChaos := 150 * 32
ExaltPrice := false

DefaultBuyShift := -0.25
; DefaultBuyShift := -0.15
; DefaultBuyShift := -0.1
; DefaultBuyShift := -0.05
DefaultSellShift := 0.1
; DefaultSellShift := 0.01

NameDBFile := "db.json"

ListThingCurrency := []
ListCurrencyWithBestRatio := []
MaxCurrencyInBest := 12 * 12 * 3

numChaos := 40
sellPriceGlobalChaos := ""

HighBorder := 100000
MidBorder := 10000
LowBorder := 100

summMassBuy := {currency: 0, noCurrency: 0, equipItem: 0, tradeBuy: 0}
discountBuyCurrency := 0.8
discountBuyNoCurrency := 0.8
discountBuyEquip := 0.3

wasCenter := false

debuggingMessage := []

ListTestedFunc.Push("DebugVariableTest")
DebugVariable(params*){
	strMessage := ""
	For index, variable in params
	{
		if (A_Index > 1)
			strMessage .= "`n"
		strMessage .= "NameVar:" . variable
	}
	AddMessage(strMessage)
}
DebugVariableTest(msg){
	if (msg="test"){
		AddMessage("Эта функция берёт все аргументы и добавляет их в сообщение по красивому")
		return false
	}
}

ListTestedFunc.Push("CreateNotePrice")
GetInfoFromClipboard(text){
	if (text="test")
	{
		AddMessage("Что здесь может сломаться?")
		return false
	}
	name =
	rarity =
	typeName =
	last =
	count =
	caption =
	note =
	skip =
	level =
	quality =
	corrupted =
	negotiablePrice =
	exactPrice =
	sockets =
	simpleHash =
	tiers := []
	Loop, parse, text, `n, `r
	{		
		if (A_Index = 1)
		{
			caption = %A_LoopField%
		}
		if (A_Index = 2)
		{
			rarity := SubStr(A_LoopField, 9)
		}
		if (A_Index = 3)
		{
			name = %A_LoopField%
		}
		if (A_Index = 4)
		{
			typeName = %A_LoopField%
		}
		if (A_Index = 5)
		{
			stack:= StrReplace(A_LoopField, " ")
			if (RegExMatch(stack, "O)Stack Size: ([\d\.]*)/([\d\.]*)", SubPart) > 0)
			{
				count := SubPart.Value(1)
			}else{
				count:= 1
			}
		}
		
		if (rarity = "Gem")
		{
			if (level = "")
				if (RegExMatch(A_LoopField, "O)Level: (\d\d?)", SubPart)>0)
				{
					level := SubPart.Value(1)
				}
			if (quality = "")
				if (RegExMatch(A_LoopField, "O)Quality: \+(\d\d?)%", SubPart)>0)
				{
					quality := SubPart.Value(1)
				}
		}else{
			if (level = "")
				if (RegExMatch(A_LoopField, "O)Item Level: (\d\d?\d?)", SubPart)>0)
				{
					level := SubPart.Value(1)
				}
		}
		
		if (RegExMatch(last, "O)Sockets:(.*)", SubPart)>0){
			sockets := SubPart.Value(1)
		}
		
		if (RegExMatch(last, "O)\(Tier: (\d*)\)", SubPart)>0){
			tiers.Push(SubPart.Value(1))
		}
		if (RegExMatch(last, "O)\(Уровень: (\d*)\)", SubPart)>0){
			tiers.Push(SubPart.Value(1))
		}
		
		if (A_LoopField = "Corrupted")
			corrupted := "Corrupted"
		
		if (A_LoopField != "")
			last = %A_LoopField%
	}
	if (RegExMatch(last, "Note:")>0)
	{
		note := SubStr(last, 7)
		if (RegExMatch(note, "~b/o")>0)
			negotiablePrice := SubStr(note, 6)
		if (RegExMatch(note, "~price")>0)
			exactPrice := SubStr(note, 8)
	}
	if (RegExMatch(last, "Примечание:")>0)
	{
		note := SubStr(last, 13)
		if (RegExMatch(note, "~b/o")>0)
			negotiablePrice := SubStr(note, 6)
		if (RegExMatch(note, "~price")>0)
			exactPrice := SubStr(note, 8)
	}
		
	
	return {name: name, typeName: typeName, price: SubStr(note, 7), count: count, caption: caption, text:text, rarity:rarity, level:level, quality:quality, corrupted:corrupted, skip:skip, negotiablePrice:negotiablePrice, exactPrice:exactPrice, note:note, sockets:sockets, tiers:tiers, simpleHash: SimpleHash(text)}
}





; Function return integer fraction near target
GetFrac(target, bottomLimit, minNumerator, minDenominator, maxNumerator, maxDenominator, stepNumerator, stepDenominator){
	if (minDenominator<1)
		minDenominator := 1
	if (minNumerator<1)
		minNumerator := 1
	if (bottomLimit){
		minDenominatorByLimit := minNumerator / target
		minDenominator := Max(minDenominator, minDenominatorByLimit)
	}else{
		maxDenominatorByLimit := maxNumerator / target
		maxDenominator := Min(maxDenominator, maxDenominatorByLimit)
	}
	idealNumerator := 0
	idealDenominator := 0
	idealFraction := false
	; AddMessage("target:" . target . "`n minNumerator:" . minNumerator . "`n maxNumerator:" . maxNumerator . "`n minNumerator:" . minDenominator . "`n maxDenominator:" . maxDenominator)
	Loop, %maxDenominator%
	{
		currentDenominator := (A_Index) * stepDenominator
		; AddMessage("A_Index:" . A_Index . "`nDen:" . currentDenominator)
		if (currentDenominator < minDenominator)
			continue
		if (currentDenominator > maxDenominator)
			break
			
		; Becouse currentNumerator*currentDenominator = target
		; But we want integer in Numerator - round(?/step)*step
		currentNumeratorFrac := target * currentDenominator / stepNumerator
		if (bottomLimit){
			currentNumerator :=	Floor(currentNumeratorFrac) * stepNumerator
		}else{
			currentNumerator :=	Ceil(currentNumeratorFrac) * stepNumerator
		}
		; AddMessage("currentNumeratorFrac:" . currentNumeratorFrac . "`ncurrentNumerator:" . currentNumerator)
		if (currentNumerator < minNumerator)
			continue
		if (currentNumerator > maxNumerator)
			break
		currentFraction := currentNumerator / currentDenominator	

		; If we found fraction which far previous - skip that iteration
		if (idealFraction != false){
			if (bottomLimit && (currentFraction <= idealFraction))
				continue
			if (!bottomLimit && (currentFraction >= idealFraction))
				continue
		}
		idealNumerator := currentNumerator
		idealDenominator := currentDenominator
		idealFraction := currentFraction
	}
	; MsgBox, Stop this
	if (idealFraction = false)
		return false
	return {Numerator:idealNumerator, Denominator:idealDenominator}
}
ListTestedFunc.Push("GetFracTest")
GetFracTest(target){
	if (target!="test")
		return 0
	; ;AddMessage("Remove this RETURN")
	; return 0
	testFrac1 := GetFrac(0.314, true, 0, 0, 10, 10, 1, 1)		
	if ((testFrac1.Numerator != 3) || (testFrac1.Denominator != 10)){
		AddMessage("GetFrac in testFrac1 return " . testFrac1.Numerator . "/" . testFrac1.Denominator . " instead 3/10" )
		return false
	}
	testFrac2 := GetFrac(0.314, false, 0, 0, 10, 10, 1, 1)	
	if ((testFrac2.Numerator != 1) || (testFrac2.Denominator != 3)){
		AddMessage("GetFrac in testFrac2 return " . testFrac2.Numerator . "/" . testFrac2.Denominator . " instead 1/3")
		return false
	}
	testFrac3 := GetFrac(11, false, 0, 0, 10, 10, 1, 1)	
	if (!!testFrac3){
		AddMessage("GetFrac in testFrac3 return " . testFrac3.Numerator . "/" . testFrac3.Denominator . " instead false")
		return false
	}
	testFrac4 := GetFrac(229.136, true, 1, 1, 100, 40, 1, 10)
	if (!!testFrac4){
		AddMessage("GetFrac in testFrac4 return " . testFrac4.Numerator . "/" . testFrac4.Denominator . " with " . testFrac4)	
		return false
	}
	testFrac5 := GetFrac(1/6.632000, false, 1, 1, 185.583818, 600, 1, 10)
	if ((testFrac5.Numerator != 89) || (testFrac5.Denominator != 590)){
		AddMessage("GetFrac in testFrac2 return " . testFrac5.Numerator . "/" . testFrac5.Denominator . " instead 89/590")
		return false
	}
	; 0,15078407720144752714113389626055
	return true
}

GetCurrentItemAtCursor(){
	clipboard := ""
	Send ^!c
	; Send ^c
	ClipWait, 0.12
	if ErrorLevel
	{
		; AddMessage("Can't define. Return from function")
		return ""
	}
	return clipboard
}


ListTestedFunc.Push("LoadDataFromFileTest")
LoadDataFromFile()
{
	global NameDBFile
	global ListThingCurrency
	if (!FileExist(NameDBFile))
		return
	dbFile	:=	FileOpen(NameDBFile, "r")
	dbFileText	:=	dbFile.Read()
	dbJSON	:=	JSON.Load(dbFileText)
	ListThingCurrency := dbJSON["Thing"]
}
LoadDataFromFileTest(msg){
	; AddMessage("Поискать файл, если найдётся - забрать данные оттуда. JSON и положить в оперативную память.")
	if (msg="test")
		return true
}

GetStackSize(name, cData)
{
	global ListThingCurrency		
	itemClass := cData["itemClass"]
	
	if (cData.HasKey("stackSize")){
		if (cData["stackSize"] != "")
			return cData["stackSize"]
	}
	if (ListThingCurrency.HasKey(name))
	{
		tempStack := ""
		elementThing := ListThingCurrency[name]
		if (elementThing.HasKey("stackSize"))
			tempStack := elementThing["stackSize"]
		if (tempStack != "")
			return tempStack
	}
				
	if (itemClass = 6)
		return 1
	if (RegExMatch(name, "Scouting Report|Eldritch Orb of Annulment")>0)
		return 20
	if (RegExMatch(name, "Exalted Orb|Fragment of | Catalyst| Oil|Blessing of |Splinter of|Sacrifice at |Eldritch| Crest|Mortal")>0)
		return 10
	if (RegExMatch(name, " Breachstone|Emblem|Goddess|Invitation| Lure")>0) ; 
		return 1
	if (RegExMatch(name, "Splinter|Shard")>0)
		return 100
	if (RegExMatch(name, "Armourer's Scrap|Orb of Regret|Orb of Transmutation|Orb of Unmaking|Scroll")>0)
		return 40				
	if (RegExMatch(name, "Orb of Augmentation|Orb of Scouring")>0)
		return 30				
	if (RegExMatch(name, "Ancient Orb|Blacksmith's Whetstone|Blessed Orb|Cartographer's Chisel|Chromatic Orb|Engineer's Orb|Gemcutter's Prism|Glassblower's Bauble|Harbinger's Orb|Jeweller's Orb|Orb of Alteration|Orb of Annulment|Orb of Binding|Orb of Horizons|Orb of Fusing|Power Core")>0)
		return 20				
	if (RegExMatch(name, "Awakened Sextant|Divine Orb|Charged Compas|Elevated Sextant|Enkindling Orb|Instilling Orb|Orb of Alchemy|Orb of Chance|Regal Orb|Ritual Vessel|Stacked Deck|Surveyor's Compass|Tainted Blessing|Vaal Orb|Veiled Chaos Orb| Recombinator")>0)
		return 10 ; |Prime Sextant | Scarab| Incubator
	if (RegExMatch(name, "Divine Vessel|Simulacrum|The Maven's Writ")>0)
		return 1
	; FAKE!
	if (RegExMatch(name, "Awakener's Orb|Maven's Orb|Mirror of Kalandra|Oil Extractor|Orb of Conflict|Orb of Dominance|Prime Regrading Lens|Sacred Orb|Secondary Regrading Lens|Tailoring Orb|Tempering Orb")>0)
		return 1 ; |Kalguuran Delirium Orb
	AddMessage("Для " . name . " не удалось получить стаки")
	return 10
}

GetTradeID(name, data, currencyDetails)
{
	global ListThingCurrency
	if (ListThingCurrency.HasKey(name))
	{
		if (name = "Exceptional Eldritch Ichor")
		{
		
			; CleanMessageAndSetTimeout(2300)
			; MsgBox, Wait
			; AddMessage(ListThingCurrency[name])
			; AddMessage(name)
			elementThing := ListThingCurrency[name]
			; AddMessage(data["detailsId"])
			; AddMessage(elementThing["detailsId"])
		}
		tempID := ""
		elementThing := ListThingCurrency[name]
		if (elementThing.HasKey("detailsId"))
			tempID := elementThing["detailsId"]
		if (tempID != "")
			return tempID
	}	
	
	For currency2, cData2 in currencyDetails
	{
		if (name = cData2.name)
		{
			if (cData2.HasKey("tradeId"))
				return cData2["tradeId"]
		}
	}			
	return data["detailsId"]
}

GetBuyPrice(data)
{
	if (data.pay.pay_currency_id = 1)
		return data.pay.value
	if (data.pay.value > 0)
		return 1/data.pay.value
	return ""
}
GetSellPrice(data)
{
	if (data.receive.pay_currency_id = 1)
		return data.receive.value
	if (data.receive.value > 0)
		return 1/data.receive.value
	return ""
}

ListTestedFunc.Push("AddFromUrlJSON")
AddFromUrlJSON(js)
{
	global ListThingCurrency	
	global DefaultBuyShift	
	global DefaultSellShift
	if (js="test"){
		AddMessage("Очень большая функция, надо делить. И чтобы всё было подвижное")
		AddMessage("Не все параметры наследуются или используются?")
		return false
	}
	For currency, cData in js.lines {
		name := cData.currencyTypeName
		if (name = "")
			name := cData.name
					
		; if (RegExMatch(name, "Silver Coin")>0)
			; continue
		
		tradeID := GetTradeID(name, cData, js.currencyDetails)
		stackSize := GetStackSize(name, cData)
			
		centerPrice := cData.chaosEquivalent
		if (centerPrice = "")
			centerPrice := cData.chaosValue
		
		buyTradePrice := GetBuyPrice(cData)
		sellTradePrice := GetSellPrice(cData)
			
		if (ListThingCurrency.HasKey(name)){
			elementThing := ListThingCurrency[name]
				maxCountBuy := min(elementThing["maxCountBuy"], stackSize)
			if (cData["itemClass"] = 6){
			}else{
				maxCountBuy:= elementThing["maxCountBuy"]
			}
			maxCountSell := elementThing["maxCountSell"]
		}else{
			maxCountBuy := -1
			maxCountSell := -1
		}
		
		ListThingCurrency[name] := {name:name, tradeID:tradeId, stackSize: stackSize, shiftBuy:DefaultBuyShift, shiftSell:DefaultSellShift, maxCountBuy: maxCountBuy, maxCountSell: maxCountSell, centerPrice: centerPrice, buyTradePrice:buyTradePrice, sellTradePrice:sellTradePrice}
		
		; AddMessage("Temporary return - remove after debug")
		;  return 
	}
}

ListTestedFunc.Push("LoadDataFromUrlTest")
; Эта штука должна быть во всех моих функциях до продакшена.
LoadDataFromUrl()
{
	global PoeNinjaJSONUrl
	tempFile := "temp.json"
	For index, value in PoeNinjaJSONUrl
	{
		FileDelete %tempFile% 
		UrlDownloadToFile, %value%, %TempFile%
		if ErrorLevel
		{
		}
		else
		{
			FC := FileOpen(tempFile, "r")
			Price := FC.Read()
			parsedJSON := JSON.Load(Price)
			AddFromUrlJSON(parsedJSON)
		}
	}
}
LoadDataFromUrlTest(msg){
	; AddMessage("Эта штука должна перебирать файловые записи и добавлять те, котрых нет и цены закупки/продажи")
	if (msg="test")
		return true
}
UpdateCurrencyPrice(frac, idTrade, nameParam, currencyData)
{
	if (!frac){
		textPrice := "~skip"
	}else{
		textPrice := "~price " . frac["Numerator"] . "/" . frac["Denominator"] . " " . idTrade
	}
	currencyData[nameParam] := textPrice
	return currencyData
}

UpdateOneDateInMemory(name, currency)
{
	global MinChaosProfit
	global MaxExalt
	global MaxChaos
	global ExaltPrice
	global HighBorder
	global MidBorder
	global LowBorder
	global defaultBuyShift
	
	if (currency["buyTradePrice"] > 0){
		MyPriceBuy := Min(currency["buyTradePrice"], currency["centerPrice"]*(1+currency["shiftBuy"]))
	}else{
		MyPriceBuy := currency["centerPrice"]*(1+currency["shiftBuy"])		
	}
	MyPriceBuyExalt := MyPriceBuy / ExaltPrice
	currency["MyPriceBuy"] := MyPriceBuy
	currency["MyPriceBuyExalt"] := MyPriceBuyExalt
	if (currency["sellTradePrice"] > 0){
		MyPriceSell := Max(currency["sellTradePrice"], currency["centerPrice"]*(1+currency["shiftSell"]))
	}else{
		MyPriceSell := currency["centerPrice"]*(1+currency["shiftSell"])		
	}
	if (currency["centerPrice"] > ExaltPrice){
		MyPriceSellExalt := MyPriceSell / ExaltPrice		
	}else{		
		MyPriceSellExalt := MyPriceSell / (ExaltPrice * (1 + defaultBuyShift) )
	}
	currency["MyPriceSellExalt"] := MyPriceSellExalt
	currency["MyPriceSell"] := MyPriceSell
	MinCountCurrency := MinChaosProfit / (MyPriceSell - MyPriceBuy)
	currency["MinCountCurrency"] := MinCountCurrency
	
	MaxCountByMyChaos := MaxExalt * ExaltPrice / MyPriceBuy
	
	
	if (currency["MaxCountBuy"] = -1)
	{
		if (currency["centerPrice"] >= HighBorder)
		{
			currency["MaxCountBuy"] := 1
		} else if (currency["centerPrice"] >= MidBorder)
		{
			currency["MaxCountBuy"] := currency["stackSize"] * 1
		} else if (currency["centerPrice"] >= LowBorder)
		{
			currency["MaxCountBuy"] := currency["stackSize"] * 5
		} else {
			currency["MaxCountBuy"] := currency["stackSize"] * 20
		}
	}
	if (currency["MaxCountSell"] = -1)
		currency["MaxCountSell"] := Ceil(currency["MaxCountBuy"]*1.3)
	
	
	MaxBuy:=Min(MaxCountByMyChaos , currency["MaxCountBuy"])
	currency["MaxBuy"] := MaxBuy
	
	
	BuyFrac := GetFrac(1/MyPriceBuy, false, MinCountCurrency, 1, MaxBuy, MaxChaos, 1, 20)
	BuyFrac := GetFrac(1/MyPriceBuy, false, MinCountCurrency, 1, MaxBuy, MaxChaos, 1, 1)
	; AddMessage("Это должно быть всегда доступно?")
	BuyFracExalt := GetFrac(1/MyPriceBuyExalt, false, 1, 1, MaxBuy, MaxExalt, 1, 1) ;Exalt i can divine by 1
	SellFrac := GetFrac(MyPriceSell, false, 1, MinCountCurrency, Min(1200, MaxChaos), currency["maxCountSell"], 1, currency["stackSize"]) ; 1200-max Chaos in inventory
	SellFrac := GetFrac(MyPriceSell, false, 1, MinCountCurrency, Min(1200, MaxChaos), currency["maxCountSell"], 1, 1) ; 1200-max Chaos in inventory
	; AddMessage("`n MyPriceBuy:" . MyPriceSell . "`n currency[""maxSell""]:" . currency["maxSell"] . "`n MaxChaos:" . 1200 . "`n currency[""stackSize""]:" . currency["stackSize"])
	SellFracExalt := GetFrac(MyPriceSellExalt, false, 1, MinCountCurrency, Min(1200, MaxExalt), currency["maxCountSell"], 1, 1) ; 1200-max Exalt in inventory
	; MyPriceSellExalt
	; nbf := !BuyFrac
	; nsf := !SellFrac
	; AddMessage("`n BuyFrac:" . BuyFrac . " -> " . nbf . "`n SellFrac:" . SellFrac . " -> " . nsf)
	; AddMessage("`n BuyFrac:" . BuyFrac . "`n SellFrac:" . SellFrac )
	; AddMessage("`n nbf:" . nbf . "`n nsf:" . nsf )
			
	currency:=UpdateCurrencyPrice(BuyFrac, currency["tradeID"], "PriceBuyTextChaos", currency)
	currency:=UpdateCurrencyPrice(SellFrac, "chaos", "PriceSellTextChaos", currency)
	currency:=UpdateCurrencyPrice(BuyFracExalt, currency["tradeID"], "PriceBuyTextExalt", currency)
	; PriceBuyTextChaos := "~price " . BuyFrac["Numerator"] . "/" . BuyFrac["Denominator"] . " " . currency["tradeID"]
	; if (!BuyFrac)
		; PriceBuyTextChaos := "~skip"
	; currency["PriceBuyTextChaos"] := PriceBuyTextChaos
	; PriceSellTextChaos := "~price " . SellFrac["Numerator"] . "/" . SellFrac["Denominator"] . " chaos"
	; currency["PriceSellTextChaos"] := PriceSellTextChaos
	; PriceBuyTextExalt := "~price " . BuyFracExalt["Numerator"] . "/" . BuyFracExalt["Denominator"] . " " . currency["tradeID"]
	; currency["PriceBuyTextExalt"] := PriceBuyTextExalt
	if (currency["centerPrice"] < ExaltPrice*(1 + defaultBuyShift))
	{
		PriceSellTextExalt := "~price " . SellFracExalt["Numerator"] . "/" . SellFracExalt["Denominator"] . " divine"
	}else{
		PriceSellTextExalt := "~price " . Round(Ceil(MyPriceSellExalt*10)/10, 1) . " divine"
	}
	currency["PriceSellTextExalt"] := PriceSellTextExalt
	
	if ((!BuyFrac) || (!SellFrac)){
		currency["ProffitAVG"] := "0.00001"
		currency["ClickCountOnChaos"] := "10000"
		return currency
					
	}
	
	ClicksCount := 0
	ClicksCount := ClicksCount + Ceil(BuyFrac["Numerator"] / currency["stackSize"]) 
	ClicksCount := ClicksCount + 2 * Ceil(BuyFrac["Denominator"] / 10) 
	; if (Ceil(BuyFrac.Denominator / 10) != Floor(BuyFrac.Denominator / 10))
	;	ClicksCount := ClicksCount + 3 ; Это для Shift действия
	; Здесь речь про полные стаки - поэтому такой блок уже не нужен
	ClicksCount := ClicksCount + Ceil(SellFrac["Numerator"] / 10) 
	ClicksCount := ClicksCount + 2 * Ceil(SellFrac["Denominator"] / currency["stackSize"]) 
			
	; BUY: a vaal / b chaos 
	; SELL c vaal / d chaos
	; Proffit: c - bd/a
	; Proffit: ca/d - b
	; ProffitAVG := (acd - bdd + caa - bad) / 2ad = (ac(a+d)-bd(a+d))/2ad = (ac-bd)(a+d)/2ad
	ProffitAVG := (BuyFrac["Numerator"] * SellFrac["Numerator"] - BuyFrac["Denominator"] * SellFrac["Denominator"]) * (BuyFrac["Numerator"] + SellFrac["Denominator"]) / (2 * BuyFrac["Numerator"] * SellFrac["Denominator"])
	currency["ProffitAVG"] := ProffitAVG	
	
	ClickCountOnChaos := ClicksCount / ProffitAVG		
	currency["ClickCountOnChaos"] := ClickCountOnChaos		
		
	return currency
}

ListTestedFunc.Push("UpdateDataInMemoryTest")
; Эта штука должна быть во всех моих функциях до продакшена.
UpdateDataInMemory()
{
	global ExaltPrice
	global KalandraPrice
	global ListThingCurrency
	global MinChaosProfit
	global MaxChaos
	global CapitalChaos
	global MaxExalt
	global listPriceChaos
	global listPriceExalted
	global HighBorder
	global MidBorder
	global LowBorder
	
	ExaltedOrb := ListThingCurrency["Divine Orb"]
	ExaltPrice := ExaltedOrb["centerPrice"]
	MaxExalt := Min(1200, Sqrt(CapitalChaos / ExaltPrice))
	MaxChaos := Min(1200, MaxExalt * ExaltPrice)
	MinChaosProfit := Max(listPriceChaos[1] - 1, Ln(MaxExalt + 1.001))
	
	global debuggingMessage
	debuggingMessage.Push("ExaltPrice: " . ExaltPrice)
	debuggingMessage.Push("MaxExalt: " . MaxExalt)
	debuggingMessage.Push("MaxChaos: " . MaxChaos)
	debuggingMessage.Push("MinChaosProfit: " . MinChaosProfit)
	debuggingMessage.Push("KalandraPrice: " . KalandraPrice)
	debuggingMessage.Push("listPriceChaos[1]: " . listPriceChaos[1])
	
	ChaosMax := listPriceExalted[2] * ExaltPrice
	Loop
	{
		checkChaosPrice := listPriceChaos.Pop()
		if (checkChaosPrice < ChaosMax)
		{
			listPriceChaos.Push(checkChaosPrice)
			break			
		}
	}
	Loop
	{
		if (listPriceChaos.Length()<3)
			break
		if (listPriceChaos[1] < MinChaosProfit){
			listPriceChaos.RemoveAt(1)
		}else{
			break
		}
	}
	
	;AddMessage("`n ExaltPrice:" . ExaltPrice . "`n MaxExalt:" . MaxExalt . "`n MaxChaos:" . MaxChaos . "`n MinChaosProfit:" . MinChaosProfit . "`n CapitalChaos:" . CapitalChaos)
	
	ListSortedByPrice := []	
	For name, currency in ListThingCurrency
	{		
		checkingPrice := currency["centerPrice"]
		sizeL := ListSortedByPrice.Length()
		posInsert := sizeL + 1
		Loop, %sizeL%
		{
			if (ListSortedByPrice[A_Index] < checkingPrice)
			{
				posInsert := A_Index
				break
			}
		}
		ListSortedByPrice.InsertAt(posInsert, checkingPrice)
	}
	sizeL := ListSortedByPrice.Length()
	HighBorder := ListSortedByPrice[Ceil(1 * sizeL / 11)]
	MidBorder := ListSortedByPrice[Ceil((1 + 2) * sizeL / 11)]
	LowBorder := ListSortedByPrice[Ceil((1 + 2 + 3) * sizeL / 11)]
	global debuggingMessage
	debuggingMessage.Push("Price Borders")
	debuggingMessage.Push("sizeL: " . sizeL)
	debuggingMessage.Push("LowBorder: " . LowBorder)
	debuggingMessage.Push("MidBorder: " . MidBorder)
	debuggingMessage.Push("HighBorder: " . HighBorder)
	
	For name, currency in ListThingCurrency
	{		
		ListThingCurrency[name] := UpdateOneDateInMemory(name, currency)
	}
	
; TemplateObject := {}

}
UpdateDataInMemoryTest(msg){
	AddMessage("Сравнить цены, выставить, рассчитать все данные")
	AddMessage("Цен в вышках пока нет - нужны")
	AddMessage("Не учтённые, не обработанные: minBuyPrice:0.01, maxBuyPrice:0.2, minSellPrice: 0.15, maxSellPrice: 0.5, priceSellChaos: priceSellExalt priceSellExaltFrac  priceSellExaltBig , priceBuyExalt: clickCountOnChaosBig:15")
	if (msg="test")
		return false
}


ListTestedFunc.Push("SaveDataToFileTest")
SaveDataToFile()
{
	global NameDBFile
	global ListThingCurrency
	JSONObj	:=	{Thing:ListThingCurrency}
	JSONText := JSON.Dump(JSONObj)
	FileDelete %NameDBFile%
	FileAppend, %JSONText%, %NameDBFile%	
}
SaveDataToFileTest(msg){
	AddMessage("И просто сохранить всё, что насчитал")
	if (msg="test")
		return false
}


ListTestedFunc.Push("GetListBestTradeTest")
; Эта штука должна быть во всех моих функциях до продакшена.
GetListBestTrade(){
	global ListCurrencyWithBestRatio
	global MaxCurrencyInBest
	global ListThingCurrency
	
	; AddMessage("GOTCHA")
	
	ListCurrencyWithBestRatio := []
	For name, currency in ListThingCurrency
	{
		if (currency["tradeID"] = "")
			continue
		; AddMessage("GOTCHA inner")
		checkingRatio := currency["ClickCountOnChaos"]
		posInsert := MaxCurrencyInBest + 1
		Loop, %MaxCurrencyInBest%
		{
			; AddMessage("GOTCHA inner inner")
			if (A_Index>ListCurrencyWithBestRatio.Count())
			{
				posInsert := A_Index
				break
			}
			currencyInArray := ListThingCurrency[ListCurrencyWithBestRatio[A_Index]]
			if (currencyInArray["ClickCountOnChaos"]>checkingRatio)
			{
				posInsert := A_Index
				break
			}
		}
		if (posInsert > MaxCurrencyInBest)
			continue
		; AddMessage(posInsert . "/" . ListCurrencyWithBestRatio.Count())
		ListCurrencyWithBestRatio.InsertAt(posInsert, name)
		if (ListCurrencyWithBestRatio.Count() > MaxCurrencyInBest)
			ListCurrencyWithBestRatio.RemoveAt(MaxCurrencyInBest + 1)
	}
}
GetListBestTradeTest(msg){
	AddMessage("Надо добавить функционал, который  позволит менять на лету границу покупки/продажи")
	if (msg="test")
		return false
}

MinLeftX := 16 ;20
MaxRightX := 650 ;590
MinTopY := 129 ;140
MaxBottomY := 760 ;710
DiffX := (MaxRightX - MinLeftX) / 12
DiffY := (MaxBottomY - MinTopY) / 12
AlreadySetDictionary := {}
AlreadySetDictionaryChaos := {}
AlreadySetDictionaryExalt := {}

MoveNextCell(bigStash)
{
	global MinLeftX
	global MaxRightX
	global MinTopY
	global MaxBottomY
	global DiffX
	global DiffY
	
	if (bigStash == ""){
		bigStash := false
	}
	
	MouseGetPos, ttx, tty
	; AddMessage(ttx . "`n" . tty)
	ttx := ttx + (bigStash ? DiffX / 2 :DiffX)
	; if (ttx < MinLeftX)
		; ttx := MinLeftX + DiffX / 2
	; if (tty > MaxBottomY)
		; tty := MaxBottomY - DiffY / 2
	if (ttx > MaxRightX)
	{
		ttx := MinLeftX + (bigStash ? DiffX / 2 :DiffX) / 2
		tty := tty - (bigStash ? DiffY / 2 :DiffY)				
	}
	if (tty < MinTopY)
	{
		; ttx := MinLeftX + DiffX / 2
		tty := MaxBottomY - (bigStash ? DiffY / 2 :DiffY)/2			
		MouseMove,  ttx, tty
		AddMessage("Check all items - return at start")
	
		return false
	}	
	; AddMessage(ttx . "`n" . tty)
	MouseMove,  ttx, tty
	return true
}

CenterMouse(){
	global MinLeftX
	global MaxRightX
	global MinTopY
	global MaxBottomY
	global DiffX
	global DiffY
	global wasCenter
	if (!wasCenter) 
		return
	MouseGetPos, ttx, tty
	dx := Floor((ttx - MinLeftX) / DiffX) * DiffX + MinLeftX + DiffX/2
	ttx := Min(MaxRightX - DiffX/2, Max(MinLeftX + DiffX/2, dx))
	dy := MaxBottomY - Floor((MaxBottomY - tty) / DiffY) * DiffY - DiffY/2	
	tty := Min(MaxBottomY - DiffY/2, Max(MinTopY + DiffY/2, dy))	
	MouseMove,  ttx, tty
}

ListTestedFunc.Push("SearchNextItemTest")
; Эта штука должна быть во всех моих функциях до продакшена.
SearchNextItem(){	
	global AlreadySetDictionary		
	
	if (!WinActive("Path of Exile"))
		return false
	CenterMouse()
	
	Loop
	{
		if (!WinActive("Path of Exile"))
			return false
		; if (!MoveNextCell(false))
			; return false
		
		readItem := GetCurrentItemAtCursor()
		if (readItem == "")	
			; continue
			if (!MoveNextCell(false))
			{
				return false
			}else{
				continue
			}
		infoCur := GetInfoFromClipboard(readItem)	
		nameCur := infoCur.name
		if (nameCur = "Chaos Orb")
			return true
		if (nameCur = "Exalted Orb")
		{
			AddMessage("Skip set price on Exalt")
			; continue
			if (!MoveNextCell(false))
				return false
		}
		
		if (AlreadySetDictionary.HasKey(nameCur))
			; continue
			if (!MoveNextCell(false))
				return false	
		return true
	}
	
}
SearchNextItemTest(msg){
	if (msg="test")
		return false
}
GetNewPriceRare(infoCur)
{
	global ExaltPrice
	global KalandraPrice
	global ListLeftUniques
	if (infoCur.rarity = "Unique")
	{		
		AddMessage("Check Name " . infoCur.name)
		; ListLeftUniques
		
		SizeLoop := ListLeftUniques.Length()
		Loop %SizeLoop%
		{
			if (ListLeftUniques[A_Index] == infoCur.Name)
			{
				; AddMessage("Save For STD! Write ~skip STD")
				return "~skip STD"
			}
		}
			
		AddMessage("Don't define price for unique item this method")
		return 0
	}
	
	countLink := 0.0
	textSockets := infoCur.sockets
	Loop, parse, textSockets, -
	{
		countLink++
	}
	
	ShowMessage := ""
	ShowMessage .= "`nName: " . infoCur.name
		
	arrTiers := infoCur.tiers
	showTiers := "Tiers: "	
	
	
	summaryLinks := Max(0.0, countLink-4) ;0-3
	summaryLinks /= 6
	
	summaryLevels := 0 ;? 75-83-84-85-86 0-3
	if (infoCur.level >= 83)
		summaryLevels += 0.5
	if (infoCur.level >= 84)
		summaryLevels += 0.5
	if (infoCur.level >= 85)
		summaryLevels += 0.5
	if (infoCur.level >= 86)
		summaryLevels += 0.5
	summaryLevels /= 8
	
	summaryTier := 0 ;0-6
	For keyTiers, valueTiers in arrTiers
	{
		showTiers .= valueTiers . " "
		summaryTier += 1/(valueTiers ** 1.5)
	}	
	summaryTier /= 6
	
	showTiers .= "-> " . summaryTier
	
	
	ShowMessage .= "`nSockets: " . infoCur.sockets . " -> " . countLink . "->" . summaryLinks
	ShowMessage .= "`n" . showTiers
	ShowMessage .= "`nLevel: " . infoCur.level . " -> " . summaryLevels
		
	summaryPrice := Max(summaryTier, summaryLinks, summaryLevels)
	firstPrice := SQRT(KalandraPrice) ** (summaryPrice)
	firstPrice := (KalandraPrice) ** (summaryPrice)
	
	ShowMessage .= "`nTestPrice = " . firstPrice
	AddMessage(ShowMessage)
	
	return Floor(firstPrice)
	
}

CheckNameAndTypeName(infoCur, needle){
	if (RegExMatch(infoCur.typeName, needle)>0)
		return true		
	if (RegExMatch(infoCur.name, needle)>0)
		return true
	return false
}
GetNewPriceSentinel(infoCur)
{
	global listFibb
	countUpPrice := 3
	if (CheckNameAndTypeName(infoCur, "Ancient Apex Sentinel"))
		return 70
	if (CheckNameAndTypeName(infoCur, "Ancient Pandemonium Sentinel"))
		return 47
	if (CheckNameAndTypeName(infoCur, "Ancient Stalker Sentinel"))
		return 46
		
	if (CheckNameAndTypeName(infoCur, "Cryptic Apex Sentinel"))
		return 44
	if (CheckNameAndTypeName(infoCur, "Cryptic Pandemonium Sentinel"))
		return 38
	if (CheckNameAndTypeName(infoCur, "Cryptic Stalker Sentinel"))
		return 29
		
	if (CheckNameAndTypeName(infoCur, "Primeval Apex Sentinel"))
		return 36
	if (CheckNameAndTypeName(infoCur, "Primeval Pandemonium Sentinel"))
		return 32
	if (CheckNameAndTypeName(infoCur, "Primeval Stalker Sentinel"))
		return 28
	
	listStrRaisePrice := ["Rarity: Rare", "chance for Empowered Enemies", "Currency", "Divination", "Expedition", "Expedition", "quantity", "Rarity of Items Found", "increased chance to add Rewards"]
	sizeArr := listStrRaisePrice.Length()
	
	txt := infoCur.text
	Loop, parse, txt, `n, `r  ; Specifying `n prior to `r allows both Windows and Unix files to be parsed.
	{
		For k, v in listStrRaisePrice
		{
			if (RegExMatch(A_LoopField, v)){
				countUpPrice := countUpPrice + 1
				AddMessage(v)
			}
		}
		; AddMessage("---")
		; AddMessage(A_LoopField)
		; AddMessage(RegExMatch(A_LoopField, "O)Empowers: (\d*) ", SubPart))
		; AddMessage(SubPart.Value(1))
		if (RegExMatch(A_LoopField, "O)Empowers: (\d*) ", SubPart))
		{
			if (SubPart.Value(1)>50)
				countUpPrice := countUpPrice + 1
			if (SubPart.Value(1)>110)
				countUpPrice := countUpPrice + 1				
		}		
		if (RegExMatch(A_LoopField, "O)(\d*)% increased Quantity of Items Found", SubPart))
		{
			if (SubPart.Value(1)>350)
				countUpPrice := countUpPrice + 1
			if (SubPart.Value(1)>450)
				countUpPrice := countUpPrice + 1	
			if (SubPart.Value(1)>500)
				countUpPrice := countUpPrice + 1	
			if (SubPart.Value(1)>550)
				countUpPrice := countUpPrice + 1				
		}
		if (RegExMatch(A_LoopField, "O)(\d*)% increased Rarity of Items Found", SubPart))
		{
			if (SubPart.Value(1)>400)
				countUpPrice := countUpPrice + 1
			if (SubPart.Value(1)>450)
				countUpPrice := countUpPrice + 1	
			if (SubPart.Value(1)>500)
				countUpPrice := countUpPrice + 1	
			if (SubPart.Value(1)>550)
				countUpPrice := countUpPrice + 1				
		}
	}
	

	return listFibb[countUpPrice]
}

SetNewPrice(infoCur){
	global ExaltPrice
	global MinChaosProfit
	newPrice := 0
	if (infoCur.caption = "Item Class: Sentinel")
		newPrice:= GetNewPriceSentinel(infoCur)
	if (infoCur.level == 0)
	{
		AddMessage("BUG")
		AddMessage("BUG")
		AddMessage("BUG")
		return true
	}
	if (newPrice=0)
		newPrice := GetNewPriceRare(infoCur)
	if (newPrice < MinChaosProfit)
	{
		Send ^{Click}
		AddMessage("No price lower. Sell vendor")
		return true
	}
	neededTailDate := SubStr(A_YWeek, -1) + 40 ; A_DD . A_MM
	neededTailDate := CurrentPostfix() ; A_DD . A_MM
	currencyPriceName := "chaos"
	if (newPrice>ExaltPrice)
	{
		newPrice :=newPrice/ExaltPrice
		currencyPriceName := "divine"
	}
	textPrice := "~b/o " . Round(newPrice, 1) . neededTailDate . " " . currencyPriceName
	if (infoCur.price != textPrice)
		CreateNotePrice(textPrice)	
	AddMessage("Set " . textPrice . " for " . infoCur.name)
	return true
}

SetPriceForItem(infoCur){
	nameCur := infoCur.name
	if (nameCur == "")
		return true
	priceNote := infoCur.note
	global listPriceChaos
	global listPriceExalted
	global ExaltPrice
	neededTailDate := CurrentPostfix() ; A_DD . A_MM
	
	if (RegExMatch(priceNote, neededTailDate)>0)
			return false
		
		if (RegExMatch(priceNote, "O)~(price|b/o) ([\d\.]*) (chaos|divine)", SubPart) <= 0)
		{
			return SetNewPrice(infoCur)			 
		}
		
		oldPrice := SubPart.Value(2)
		newPrice := false
		currencyPriceName := false
		if (SubPart.Value(3) = "divine"){		
			SizeLoop := listPriceExalted.Length()
			Loop %SizeLoop%
			{
				checkingPrice := listPriceExalted[SizeLoop + 1 - A_Index]
				if (checkingPrice < oldPrice - 0.1)
				{
					newPrice := checkingPrice
					currencyPriceName := " divine"
					break
				}					
			}
			oldPrice := oldPrice * ExaltPrice			
		}
		
		if (!newPrice)
		{	
			SizeLoop := listPriceChaos.Length()
			Loop %SizeLoop%
			{
				checkingPrice := Floor(listPriceChaos[SizeLoop + 1 - A_Index])
				if (checkingPrice < oldPrice - 0.1)
				{
					newPrice := checkingPrice
					currencyPriceName := " chaos"
					break
				}					
			}	
		}
		
		
		if (!newPrice)
		{
			Send ^{Click}
			AddMessage("No price lower. Sell vendor")
			return	true		
		}
		
		textPrice := "~price " . Round(newPrice, 1) . neededTailDate . currencyPriceName
		; AddMessage("Need set new price")
		AddMessage("Set " . textPrice . " for " . nameCur)
		if (infoCur.price != textPrice)
			CreateNotePrice(textPrice)	
		; AddMessage(SubPart.Value(2))
		; ~price ([\d\.]*) (chaos|exalted)
		
		return true
}

ListTestedFunc.Push("MassSetPriceTest")
; Эта штука должна быть во всех моих функциях до продакшена.
MassSetPrice()
{
	global AlreadySetDictionaryChaos
	global AlreadySetDictionary
	global ListCurrencyWithBestRatio
	global ListThingCurrency
	global StablePriced
	
		
	Loop
	{
		if (!SearchNextItem())
			return
			
		readItem := GetCurrentItemAtCursor()	
		infoCur := GetInfoFromClipboard(readItem)	
		nameCur := infoCur.name
		priceNote := infoCur.price
		caption := infoCur.caption
		count := infoCur.count
		
		if (nameCur = "Chaos Orb"){		
			if (AlreadySetDictionaryChaos.HasKey(priceNote))		
				if (MoveNextCell(false)){
					continue
				}else{
					return
				}
						
			Loop
			{
				if (A_Index > ListCurrencyWithBestRatio.Count())
				{
					AddMessage("No more chaos'es price in Best Ratio")
					return
				}
				checkedCurrency:=ListCurrencyWithBestRatio[A_Index]
				currencyData:=ListThingCurrency[checkedCurrency]	
				textPrice := currencyData["PriceBuyTextChaos"]
				if (RegExMatch(priceNote, textPrice)>0)
					continue
				
				if (AlreadySetDictionaryChaos.HasKey(textPrice))
					continue
					
				AlreadySetDictionaryChaos[textPrice] := 1
				CreateNotePrice(textPrice)
				AddMessage(checkedCurrency . " " . textPrice)
				
				return
			}			
		}
		
		if (nameCur = "Scroll Fragment"){
			Prices := ListThingCurrency[priceNote]
			textPriceChaos := Prices["PriceSellTextChaos"]
			textPriceExalt := Prices["PriceSellTextExalt"]
			AddMessage(priceNote . " " . textPriceChaos . "; " . textPriceExalt)
			continue
		}
		
		stablePrice := false
		Loop % StablePriced.Length()
		{		
			name := StablePriced[A_Index]
			if (RegExMatch(caption, name)>0)
				stablePrice := true
		}
		
		if (stablePrice)
		{	
			Prices := ListThingCurrency[nameCur]
			if ((count * Prices["MyPriceSellExalt"]) > 1.1){
				textPrice := Prices["PriceSellTextExalt"]
			}else{
				textPrice := Prices["PriceSellTextChaos"]
			}
			; AlreadySetDictionary[nameCur] := textPrice
			if (priceNote == textPrice){
				continue
			}
			CreateNotePrice(textPrice)	
			AddMessage(nameCur . " " . textPrice)	
			return
		}
		
		if (SetPriceForItem(infoCur)){							
			MoveNextCell(false)
			return
		}else{						
			if (!MoveNextCell(false))
				return
		}
		
	}
	
	
	
	; Так, мы берём текст 
; AddMessage("Записи с листа: массовое торговое - кнопка для автораздачи")
; AddMessage("Записи с листа: Ставим в незнакомое, пробуем установить, если получилось - сдвинься и поменяй текст.")
; AddMessage("Записи с листа: Запоминай - кого уже записал и это больше не ставит")
	
}
MassSetPriceTest(msg){
	if (msg="test")
		return false
}

CollectAndSaveToFile(){

	AddMessage("Start collect")	
	data := []
	CenterMouse()
	; while (MoveNextCell(true)){
	while (MoveNextCell(false)){
		readItem := GetCurrentItemAtCursor()
		data.Push({"text":readItem})
	}
	
	JSONText := JSON.Dump(data)
	; FileDelete items.json
	FileAppend, %JSONText%, itemsF6.json	
	
	; FileAppend, % Chr(0xFEFF) . JSONText, items.json, UTF-8

	AddMessage("File Complete")	
}

DeepSeekDump(obj) {
	if (IsObject(obj)) {
		isArray := (obj.Length() == obj.Count()) ; Проверяем, массив ли это
		str := isArray ? "[" : "{"
		for key, value in obj {
			if (!isArray) {
				str .= (A_Index > 1 ? "," : "") . "`n" . "'" . key . "': "
			} else {
				str .= (A_Index > 1 ? "," : "") . "`n" . "    "
			}
			str .= DeepSeekDump(value)
		}
		str .= (str != (isArray ? "[" : "{")) ? "`n" : ""
		str .= isArray ? "]" : "}"
		return str
	} else if (obj == "") {
		return "null"
	} else if (obj ~= "^-?\d+\.?\d*$") { ; Число
		return obj
	} else { ; Строка
		return "'" . obj . "'"
	}
}

ListTestedFunc.Push("SetSinglePriceTest")
; Эта штука должна быть во всех моих функциях до продакшена.
SetSinglePrice(){
	global sellPriceGlobalChaos
	global ListThingCurrency
	if (!WinActive("Path of Exile"))
		return
		
	CenterMouse()
	
	readItem := GetCurrentItemAtCursor()
	if (readItem = "")
		return
	
	infoCur := GetInfoFromClipboard(readItem)	
	nameCur := infoCur.name
	previousPrice := infoCur.price
	
	; if (nameCur = "Exalted Orb"){
	;	CreateNotePrice(sellPriceGlobalExalt)
	; 	return
	; }
	if (nameCur = "Chaos Orb"){
	; 	ToolTip, %sellPriceGlobalChaos%, 0, 0
		if (sellPriceGlobalChaos == previousPrice)
		{
			AddMessage("Already seted:" . sellPriceGlobalChaos)
		}else{
			CreateNotePrice(sellPriceGlobalChaos)
		}
		return
	}
	if (nameCur = "Scroll Fragment"){
		nameCur := infoCur.note
	}
	Prices := ListThingCurrency[nameCur]
	sellPriceGlobalChaos := Prices["PriceBuyTextChaos"]
	; sellPriceGlobalExalt := Prices.priceBuyExalt
	AddMessage(nameCur . " " . sellPriceGlobalChaos)
}
SetSinglePriceTest(msg){
	if (msg="test")
		return false	
}

SimpleHash(str) {
    hash := 2166136261

    ; Разбираем на строки
    Loop, Parse, str, `n, `r
    {
        line := A_LoopField

        ; Пропустить, если начинается с "Note:"
        if (SubStr(line, 1, 5) = "Note:")
            continue

        ; Хешируем эту строку
        Loop, Parse, line
            hash := (hash * 16777619) ^ Asc(A_LoopField)
        
        ; Добавляем символ переноса для стабильности
        hash := (hash * 16777619) ^ 10  ; "\n"
    }

    return hash & 0xFFFFFFFF
}
global processed := {}  ; хеши в памяти, не сохраняются на диск
WasProcessed(h) {
    global processed

    if (processed.HasKey(h))
        return true  ; уже был

    processed[h] := true
    return false
}
SetSingleObjectPrice(){
	static alreadySetting := false

	divineCost := 110
	minPrice := 1
	lowPercent := 0.65
	highPercent := 0.80

	if (!WinActive("Path of Exile"))
		return
		
	if (alreadySetting) 
		return
	alreadySetting := true
	
	CenterMouse()
	
	readItem := GetCurrentItemAtCursor()
	if (readItem = ""){
		MoveNextCell(false)
		alreadySetting := false
		return
	}
	
	infoItem := GetInfoFromClipboard(readItem)	
	nameItem := infoItem.name
	previousPrice := infoItem.negotiablePrice		
	hash := infoItem.simpleHash
	
	if (WasProcessed(hash)){
		MoveNextCell(false)
		alreadySetting := false
		return
	}
	
	RegExMatch(previousPrice, "O)(\d+) (.+)$", SubPart)
	countCurrency := SubPart.Value(1)
	nameCurrency := SubPart.Value(2)
	
	if (countCurrency = 1 && nameCurrency = "divine"){
		countCurrency := divineCost
		newNameCurrency := "chaos"
	}else if (nameCurrency = "alch"){
		countCurrency := 0
		newNameCurrency := "drop"		
	}else{	
		newNameCurrency := nameCurrency
	}
	
	if (countCurrency <= minPrice){
		newNameCurrency := "drop"
		newPrice := 0
	}else{
		lowNextPrice := Max(Min(Floor(countCurrency * lowPercent), countCurrency-1), minPrice)
		highNextPrice := Max(Min(Floor(countCurrency * highPercent), countCurrency-1), minPrice)
		Random, newPrice, lowNextPrice, highNextPrice
	}
	
	; AddMessage(nameItem . " " . previousPrice . " ")
	; AddMessage(countCurrency . " " . nameCurrency)
	; AddMessage(hash)
	AddMessage(newPrice . " |" . newNameCurrency . "|" . SubStr(newNameCurrency, 1, 1) . "|" . newNameCurrency[1] . "|")
	; AddMessage(newPrice . " " . newNameCurrency)
	
	if (newNameCurrency = "drop"){
		Send {Blind}{Ctrl down}
		Sleep 70
		Send {Click}	
		Sleep 70
		Send {Blind}{Ctrl up}
		Sleep 70
	}else if (newNameCurrency = nameCurrency){
		Send {RButton}
		Sleep 70
		Send %newPrice%
		Sleep 70
		Send {Enter}
	} else {
		Send {RButton}
		Sleep 70
		Send %newPrice%
		Sleep 70
		Send {Tab}
		Sleep 400
		SendInput % SubStr(newNameCurrency, 1, 1)
		Sleep 300
		Send {Enter}
		Sleep 70
		Send {Enter}
	}
	MoveNextCell(false)
	Sleep 300
	alreadySetting := false
	
	; if (nameCur = "Exalted Orb"){
	;	CreateNotePrice(sellPriceGlobalExalt)
	; 	return
	; }
	; if (nameCur = "Chaos Orb"){
		; if (sellPriceGlobalChaos == previousPrice)
		; {
			; AddMessage("Already seted:" . sellPriceGlobalChaos)
		; }else{
			; CreateNotePrice(sellPriceGlobalChaos)
		; }
		; return
	; }
	; if (nameCur = "Scroll Fragment"){
		; nameCur := infoCur.note
	; }
	; Prices := ListThingCurrency[nameCur]
	; sellPriceGlobalChaos := Prices["PriceBuyTextChaos"]
	; AddMessage(nameCur . " " . sellPriceGlobalChaos)
}

ListTestedFunc.Push("SearchNameByTradeIdTest")
; Эта штука должна быть во всех моих функциях до продакшена.
SearchNameByTradeId(priceWithTradeId){
	global ListThingCurrency
	For currency, cData in ListThingCurrency {
		checkedTradeId := cData["tradeID"]
		; AddMessage("Search " . checkedTradeId . " in " . priceWithTradeId)
		if (RegExMatch(priceWithTradeId, checkedTradeId)>0)
			return currency
	}
	return ""
}
SearchNameByTradeIdTest(msg){
	if (msg="test")
		return false
}


	
ListTestedFunc.Push("AskAndChangeParamTest")
; Эта штука должна быть во всех моих функциях до продакшена.
AskAndChangeParam(textQuestion, changedVariable){
	global ListThingCurrency
	if (!WinActive("Path of Exile"))
		return
	
	readItem := GetCurrentItemAtCursor()
	if (readItem = "")
		return
	infoCur := GetInfoFromClipboard(readItem)	
	nameCur := infoCur.name
	AddMessage(nameCur)
	if ((nameCur == "Chaos Orb") || (nameCur == "Exalted Orb"))
	{		
		priceNote := infoCur.price
		AddMessage(priceNote)
		nameCur := SearchNameByTradeId(priceNote)
	}
	if (nameCur == "Scroll Fragment")
	{
		nameCur := infoCur.note		
	}
	if (nameCur = "")
	{
		AddMessage("We can't define item")
		return
	}
	changingCurrency := ListThingCurrency[nameCur]
	prevValue:=changingCurrency[changedVariable]
	InputBox, userAnswer, %textQuestion%, %nameCur%, /*HIDE*/, /*Width*/, /*Height*/, /*X*/, /*Y*/, /*Locale*/, /*Timeout*/, %prevValue%

	if (ErrorLevel = 0 ) 
	{
		currencyData := ListThingCurrency[nameCur]
		currencyData[changedVariable] := 1 * userAnswer
		ListThingCurrency[nameCur] := UpdateOneDateInMemory(nameCur, currencyData)
		SaveDataToFile()
	}
}
AskAndChangeParamTest(msg){
	if (msg="test")
		return false
}
		
			
ListTestedFunc.Push("CleanMassBuyTest")
; Эта штука должна быть во всех моих функциях до продакшена.
CleanMassBuy(){
	global summMassBuy
	MsgBox, 4,, Would you cleanmassBuy? (press Yes or No)
	IfMsgBox Yes
		summMassBuy := {currency: 0, noCurrency: 0, equipItem: 0, tradeBuy: 0}
	else
		return	
}
CleanMassBuyTest(msg){
	if (msg="test")
		return false
}
ListTestedFunc.Push("AddMassBuyTest")
; Эта штука должна быть во всех моих функциях до продакшена.
AddMassBuy(){
	global summMassBuy	
	global ListThingCurrency	
	if (!WinActive("Path of Exile"))
		return
				
	readItem := GetCurrentItemAtCursor()
	if (readItem == "")
		return
	infoCur := GetInfoFromClipboard(readItem)
	if (infoCur.name = "Chaos Orb"){
			CenterPrice := 1
			MyPriceBuy := 1
	}else{
		Prices := ListThingCurrency[infoCur.name]
		if (Prices.centerPrice>0)
		{
			CenterPrice := Prices.centerPrice
			MyPriceBuy := Prices.MyPriceBuy
		}else{
			CenterPrice := 0
			MyPriceBuy := 0
		}
	}
	CenterPriceThatStack :=  CenterPrice * infoCur.count
	MyPriceThatStack := MyPriceBuy * infoCur.count
	if (infoCur.caption = "Item Class: Stackable Currency")
	{
		summMassBuy.currency += CenterPriceThatStack
	}else{
		summMassBuy.noCurrency += CenterPriceThatStack
	}
	summMassBuy.tradeBuy += MyPriceThatStack
	AddMessage("Bulk buy + " . infoCur.count . " " . infoCur.name . "(" . MyPriceThatStack . "/" . CenterPriceThatStack . ")")
	summMassBuy.equipItem += 0
}
AddMassBuyTest(msg){
	if (msg="test")
		return false
}
ListTestedFunc.Push("ShowMassBuyTest")
; Эта штука должна быть во всех моих функциях до продакшена.
ShowMassBuy(){
	global summMassBuy
	global discountBuyCurrency
	global discountBuyNoCurrency
	global discountBuyEquip
	global ExaltPrice
	
	chaosMyPrice := Ceil(summMassBuy.tradeBuy)
	exaltShow := Floor(summMassBuy.tradeBuy / ExaltPrice)
	chaosShow := Ceil(summMassBuy.tradeBuy - exaltShow * ExaltPrice)
	if (((ExaltPrice - chaosShow)/summMassBuy.tradeBuy)<0.01){
		exaltShow := exaltShow + 1
		chaosShow := 0
	}
	message := "My Price: " . chaosMyPrice . " chaos "
	if (exaltShow > 0){
		message := message . "or " . exaltShow . " div "
		if (chaosShow > 0)
			message := message . chaosShow . " chaos"
	}
	clipboard := message
	; message := message . "`n" . summMassBuy.tradeBuy . "`n" . (exaltShow * ExaltPrice) . "`n" . (summMassBuy.tradeBuy - exaltShow * ExaltPrice) 
	; message := "Currency: " . Ceil(summMassBuy.currency * discountBuyCurrency) . "`nNoCurrency: " . Ceil(summMassBuy.noCurrency * discountBuyNoCurrency) . "`nEquipItem: " . Ceil(summMassBuy.equipItem * discountBuyEquip) . "`nMyPrice: " . Ceil(summMassBuy.tradeBuy)
	AddMessage(message)
}
ShowMassBuyTest(msg){
	if (msg="test")
		return false
}
	
ListTestedFunc.Push("TemplateFunctionTest")
; Эта штука должна быть во всех моих функциях до продакшена.
TemplateFunction(){
}
TemplateFunctionTest(msg){
	if (msg="test")
		return false
}
		
AddMessage("Start script")

CheckAllFunc()

; LoadDataFromFile()
; LoadDataFromUrl()
; UpdateDataInMemory()
; SaveDataToFile()

; GetListBestTrade()

/*
Temporary output - need change on click key
AddMessage(ListCurrencyWithBestRatio.Count())
For kkk, vvv in ListCurrencyWithBestRatio
{
	ccc := ListThingCurrency[vvv]
	DebugVariable(vvv, ccc["PriceBuyTextChaos"], ccc["PriceSellTextChaos"], ccc["ClickCountOnChaos"])
	;AddMessage(vvv . "`nPrice:" . ccc["PriceBuyTextChaos"] . " - " . ccc["PriceSellTextChaos"] . "(" . ccc["ClickCountOnChaos"] . ")")
}
*/

AddMessage("Поиск в инвентаре комлектов")
AddMessage("Камни тоже нужно оценивать")
AddMessage("Список желания - сортировать по нужной осколки сделать зависящие от целого")
AddMessage("Cкипать ненужные позиции`nИ раз в минуту - проверять есть ли запросы которые выгоднее моих закупок")
AddMessage("В том числе и на гадальных картах")
AddMessage("Но здесь уже надо учитывать высокие позиции")
AddMessage("И для легендарных ребят тоже надо.")
AddMessage("В скрипте должна быть настройка - насколько сильно я хочу продавать и покупать")
AddMessage("Цену за экзальт должно считать автоматически а не константой в скрипте.")
AddMessage("Указывать мою сумму хаосов которую я могу тратить - закупка не должна быть выше этой суммы")
AddMessage("Сверка цен входящих - по позиции покажи ожидаемое количество на отдачу")
AddMessage("Игнорируй и вставляй надпись NFT? Или со скипом так?  ")
AddMessage("Используй БД PoE с github")
AddMessage("Храни настройки")
AddMessage("Чисти временные файлы за собой")
AddMessage("Оценка карт и камней")
AddMessage("По билду из PoB - какие мне нужны камни где их купить и какие умения выбирать на дереве")
AddMessage("Составление для живого поиска из PoB нужные для билда вещи и хорошей торговли")
AddMessage("Для билдов вести расчёт соотношения атаки и защиты 1/1 - стекло 2/1 - норма 3/1 - танк")
AddMessage("Работа с вкладками?")
AddMessage("Для комплектов поиск излишков которые можно не страшно продать")
AddMessage("На клавишу global 820")
AddMessage("Типо биржевые сводки чтобы видеть где есть выгодное. Возможно сразу с кнопками заказа или перехода на онлайн поиск")
AddMessage("Просто показать цену без установки")
AddMessage("Учесть для масел осколков и эсенций что они превращаемые")
AddMessage("Автовитрину считать по моей сумме денег - до 1/14 части и по выгодности торовли")
AddMessage("По хорошему надо объём исчитывать из ценности - мелкие вещи в больших объёмах")
AddMessage("Скрипт должен  уметь двигаться по чуть-чуть - выставляя нужные цены если они отличаются и учитывая что здесь - свитки или инное")
AddMessage("Учесть существование poe.price и скидку со временем если объект давно что ли")
AddMessage("В базе данных должны быть настройки цен и стремиться к минимальному количеству или минимальной цене")
AddMessage("Специальный параметр - скупаем всё или только с уменьшением стаков")
AddMessage("Для валют бы учитывать - насколько большой объём торговли и у каждого человека")
AddMessage("Надо учесть что при включенном скрипте иногда я не в POE - пропусти комманду дальше")
AddMessage("А когда будет пересчёт потока?")
AddMessage("А когда надо делать передамп цен? Когда?")
AddMessage("Минимальная цена выгоды - в том числе и для обычных предметов")
AddMessage("Дальше блок сообщений с листочка - как надо")
AddMessage("Ачивки: недостающие уники в моей коллекции(по стандарту)")
AddMessage("Ачивки: непройденные ачивки - с сайта брать данные и показывать справку")
AddMessage("Ачивки: чекбокс по фольклористу и надписям лора")
AddMessage("Ачивки: глубина шахты?")
AddMessage("Ачивки: мой скрипт должен сам уметь диагностировать - что у него сделано, а что нет")
AddMessage("Ачивки: посчитать, какие купленные вкладки на стандарте заполнены, а какие ещё нет")
AddMessage("Ачивки: под конец лиги немного распродавать вещи, которых у меня будет с избытком после миграции на стандарт")
AddMessage("Ачивки: Оценить время до левелапа с текущей скоростью")
AddMessage("Оценка стоимости PoB, возможно через poe.prices")
AddMessage("Торговля: Для предметов - возможность понижать цену, если долго торгуется(помнить у себя что и когда выставлялось?)")
AddMessage("Торговля: Кнопки kick, hideout, /afk /global 820 /dnd /оставшиеся монстры")
AddMessage("Торговля: С торгового помощника - готовые сообщени")
AddMessage("Торговля: Неровная цена, чтобы её не меняли?")
AddMessage("Торговля: Гадальные карты, дающие особые вещи - оценивать по этим вещам")
AddMessage("Торговля: Сравнить два одноимённых уника - кто чисто лучше")
AddMessage("Торговля: Опознание вневременных самоцветов и их торговля")
AddMessage("Торговля: Купить/искать вещи уники с высокими ролами и дешёво для перепродажи")
AddMessage("Торговля: Скупка 6-линков дешевле божественной сферы")
AddMessage("Торговля: При покупки эссенций - считать нижние цены как дроби от верхних")
AddMessage("Торговля: Торговля зверьми - какие области дорогие для фарма")
AddMessage("Торговля: Баночки - сосуды духов. Какие цены?")
AddMessage("Торговля: торговля с overpriced fossil")
AddMessage("Торговля: скупка баз с рынка, что ниже ценного")
AddMessage("Торговля: Оценщик учитывает уровень предмета и базу")
AddMessage("Торговля: Торговля крафтом грядок")
AddMessage("Торговля: Торговля контрактами")
AddMessage("Торговля: Подсчёт средней прибыли, чтобы знать, что фармить выгодно от торговли")
AddMessage("Торговля: цены для скальпинга")
AddMessage("Торговля: цены для фоновой торговли")
AddMessage("Торговля: превращение скарабеев с помощью сферы горизонтов")
AddMessage("Торговля: учёт что хорошо торговалось а что мало торгуется")
AddMessage("Торговля: для гадальных карт ставить цену исходя из получаемого результата")
AddMessage("Торговля: Цены через poe.prices")
AddMessage("Торговля: Минимальная цена 6-линка - Divine Orb+1")
AddMessage("Торговля: Определять ценность по роллам")
AddMessage("Торговля: Искать запросы выгоднее моих")
AddMessage("Торговля: Для уников делай тройную цену?")
AddMessage("Торговля: Оценить стоимость фрагшментов метаморфа по составу")
AddMessage("Торговля: Контракты оценивать как-то. По уровню и используемое")
AddMessage("Торговля: Помнить текущую выставленную цену")
AddMessage("Торговля: Обработка входящих торговых запросов")
AddMessage("Торговля: Поддержка исходящих запросов с поддержкой повторов")
AddMessage("Торговля: На исходящих запросах также кнопки /trade, чтобы быстрее кликать")
AddMessage("Торговля: Отлистывалка нужного количества валюты из запаса")
AddMessage("Торговля: ctrl+left click по одной кнопке")
AddMessage("Торговля: задавать режим скальпинга или медленной скупки")
AddMessage("Торговля: делать выставка витрины по одной кнопки, чтобы всё двигалось")
AddMessage("Торговля: Составлять запросов WTB для отправки в чатик")
AddMessage("Торговля: учти, что иногда я закупаюсь излишком - в этом случае на вкладке закупке надо это убирать")
AddMessage("Торговля: Составлять цену закупочную для сетов для торговли через TFT")
AddMessage("Торговля: При получении запроса - проверить, проходит ли он по моим ценнам или был изменён")
AddMessage("Торговля: Выставлять цены и пропускать те клетки, где нет нужного цвета")
AddMessage("Торговля: Для осколков вышки надо ставить дробную цену за 1 штуку")
AddMessage("Торговля: Для карт-валюты рассчитать их цену и ставить за 1 штуку")
AddMessage("Торговля: Для rogue-maker нет цены на poe.ninja")
AddMessage("Торговля: Для Sacred Blosoom нет цены на poe.ninja")
AddMessage("Фарм: Сообщения Invite Me по чатиковым вещам или предложениям")
AddMessage("Фарм: Отслеживания, когда и что пишут в чате?")
AddMessage("Фарм: Отлов в чате LF Leecher")
AddMessage("Фарм: Фильтр для сборки с пола во время личинга(без высоких ценностей)")
AddMessage("Фарм: Фарм зверья")
AddMessage("Фарм: Активное использование алтаря")
AddMessage("Фарм: Поиск ископаемых - цены и биомы")
AddMessage("Фарм: Босы шахт")
AddMessage("Фарм: Грядкафарм для цветка")
AddMessage("Фарм: Ограбления - копить жетоны и очки открытий - лёгкие контракты")
AddMessage("Фарм: фильтры с хорошими базами")
AddMessage("Фарм: Ограбления - фарм чисто мелочи - сложные контракты")
AddMessage("Фарм: Ограбления - фарм особого?")
AddMessage("Фарм: Альва - плотность чуваков?")
AddMessage("Фарм: фарм зодчего Атцоаль")
AddMessage("Фарм: фарм просто карт - общий/на гадалки?")
AddMessage("Фарм: Скоростный фарм босов общий/с особым дропом")
AddMessage("Фарм: Фарм MF - валюты/уники")
AddMessage("Фарм: Зачистка грибных карт")
AddMessage("Фарм: поход в делириум")
AddMessage("Фарм: походы в 4-х фрагментах(Сирис и т.д.)")
AddMessage("Фарм: Журналы экспедиции")
AddMessage("Фарм: Фарм экспедиционной валюты")
AddMessage("Фарм: Зачистка карт для делириумной массы")
AddMessage("Фарм: Смотреть на картах - что есть опасное и для кого?")
AddMessage("Фарм: Считывать параметры карты Кирака - проверка опасного")
AddMessage("Сколько уже играю, пора ли делать перерыв и успею ли я сделать то или иное действие?")
AddMessage("Поиск хаос рецептов и рецептов вышки")
AddMessage("Внутренний будильник и режим игры?")
AddMessage("Сервисы: Водить людей в лабиринты защищённо и быстро")
AddMessage("Сервисы: Протаскивание по актам - автофарм, снос босов, скорость и защита")
AddMessage("Сервисы: По испытаниям - учитывая цены, время и затраты")
AddMessage("Билдострой: Справка по актам - куда бежать")
AddMessage("Билдострой: Справка по камням - награды, покупаемые, смены")
AddMessage("Билдострой: Фильтры для прокачки")
AddMessage("Билдострой: Пробежка по кровавому акведуку")
AddMessage("Билдострой: Оценка сколько опыта в час и когда левелапнешься?")
AddMessage("Билдострой: пробежки по 67-му уровню в 10-м акте")
AddMessage("Билдострой: Собирание богов в сосуды")
AddMessage("Билдострой: сравнение своего дерева с деревом PoB(те, что надо сменить - в поиске)")
AddMessage("Билдострой: сравнение своих камней с PoB и ссылка на торговый закуп")
AddMessage("Билдострой: торговые запросы на основе PoB-предмет")
AddMessage("Билдострой: торговые запросы на такое-же, но лучше чем моё")
AddMessage("Билдострой: сборка для личинга")
AddMessage("Билдострой: сборка для 5 эмблем - ресетер, аура, аура+ресетер")
AddMessage("Билдострой: Фильтр для поиска с пола для мин-максерства")
AddMessage("Билдострой: Пробегание лабиринта на выживание - восхождения")
AddMessage("Билдострой: Миррорные сборки стандарта")
AddMessage("Билдострой: Глубинная прокачка в шахтах")
AddMessage("Билдострой: Фильтр для билдов, чтобы искать разное/интересное")
AddMessage("Оценка: Осколки делать в зависимости от целого")
AddMessage("Оценка: Быстрая оценка для скупки с суммированием всего просмотренного")
AddMessage("Оценка: Оценка карт и камней")
AddMessage("Оценка: Для эссенций и масел учти превращения")
AddMessage("Оценка: Смотреть цены в том числе через вышки, возможна через запрос к торговым сайтам")
AddMessage("Оценка: Настройка - мин. нужное мне число стаков, учти, что в начале лиги много важного")
AddMessage("Оценка: Как слать запросы на poe.prices")
AddMessage("Оценка: как оценить по свойствам самому? Чёрный ящик с poe.prices")
AddMessage("Оценка: учти, что вещи на рынке - уже не купленное")
AddMessage("Оценка: модифицировать цены в зависимости от моих запасов?")
AddMessage("Оценка: поиск наиболее оборотных позиций, пользуясь тем, что poe показывает таже время и имя выставившего")
AddMessage("Оценка: Спецкалькулятор для валют - чтобы на лету смотреть")
AddMessage("Оценка: Оценка гадальной карты на вкладке карт(название считывать с экраном)")
AddMessage("Оценка: Если ниже границы - сразу сгружай")
AddMessage("Оценка: Для осколков вышки отдельная цена?")
AddMessage("Используй уже готовые БД - где их взять?")
AddMessage("Показывать цену без установки")
AddMessage("Настройка активных клавиш")
AddMessage("Крафт: Какие камни выгодно качать")
AddMessage("Крафт: Какие камни выгодно ваалить")
AddMessage("Крафт: Какие veiled моды - хороши?")
AddMessage("Крафт: какие камни выгодно менять призмой")
AddMessage("Крафт: Звери - вокруг духов")
AddMessage("Крафт: Крафт ископаемых")
AddMessage("Крафт: Грядковое создание")
AddMessage("Крафт: Закупка хороших баз(в т.ч. и шлемов)")
AddMessage("Крафт: Лабокрафт шапок")
AddMessage("Крафт: Дабл крафт в храме - что выгодно с учётом провала")
AddMessage("Крафт: Скупка крафтовых материалов")
AddMessage("Крафт: Оценить среднею востребованность крафта и его цены")
AddMessage("Крафт: Особые камни Enh... Enl... Emp... - качать к LVL3")
AddMessage("Крафт: Массельная обработка?")
AddMessage("Крафт: Цены на лабороторные шапки?")
AddMessage("Ободранные с пустыми trade id - их надо пропускать?")
AddMessage("Осколки почему-то без trade id")
AddMessage("Крафт: Грядковый крафт - готовые сообщения")
AddMessage("Записи с листа: массовое торговое - кнопка для автораздачи")
AddMessage("Записи с листа: Ставим в незнакомое, пробуем установить, если получилось - сдвинься и поменяй текст.")
AddMessage("Записи с листа: Дошли до правого края - иди слева. Если вышло за край снизу - сверху и останавливайся.")
AddMessage("Записи с листа: Запоминай - кого уже записал и это больше не ставит")
AddMessage("Ошибки: у части выдаёт /")
AddMessage("Ошибки: у части нет id'шного торгового")
AddMessage("Ошибки: смена макс. количества")
AddMessage("Ошибки: смена края цен")
AddMessage("Ошибки: сдвиг цены не сохранился")
AddMessage("Ошибки: писать, когда выгоды мало в продаже")
AddMessage("Ошибки: искать, каких вещей у меня нет в тайниках")
AddMessage("Ошибки: Заряженные компасы в закупке - пропускать")

CleanMessageAndSetTimeout(450)
SoundBeep
AddMessage("Finish script")
; --------------------------
; --------------------------
; --------------------------
; --------------------------
; --------------------------
; --------------------------
; --------------------------
; --------------------------
; Файл настроек завести
; --------------------------
; Функция для выставления цены продажи за вышку с учётом опта
; --------------------------
; Оценка по свойствам
; --------------------------
; Помнить цену при входящих запросах
; --------------------------
; Фильтр с оценкой на основе свойств
; --------------------------
; На покупку должно быть всегда.
; --------------------------
/*

; TemplateObject := {name:"Template", tradeID:"fake", buyTradePrice:0.1, minBuyPrice:0.01, maxBuyPrice:0.2, sellTradePrice:0.2, minSellPrice: 0.15, maxSellPrice: 0.5, stackSize: 10, maxSell:100, shiftBuy:-0.2, shiftSell:0.2, maxCountBuy: 600, maxCountSell: 200, priceSellChaos: "~price 1 chaos", priceSellExalt:"~price 1 exalted", priceSellExaltFrac:"~price 1.1 exalted", priceSellExaltBig:"~price 2 exalted" priceBuyChaos:"~price 10 thing", priceBuyExalt:"~price 1000 thing", minCountCurrency:16, clickCountOnChaos:13, clickCountOnChaosBig:15}




GetGoodFracSell(wantSellPrice){
	global ExaltPrice
	temp := Ceil(wantSellPrice*10/ExaltPrice)
	big := Floor(temp/10)
	small := temp-big*10
	res = %big%.%small%
	return res
}
*/

; !F2::
	; wasCenter := !wasCenter
	; if (wasCenter){
		; AddMessage("Теперь центрируем")
	; }else{
		; AddMessage("Теперь не центрируем")
	; }
; return

F2::
	SetSingleObjectPrice()
return

F3::
	SetSinglePrice()
return

; ^F2::
	; AskAndChangeParam("Set new maximum buy", "maxCountBuy")
; return 

; +F2::
	; AskAndChangeParam("Set new offset buy", "shiftBuy")
; return 

; ^+F2::	"":"-0.2","":"-0.01"
; 	; AskAndChangeParam("Set new maximum offset", "MyPriceBuy")
	; SetNewStackBuy()
; 	AddMessage("Сохранять данные каждый раз и пересчитывать для этого параметра")
; return 

; ^F3::
	; AskAndChangeParam("Set new maximum sell", "maxCountSell")
; return 

; +F3::
	; AskAndChangeParam("Set new offset sell", "shiftSell")
; return

; ^+F3::
; 	SetNewStackSell()
; 	AddMessage("Сохранять данные каждый раз и пересчитывать для этого параметра")	
; return
	
; ^F4::
	; ShowMassBuy()
; return

; +F4::
	; CleanMassBuy()
; return

; F4::
	; AddMassBuy()
; return

; ^+F1::
	; For kdebuggingMessage, vdebuggingMessage in debuggingMessage
		; AddMessage(vdebuggingMessage)
; return

; \::
	; if (!WinActive("Path of Exile"))
	; {
		; Send /
		; return
	; }
	; Send ^{Click}
; return

; F6::
	; CollectAndSaveToFile()
; return