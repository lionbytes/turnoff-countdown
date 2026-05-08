::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAjk
::fBw5plQjdCqDJGmW+0g1Kw98cCODMW6pOoov4P3v6+WQrA0pXe86arPS2buAbeEA/kD2fIUmmHNZl6s=
::YAwzuBVtJxjWCl3EqQJgSA==
::ZR4luwNxJguZRRnk
::Yhs/ulQjdF+5
::cxAkpRVqdFKZSDk=
::cBs/ulQjdF+5
::ZR41oxFsdFKZSDk=
::eBoioBt6dFKZSDk=
::cRo6pxp7LAbNWATEpCI=
::egkzugNsPRvcWATEpCI=
::dAsiuh18IRvcCxnZtBJQ
::cRYluBh/LU+EWAnk
::YxY4rhs+aU+JeA==
::cxY6rQJ7JhzQF1fEqQJQ
::ZQ05rAF9IBncCkqN+0xwdVs0
::ZQ05rAF9IAHYFVzEqQJQ
::eg0/rx1wNQPfEVWB+kM9LVsJDGQ=
::fBEirQZwNQPfEVWB+kM9LVsJDGQ=
::cRolqwZ3JBvQF1fEqQJQ
::dhA7uBVwLU+EWDk=
::YQ03rBFzNR3SWATElA==
::dhAmsQZ3MwfNWATElA==
::ZQ0/vhVqMQ3MEVWAtB9wSA==
::Zg8zqx1/OA3MEVWAtB9wSA==
::dhA7pRFwIByZRRnk
::Zh4grVQjdCyDJGyX8VAjFDlVXwyDLleeA6YX/Ofr0/6Or0gPGucnfe8=
::YB416Ek+ZG8=
::
::
::978f952a14a936cc963da21a135fa983
@echo off
setlocal enabledelayedexpansion
title Session Timer
color 4F

echo ============================================
echo              SESSION TIMER
echo ============================================
echo.

:: Ask for time in minutes
set /p minutes="Enter session length in minutes: "

:: Validate input is a number
echo %minutes%| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo ERROR: Please enter a valid number.
    pause
    exit /b
)

:: Must be more than 10 minutes for the warning to make sense
if %minutes% LEQ 10 (
    echo ERROR: Session must be longer than 10 minutes.
    pause
    exit /b
)

:: Ask what action to take when time is up
echo.
echo What should happen when the session ends?
echo.
echo   1. Terminate program(s) (.exe)
echo   2. Shut down the PC
echo   3. Restart the PC
echo.
set /p action="Enter choice (1, 2 or 3): "

if "%action%"=="1" goto ask_exe
if "%action%"=="2" goto confirm
if "%action%"=="3" goto confirm

echo ERROR: Invalid choice. Please enter 1, 2 or 3.
pause
exit /b

:ask_exe
echo.
echo Enter one or more .exe names separated by commas.
echo Examples: chrome.exe, firefox.exe, vlc.exe
echo.
set /p target_raw="Enter .exe name(s) to terminate when time is up: "

set "target_display="
set exe_count=0
set "parse_input=%target_raw%"

:parse_loop
for /f "tokens=1* delims=," %%A in ("!parse_input!") do (
    set "token=%%A"
    for /f "tokens=* delims= " %%T in ("!token!") do set "token=%%T"
    for /l %%i in (1,1,10) do if "!token:~-1!"==" " set "token=!token:~0,-1!"

    if not "!token!"=="" (
        set /a exe_count+=1
        set "exe_!exe_count!=!token!"
        if "!target_display!"=="" (
            set "target_display=!token!"
        ) else (
            set "target_display=!target_display!, !token!"
        )
    )
    set "parse_input=%%B"
    if not "%%B"=="" goto parse_loop
)

if %exe_count%==0 (
    echo ERROR: No valid .exe names entered.
    pause
    exit /b
)

goto confirm

:confirm
echo.
echo ============================================
if "%action%"=="1" echo  Action         : Terminate %target_display%
if "%action%"=="2" echo  Action         : Shut down PC
if "%action%"=="3" echo  Action         : Restart PC
echo  Session length : %minutes% minute(s)
echo  Warning at     : 10 minutes remaining
echo ============================================
echo.
set /p confirm="Start timer? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Timer cancelled.
    pause
    exit /b
)

:: Calculate milliseconds
set /a warn_ms=(%minutes% - 10) * 60 * 1000
set /a final_ms=10 * 60 * 1000

:: Build a pipe-delimited exe list to pass cleanly as a single VBScript argument.
:: Pipes are safe here — they never appear in .exe names — and the whole thing
:: is double-quoted on the command line so batch won't misinterpret the pipe.
set "exe_arg="
if "%action%"=="1" (
    for /l %%i in (1,1,%exe_count%) do (
        if "!exe_arg!"=="" (
            set "exe_arg=!exe_%%i!"
        ) else (
            set "exe_arg=!exe_arg!|!exe_%%i!"
        )
    )
)

