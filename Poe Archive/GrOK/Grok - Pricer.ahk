; ============================================================
; PoE Minimal Pricer — MVP November 2025
; Один файл, одна клавиша Ctrl+C → огромная цифра цены в chaos
; Работает в Affliction 3.24 на редких оружии/броне/щите/перчатках и т.д.
; Автор: мы с тобой вместе за 1 вечер =)
; ============================================================

#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SetBatchLines -1

; Горячая клавиша — Ctrl+C на предмете в игре
`::
    Clipboard := ""
    Send ^c
    ClipWait, 1
    if (Clipboard = "") {
        Tooltip, Нет предмета в буфере, 960, 540, 1
        SetTimer, RemoveTooltip, -1500
        return
    }

    price := CalculatePrice(Clipboard)

    if (price = 0)
        priceText := "< 10 chaos"
    else if (price < 30)
        priceText := "≈ " price " chaos"
    else
        priceText := "≈ " price " chaos!"

    ; Большая зелёная надпись посередине экрана
    Gui, +LastFound +AlwaysOnTop -Caption +ToolWindow +E0x20
    Gui, Color, 000000
    Gui, Margin, 0, 0
    Gui, Font, s72 bold cLime, Arial Black
    Gui, Add, Text, Center BackgroundTrans, %priceText%
    Gui, Show, Center NoActivate

    ; Звук «динь!» если цена вкусная
    if (price >= 100)
        SoundPlay, *-1

	Sleep 70
	Send {Blind}{Ctrl down}
	Sleep 70
	Send {Click}	
	Sleep 70
	Send {Blind}{Ctrl up}
	Sleep 270 
	Send %price%
	Sleep 170 
	Send {Enter}	
	
    ; Sleep, 200
    Gui, Destroy
return

RemoveTooltip:
    Tooltip
return

; ============================================================
CalculatePrice(itemText) {
    price := 1  ; базовая цена редкого предмета

    ; +life
    if RegExMatch(itemText, "\+([0-9]+) to maximum Life", m)
        life := m1
        if (life >= 100) {
			price += 40
		} else if (life >= 80) {
			price += 22
		} else if (life >= 60) {
			price += 10
		} else if (life >= 40) {
			price += 4
		}

    ; % increased Physical Damage
    if RegExMatch(itemText, "(\d+)% increased Physical Damage", m) && InStr(itemText, "Weapon")
        price += Round(m1 / 4)

    ; Attack Speed / Cast Speed
    if RegExMatch(itemText, "(\d+)% increased Attack Speed", m)
        price += Round(m1 * 3.2)
    if RegExMatch(itemText, "(\d+)% increased Cast Speed", m)
        price += Round(m1 * 2.8)

    ; +1 to Level of all Gems / Spell / Physical и т.д.
    if InStr(itemText, "+1 to Level of all ")
        price += 60
    if InStr(itemText, "+1 to Level of Socketed Gems")
        price += 35

    ; Добавленный элементальный дамаг (T1–T2)
    if RegExMatch(itemText, "Adds (\d+) to (\d+) Fire Damage", m1)
        if (m2 >= 100) {
			price += 35
		}
        else if (m2 >= 70) {
			price += 18
		}
    if RegExMatch(itemText, "Adds (\d+) to (\d+) Cold Damage", m1)
        if (m2 >= 100) {
			price += 32
		}
        else if (m2 >= 70) {
			price += 16
		}
    if RegExMatch(itemText, "Adds (\d+) to (\d+) Lightning Damage", m1)
        if (m2 >= 120) {
			price += 45
		}
        else if (m2 >= 80) {
			price += 22
		}

    ; % increased Spell Damage
    if RegExMatch(itemText, "(\d+)% increased Spell Damage", m)
        price += Round(m1 * 0.7)

    ; Криты
    if RegExMatch(itemText, "\+(\d+)% to Critical Strike Multiplier", m)
        price += Round(m1 * 1.1)

    ; Тотал резисты
    if RegExMatch(itemText, "\+(\d+)% to all Elemental Resistances", m)
        price += Round(m1 * 0.6)

    ; Миньоны (Convoking Wand и т.п.)
    if InStr(itemText, "Minions deal") && InStr(itemText, "increased Damage")
        price += 30

    ; Немного бонуса за высокий ilvl (просто чтобы не было 5 chaos на 86+)
    if RegExMatch(itemText, "Item Level: (\d+)", m)
        if (m1 >= 83)
            price += 12

    ; ; Округляем и чуть «приукрашиваем» — психологически приятнее видеть круглые цифры
    ; price := Round(price / 5) * 5
    ; if (price < 10)
        ; price := 0  ; мусор

	

    return price
}
; ============================================================

; Esc::ExitApp  ; Esc — выход из скрипта