# DCSI v1.0
DCS infinity, an autoit script to manage DAWS persistent campaigns/long missions on servers.
The compiled code is also available to the .au3. To compile the AU3 download Autoit from https://www.autoitscript.com/site/autoit-script-editor/downloads/ 

The script is specifically targetting dedicated server administrators who can autostart their servers using Ciribobs dedicated server script and who wish to use Chromium's DAWS persistent server to save their game. It can then persist a single mission through restarts without any further action. It works by setting the last save game to the 1st named autostart mission. It also tidies the saved games by deleting them, checks DCS is running and restarts DCS at a customisable hour number.

PREREQUISITES
1. DAWS save game https://forums.eagle.ru/showthread.php?t=149899
2. Dedicated server script from Ciribob. https://forums.eagle.ru/showthread.php?t=160829 This script assumes you use it, it has less use without it but is not completely pointless.
3. A server, mission you might need to save etc.

INSTALLATION
DCSI requires to be run as administrator. I suggest putting it into your startup so it will launch DCS when the server restarts. You can optionally set your server to shut down and restart using windows scheduled tasks.

Configure DAWS to autosave. Do not configure DAWS to save to a different directory, by default it picks your missions folder. DCSI needs to use your saved games/DCS/Missions folder and watch for DAWS autosaves here. Do not change the default save name, DCSI is looking for a file called DAWS_AutoSave.miz. It is strongly advised to delete your mission list before starting (serversettings.lua or use the GUI)

NORMAL USE
DCSI creates a folder called "Persistent" under your missions directory. In the mission directory itself it creates a persistence.log and an ini file with two settings that you can change at any time. One setting changes the interval on which the app checks for a new save file, the other the interval in hours, plus one, before it will kill and restart DCS. If for some reason DAWS fails to make a savegame, you can check the recycle bin for the previous saves. DCS always locks the mission file in use in read-write mode so you cannot delete the mission file in use. After every save, however, DCSI will attempt to delete all miz files int he persistent folder, so do not put anything else in there. You can edit the ini file on the fly, it will check on the interval you set which is in milliseconds. The restart interval is in hours. Due to comparing two whole numbers and counting up hours as single digits, you need to wait one more hour before the limit trips. ie, if you set 3 in the ini, you need to wait four hours entirely for the restart. Sorry :)