:: -------------------------------------------------------
:: Write a SINGLE static VBScript template.
:: All variable data is passed in as WScript.Arguments so
:: we never need to embed quotes or dynamic values inside
:: the echo statements — which is what broke things before.
::
:: Arguments: warn_ms  final_ms  action  exe_list
:: -------------------------------------------------------
set "vbs=%TEMP%\session_timer_%RANDOM%.vbs"

(
echo Dim wMs, fMs, act, exeArg, warnMsg
echo wMs    = CLng^(WScript.Arguments^(0^)^)
echo fMs    = CLng^(WScript.Arguments^(1^)^)
echo act    = WScript.Arguments^(2^)
echo exeArg = WScript.Arguments^(3^)
echo.
echo Select Case act
echo     Case "1" : warnMsg = "10 minutes remaining! " ^& exeArg ^& " will be terminated soon."
echo     Case "2" : warnMsg = "10 minutes remaining! Your PC will shut down soon."
echo     Case "3" : warnMsg = "10 minutes remaining! Your PC will restart soon."
echo End Select
echo.
echo WScript.Sleep wMs
echo MsgBox warnMsg, 48, "Session Timer"
echo WScript.Sleep fMs
echo.
echo Select Case act
echo.
echo     Case "1"
echo         Dim objWMI, colProc, proc, exeList, exeName
echo         Dim totalKilled, notFound, k
echo         totalKilled = 0
echo         notFound = ""
echo         exeList = Split^(exeArg, "|"^)
echo         Set objWMI = GetObject^("winmgmts:\\.\root\cimv2"^)
echo         For Each exeName In exeList
echo             k = 0
echo             Set colProc = objWMI.ExecQuery^("SELECT * FROM Win32_Process WHERE Name='" ^& exeName ^& "'"^)
echo             For Each proc In colProc
echo                 proc.Terminate
echo                 k = k + 1
echo                 totalKilled = totalKilled + 1
echo             Next
echo             If k = 0 Then
echo                 If notFound = "" Then
echo                     notFound = exeName
echo                 Else
echo                     notFound = notFound ^& ", " ^& exeName
echo                 End If
echo             End If
echo         Next
echo         Dim doneMsg
echo         If totalKilled ^> 0 And notFound = "" Then
echo             doneMsg = "Time's up! All specified program(s) have been terminated."
echo         ElseIf totalKilled ^> 0 Then
echo             doneMsg = "Time's up! Some program(s) terminated." ^& vbCrLf ^& "Not found (already closed?): " ^& notFound
echo         Else
echo             doneMsg = "Time's up! None of the specified program(s) were found - they may already be closed."
echo         End If
echo         MsgBox doneMsg, 16, "Session Timer"
echo.
echo     Case "2"
echo         MsgBox "Time's up! Your PC will now shut down.", 16, "Session Timer"
echo         CreateObject^("WScript.Shell"^).Run "shutdown /s /t 0"
echo.
echo     Case "3"
echo         MsgBox "Time's up! Your PC will now restart.", 16, "Session Timer"
echo         CreateObject^("WScript.Shell"^).Run "shutdown /r /t 0"
echo.
echo End Select
echo.
echo Set fso = CreateObject^("Scripting.FileSystemObject"^)
echo fso.DeleteFile WScript.ScriptFullName
) > "%vbs%"

:: Launch the VBScript silently with all data passed as arguments.
:: Because this is a single unconditional write + launch, there are no
:: nested if/redirect conflicts that could silently corrupt the .vbs file.
start "" wscript.exe "%vbs%" %warn_ms% %final_ms% "%action%" "%exe_arg%"

:: -------------------------------------------------------
:: Countdown display — purely visual, closing this window
:: does NOT affect the background timer in any way.
:: -------------------------------------------------------
set /a total_secs=%minutes% * 60

for /l %%i in (%total_secs%, -1, 0) do (
    set /a mm=%%i / 60
    set /a ss=%%i %% 60

    if !ss! LSS 10 (set "ss_fmt=0!ss!") else (set "ss_fmt=!ss!")

    cls
    echo ============================================
    echo              SESSION TIMER
    echo ============================================
    echo.
    if "%action%"=="1" echo  Action  : Terminate %target_display%
    if "%action%"=="2" echo  Action  : Shut down PC
    if "%action%"=="3" echo  Action  : Restart PC
    echo.
    echo  Time remaining : !mm!:!ss_fmt!
    echo.
    if %%i==600 echo  [ 10-minute warning popup will appear shortly ]
    echo ============================================
    echo.
    echo  Closing this window will NOT stop the timer.
    echo.

    if %%i==0 goto done
    timeout /t 1 /nobreak >nul
)

:done
echo  Session complete.
echo.
pause
