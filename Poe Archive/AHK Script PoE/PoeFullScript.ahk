#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance Force

SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include json.ahk
#Include message.ahk
#Include PoeConstSettings.ahk

ListTestedFunc := []

; ListCurrencyOverview := ["Currency", "Fragment"]
; ListItemOverview := ["Invitation", "Incubator", "Incubator", "DivinationCard", "DeliriumOrb", "Scarab", "Fossil", "Oil", "Essence", "Resonator", "Artifact"]
; ListItemGemOverview := "SkillGem"
; PoeNinjaAPIUrl := "https://poe.ninja/api/data/"
StablePriced := ["Currency", "Fragments", "Misc Map Items"]
listPriceChaos := [1, 2]
listPriceBig := [1, 1.3, 1.6, 2]
listFibb := [1, 1, 2]
WantCurrency := ["Orb of Annulment", "Veiled Chaos Orb", "Exalted Orb", "Divine Orb", "Sacred Orb", "Awakener's Orb", "Orb Of Dominance"]
WantCurrency := ["Exalted Orb", "Divine Orb", "Chaos Orb"]
; ListedLeftUniquesFile := "listLeftUnique.json" 
; ListLeftUniques := []

Loop, 20
{
	lengthFib := listPriceChaos.Length()
	newFib := listPriceChaos[lengthFib] + listPriceChaos[lengthFib-1]
	listPriceChaos.Push(newFib)
	lengthFib := listPriceBig.Length()
	newFib := listPriceBig[lengthFib-3] + listPriceBig[lengthFib-1]
	listPriceBig.Push(newFib)
	lengthFib := listFibb.Length()
	newFib := listFibb[lengthFib] + listFibb[lengthFib-1]
	listFibb.Push(newFib)
	listFibb.Push(newFib + listFibb[lengthFib])
}


MinChaosProfit := false
MaxChaos := false
MaxBigCurrency := false
CapitalChaos := 2059 ;1418 ;720 ;535 ;215 ;1
; CapitalChaos := 416883 ;STD!
startLeague := false

BigCurrencyPrice := false
KalandraPrice := false

ProcEnough := 0.98

DefaultBuyShift := -0.22
DefaultSellShift := 0.01
MarkupPrice := 2.1

NameBigCurrency := "Divine Orb"

ListCurrencyWithBestRatio := []
MaxCurrencyInBest := 12 * 12 * 3

numChaos := 1
sellPriceGlobalForChaos := ""
sellPriceGlobalForBigCurrency := ""

HighBorder := 100000
MidBorder := 10000
LowBorder := 100

summMassBuy := {currency: 0, noCurrency: 0, equipItem: 0, tradeBuy: 0}
discountBuyCurrency := 0.8
discountBuyNoCurrency := 0.7
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

ListTestedFunc.Push("GetInfoFromClipboard")
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
		
	
	return {name: name, typeName: typeName, price: SubStr(note, 7), count: count, caption: caption, text:text, rarity:rarity, level:level, quality:quality, corrupted:corrupted, skip:skip, negotiablePrice:negotiablePrice, exactPrice:exactPrice, note:note, sockets:sockets, tiers:tiers}
}

ListTestedFunc.Push("CreateNotePrice")
CurrentPostfix(){
	global CurrentLeague
	if (CurrentLeague = "Standard"){
		return SubStr(A_YWeek, -1) + 40
	}else{
		return A_DD
	}
}
DefineAndPutPrice(chaosEquiv, name){
	global WantCurrency
	global ListThingCurrency
	global CurrentLeague
	global BigCurrencyPrice
	global NameBigCurrency
	
	if (chaosEquiv="test"){
		AddMessage("Считать в моих нужных или любимых валютах")
		return false
	}
	
	if (CurrentLeague = "Standard"){
		prefix := "~b/o "
	}else{
		prefix := "~price "
	}
	postfix := CurrentPostfix()
		
	; minDiffInChaos := chaosEquiv
	; wantedPrice := chaosEquiv
	; wantedCurrency := "chaos"
	; sizeArr := WantCurrency.Count()
	; Loop, %sizeArr%
	; {
		; currencyName := WantCurrency[A_Index]
		; if (currencyName = "Chaos Orb")
		; {
			; priceCurInChaos := 1
			; tradeId := "chaos"
		; }else{
			; dataCurr := ListThingCurrency[currencyName]
			; priceCurInChaos := dataCurr.centerPrice
			; tradeId := dataCurr.tradeID
		; }
		; priceFracInCurr := chaosEquiv / priceCurInChaos
		; priceInCurr := Ceil(priceFracInCurr)
		; diffInChaos := Abs(priceInCurr - priceFracInCurr) * priceCurInChaos
		; wantedPriceT := Round(Ceil(priceInCurr*10)/10, 1)
		; AddMessage("currencyName: " . currencyName . "`npriceCurInChaos: " . priceCurInChaos . "`npriceFracInCurr: " . priceFracInCurr . "`npriceInCurr: " . priceInCurr . "`ndiffInChaos: " . diffInChaos . "`nminDiffInChaos: " . minDiffInChaos . "`nwantedPrice: " . wantedPriceT . "`nwantedCurrency: " . tradeId)
		; if (diffInChaos<minDiffInChaos)
		; {
			; minDiffInChaos := diffInChaos
			; wantedPrice := Round(Ceil(priceInCurr*10)/10, 1)
			; wantedCurrency := tradeId
		; }
	; }
	AddMessage("Мы должны уметь определять tradeId в общем случае")
	tradeIdBigCurrence := "divine" 
	wantedPrice := Round(Ceil(chaosEquiv*10)/10, 1)
	wantedCurrency := "chaos"
	if (chaosEquiv > BigCurrencyPrice)
	{		
		wantedPrice :=  Round(Ceil((chaosEquiv/BigCurrencyPrice)*10)/10, 1)
		wantedCurrency := tradeIdBigCurrence
	}
	
	textPrice := prefix . wantedPrice . postfix . " " . wantedCurrency
	CreateNotePrice(textPrice)
	AddMessage("Set " . textPrice . " for " . name)
}

