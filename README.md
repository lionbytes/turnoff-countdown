# Turnoff Countdown

Session Timer is a Windows batch script that lets you set a time limit on a work or play session. When the timer expires, it can automatically kill one or more running programs, shut down your PC, or restart it.  

A popup warning appears at the 10-minute mark so you're never caught off guard. The countdown is displayed live in the terminal window, but the actual timer runs as a background VBScript process — so closing the terminal won't cancel it.  

### Features:
- Set any session length over 10 minutes
- Choose what happens at the end: terminate program(s), shut down, or restart
- Terminate multiple `.exe` processes at once by entering them as a comma-separated list
- 10-minute warning popup before the action fires
- Background timer survives terminal closure
- Reports which processes were killed and which were already closed

### Usage:

1. Run `turnoff-countdown.bat` or `turnoff-countdown.exe` as a normal user (no admin rights required for process termination of user-owned apps; shutdown/restart may prompt UAC)
2. Enter the session length in minutes
3. Choose an end action and follow the prompts
4. The countdown starts — you can close the terminal freely

Requirements: Windows with `wscript.exe` available (standard on all modern Windows installs)
