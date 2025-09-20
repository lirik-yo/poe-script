run := false

`::
	run := not run
	SetTimer, CC, 400
return

CC:
	if (not(run))
		return
	Loop 5
	{
		Send {Click 3}  ; Auto-repeat consists of consecutive down-events (with no up-events).
		Sleep 100  ; The number of milliseconds between keystrokes (or use SetKeyDelay).
	}
return ;