#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\Pictures\330px-Infinite.svg.ico
#AutoIt3Wrapper_Outfile=DCSI.exe
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Comment=DCS Infinnity is a server monitor for use specifically with DAWS persistence and Autostarting servers
#AutoIt3Wrapper_Res_Fileversion=1.0.0.2
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; v1.0 October 22th 2016, thebgpikester@hotmail.com, use any, all of the below however you like
; DCS Infinity is an Autoit script that  helps server administrators run a persistent server using Ciribob's dedicated server script changes and the DAWS package by Chromium.
; it launches DCS live (not working with alpha or beta) if not running, launches DCS and watches how long it has been running. Autostop and start. It then copies and timestamps individual files
; and configures to launch the latest save on startup. It cleans up excessive save games.
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <WinAPIFiles.au3>
#include <File.au3>
#include <Date.au3>

;declare things
local $dcspath = RegRead("HKCU\SOFTWARE\Eagle Dynamics\DCS World", "Path") ;for running wherever your DCS main is located
local $dcs = $dcspath&"\bin\DCS_updater.exe"
local $DCSfolder = @UserProfileDir&"\Saved Games\DCS\"
local $Filepathorig = $DCSfolder&"Missions\DAWS_AutoSave.miz"
local $Filepathnew = $DCSfolder&"Missions\Persistent\"
local $serversettings = $DCSfolder&"Config\ServerSettings.lua"
local $log = $DCSfolder&"Missions\Persistent\persistence.log"

;open the log
Global $hFileOpen = FileOpen($log, 9)
    If $hFileOpen = -1 Then
        MsgBox($MB_SYSTEMMODAL, "", "Cannot open the logfile, permissions?.",5)
        Exit
    EndIf

;write or read the ini file if its not there.Defaults shown
if FileExists ($Filepathnew & "\persistence.ini") Then
	Local $checkinterval = IniRead($Filepathnew & "persistence.ini", "General", "CheckInterval", "10000")
	Global $DCStimeCheck = IniRead($Filepathnew & "persistence.ini", "General", "Restarthours", "4")
Else
	IniWrite($Filepathnew & "persistence.ini", "General", "Milliseconds between checking for a new save", "10000")
	IniWrite($Filepathnew & "persistence.ini", "General", "Restart DCS these hours", "3")
EndIf

;kick off the logging
FileWrite($hFileOpen, @YEAR &" " & @MON & "-" & @MDAY & "-" & @HOUR &":"& @MIN & ":" & @SEC & " Program launch" & @CRLF)

While 1 ;main program loop

if ProcessExists ("DCS.exe") Then

Else
	FileWrite($hFileOpen, @YEAR &" " & @MON & "-" & @MDAY & "-" & @HOUR &":"& @MIN & ":" & @SEC & " DCS was not running, starting process." & @CRLF)
	Run($dcs) ; launch it first time most likely
	Sleep(1000) ; 1 second delay since the launcher launches first. On an update this might be problematic
EndIf

while ProcessExists ( "DCS.exe" ) ; only do this if the program is running
Local $checkinterval = IniRead($Filepathnew & "persistence.ini", "General", "Milliseconds between checking for a new save", "10000") ; we can change this on the fly
Global $DCStimeCheck = IniRead($Filepathnew & "persistence.ini", "General", "Restart DCS these hours", "3"); we can change this on the fly, 3 means every four hours as the hours are reported as a single number
$datestamp = @MON&"-"&@MDAY&"-"&@HOUR&@MIN
$missionname = "Persist-"&$datestamp&".miz"
$text = '        [1] = "'&@HomeDrive&'\\Users\\'&@UserName&'\\Saved Games\\DCS\\Missions\\Persistent\\'&$missionname&'",' ;debugging this line, really tricky due to the \\ doubles - windows vista or later
;MsgBox(0,"",$text) ; for debugging
if FileExists($Filepathorig) Then ; check for an autosave else continue to the sleep interval
	cleanup();sends the existing files to Recyclebin
	sleep(3000);added due to a crash after restart
	FileMove($Filepathorig, $Filepathnew&$missionname, 9) ; move and rename the file in one
	sleep(1000) ; waits here for write latency
	_FileWriteToLine ($serversettings, 6, $text, True) ;edits the serversettings.lua line 1
	sleep(1000); waits here for write latency
	FileWrite($hFileOpen, @YEAR &" " & @MON & "-" & @MDAY & "-" & @HOUR &":"& @MIN & ":" & @SEC & "New save: " & $text & @CRLF)
EndIf
ProcessMon() ; checks the DCS process run time for the time check - whole hours only in the ini file
sleep($checkinterval);wait the checking interval in the ini
WEnd

sleep(10000) ;Check if DCS is running every 10 seconds.
WEnd

Func ProcessMon() ;

$process = "'DCS.exe'"
$timeup = $DCStimeCheck
$wbemFlagReturnImmediately = 0x10
$wbemFlagForwardOnly = 0x20
$colItems = ""
$strComputer = "localhost"
$objWMIService = ObjGet("winmgmts:\\" & $strComputer & "\root\CIMV2")
$colItems = $objWMIService.ExecQuery("SELECT * FROM Win32_Process Where NAME = " & $process &"", "WQL", $wbemFlagReturnImmediately + $wbemFlagForwardOnly)


If IsObj($colItems) then
   For $objItem In $colItems
      $time = WMIDateStringToDate($objItem.CreationDate)
      $PID = $objItem.ProcessId
      $Starttime = StringRight($time, 8)
      ;Msgbox(1,"WMI Outputime",$time)
      $Date = StringTrimRight($time, 9)
      ;Msgbox(1,"WMI Outputdate",$pid)
      $array = StringSplit($date, '/', 1)
      $FixDate = $array[3] & '/' & $array[1] &'/' & $array[2] & ' ' & $Starttime
       ;Msgbox(1,"WMI fixdate",$FixDate)
      $iDateCalc = _DateDiff( 'h',$FixDate,_NowCalc())
      ;Msgbox(1,"nowcalc",$iDateCalc)
      if $iDateCalc > $timeup then
         ProcessClose($PID) ; this part should kill DCS
		 FileWrite($hFileOpen, "DCS has been running for: " & $iDateCalc & " hours and will now be terminated" & @CRLF)

      EndIf

       Next
Else
   ;Msgbox(0,"WMI Output","No WMI Objects Found for class: " & "Win32_Process" )
   FileWrite($hFileOpen, "No WMI Objects Found for class" & @CRLF)
Endif
  $time =""
  $PID=""

EndFunc

Func WMIDateStringToDate($dtmDate)

    Return (StringMid($dtmDate, 5, 2) & "/" & _
    StringMid($dtmDate, 7, 2) & "/" & StringLeft($dtmDate, 4) _
    & " " & StringMid($dtmDate, 9, 2) & ":" & StringMid($dtmDate, 11, 2) & ":" & StringMid($dtmDate,13, 2))
EndFunc

Func cleanup()

Local $FileList = _FileListToArray($Filepathnew, "*.miz", 1, True)
For $i = 1 To Ubound($FileList) -1
            FileRecycle($FileList[$i])
Next
EndFunc