ListTestedFunc.Push("CreateNotePrice")
CreateNotePrice(text){
	if (text="test")
	{
		AddMessage("Чего-то там с неидеальным попаданием было. Надо цифры пересчитвывать")
		return false
	}
	MouseGetPos OutputVarX, OutputVarY
	MouseXDiff = -100
	if (OutputVarX < 140)
	{
		MouseXDiff := 40-OutputVarX
	}
	Click, Rel 0, 0 Right
	
	LeftTime = 1000
	
	ClickX := OutputVarX+MouseXDiff
	ClickY := OutputVarY+80
	ClickXCheck := ClickX-10
	ClickYCheck := ClickY+20
	PixelGetColor, BeforeColor, %ClickXCheck%, %ClickYCheck%
	
	while(LeftTime>0)
	{
		Sleep 140
		Click, %ClickX%, %ClickY%
		Sleep 100
		PixelGetColor,AfterColor, %ClickXCheck%, %ClickYCheck%
		; ToolTip, %BeforeColor%`n%AfterColor%, 0, 0
		; Sleep 2000
		if (BeforeColor = AfterColor){
			LeftTime := LeftTime - 240
		}else{
			break
		}
	}
	
	if (LeftTime < 0)
	{
		AddMessage("Can't open set price" . text . " in clipboard")
		clipboard := text
		return
	}
	
	Send {Down}{Up}{Up}{Up}{Up}
	Sleep 100
	Send {Enter}
	Sleep 100
	Send {Home}
	Sleep 100
	Send +{End}
	Sleep 100
	Send, %text%
	Sleep, 100
	Send {Enter}

	MouseMove,  OutputVarX, OutputVarY

	AddMessage("Complete!")
}



CheckAllFunc(){
	global ListTestedFunc
	for k, func in ListTestedFunc{
		if (%func%("test")){
		}else{
			AddMessage("Function " . func . " doesn't work")
		}
	}	
}

; Function return integer fraction near target
GetFrac(target, bottomLimit, minNumerator, minDenominator, maxNumerator, maxDenominator, stepNumerator, stepDenominator){
	global ProcEnough
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
		
		if ((Min(idealFraction, target)/Max(idealFraction, target)) > ProcEnough)
			break
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
	ClipWait, 0.1
	if ErrorLevel
	{
		; AddMessage("Can't define. Return from function")
		return ""
	}
	return clipboard
}


; AddFromUrlJSON(js)
; {
	; global ListThingCurrency	
	; global DefaultBuyShift	
	; global DefaultSellShift
	; if (js="test"){
		; AddMessage("Очень большая функция, надо делить. И чтобы всё было подвижное")
		; AddMessage("Не все параметры наследуются или используются?")
		; return false
	; }
	; For currency, cData in js.lines {
		; name := cData.currencyTypeName
		; if (name = "")
			; name := cData.name
					
		; if (RegExMatch(name, "Silver Coin")>0)
			; continue
		
		; tradeID := GetTradeID(name, cData, js.currencyDetails)
		; stackSize := GetStackSize(name, cData)
			
		; centerPrice := cData.chaosEquivalent
		; if (centerPrice = "")
			; centerPrice := cData.chaosValue
		
		; buyTradePrice := GetBuyPrice(cData)
		; sellTradePrice := GetSellPrice(cData)
	
		; if (ListThingCurrency.HasKey(name)){
			; elementThing := ListThingCurrency[name]
				; maxCountBuy := min(elementThing["maxCountBuy"], stackSize-1)
			; if (cData["itemClass"] = 6){
			; }else{
				; maxCountBuy:= elementThing["maxCountBuy"]
			; }
			; maxCountSell := elementThing["maxCountSell"]
		; }else{
			; maxCountBuy := -1
			; maxCountSell := -1
		; }
		
		; ListThingCurrency[name] := {name:name, tradeID:tradeId, stackSize: stackSize, shiftBuy:DefaultBuyShift, shiftSell:DefaultSellShift, maxCountBuy: maxCountBuy, maxCountSell: maxCountSell, centerPrice: centerPrice, buyTradePrice:buyTradePrice, sellTradePrice:sellTradePrice}
		
		 ; return 
	; }
; }
UpdateCurrencyPrice(frac, idTrade, nameParam, currencyData)
{
	if (!frac){
		textPrice := "~skip"
	}else{
		if (frac["Denominator"] = 1)
		{
			textPrice := "~price " . frac["Numerator"] . " " . idTrade
		}else{
			textPrice := "~price " . frac["Numerator"] . "/" . frac["Denominator"] . " " . idTrade
		}
	}
	currencyData[nameParam] := textPrice
	return currencyData
}


UpdateOneDateInMemory(name, currency)
{
	global MinChaosProfit
	global MaxBigCurrency
	global MaxChaos
	global BigCurrencyPrice
	global HighBorder
	global MidBorder
	global LowBorder
	global defaultBuyShift
	global NameBigCurrency
	global startLeague		
	
	if (currency["buyTradePrice"] > 0){
		MyPriceBuy := Min(currency["buyTradePrice"], currency["centerPrice"]*(1+currency["shiftBuy"]))
	}else{
		MyPriceBuy := currency["centerPrice"]*(1+currency["shiftBuy"])		
	}
	MyPriceBuyBigCurrency := MyPriceBuy / BigCurrencyPrice
	currency["MyPriceBuy"] := MyPriceBuy
	currency["MyPriceBuyBigCurrency"] := MyPriceBuyBigCurrency
	if (currency["sellTradePrice"] > 0){
		MyPriceSell := Max(currency["sellTradePrice"], currency["centerPrice"]*(1+currency["shiftSell"]))
	}else{
		MyPriceSell := currency["centerPrice"]*(1+currency["shiftSell"])		
	}
	if (currency["centerPrice"] > BigCurrencyPrice){
		MyPriceSellBigCurrency := MyPriceSell / BigCurrencyPrice		
	}else{		
		MyPriceSellBigCurrency := MyPriceSell / (BigCurrencyPrice * (1 + defaultBuyShift) )
	}
	currency["MyPriceSellBigCurrency"] := MyPriceSellBigCurrency
	currency["MyPriceSell"] := MyPriceSell
	MinCountCurrency := MinChaosProfit / (MyPriceSell - MyPriceBuy)
	currency["MinCountCurrency"] := MinCountCurrency
	
	MaxCountByMyChaos := MaxBigCurrency * BigCurrencyPrice / MyPriceBuy
	
	
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
	if (startLeague)
		BuyFrac := GetFrac(1/MyPriceBuy, false, 1, 1, MaxBuy, MaxChaos, 1, 1)
	; AddMessage("Это должно быть всегда доступно?")
	BuyFracBigCurrency := GetFrac(1/MyPriceBuyBigCurrency, false, 1, 1, MaxBuy*3, MaxBigCurrency, 1, 1) ;Big currency i can divine by 1
	SellFrac := GetFrac(MyPriceSell, false, 1, MinCountCurrency, Min(600, MaxChaos), currency["maxCountSell"], 1, currency["stackSize"]) ; 600-max Chaos in inventorycurrency[""stackSize""]:" . currency["stackSize"])
	if (startLeague)
		SellFrac := GetFrac(MyPriceSell, false, 1, 1, Min(600, MaxChaos), currency["maxCountSell"], 1, 1) ; 600-max Chaos in inventorycurrency[""stackSize""]:" . currency["stackSize"])
	SellFracBigCurrency := GetFrac(MyPriceSellBigCurrency, false, 1, MinCountCurrency, Min(600, MaxBigCurrency), currency["maxCountSell"], 1, 1) 
	; MyPriceSellBigCurrency
	; nbf := !BuyFrac
	; nsf := !SellFrac
	; AddMessage("`n BuyFrac:" . BuyFrac . " -> " . nbf . "`n SellFrac:" . SellFrac . " -> " . nsf)
	; AddMessage("`n BuyFrac:" . BuyFrac . "`n SellFrac:" . SellFrac )
	; AddMessage("`n nbf:" . nbf . "`n nsf:" . nsf )
			
	currency:=UpdateCurrencyPrice(BuyFrac, currency["tradeID"], "PriceBuyTextChaos", currency)
	currency:=UpdateCurrencyPrice(SellFrac, "chaos", "PriceSellTextChaos", currency)
	; currency["PriceSellTextChaos"] := "~skip"
	currency:=UpdateCurrencyPrice(BuyFracBigCurrency, currency["tradeID"], "PriceBuyTextBigCurrency", currency)
	; PriceBuyTextChaos := "~price " . BuyFrac["Numerator"] . "/" . BuyFrac["Denominator"] . " " . currency["tradeID"]
	; if (!BuyFrac)
		; PriceBuyTextChaos := "~skip"
	; currency["PriceBuyTextChaos"] := PriceBuyTextChaos
	; PriceSellTextChaos := "~price " . SellFrac["Numerator"] . "/" . SellFrac["Denominator"] . " chaos"
	; currency["PriceSellTextChaos"] := PriceSellTextChaos
	; PriceBuyTextBigCurrency := "~price " . BuyFracBigCurrency["Numerator"] . "/" . BuyFracBigCurrency["Denominator"] . " " . currency["tradeID"]
	; currency["PriceBuyTextBigCurrency"] := PriceBuyTextBigCurrency
	
	AddMessage("Мы должны уметь определять tradeId в общем случае")
	tradeIdBigCurrence := "divine" 
	if (currency["centerPrice"] < BigCurrencyPrice*(1 + defaultBuyShift))
	{
		PriceSellTextBigPrice := "~price " . SellFracBigCurrency["Numerator"] . "/" . SellFracBigCurrency["Denominator"] . " " . tradeIdBigCurrence
	}else{
		PriceSellTextBigPrice := "~price " . Round(Ceil(MyPriceSellBigCurrency*10)/10, 1) . " " . tradeIdBigCurrence
	}
	currency["PriceSellTextBigPrice"] := PriceSellTextBigPrice
	
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


UpdateDataInMemory()
{
	global KalandraPrice
	global BigCurrencyPrice
	global ListThingCurrency
	global MinChaosProfit
	global MaxChaos
	global CapitalChaos
	global MaxBigCurrency
	global listPriceChaos
	global listPriceBig
	global HighBorder
	global MidBorder
	global LowBorder
	global CurrentLeague
	
	AddMessage("Loading: UpdateDataInMemory")
	
	BigCurrency := ListThingCurrency["Divine Orb"]
	BigCurrencyPrice := BigCurrency["centerPrice"]
	KalandraCurrency := ListThingCurrency["Mirror of Kalandra"]
	KalandraPrice:= KalandraCurrency["centerPrice"]
	MaxBigCurrency := Min(600, (CapitalChaos / BigCurrencyPrice) ** (2/3) )
	MaxChaos := Min(600, MaxBigCurrency * BigCurrencyPrice, CapitalChaos)
	MinChaosProfit := Ln(CapitalChaos + 1.001)
	if (CurrentLeague = "Standard")
		MinChaosProfit := Ln(MaxBigCurrency)
	
	global debuggingMessage
	debuggingMessage.Push("BigCurrencyPrice: " . BigCurrencyPrice)
	debuggingMessage.Push("MaxBigCurrency: " . MaxBigCurrency)
	debuggingMessage.Push("MaxChaos: " . MaxChaos)
	debuggingMessage.Push("MinChaosProfit: " . MinChaosProfit)
	
	ChaosMax := listPriceBig[2] * BigCurrencyPrice
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
		if (listPriceChaos[1] < (MinChaosProfit/10)){
			listPriceChaos.RemoveAt(1)
		}else{
			break
		}
	}
	
	;AddMessage("`n BigCurrencyPrice:" . BigCurrencyPrice . "`n MaxBigCurrency:" . MaxBigCurrency . "`n MaxChaos:" . MaxChaos . "`n MinChaosProfit:" . MinChaosProfit . "`n CapitalChaos:" . CapitalChaos)
	
	ListSortedByPrice := []	
	For name, currency in ListThingCurrency
	{		
		AddMessage("Loading: UpdateDataInMemory - " . name)
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

UpdateDataInMemoryTest(msg)
{
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
SaveDataToFileTest(msg)
{
	AddMessage("И просто сохранить всё, что насчитал")
	if (msg="test")
		return false
}


ListTestedFunc.Push("GetListBestTradeTest")
; Эта штука должна быть во всех моих функциях до продакшена.
GetListBestTrade()
{
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
GetListBestTradeTest(msg)
{
	AddMessage("Надо добавить функционал, который  позволит менять на лету границу покупки/продажи")
	if (msg="test")
		return false
}

MinLeftX := 20
MaxRightX := 590
MinTopY := 140
MaxBottomY := 710
DiffX := (MaxRightX - MinLeftX) / 12
DiffY := (MaxBottomY - MinTopY) / 12
AlreadySetDictionary := {}
AlreadySetDictionaryChaos := {}
AlreadySetDictionaryBigCurrency := {}

MoveNextCell()
{
	global MinLeftX
	global MaxRightX
	global MinTopY
	global MaxBottomY
	global DiffX
	global DiffY
	MouseGetPos, ttx, tty
	; AddMessage(ttx . "`n" . tty)
	ttx := ttx + DiffX
	; if (ttx < MinLeftX)
		; ttx := MinLeftX + DiffX / 2
	; if (tty > MaxBottomY)
		; tty := MaxBottomY - DiffY / 2
	if (ttx > MaxRightX)
	{
		ttx := MinLeftX + DiffX / 2
		tty := tty - DiffY			
	}
	if (tty < MinTopY)
	{
		; ttx := MinLeftX + DiffX / 2
		tty := MaxBottomY - DiffY/2			
		MouseMove,  ttx, tty
		AddMessage("Check all items - return at start")
	
		return false
	}	
	; AddMessage(ttx . "`n" . tty)
	MouseMove,  ttx, tty
	return true
}

CenterMouse()
{
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
SearchNextItem()
{	
	global AlreadySetDictionary		
	global NameBigCurrency		
	
	if (!WinActive("Path of Exile"))
		return false
	CenterMouse()
	
	Loop
	{
		if (!WinActive("Path of Exile"))
			return false
		; if (!MoveNextCell())
			; return false
		
		readItem := GetCurrentItemAtCursor()
		if (readItem == "")	
			; continue
			if (!MoveNextCell())
			{
				return false
			}else{
				continue
			}
		
		infoCur := GetInfoFromClipboard(readItem)	
		nameCur := infoCur.name
		if (nameCur = "Chaos Orb")
			return true
		if (nameCur = NameBigCurrency)
		{
			AddMessage("Skip set price on BigPrice")
			; continue
			if (!MoveNextCell())
			{
				return false
			}else{
				continue
			}
		}
		
		if (CheckAlreadySet(infoCur))
			if (!MoveNextCell())
			{
				return false
			}else{
				continue
			}
		
		if (AlreadySetDictionary.HasKey(nameCur))
			; continue
			if (!MoveNextCell())
			{
				return false
			}else{
				continue
			}	
		return true
	}
	
}
SearchNextItemTest(msg){
	if (msg="test")
		return false
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
	countUpPrice := 2
	if (CheckNameAndTypeName(infoCur, "Ancient Apex Sentinel"))
		return 44
	if (CheckNameAndTypeName(infoCur, "Ancient Pandemonium Sentinel"))
		return 33
	if (CheckNameAndTypeName(infoCur, "Ancient Stalker Sentinel"))
		return 42
		
	if (CheckNameAndTypeName(infoCur, "Cryptic Apex Sentinel"))
		return 33
	if (CheckNameAndTypeName(infoCur, "Cryptic Pandemonium Sentinel"))
		return 35
	if (CheckNameAndTypeName(infoCur, "Cryptic Stalker Sentinel"))
		return 22
		
	if (CheckNameAndTypeName(infoCur, "Primeval Apex Sentinel"))
		return 33
	if (CheckNameAndTypeName(infoCur, "Primeval Pandemonium Sentinel"))
		return 33
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
GetNewPriceRare(infoCur)
{
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
	
	; ShowMessage := ""
	; ShowMessage .= "`nName: " . infoCur.name
		
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
	
	
	; ShowMessage .= "`nSockets: " . infoCur.sockets . " -> " . countLink . "->" . summaryLinks
	; ShowMessage .= "`n" . showTiers
	; ShowMessage .= "`nLevel: " . infoCur.level . " -> " . summaryLevels
		
	summaryPrice := Max(summaryTier, summaryLinks, summaryLevels)
	firstPrice := KalandraPrice ** (summaryPrice)
	
	; ShowMessage .= "`nTestPrice = " . firstPrice
	; AddMessage(ShowMessage)
	
	return firstPrice
	
}
GetNewPriceGem(infoCur)
{
	global WantCurrency
	global GemsJSON
	global MarkupPrice	
	
	if (CheckAlreadySet(infoCur))
		return
	if (infoCur.rarity != "Gem")
		return

	WantPrice := -1
	checkLevel := infoCur.level
	
	checkQuality := infoCur.quality
	if (checkQuality<18){
		checkQuality =
	}else if (checkQuality<23){
		checkQuality := 20
	}
	; AddMessage(checkLevel . "|" . infoCur.level)
	; AddMessage(checkQuality . "|" . infoCur.quality)
	For gems, cData in GemsJSON {		
		if (infoCur.name != cData.name)
			continue
		if (checkLevel != cData.gemLevel)
		; if (infoCur.level != cData.gemLevel)
			continue
		if ((cData.HasKey("gemQuality")) && (checkQuality != cData.gemQuality))
		; if (infoCur.quality != cData.gemQuality)
			continue
		if (infoCur.corrupted = "Corrupted"){
			if (!cData.corrupted)
				continue
		}else{
			if (cData.corrupted)
				continue
		}
		WantPrice := cData.chaosValue * (1 + MarkupPrice)
		; AddMessage(cData.chaosValue . "|" . WantPrice)
		return WantPrice
	}
	return 0
}

SetNewPrice(infoCur){
	global BigCurrencyPrice
	global MinChaosProfit
	newPrice := 0
	MsgBox, 1
	if (infoCur.caption = "Item Class: Sentinel")
		newPrice:= GetNewPriceSentinel(infoCur)
	MsgBox, 2
	if (infoCur.rarity = "Gem")
		newPrice:= GetNewPriceGem(infoCur)
	MsgBox, 3
	if (newPrice = 0)
		newPrice := GetNewPriceRare(infoCur)
	MsgBox, 4
		
	if newPrice is not number
	{
		CreateNotePrice(newPrice)
		AddMessage("Set " . newPrice . " for " . infoCur.name)
		return true	
	}
	if (newPrice=0)
		return false	
	if (newPrice < MinChaosProfit)
	{
		Send ^{Click}
		AddMessage("No price lower. Sell vendor")
		return true
	}
	DefineAndPutPrice(newPrice, infoCur.name)
	; neededTailDate := A_DD . A_MM
	; currencyPriceName := "chaos"
	; if (newPrice>BigCurrencyPrice)
	; {
		; newPrice :=newPrice/BigCurrencyPrice
		; currencyPriceName := "exalted"
	; }
	; textPrice := "~price " . Round(newPrice, 1) . neededTailDate . " " . currencyPriceName
	; if (infoCur.price != textPrice)
		; CreateNotePrice(textPrice)	
	; AddMessage("Set " . textPrice . " for " . infoCur.name)
	return true
}

SetPriceForItem(infoCur){
	nameCur := infoCur.name
	priceNote := infoCur.note
	global listPriceChaos
	global CurrentLeague
	global listPriceBig
	global BigCurrencyPrice
	global NameBigCurrency
	neededTailDate := CurrentPostfix()
	
	
	if (RegExMatch(priceNote, neededTailDate)>0)
			return false
		
		AddMessage("Определение, что это за сфера и ее tradeId должны быть автоматические")
		tradeIdBigCurrence := "divine"
		
		if (RegExMatch(priceNote, "O)~(price|b/o) ([\d\.]*) (chaos|" . tradeIdBigCurrence . ")", SubPart) <= 0)
		{
			return SetNewPrice(infoCur)			 
		}
		
		oldPrice := SubPart.Value(2)
		newPrice := false
		currencyPriceName := false
		if (SubPart.Value(3) = tradeIdBigCurrence){		
			SizeLoop := listPriceBig.Length()
			Loop %SizeLoop%
			{
				checkingPrice := listPriceBig[SizeLoop + 1 - A_Index]
				if (checkingPrice < oldPrice - 0.1)
				{
					newPrice := checkingPrice
					currencyPriceName := " " . tradeIdBigCurrence
					break
				}					
			}
			oldPrice := oldPrice * BigCurrencyPrice			
		}
		
		if (!newPrice)
		{	
			SizeLoop := listPriceChaos.Length()
			Loop %SizeLoop%
			{
				checkingPrice := listPriceChaos[SizeLoop + 1 - A_Index]
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
		
		if (CurrentLeague = "Standard"){
			prefix := "~b/o "
		}else{
			prefix := "~price "
		}
		
		textPrice := prefix . Round(newPrice, 1) . neededTailDate . currencyPriceName
		; AddMessage("Need set new price")
		AddMessage("Set " . textPrice . " for " . nameCur)
		if (infoCur.note != textPrice)
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
		note := infoCur.note
		caption := infoCur.caption
		count := infoCur.count
		
		if ((RegExMatch(note, "~skip")>0) || (RegExMatch(note, "000")>0))
			if (MoveNextCell()){
				continue
			}else{
				return
			}
		
		if (nameCur = "Chaos Orb"){		
			if (AlreadySetDictionaryChaos.HasKey(priceNote))		
				if (MoveNextCell()){
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
				MoveNextCell()
				
				return
			}			
		}
		
		if (note = "Scroll Fragment"){
			Prices := ListThingCurrency[note]
			textPriceChaos := Prices["PriceSellTextChaos"]
			textPriceBigCurrency := Prices["PriceSellTextBigPrice"]
			AddMessage(note . " " . textPriceChaos . "; " . textPriceBigCurrency)
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
			if ((count * Prices["MyPriceSellBigCurrency"]) > 1.1){
				textPrice := Prices["PriceSellTextBigPrice"]
			}else{
				textPrice := Prices["PriceSellTextChaos"]
			}
			; AlreadySetDictionary[nameCur] := textPrice
			if (note == textPrice){
				continue
			}
			CreateNotePrice(textPrice)	
			AddMessage(nameCur . " " . textPrice)	
			return
		}
		
		if (SetPriceForItem(infoCur)){							
			MoveNextCell()
			return
		}else{						
			if (!MoveNextCell())
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

ListTestedFunc.Push("SetSinglePriceTest")
; Эта штука должна быть во всех моих функциях до продакшена.
SetSinglePrice(){
	global sellPriceGlobalForChaos
	global sellPriceGlobalForBigCurrency
	global ListThingCurrency
	global NameBigCurrency
	if (!WinActive("Path of Exile"))
		return
		
	CenterMouse()
	
	readItem := GetCurrentItemAtCursor()
	if (readItem = "")
		return
	
	infoCur := GetInfoFromClipboard(readItem)	
	nameCur := infoCur.name
	previousNote := infoCur.note
	
	if (nameCur = NameBigCurrency){
		if (sellPriceGlobalForBigCurrency == previousNote)
		{
			AddMessage("Already seted:" . sellPriceGlobalForBigCurrency . "|" . previousNote)
		}else{
			CreateNotePrice(sellPriceGlobalForBigCurrency)
		}
		return
	}
	if (nameCur = "Chaos Orb"){
	; 	ToolTip, %sellPriceGlobalChaos%, 0, 0
		if (sellPriceGlobalForChaos = previousNote)
		{
			AddMessage("Already seted:" . sellPriceGlobalForChaos . "|" . previousNote)
		}else{
			CreateNotePrice(sellPriceGlobalForChaos)
		}
		return
	}
	if (nameCur = "Scroll Fragment"){
		nameCur := infoCur.note
	}
	Prices := ListThingCurrency[nameCur]
	sellPriceGlobalForChaos := Prices["PriceBuyTextChaos"]
	sellPriceGlobalForBigCurrency := Prices["PriceBuyTextBigCurrency"]
	AddMessage(nameCur . " " . sellPriceGlobalForChaos . "; " . sellPriceGlobalForBigCurrency)
}
SetSinglePriceTest(msg){
	if (msg="test")
		return false
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
	global NameBigCurrency
	if (!WinActive("Path of Exile"))
		return
	
	readItem := GetCurrentItemAtCursor()
	if (readItem = "")
		return
	infoCur := GetInfoFromClipboard(readItem)	
	nameCur := infoCur.name
	AddMessage(nameCur)
	if ((nameCur == "Chaos Orb") || (nameCur == NameBigCurrency))
	{		
		priceNote := infoCur.price
		AddMessage(priceNote)
		nameCur := SearchNameByTradeId(priceNote)
	}
	if (nameCur == "Scroll Fragment")
	{
		nameCur := infoCur.price		
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
	Prices := ListThingCurrency[infoCur.name]
	CenterPriceThatStack :=  Prices.centerPrice * infoCur.count
	MyPriceThatStack := Prices.MyPriceBuy * infoCur.count
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
	
	message := "Currency: " . Ceil(summMassBuy.currency * discountBuyCurrency) . "`nNoCurrency: " . Ceil(summMassBuy.noCurrency * discountBuyNoCurrency) . "`nEquipItem: " . Ceil(summMassBuy.equipItem * discountBuyEquip) . "`nMyPrice: " . Ceil(summMassBuy.tradeBuy) 
	AddMessage(message)
}
ShowMassBuyTest(msg){
	if (msg="test")
		return false
}

CheckAlreadySet(data){
	needle := CurrentPostfix()
	if (RegExMatch(data.negotiablePrice, needle)>0)
		return true
	if (RegExMatch(data.exactPrice, needle)>0)
		return true
	return false
}

ListTestedFunc.Push("TemplateFunctionTest")
; Эта штука должна быть во всех моих функциях до продакшена.
Test(){
	if (!WinActive("Path of Exile"))
		return
	SoundBeep
}
TestTest(msg){
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
UpdateDataInMemory()
SaveDataToFile()


GetListBestTrade()

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
AddMessage("Торговля: Запоминать, где по координатам и вкладкам находятся мои нужные ресурсы, чтобы сразу с них набирать нужное количество.")
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
AddMessage("Торговля: Посчитать бы - как самое выгодное получать линзу опыта?")
AddMessage("Торговля: Сдвигать цены по разному - для чёткой цены и обсуждаемой(asking price) - по 10%")
AddMessage("Торговля: Сдвиги цен на закупку и продажу должны быть разными для хаосов и для вышек")
AddMessage("Торговля: Переходы валют через вендора - также надо учесть, ибо часто есть выгодные")
AddMessage("Торговля: Определять цены не только стандартные - хаосы, вышки, диваны и т.д., а любые")
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
AddMessage("Оценка: У Туджина скупка - оценивать, насколько хаоса и что здесь самое выгодное? Как-то работать с разными артефактами от него.")
AddMessage("Оценка: Свми журналы экспедиции тоже надо юы оценивать")
AddMessage("Используй уже готовые БД - где их взять?")
AddMessage("Показывать цену без установки")
AddMessage("Настройка активных клавиш")
AddMessage("Крафт: Какие камни выгодно качать")
AddMessage("Крафт: Какие камни выгодно ваалить")
AddMessage("Крафт: Какие veiled моды - хороши?")
AddMessage("Крафт: Учти, что есть рецепт на окрыление скарабеев - пользуйся им для повышения цен на своих")
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
AddMessage("Крафт: Контроль крафта - проверки свойств, какие продаются")
AddMessage("Ободранные с пустыми trade id - их надо пропускать?")
AddMessage("Осколки почему-то без trade id")
AddMessage("Записи с листа: массовое торговое - кнопка для автораздачи")
AddMessage("Записи с листа: регулярка для свойств карт, чтобы более компактно проверять карту")
AddMessage("Записи с листа: Ставим в незнакомое, пробуем установить, если получилось - сдвинься и поменяй текст.")
AddMessage("Записи с листа: Дошли до правого края - иди слева. Если вышло за край снизу - сверху и останавливайся.")
AddMessage("Записи с листа: Запоминай - кого уже записал и это больше не ставит")
AddMessage("Записи с листа: Автооценка по Tier и парам свойств")
AddMessage("Записи с листа: Автооценка уников с колебанием цен от произведения свойств")
AddMessage("Записи с листа: Скрипт для ускорения перекладки всякого в гильдейку и при конце лиги")
AddMessage("Записи с листа: Закупка дорогих гадалок")
AddMessage("Записи с листа: Учёт медианы изменений в POE")
AddMessage("Записи с листа: Скупка витриной Exalt - теперь через божественные сферы")
AddMessage("Записи с листа: Пропускай skip")
AddMessage("Записи с листа: Проверь, что скарабеи меняются 3 к 1 и учти в ценах")
AddMessage("Записи с листа: Ставь цену за хаос или за вышки, если вторая skip - иначе полный skip")
AddMessage("Записи с листа: Автоматизировать поиск, что сейчас с ценами, что сменить и как определить, что надо перекрафтить")
AddMessage("Записи с листа: Если цена дальше 1/(max+1) - ставь skip")
AddMessage("Записи с листа: Скрипт, сравнивающий POB и данные сайта, выводит на экран чего не хватает")
AddMessage("Записи с листа: Можно снимать данные с секстантов и сравнивать с https://github.com/The-Forbidden-Trove/tft-data-prices/blob/master/lsc/bulk-compasses.json - если выгодно, то компасить?")
AddMessage("Записи с листа: Компасы проверять на адекватность")
AddMessage("Записи с листа: Клавиши вне PoE надо передавать дальше")
AddMessage("Записи с листа: Карты проверять на линейное - массовое, лутовое и свойства")
AddMessage("Ошибки: у части выдаёт /")
AddMessage("Ошибки: у части нет id'шного торгового")
AddMessage("Ошибки: смена макс. количества")
AddMessage("Ошибки: смена края цен")
AddMessage("Ошибки: сдвиг цены не сохранился")
AddMessage("Ошибки: писать, когда выгоды мало в продаже")
AddMessage("Ошибки: искать, каких вещей у меня нет в тайниках")
AddMessage("Ошибки: Заряженные компасы в закупке - пропускать")
AddMessage("Ошибки: Заряженные компасы и пойманные звери - это не валюта, а предметы")
AddMessage("Ошибки: Компасы на покупку не больше 1-го хаоса(у Кирака так можно купить)")
AddMessage("Ошибки: Почему-то моя цена за детали доспеха запредельная")
AddMessage("Ошибки: Отлавливать бы - все ли слоты под камни у меня заняты? Чтобы прокачивать.")
AddMessage("Ошибки: Закупка разных пар")
AddMessage("Ошибки: Всякие пары автоматизированы")
AddMessage("Ошибки: Автоматизация обмена карт")
AddMessage("Ошибки: Автоматизация перекладывания в сундук в продажу и так далее")
AddMessage("Ошибки: Автоматизация вскрытия колоды")
AddMessage("Код: работать надо над ценами и запрашиваемыми ценами - чтоб пользоваться уже пропарсенным")
AddMessage("Код: Добавить считывание skip и причины(после skip)")
AddMessage("Код: Выставлять цены на стандарте раз в неделю, а не раз в день")
AddMessage("Код: По переменной стандарт/лига определять какую пишем цену- price или b/o")
AddMessage("Код: самостоятельно определить список желаемых валют(их мало, и до 10 штук равномерно распределных? Только валюты?)")
AddMessage("Код: Загрузка медленных частей должна быть фоном")
AddMessage("Код: Сообщение о том, что дозагружаются данные")
AddMessage("Торговля: Попарные торговли для валют")
AddMessage("Оценка: Пропускай и пищи со свйоствами без тиров")
AddMessage("Оценка: Кластерные самоцветы надо оценивать иначе")
AddMessage("Оценка: В варианте с базами надо учесть разные implicit - по типу разные")
AddMessage("Оценка: Добавить вокруг Фиббоначи некоторую рандомность")
AddMessage("QoL: Очищать весь поток сообщений по кнопке")
AddMessage("Торговля: Цена по F3 - первое по отношению ко второму)")
AddMessage("Код времянка: BuyFrac := GetFrac(1/MyPriceBuy, false, 1, 1, MaxBuy, MaxChaos, 1, 1)")
AddMessage("Код времянка: Учесть, что часть масел дешевле экстрактить, чем продать")
AddMessage("Код времянка: Вход и выход из убежки должен ставить autoreply, что в бою и будете ли меня ждать?")

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
	global BigCurrencyPrice
	temp := Ceil(wantSellPrice*10/BigCurrencyPrice)
	big := Floor(temp/10)
	small := temp-big*10
	res = %big%.%small%
	return res
}
*/

!F2::
	wasCenter := !wasCenter
	if (wasCenter){
		AddMessage("Теперь центрируем")
	}else{
		AddMessage("Теперь не центрируем")
	}
return

F2::
	MassSetPrice()
return

F3::
	SetSinglePrice()
return

^F2::
	AskAndChangeParam("Set new maximum buy", "maxCountBuy")
return 

+F2::
	AskAndChangeParam("Set new offset buy", "shiftBuy")
return 

; ^+F2::	"":"-0.2","":"-0.01"
; 	; AskAndChangeParam("Set new maximum offset", "MyPriceBuy")
	; SetNewStackBuy()
; 	AddMessage("Сохранять данные каждый раз и пересчитывать для этого параметра")
; return 

^F3::
	AskAndChangeParam("Set new maximum sell", "maxCountSell")
return 

+F3::
	AskAndChangeParam("Set new offset sell", "shiftSell")
return

; ^+F3::
; 	SetNewStackSell()
; 	AddMessage("Сохранять данные каждый раз и пересчитывать для этого параметра")	
; return
	
^F4::
	ShowMassBuy()
return

+F4::
	CleanMassBuy()
return

F4::
	AddMassBuy()
return

^+F1::
	For kdebuggingMessage, vdebuggingMessage in debuggingMessage
		AddMessage(vdebuggingMessage)
return

`::
	Test()
return

\::
	if (!WinActive("Path of Exile"))
	{
		Send /
		return
	}
	Send ^{Click}
return