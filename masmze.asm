;
;	MASMZE-3D, a half-game, half-(tech)demo made on MASM32 and WinAPI.
;	Copyright (C) 2023  Yevhenii Ionenko (aka GreatCorn)
;
;	This program is free software: you can redistribute it and/or modify
;	it under the terms of the GNU General Public License as published by
;	the Free Software Foundation, either version 3 of the License, or
;	(at your option) any later version.
;
;	This program is distributed in the hope that it will be useful,
;	but WITHOUT ANY WARRANTY; without even the implied warranty of
;	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;	GNU General Public License for more details.
;
;	You should have received a copy of the GNU General Public License
;	along with this program.  If not, see <http://www.gnu.org/licenses/>.

.386
.model flat,stdcall
option casemap:none

; Include libraries
include include\windows.inc

include include\advapi32.inc
includelib advapi32.lib
include include\comctl32.inc
includelib comctl32.lib
include include\gdi32.inc
includelib gdi32.lib
include include\glu32.inc
includelib glu32.lib
include include\kernel32.inc
includelib kernel32.lib
include include\masm32.inc
includelib masm32.lib
include include\msvcrt.inc
includelib msvcrt.lib
include include\opengl32.inc
includelib opengl32.lib
include include\user32.inc
includelib user32.lib
include include\winmm.inc
includelib winmm.lib

include macros\macros.asm

; Include project files
include audio.inc
include heapstack.inc
include importers.inc
include maths.inc

; -----	MAIN INTERFACE -----

; ----- CONSTANTS -----
MZC_PASSTOP EQU 1	; Maze cell constants for bitwise operations
MZC_PASSLEFT EQU 2
MZC_VISITED EQU 4
MZC_LAMP EQU 8
MZC_PIPE EQU 16
MZC_WIRES EQU 32
MZC_TABURETKA EQU 64
MZC_ROTATED EQU 128

FNT_LEFT EQU 0		; Font alignment constants for DrawBitmapText
FNT_CENTERED EQU 1
FNT_RIGHT EQU 2

FPU_ZERO EQU 0C00h	; Rounding towards zero (trunc) FPU mode

DEVMODEA STRUCT	; Not all DEVMODEA fields ended up in DEVMODE in windows.inc
	dmDeviceName	BYTE	CCHDEVICENAME dup(?)
	dmSpecVersion	WORD	?
	dmDriverVersion	WORD	?
	dmSize			WORD	?
	dmDriverExtra	WORD	?
	dmFields		DWORD	?
	union
		struct
			dmOrientation	WORD	?
			dmPaperSize 	WORD	?
			dmPaperLength	WORD	?
			dmPaperWidth	WORD	?
			dmScale			WORD	?
			dmCopies		WORD	?
			dmDefaultSource	WORD	?
			dmPrintQuality	WORD	?
		ends
		;dmPosition POINTL <>	; are Microsoft docs also tripping
		struct
			dmPosition				POINTL	<>
			dmDisplayOrientation	DWORD	?
			dmDisplayFixedOutput	DWORD	?
		ends
	ends
	dmColor			WORD	?
	dmDuplex		WORD	?
	dmYResolution	WORD	?
	dmTTOption		WORD	?
	dmCollate		WORD	?
	dmFormName		BYTE	CCHFORMNAME dup (?)
	dmLogPixels		WORD	?
	dmBitsPerPel	DWORD	?
	dmPelsWidth		DWORD	?
	dmPelsHeight	DWORD	?
	union
		dmDisplayFlags	DWORD	?
		dmNup			DWORD	?
	ends
	dmDisplayFrequency	DWORD	?
	dmICMMethod			DWORD	?
	dmICMIntent			DWORD	?
	dmMediaType			DWORD	?
	dmDitherType		DWORD	?
	dmReserved1			DWORD	?
	dmReserved2			DWORD	?
	dmPanningWidth		DWORD	?
	dmPanningHeight		DWORD	?
DEVMODEA ENDS
JOYCAPSAFIX STRUCT	; Also wrong header in windows.inc
; Also the TAB key is on your keyboard for a reason
	wMid			WORD	?
	wPid			WORD	?
	szPname			BYTE MAXPNAMELEN dup (?)
	wXmin			DWORD	?
	wXmax			DWORD	?
	wYmin			DWORD	?
	wYmax			DWORD	?
	wZmin			DWORD	?
	wZmax			DWORD	?
	wNumButtons		DWORD	?
	wPeriodMin		DWORD	?
	wPeriodMax		DWORD	?
	wRmin			DWORD	?
	wRmax			DWORD	?
	wUmin			DWORD	?
	wUmax			DWORD	?
	wVmin			DWORD	?
	wVmax			DWORD	?
	wCaps			DWORD	?
	wMaxAxes		DWORD	?
	wNumAxes		DWORD	?
	wMaxButtons		DWORD	?
	szRegKey		BYTE MAXPNAMELEN dup(?)
	szOEMVxD		BYTE MAX_JOYSTICKOEMVXDNAME dup(?)
JOYCAPSAFIX ENDS

.CONST

ClassName DB "FMain", 0		; Window class name
ClassSett DB "FSettings", 0	; Settings window class name
ClassButton DB "BUTTON", 0	; Button element
ClassEdit DB "EDIT", 0	; Edit element
ClassCombo DB "COMBOBOX", 0	; Combobox element
ClassStatic DB "STATIC", 0	; Static element (label)
ClassTrackbar DB "msctls_trackbar32", 0	; Trackbar element
ClassUpdown DB "msctls_updown32", 0		; Updown element
FontName DB "Segoe UI", 0	; Settings font
AppName DB "01. MASMZE#02. ICH RUF ZUM ABGRUND#03. RECITATIVO",35,
"04. BLESSING#04. SARABANDE FROM PARTITA E-MOLL", 35,
"05. THE CYCLE#06. ESMOVAYU ADRAST", 0	; App name & caption
Icon DB "ICON", 0			; Icon resource name

ErrorCaption DB "ERROR", 0	; Error specifications
ErrorDC DB "Can't get device context.", 0
ErrorPF DB "Can't choose pixel format.", 0
ErrorPFS DB "Can't set pixel format.", 0
ErrorGLC DB "Can't create GL context.", 0
ErrorGLCC DB "Can't make GL context current.", 0
ErrorMaze DB "Can't free maze memory.", 0	
ErrorMazeBuffer DB "Can't unlock maze buffer.", 0	
ErrorOpenGL DB "OpenGL error occured.", 0	

CCEscape DB "ESC TO CLOSE", 0	; Subtitles and miscellaneous strings
CCEscapeJ DB "START TO CLOSE", 0

CCLevel DB "LAYER:", 0

; Random subtitles to show when entering a layer
CCRandom1 DB "I REMEMBER THIS PLACE.", 0
CCRandom2 DB "IT SMELLS WET HERE.", 0
CCRandom3 DB "THE AIR TASTES STAGNANT.", 0
CCRandom4 DB "DAMPNESS CLINGS TO THE WALLS.", 0
CCRandom5 DB "SOMETHING WATCHES FROM AFAR.", 0
CCRandom6 DB "THE WALLS VIBRATE SLIGHTLY.", 0

CCAscend1 DB "I REMEMBER EVERYTHING.", 0
CCAscend2 DB "IT SMELLS BURNT HERE.", 0
CCAscend3 DB "THE AIR TASTES METALLIC.", 0
CCAscend4 DB "DUST CLINGS TO THE WALLS.", 0
CCAscend5 DB "NOBODY IS PRESENT.", 0
CCAscend6 DB "THE WALLS ARE SILENT.", 0

CCTrench DB "THE CYCLE PERSEVERETH.", 0

CCShn1 DB "I HAVE BEEN HERE FOR TOO LONG.", 0
CCShn2 DB "I NEED TO FIND A WAY OUT.", 0
CCShn3 DB "SOMETHING HORRIBLE OCCURED.", 0

CCCompass DB "PICKED UP COMPASS.", 0	; Functional subtitles
CCGlyphNone DB "THE ABYSS IMMURETH THY MALEFACTIONS.", 0
CCGlyphRestore DB "THINE EXCULPATION BETIDETH.", 0
CCKey DB "PICKED UP KEY.", 0
CCShop DB "PRESS ENTER TO BUY MAP FOR 5 GLYPHS", 0
CCShopJ DB "PRESS SELECT TO BUY MAP FOR 5 GLYPHS", 0
CCShopBuy DB "THANK YOU FOR YOUR PURCHASE.", 0
CCShopNo DB "NOT ENOUGH GLYPHS.", 0
CCSpace DB "MASH SPACE TO FIGHT BACK", 0
CCSpaceJD DB "MASH CROSS TO FIGHT BACK", 0
CCSpaceJX DB "MASH A TO FIGHT BACK", 0
CCTeleport DB "REALITY CONTORTS, FRACTURES EMERGE.", 0
CCTeleportBad DB "TIME SHIFTS, CONTROL SLIPS AWAY.", 0
CCTram DB "PRESS ENTER TO GET ON", 0
CCTramJ DB "PRESS SELECT TO GET ON", 0
CCTramExit DB "PRESS ENTER TO GET OFF", 0
CCTramExitJ DB "PRESS SELECT TO GET OFF", 0

CCCroa1 DB "THOU HADST A PATH ENDURING.", 0
CCCroa2 DB "WE GREET THY CONCEPTION", 0
CCCroa3 DB "AND THINE INADVERTENT SCRIPTOR.", 0
CCCroa4 DB "WE HAVE NOT CONTROL OVER THE PROFANED MUNDY,", 0
CCCroa5 DB "AND IN THE CONTEXT OF TIME,", 0
CCCroa6 DB "OUR PERSISTENCE HERE IS BUT PALTRY.", 0
CCCroa7 DB "THOU HAST ARRIVED TO THE BORDER.", 0
CCCroa8 DB "YET, AS A BOUND ENTITY,", 0
CCCroa9 DB "ADVANCE IT THOU CANST NOT.", 0
CCCroa10 DB "HAVING A MEANS TO PEER INTO THE ABYSSES,", 0
CCCroa11 DB "YOU MAYST PERSEVERE THE CYCLE,", 0
CCCroa12 DB "OR HALT, ABANDON AND FORGET.", 0
CCCroa13 DB "PERHAPS WE MAY MEET ANOTHER TIME.", 0

CCIntro1 DB "GREATCORN PRESENTS", 0
CCIntro2 DB "A GAME WRITTEN IN X86 ASSEMBLY", 0
CCIntro3 DB "WITH MASM32 AND OPENGL", 0

CCCheckpoint DB "PRESS ENTER TO PROCEED", 0
CCCheckpointJ DB "PRESS SELECT TO PROCEED", 0
CCLoad DB "IS THIS WHERE I WAS BEFORE?", 0
CCSave DB "THE DIVINE PROGENITRESS AWAITS.", 0
CCSaved DB "THY CONCEPTION HATH BEEN PRESERVED.", 0
CCSaveErase DB "PRESS ENTER TO ERASE SAVE", 0
CCSaveEraseJ DB "PRESS SELECT TO ERASE SAVE", 0

MenuSettings DB "SETTINGS", 0	; Menu-related strings
MenuDisabled DB "Disabled", 0
MenuFullscreen DB "Fullscreen:", 0
MenuResolution DB "Windowed resolution:", 0
MenuBrightness DB "Brightness:", 0
MenuMouseSensitivity DB "Mouse sensitivity:", 0
MenuJoystick DB "Joystick:", 0
MenuJoystickSensitivity DB "Joystick sensitivity:", 0
MenuAudioVolume DB "Audio volume:", 0
MenuOK DB "OK", 0
MenuPaused DB "MASMZE-3D IS PAUSED", 0
MenuResume DB "RESUME", 0
MenuSensitivity DB "SENSITIVITY", 0
MenuExit DB "EXIT", 0
MenuSettingsWIP DB "SETTINGS ARE WORK IN PROGRESS#PLEASE USE THE SETTINGS.INI FILE#PRESS ESC TO GO BACK", 0


Note1 DB \
"PRAISED BE THE DIVINE",35, \
"MASTERS OF THE MUNDI,",35, \
"TORLAGG AND NEQAOTOR!",35, \
"MANY PLEAS OF MINE",	35, \
"FOR SALVATION REMAIN",	35, \
"UNANSWERED, BUT I",	35, \
"BELIEVE IN THEE AND",	35, \
"THINE OMNIPOTENCE!",	35, \
"THE ABYSS IS BROAD",	35, \
"AND DEEP, BUT I WILL",	35, \
"FIND MY EXIT, WITH",	35, \
"THE HELP OF THE CROA",	35, \
"I WILL, SURELY...",	0

Note2 DB \
"THEY CALLED IT TO-NE,",35, \
"FOR IT MUST BE THE",	35, \
"LAND UNDER THE RULE",	35, \
"OF THE NETHER AND",	35, \
"EASTERN CROA, BUT I",	35, \
"SEE NO SIGNS OF THEIR",35, \
"WORK HERE... I FOUND",	35, \
"IT APPROPRIATE TO",	35, \
"ASSOCIATE SV WITH",	35, \
"AOTIR MUNDY, BUT NOW",	35, \
"I AM NOT AS SURE AS I",35, \
"WAS BEFORE...",		0

Note3 DB \
"GRAND DISCONCERTMENT",	35, \
"BEFELL ME. EITHER I",	35, \
"FOUND A POSSIBLE",		35, \
"CONNECTION TO THE",	35, \
"MUND OF NEQAOTOR, OR",	35, \
"I HAVE DISCOVERED THE",35, \
"FUNCTION OF THIS",		35, \
"ABYSS.",				35, \
"TO-NE PRAISES SIN AND",35, \
"THROUGH BLASPHEMY, I",	35, \
"AM ABLE TO PERSIST IN",35, \
"A MORE STABLE MANNER.",0

Note4 DB \
"THE GLYPHS, I AM",		35, \
"BEGINNING TO",			35, \
"UNDERSTAND THEM. I",	35, \
"MAY BE ABLE TO",		35, \
"DECIPHER THE MEANINGS",35, \
"OF THE INSCRIPTIONS",	35, \
"HERE. THEY LOOK TO BE",35, \
"THE SAME AS WHAT SV",	35, \
"USES. IF I AM",		35, \
"SUCCESSFUL, THIS WILL",35, \
"BE A SIGNIFICANT",		35, \
"ACCOMPLISHMENT FOR",	35, \
"KURLYKISTAN.",	0

Note5 DB \
"SANCTA VITA.",			35, \
"THESE WORDS STILL",	35, \
"RING IN MY HEAD AS IF",35, \
"UTTERED A MERE",		35, \
"FRACTION OF A MOMENT",	35, \
"BEFORE. I WANTED",		35, \
"ANSWERS AND I FOUND",	35, \
"THEM, BUT I HAVE",		35, \
"DOOMED MYSELF. THE",	35, \
"SMILE OF THE",			35, \
"PROGENITRESS BRINGS",	35, \
"ME ONLY DISFAVOR.",	35, \
"I MISS MY HOME.", 0

Note6 DB \
"ENDLESS. INEXACT.",	35, \
"EVERPRESENT.",			35, \
"IMPRUDENT BE BROUGHT",	35, \
"TO REASON.",			35, \
"WHEN TIME IS LOST,",	35, \
"BEGOTTEN BE A NEW",	35, \
"CONCEPT.",				35, \
"I HAVE BEEN DECEIVED.",35, \
"I HAVE BEEN",			35, \
"RIDICULED.",			35, \
"I FOUND NOT A SINGLE",	35, \
"ANSWER BUT LED MYSELF",35, \
"TO MINE OWN DEMISE.",	0

Note7 DB \
"AZ POHEHBET MYOLIC",	35, \
"OKKLQS SANCTA VITA.",	35, \
35, \
"SGORT AZA NA SYXNE",	35, \
"SYY NE ESMOVETU",		35, \
"SHOMBOM,",				35, \
"TAKVO ONEM AZA",		35, \
"ESMOVETY HOMBET NA",	35, \
"TRUMB K YERHENY",		35, \
"M O T R E,",			35, \
35, \
"DA SANTITSY YGA",		35, \
"DA ESMOVAYU ADRAST.",	0


IniPath DB "settings.ini", 0	; Ini-related strings
IniAudio DB "Audio", 0
IniGraphics DB "Graphics", 0
IniFullscreen DB "Fullscreen", 0
IniWidth DB "Width", 0
IniHeight DB "Height", 0
IniBrightness DB "Brightness", 0
IniControls DB "Controls", 0
IniJoystickID DB "JoystickID", 0
IniJoystickSensitivity DB "JoystickSensitivity", 0
IniMouseSensitivity DB "MouseSensitivity", 0
IniVolume DB "Volume", 0
IniFalse DB "false", 0
IniTrue DB "true", 0
Ini1N DB "-1", 0
Ini03 DB "0.3", 0
Ini05 DB "0.5", 0
Ini10 DB "1.0", 0
Ini20 DB "2.0", 0

RegPath DB "Software\\GreatCorn\\MASMZE-3D", 0	; Registry-related strings
RegLayer DB "Layer", 0
RegCompass DB "Compass", 0
RegCurLayer DB "CurLayer", 0
RegCurWidth DB "CurWidth", 0
RegCurHeight DB "CurHeight", 0
RegGlyphs DB "Glyphs", 0
RegFloor DB "Floor", 0
RegWall DB "Wall", 0
RegRoof DB "Roof", 0
RegMazeW DB "MazeW", 0
RegMazeH DB "MazeH", 0
RegComplete DB "Complete", 0

; Resource paths
ImgBricks DB "GFX\bricks.gct", 0	; Images
ImgCompass DB "GFX\compass.gct", 0
ImgCompassWorld DB "GFX\compassWorld.gct", 0
ImgConcrete DB "GFX\concrete.gct", 0
ImgConcreteRoof DB "GFX\concreteRoof.gct", 0
ImgCroa DB "GFX\croa.gct", 0
ImgCursor DB "GFX\cursor.gct", 0
ImgDiamond DB "GFX\diamond.gct", 0
ImgDirt DB "GFX\dirt.gct", 0
ImgDoor DB "GFX\door.gct", 0
ImgDoorblur DB "GFX\doorblur.gct", 0
ImgEBD1 DB "GFX\EBD1.gct", 0
ImgEBD2 DB "GFX\EBD2.gct", 0
ImgEBD3 DB "GFX\EBD3.gct", 0
ImgEBDShadow DB "GFX\EBDShadow.gct", 0
ImgFacade DB "GFX\facade.gct", 0
ImgFloor DB "GFX\floor.gct", 0
ImgGlyphs DB "GFX\glyphs.gct", 0
ImgHbd DB "GFX\hbd.gct", 0
ImgKey DB "GFX\key.gct", 0
ImgKoluplyk DB "GFX\koluplyk.gct", 0
ImgLamp DB "GFX\lamp.gct", 0
ImgLight DB "GFX\light.gct", 0
ImgMap DB "GFX\map.gct", 0
ImgMetal DB "GFX\metal.gct", 0
ImgMetalFloor DB "GFX\metalFloor.gct", 0
ImgMetalRoof DB "GFX\metalRoof.gct", 0
ImgMotrya DB "GFX\motrya.gct", 0
ImgNoise DB "GFX\noise.gct", 0
ImgPaper DB "GFX\paper.gct", 0
ImgPipe DB "GFX\pipe.gct", 0
ImgPlanks DB "GFX\planks.gct", 0
ImgPlaster DB "GFX\plaster.gct", 0
ImgRain DB "GFX\rain.gct", 0
ImgRoof DB "GFX\roof.gct", 0
ImgSigns1 DB "GFX\signs1.gct", 0
ImgShadow DB "GFX\shadow.gct", 0
ImgSky DB "GFX\sky.gct", 0
ImgTaburetka DB "GFX\taburetka.gct", 0
ImgTileBig DB "GFX\tileBig.gct", 0
ImgTilefloor DB "GFX\tilefloor.gct", 0
ImgTone DB "GFX\tone.gct", 0
ImgTram DB "GFX\tram.gct", 0
ImgTree DB "GFX\tree.gct", 0
ImgTutorial DB "GFX\tutorial.gct", 0
ImgTutorialJ DB "GFX\tutorialJ.gct", 0
ImgVas DB "GFX\vas.gct", 0
ImgVebra DB "GFX\vebra.gct", 0
ImgVignette DB "GFX\vignette.gct", 0
ImgVignetteRed DB "GFX\vignetteRed.gct", 0
ImgWall DB "GFX\wall.gct", 0
ImgWB DB "GFX\WB.gct", 0
ImgWBBK DB "GFX\WBBK.gct", 0
ImgWBBKP DB "GFX\WBBKP.gct", 0
ImgWBBK1 DB "GFX\WBBK1.gct", 0
ImgWhitewall DB "GFX\whitewall.gct", 0

ImgGlyph1 DB "GFX\glyph1.gct", 0
ImgGlyph2 DB "GFX\glyph2.gct", 0
ImgGlyph3 DB "GFX\glyph3.gct", 0
ImgGlyph4 DB "GFX\glyph4.gct", 0
ImgGlyph5 DB "GFX\glyph5.gct", 0
ImgGlyph6 DB "GFX\glyph6.gct", 0
ImgGlyph7 DB "GFX\glyph7.gct", 0

ImgWmblykHappy DB "GFX\wmblykHappy.gct", 0
ImgWmblykNeutral DB "GFX\wmblykNeutral.gct", 0
ImgWmblykJumpscare DB "GFX\wmblykJumpscare.gct", 0
ImgWmblykStr DB "GFX\wmblykStr.gct", 0
ImgWmblykL1 DB "GFX\wmblykL1.gct", 0
ImgWmblykL2 DB "GFX\wmblykL2.gct", 0
ImgWmblykL3 DB "GFX\wmblykL3.gct", 0
ImgWmblykW1 DB "GFX\wmblykW1.gct", 0
ImgWmblykW2 DB "GFX\wmblykW2.gct", 0

ImgVirdyaBlink DB "GFX\virdyaBlink.gct", 0
ImgVirdyaDown DB "GFX\virdyaDown.gct", 0
ImgVirdyaN DB "GFX\virdyaN.gct", 0
ImgVirdyaNeut DB "GFX\virdyaNeut.gct", 0
ImgVirdyaUp DB "GFX\virdyaUp.gct", 0

ImgKubale DB "GFX\kubale.gct", 0
ImgKubaleV1 DB "GFX\kubaleV1.gct", 0
ImgKubaleV2 DB "GFX\kubaleV2.gct", 0
ImgKubaleV3 DB "GFX\kubaleV3.gct", 0
ImgKubaleV4 DB "GFX\kubaleV4.gct", 0
ImgKubaleV5 DB "GFX\kubaleV5.gct", 0
ImgKubaleV6 DB "GFX\kubaleV6.gct", 0
ImgKubaleV7 DB "GFX\kubaleV7.gct", 0
ImgKubaleV8 DB "GFX\kubaleV8.gct", 0
ImgKubaleV9 DB "GFX\kubaleV9.gct", 0

ImgFontPath DB "GFX\font\font.gcf", 0	; A collection of paths to images

MdlSphere DB "Sphere.gcm", 0	; Models
MdlUVCube DB "UVCube.gcm", 0
MdlCompassArrow DB "GFX\compassArrow.gcm", 0
MdlCompassWorld DB "GFX\compassWorld.gcm", 0
MdlCrevice DB "GFX\crevice.gcm", 0
MdlDoor DB "GFX\door.gcm", 0
MdlDoorway DB "GFX\doorwayM.gcm", 0
MdlDoorFrame DB "GFX\doorFrame.gcm", 0
MdlDoorFrameLock DB "GFX\doorFrameLock.gcm", 0
MdlGlyphs DB "GFX\glyphs.gcm", 0
MdlKey DB "GFX\key.gcm", 0
MdlLamp DB "GFX\lamp.gcm", 0
MdlPadlock DB "GFX\padlock.gcm", 0
MdlPipe DB "GFX\pipe.gcm", 0
MdlPlane DB "GFX\planeM.gcm", 0
MdlPlaneC DB "GFX\planeC.gcm", 0
MdlPlanks DB "GFX\planks.gcm", 0
MdlSigil1 DB "GFX\sigil1.gcm", 0
MdlSigil2 DB "GFX\sigil2.gcm", 0
MdlSigns1 DB "GFX\signs1.gcm", 0
MdlStairs DB "GFX\stairsM.gcm", 0
MdlTaburetka DB "GFX\taburetka.gcm", 0
MdlWBBK DB "GFX\wbbk.gcm", 0
MdlWires DB "GFX\wires.gcm", 0

MdlCityConcrete DB "GFX\cityConcrete.gcm", 0
MdlCityFacade DB "GFX\cityFacade.gcm", 0
MdlCityTerrain DB "GFX\cityTerrain.gcm", 0
MdlOutsBunker DB "GFX\outskirtsBunker.gcm", 0
MdlOutsRoad DB "GFX\outskirtsRoad.gcm", 0
MdlOutsTerrain DB "GFX\outskirtsTerrain.gcm", 0
MdlOutsTrees DB "GFX\outskirtsTrees.gcm", 0

MdlCheckFloor DB "GFX\checkFloor.gcm", 0
MdlCheckWalls DB "GFX\checkWalls.gcm", 0
MdlCheckRoof DB "GFX\checkRoof.gcm", 0

MdlUpFloor DB "GFX\upFloor.gcm", 0
MdlUpWalls DB "GFX\upWalls.gcm", 0
MdlUpRoof DB "GFX\upRoof.gcm", 0

MdlBorderFloor DB "GFX\borderFloor.gcm", 0
MdlBorderWall DB "GFX\borderWall.gcm", 0
MdlSky DB "GFX\sky.gcm", 0

MdlTerrain DB "GFX\terrain.gcm", 0

MdlWallB DB "GFX\wallB.gcm", 0
MdlWallD DB "GFX\wallD.gcm", 0
MdlWallM DB "GFX\wallM.gcm", 0
MdlWallS DB "GFX\wallS.gcm", 0
MdlWallT DB "GFX\wallT.gcm", 0
MdlWallT2 DB "GFX\wallT2.gcm", 0
MdlWallTR DB "GFX\wallTR.gcm", 0
MdlWallW DB "GFX\wallW.gcm", 0

MdlVebraLook1 DB "GFX\vebraLook1.gcm", 0
MdlVebraLook2 DB "GFX\vebraLook2.gcm", 0
MdlVebraExit1 DB "GFX\vebraExit1.gcm", 0
MdlVebraExit2 DB "GFX\vebraExit2.gcm", 0
MdlVebraExit3 DB "GFX\vebraExit3.gcm", 0
MdlVebraExit4 DB "GFX\vebraExit4.gcm", 0
MdlVebraExit5 DB "GFX\vebraExit5.gcm", 0
MdlVebraExit6 DB "GFX\vebraExit6.gcm", 0

MdlWBWalk1 DB "GFX\wbWalk1.gcm", 0
MdlWBWalk2 DB "GFX\wbWalk2.gcm", 0
MdlWBWalk3 DB "GFX\wbWalk3.gcm", 0
MdlWBIdle1 DB "GFX\wbIdle1.gcm", 0
MdlWBIdle2 DB "GFX\wbIdle2.gcm", 0
MdlWBAttack1 DB "GFX\wbAttack1.gcm", 0
MdlWBAttack2 DB "GFX\wbAttack2.gcm", 0
MdlWBAttack3 DB "GFX\wbAttack3.gcm", 0

MdlWmblykBody DB "GFX\wmblykBody.gcm", 0
MdlWmblykBodyG DB "GFX\wmblykBodyG.gcm", 0
MdlWmblykCrawl1 DB "GFX\wmblykCrawl1.gcm", 0
MdlWmblykCrawl2 DB "GFX\wmblykCrawl2.gcm", 0
MdlWmblykHead DB "GFX\wmblykHead.gcm", 0
MdlWmblykWalk1 DB "GFX\wmblykWalk1.gcm", 0
MdlWmblykWalk2 DB "GFX\wmblykWalk2.gcm", 0
MdlWmblykWalk3 DB "GFX\wmblykWalk3.gcm", 0
MdlWmblykWalk4 DB "GFX\wmblykWalk4.gcm", 0
MdlWmblykStr0 DB "GFX\wmblykStr0.gcm", 0
MdlWmblykStr1 DB "GFX\wmblykStr1.gcm", 0
MdlWmblykStr2 DB "GFX\wmblykStr2.gcm", 0
MdlWmblykStrL0 DB "GFX\wmblykStrL0.gcm", 0
MdlWmblykStrL1 DB "GFX\wmblykStrL1.gcm", 0
MdlWmblykStrL2 DB "GFX\wmblykStrL2.gcm", 0
MdlWmblykStrW0 DB "GFX\wmblykStrW0.gcm", 0
MdlWmblykStrW1 DB "GFX\wmblykStrW1.gcm", 0
MdlWmblykStrW2 DB "GFX\wmblykStrW2.gcm", 0
MdlWmblykDead DB "GFX\wmblykDead.gcm", 0
MdlWmblykTram DB "GFX\wmblykTram.gcm", 0

MdlKoluplykDig1 DB "GFX\koluplykDig1.gcm", 0
MdlKoluplykDig2 DB "GFX\koluplykDig2.gcm", 0
MdlKoluplykDig3 DB "GFX\koluplykDig3.gcm", 0
MdlKoluplykDig4 DB "GFX\koluplykDig4.gcm", 0
MdlKoluplykShop1 DB "GFX\koluplykShop1.gcm", 0
MdlKoluplykShop2 DB "GFX\koluplykShop2.gcm", 0

MdlKubale1 DB "GFX\kubale1.gcm", 0
MdlKubale2 DB "GFX\kubale2.gcm", 0
MdlKubale3 DB "GFX\kubale3.gcm", 0
MdlKubale4 DB "GFX\kubale4.gcm", 0

MdlMotrya1 DB "GFX\motrya1.gcm", 0
MdlMotrya2 DB "GFX\motrya2.gcm", 0
MdlMotrya3 DB "GFX\motrya3.gcm", 0
MdlMotrya4 DB "GFX\motrya4.gcm", 0

MdlTram DB "GFX\tram.gcm", 0
MdlTramG DB "GFX\tramG.gcm", 0
MdlTramD1 DB "GFX\tramD1.gcm", 0
MdlTramDG1 DB "GFX\tramDG1.gcm", 0
MdlTramD2 DB "GFX\tramD2.gcm", 0
MdlTramDG2 DB "GFX\tramDG2.gcm", 0
MdlTramD3 DB "GFX\tramD3.gcm", 0
MdlTramDG3 DB "GFX\tramDG3.gcm", 0
MdlTramD4 DB "GFX\tramD4.gcm", 0
MdlTramDG4 DB "GFX\tramDG4.gcm", 0

MdlTrack DB "GFX\track.gcm", 0
MdlTrackTurn DB "GFX\trackTurn.gcm", 0

MdlVasT1 DB "GFX\vasT1.gcm", 0
MdlVasT2 DB "GFX\vasT2.gcm", 0
MdlVasT3 DB "GFX\vasT3.gcm", 0

MdlVirdyaBack1 DB "GFX\virdyaBack1.gcm", 0
MdlVirdyaBack2 DB "GFX\virdyaBack2.gcm", 0
MdlVirdyaBack3 DB "GFX\virdyaBack3.gcm", 0
MdlVirdyaBack4 DB "GFX\virdyaBack4.gcm", 0
MdlVirdyaBack5 DB "GFX\virdyaBack5.gcm", 0
MdlVirdyaBack6 DB "GFX\virdyaBack6.gcm", 0
MdlVirdyaBody DB "GFX\virdyaBody.gcm", 0
MdlVirdyaH1 DB "GFX\virdyaH1.gcm", 0
MdlVirdyaH2 DB "GFX\virdyaH2.gcm", 0
MdlVirdyaHead DB "GFX\virdyaHead.gcm", 0
MdlVirdyaRest DB "GFX\virdyaRest.gcm", 0
MdlVirdyaWalk1 DB "GFX\virdyaWalk1.gcm", 0
MdlVirdyaWalk2 DB "GFX\virdyaWalk2.gcm", 0
MdlVirdyaWalk3 DB "GFX\virdyaWalk3.gcm", 0
MdlVirdyaWalk4 DB "GFX\virdyaWalk4.gcm", 0
MdlVirdyaWalk5 DB "GFX\virdyaWalk5.gcm", 0
MdlVirdyaWalk6 DB "GFX\virdyaWalk6.gcm", 0
MdlVirdyaWalk7 DB "GFX\virdyaWalk7.gcm", 0
MdlVirdyaWalk8 DB "GFX\virdyaWalk8.gcm", 0
MdlVirdyaWave1 DB "GFX\virdyaWave1.gcm", 0
MdlVirdyaWave2 DB "GFX\virdyaWave2.gcm", 0
MdlVirdyaWave3 DB "GFX\virdyaWave3.gcm", 0
MdlVirdyaWave4 DB "GFX\virdyaWave4.gcm", 0
MdlVirdyaWave5 DB "GFX\virdyaWave5.gcm", 0

MdlNeqaotor DB "GFX\neqaotor.gcm", 0
MdlTorlagg DB "GFX\torlagg.gcm", 0

MdlHbd DB "GFX\hbd.gcm", 0
MdlHbdS DB "GFX\hbdS.gcm", 0

SndAlarmPath DB "SFX\alarm.gcs", 0		; Sounds
SndAmbPath DB "SFX\amb.gcs", 0
SndAmbTPath DB "SFX\ambT.gcs", 0
SndCheckpointPath DB "SFX\checkpoint.gcs", 0
SndDeathPath DB "SFX\death.gcs", 0
SndDigPath DB "SFX\dig.gcs", 0
SndDistressPath DB "SFX\distress.gcs", 0
SndDoorClosePath DB "SFX\doorClose.gcs", 0
SndDripPath DB "SFX\drip.gcs", 0
SndEBDPath DB "SFX\ebd.gcs", 0
SndEBDAPath DB "SFX\ebdA.gcs", 0
SndExitPath DB "SFX\exit.gcs", 0
SndExit1Path DB "SFX\exit1.gcs", 0
SndExplosionPath DB "SFX\explosion.gcs", 0
SndHbdPath DB "SFX\hbd.gcs", 0
SndHbdOPath DB "SFX\hbdO.gcs", 0
SndHurtPath DB "SFX\hurt.gcs", 0
SndImpactPath DB "SFX\impact.gcs", 0
SndIntroPath DB "SFX\intro.gcs", 0
SndStep1 DB "SFX\step-01.gcs", 0
SndStep2 DB "SFX\step-02.gcs", 0
SndStep3 DB "SFX\step-03.gcs", 0
SndStep4 DB "SFX\step-04.gcs", 0
SndKeyPath DB "SFX\key.gcs", 0
SndKubalePath DB "SFX\kubale.gcs", 0
SndKubaleAppearPath DB "SFX\kubaleAppear.gcs", 0
SndKubaleVPath DB "SFX\kubaleV.gcs", 0
SndMistakePath DB "SFX\mistake.gcs", 0
SndMus1Path DB "SFX\mus1.gcs", 0
SndMus2Path DB "SFX\mus2.gcs", 0
SndMus3Path DB "SFX\mus3.gcs", 0
SndMus4Path DB "SFX\mus4.gcs", 0
SndMus5Path DB "SFX\mus5.gcs", 0
SndRand1Path DB "SFX\rand1.gcs", 0
SndRand2Path DB "SFX\rand2.gcs", 0
SndRand3Path DB "SFX\rand3.gcs", 0
SndRand4Path DB "SFX\rand4.gcs", 0
SndRand5Path DB "SFX\rand5.gcs", 0
SndRand6Path DB "SFX\rand6.gcs", 0
SndSavePath DB "SFX\save.gcs", 0
SndScribblePath DB "SFX\scribble.gcs", 0
SndSirenPath DB "SFX\siren.gcs", 0
SndSlamPath DB "SFX\slam.gcs", 0
SndSplashPath DB "SFX\splash.gcs", 0
SndTramPath DB "SFX\tram.gcs", 0
SndTramAnn1Path DB "SFX\tramAnn1.gcs", 0
SndTramAnn2Path DB "SFX\tramAnn2.gcs", 0
SndTramAnn3Path DB "SFX\tramAnn3.gcs", 0
SndTramClosePath DB "SFX\tramClose.gcs", 0
SndTramOpenPath DB "SFX\tramOpen.gcs", 0
SndVirdyaPath DB "SFX\virdya.gcs", 0
SndWBAlarmPath DB "SFX\wbAlarm.gcs", 0
SndWBAttackPath DB "SFX\wbAttack.gcs", 0
SndWBIdle1Path DB "SFX\wbIdle1.gcs", 0
SndWBIdle2Path DB "SFX\wbIdle2.gcs", 0
SndWBStep1Path DB "SFX\wbStep-01.gcs", 0
SndWBStep2Path DB "SFX\wbStep-02.gcs", 0
SndWBStep3Path DB "SFX\wbStep-03.gcs", 0
SndWBStep4Path DB "SFX\wbStep-04.gcs", 0
SndWBBKPath DB "SFX\wbbk.gcs", 0
SndWhisperPath DB "SFX\wh.gcs", 0
SndWmblykPath DB "SFX\wmblyk.gcs", 0
SndWmblykBPath DB "SFX\wmblykB.gcs", 0
SndWmblykStrPath DB "SFX\wmblykStr.gcs", 0
SndWmblykStrMPath DB "SFX\wmblykStrM.gcs", 0

SndAmbW1Path DB "SFX\amb1.gcs", 0
SndAmbW2Path DB "SFX\amb2.gcs", 0
SndAmbW3Path DB "SFX\amb3.gcs", 0
SndAmbW4Path DB "SFX\amb4.gcs", 0

clBlack REAL4 0.0, 0.0, 0.0, 1.0		; Some colors
clDarkGray REAL4 0.2, 0.2, 0.2, 1.0
clGray REAL4 0.5, 0.5, 0.5, 1.0
clTrench REAL4 0.24, 0.24, 0.22
clYellow REAL4 1.0, 0.83, 0.56, 1.0
clWhite REAL4 1.0, 1.0, 1.0, 1.0

; A generic quad for generic quad-related quad-purposes
qdTopLeft REAL4 0.0, 0.0, 0.0		; Vertices
qdTopRight REAL4 1.0, 0.0, 0.0
qdBottomLeft REAL4 0.0, 1.0, 0.0
qdBottomRight REAL4 1.0, 1.0, 0.0

qdUVTopLeft REAL4 0.0, 0.0			; UVs
qdUVTopRight REAL4 1.0, 0.0
qdUVBottomLeft REAL4 0.0, 1.0
qdUVBottomRight REAL4 1.0, 1.0


dbNear REAL8 0.01		; Doubles (REAL8) values for GLU perspective
dbFar REAL8 100.0

; Floats that have game-specific significance
flCamHeight REAL4 -1.2	; Default camera height 
flCamSpeed REAL4 3.6	; Default camera speed
flDoor REAL4 0.65		; Door offset
flStep REAL4 6.0		; Step animation speed
flShine REAL4 64.0		; Environment shininess
flWTh REAL4 0.4			; Wall thickness
flWMr REAL4 0.15		; Wall margin
flWLn REAL4 2.15		; Wall length
flKubaleTh REAL4 0.7	; Kubale thiccness
flRaycast REAL4 1.0		; Raycast resolution
flPaper REAL4 640.0		; Paper width
flTramH REAL4 -1.6		; Tram cam height
flWmblykAnim REAL4 0.15	; Wmblyk animation speed

mnButton REAL4 256.0, 48.0	; Menu button size
mnFont REAL4 16.0, 32.0		; Menu font size
mnFontSpacing REAL4 1.25	; Menu font spacing (in scaled units)

; Array of 4-direction angles in radians to iterate through
rotations REAL4 0.0, 1.5707, 3.1415, -1.5707


; ----- INITIALIZED DATA -----
.DATA
CCGlyph DB "PLACED GLYPH. ? REMAINING.", 0	; For replacing ? with number
CCDeath DB "YOU DIED.", 0

canControl BYTE 0			; Boolean to enable/disable player control
focused BYTE 1				; Window focus
fullscreen BYTE 0			; Boolean to store if the game is fullscreen
resEnum DWORD 0				; Monitor resolution enumerator
lastTime DWORD 0			; Used to compare performance counter for deltaTime
perfFreq DWORD 0, 0			; 'QWORD' performance frequency, for deltaTime
playerState BYTE 11			; Player state for various uses, like cutscenes
screenSize DWORD 800, 600	; Screen size, changes when resizing
tick DWORD 0, 0				; 'QWORD' current tick, for deltaTime
windowSize DWORD 800, 600	; Window size to change back to after fullscreen
windowPos DWORD 0, 0		; Window position to change back to

keyUp BYTE 0				; Keys, too lazy to do bitwise stuff
keyDown BYTE 0
keyLeft BYTE 0
keyRight BYTE 0
keySpace BYTE 0
keyCtrl BYTE 0
keyLMB BYTE 0
debugF BYTE 0

SettStr DB 16 dup (0)
joystickID SDWORD -1	; Joystick ID
joystickXInput BYTE 0	; XInput or DirectInput (axes difference)
joyUsed BYTE 0			; If Joystick was used last
joyCrouch BYTE 0		; Keybinds
joyGlyph BYTE 0
joyAction BYTE 0
joyConfirm BYTE 0
joyMenu BYTE 0
joyLMB BYTE 0

msX REAL4 0.0	; Mouse position as REAL4
msY REAL4 0.0
winX SWORD 0	; Window position
winY SWORD 0
winW SWORD 0	; Window size
winH SWORD 0
winWS SWORD 0	; Size from settings
winHS SWORD 0
winWH SWORD 0
winHH SWORD 0
winCX SWORD 0	; Window center
winCY SWORD 0
winWHF REAL4 0.0
winHHF REAL4 0.0
winSize DWORD 0

camCrouch REAL4 0.0					; Camera crouch value that gets added to Y
camCurSpeed REAL4 0.0, 0.0, 0.0		; Current camera speed
camForward REAL4 0.0, 0.0, 0.0		; Camera forward vector
; Camera listener position and orientation, used to pass to alListenerfv
camListener REAL4 0.0, 0.0, 0.0, 0.0, -1.0, 0.0
camLight REAL4 -0.0, 0.0, -0.0		; Camera light local position
; Only the camera uses negative coordinates in glTranslatef
camPos REAL4 -0.6, -1.2, -1.0, 1.0	; Camera position (negative)
camPosN REAL4 0.0, 0.0				; Camera negative position (positive)
camPosL REAL4 -0.0, -1.2, -0.0		; Lerped camera position
camPosNext REAL4 -0.0, -1.2, -0.0	; Next camera position, for collision
camStranglePos REAL4 0.0, 0.0		; Position to return to after strangling
camRight REAL4 0.0, 0.0, 0.0		; Camera right vector
camRot REAL4 -0.5, -3.1, 0.0		; Camera rotation, in radians
camRotL REAL4 0.0, 3.14, 0.0		; Lerped camera rotation
camStep REAL4 0.0					; Value for animating walking
camStepSide REAL4 0.0				; Side step animation
camTilt REAL4 0.0					; Dynamic tilt when strafing
camTurnSpeed REAL4 0.3				; Mouse sensitivity
camJoySpeed REAL4 2.0				; Joystick sensitivity

lastStepSnd DWORD 0		; Last step sound index, to not repeat it

mouseRel SWORD 0, 0		; Mouse position, relative to screen center
mousePos SWORD 0, 0		; Absolute mouse position

ccTimer REAL4 -1.0	; Subtitles timer
ccText DWORD 0		; Subtitles text pointer	
ccTextLast BYTE 255	; Last subtitles index, to not repeat it

wmblyk DWORD 0				; Wmblyk's state
wmblykAnim DWORD 11			; Wmblyk's animation
wmblykPos REAL4 1.0, 7.0	; Wmblyk's position
wmblykDir REAL4 0.0			; Wmblyk's direction
wmblykBlink REAL4 5.0		; Wmblyk's blink and general-purpose timer
wmblykJumpscare REAL4 0.0	; Wmblyk's jumpscare value (used as alpha)
wmblykWalkAnim REAL4 7.0	; Wmblyk's walk animation speed etc
wmblykStrAnim REAL4 3.0		; Wmblyk's strangle animation speed etc
wmblykDirI DWORD 0			; Wmblyk's direction index (from rotations)
wmblykDirS BYTE 0, 4, 8, 12	; Wmblyk's direction pool (possible indices)
wmblykTurn BYTE 0			; Boolean if Wmblyk should turn
wmblykStr REAL4 0.0			; Strangling/fighting back value etc
wmblykStrState DWORD 13		; Wmblyk's strangling state
wmblykStrM REAL4 0.0		; Wmblyk's strangling music gain
wmblykStealth REAL4 0.0		; Wmblyk's general-purpose stealth value etc
wmblykStealthy BYTE 0		; Wmblyk's stealth state

kubaleAppeared BYTE 0		; Boolean if Kubale ever appeared
kubale DWORD 0				; Kubale state
kubaleDir REAL4 0.0			; Kubale direction
kubalePos REAL4 3.0, 3.0	; The act of transferring the Kubale
kubaleSpeed REAL4 0.0, 0.0	; Kubale speed, for collision
kubaleInkblot DWORD 0		; Kubale inkblot index
kubaleVision REAL4 0.0		; Kubale vision value (used as alpha and gain)
kubaleRun REAL4 0.0			; Kubale scampering sound gain

vasPos REAL4 0.0, 0.0

hbd BYTE 0				; Huenbergondel's state
hbdPos DWORD 0, 0		; Huenbergondel's position, in maze cell integers
hbdPosF REAL4 1.0, 1.0	; Huenbergondel's position, in floats (for drawing)
hbdRot DWORD 0			; Huenbergondel's rotation, in rotations[] index
hbdRotF REAL4 0.0		; Huenbergondel's rotation, in floats
hbdTimer REAL4 6.0		; Huenbergondel's timer
hbdMdl DWORD 56			; Huenbergondel's model index

doorSlam BYTE 0			; Door slam event state
doorSlamRot REAL4 0.0	; The entrance door rotation (for drawing)

virdya DWORD 0				; Virdya's model index
virdyaEmote BYTE 6			; Virdya's emote cooldown
virdyaBlink REAL4 1.0		; Virdya's blink and facial timer
virdyaDest REAL4 1.0, 1.0	; Virdya's destination position for walking state
virdyaFace DWORD 0			; Virdya's face texture pointer
virdyaHeadRot REAL4 0.0, 0.0; Virdya's head rotation (X, Y)
virdyaPos REAL4 3.0, 3.0	; Virdya's position
virdyaPosPrev REAL4 3.0, 3.0; Virdya's previous position (for calculating speed)
virdyaRot REAL4 3.1			; Virdya's global rotation
virdyaRotL REAL4 0.0, 0.0, 0.0	; Virdya's interpolated rotation
virdyaTimer REAL4 0.0		; Virdya's state timer
virdyaSpeed REAL4 0.0, 0.0	; Virdya's calculated speed
virdyaState BYTE 0			; Virdya's state
virdyaSound REAL4 0.0		; Virdya's defensive sound gain

camAspect REAL8 1.0		; Camera aspect ratio, changed when resizing
camFOV REAL8 75.0		; Camera FOV, may be dynamic

deltaTime REAL4 0.01	; Delta time multiplier
delta2 REAL4 0.01		; deltaTime * 2
delta10 REAL4 0.01		; deltaTime * 10

fade REAL4 1.0			; Fade value, used as alpha
fadeState BYTE 0		; Fade state, 0 = no fade, 1 = fade in, 2 = fade out
fogDensity REAL4 0.5	; Exponential fog density value, set with fade
vignetteRed REAL4 0.0	; Red vignette alpha

Menu BYTE 0			; Menu state, 0 = no menu, 1 = pause, 2 = options
Gamma REAL4 0.5		; Fake gamma / brightness multiplier

Compass BYTE 0	; Compass state, 0 = none, 1 = in layer, 2 = in possession
CompassPos REAL4 0.0, 0.0	; Compass item layer position
CompassRot REAL4 0.0		; Compass arrow rotation

Glyphs BYTE 7				; Available glyphs
GlyphsInLayer BYTE 0		; Glyphs placed in layer
GlyphOffset BYTE 0			; Glyph offset to not repeat placed
GlyphPos REAL4 14 DUP(0.0)	; Glyph positions
GlyphRot REAL4 7 DUP(0.0)	; Glyph rotations

MazeSeed DWORD 0	; Sneed's Feed & Seed (Formerly Chuck's)
MazeW DWORD 6		; Maze width
MazeH DWORD 6		; Maze height
MazeWM1 DWORD 0		; Maze width-1
MazeHM1 DWORD 0		; Maze height-1
MazePool DWORD 0	; Used when generating maze
MazeSize DWORD 0	; Maze byte size
MazeSizeM1 DWORD 0	; Maze - (1, 1) byte size
MazeType BYTE 0		; 0 - normal, 1 - squiggly, 2 - broken
MazeCrevice BYTE 0			; Maze crevice active
MazeCrevicePos DWORD 0, 0	; Maze crevice position to crawl through
MazeDoor REAL4 0.0			; Maze end door value, used for rotating
MazeDoorPos REAL4 0.0, 0.0	; Maze end door cell center position in REAL4
MazeGlyphs BYTE 0			; Maze glyphs item
MazeGlyphsPos REAL4 0.0, 0.0; Glyphs item position in layer
MazeGlyphsRot REAL4 0.0		; Glyphs item rotation
MazeLocked BYTE 0	; Locked layer, 0 = not locked, 1 = locked, 2 = unlocked
MazeKeyPos REAL4 0.0, 0.0	; Key position
MazeKeyRot REAL4 0.0, 0.0	; Key rotation
MazeHostile BYTE 0			; Used with intro
MazeNote BYTE 0				; Note state
MazeNotePos REAL4 0.0, 0.0	; Note position, rotation determined by MagnitudeSqr
MazeSiren REAL4 0.0			; Siren gain etc (intro)
MazeSirenTimer REAL4 51.0	; Siren timer (intro)
MazeTeleport BYTE 0			; Teleporters state
MazeTeleportPos REAL4 0.0, 0.0, 0.0, 0.0	; First & second tele positions
MazeTeleportRot REAL4 0.0	; Teleporter rotation for animating
MazeTram BYTE 0				; Tram state
MazeTramDoors DWORD 99		; Tram doors list to draw
MazeTramArea DWORD 0, 0		; The area (X from, X to) that the rails occupy
MazeTramRot DWORD 8, 0		; Tram direction (rotations[]) and REAL4 rotation
MazeTramPlr BYTE 0			; Tram player state
MazeTramPos REAL4 0.0, 0.0, 0.0	; Tram position (XYZ, for light)
MazeTramSpeed REAL4 0.0		; Tram speed to accelerate
MazeTramSnd DWORD 0			; Tram sound index
MazeRandTimer REAL4 10.0	; Random ambient sound timer
MazeRandPos REAL4 0.0, 0.0	; Random ambient sound position

WmblykTram BYTE 0	; Wmblyk can get on the tram

Checkpoint BYTE 0			; Checkpoint state
CheckpointDoor REAL4 0.0	; Checkpoint exit door rotation
CheckpointMus REAL4 0.0		; Checkpoint music gain level for interpolation
CheckpointPos REAL4 0.0, 0.0; Checkpoint position

AscendDoor BYTE 0					; Ascension door state for sound
AscendColor REAL4 0.0, 0.0, 0.0, 0.0; Ascension & wasteland sky & fog color
AscendVolume REAL4 0.0, 0.0			; Ascension volume value and lerp target
AscendSky REAL4 0.0					; Value to set AscendColor to

RubblePos REAL4 200.0, 200.0, 200.0, 200.0	; Wasteland rubble positions
MotryaDist REAL4 40.0

Motrya DWORD 0				; Motrya's state
MotryaTimer REAL4 0.1		; Motrya's timer (used for white fade too)
MotryaPos REAL4 0.0, 0.0	; Motrya's position
Save BYTE 0					; Save light state
SaveSize REAL4 0.0			; Save light size
SavePos REAL4 1.0, 0.2, 0.2	; Save XY position plus Y target position to lerp to

PMSeed DWORD 0	; Previous maze layer seed
PMW DWORD 0		; Previous maze width
PMH DWORD 0		; Previous maze height

MazeLevel DWORD 0	; Current maze layer
MazeLevelPopup BYTE 0	; Maze layer popup, 0 = none, 1 = down, 2 = up
MazeLevelPopupY REAL4 -48.0
MazeLevelPopupTimer REAL4 0.0

Shn BYTE 0
ShnTimer REAL4 80.0
ShnPos REAL4 1.0, 1.0

Vebra DWORD 0			; Vebra animation frame (and state)
VebraTimer REAL4 1.0	; Vebra animation timer

WBBK BYTE 0				; WBBK state
WBBKCamDir REAL4 0.0	; WBBK cam direction for lerping
WBBKDist REAL4 4.0		; WBBK distance factor
WBBKPos REAL4 1.0, 5.0	; WBBK position to draw at
WBBKSndID DWORD 5		; WBBK last ambient sound ID
WBBKSndPos REAL4 0.0, 0.0, 0.0, 0.0	; WBBK sound position
WBBKTimer REAL4 0.0		; WBBK general-purpose timer
WBBKSTimer REAL4 20.0	; WBBK timer when player isn't moving

; Was intended to be unabstracted Webubychko, but it was too thicc so changed it
WB BYTE 0				; WB unabstracted state
WBAnim BYTE 0			; WB animation (0 - idle, 1 - walk, 2 - attack)
WBFrame DWORD 114		; WB animation frame
WBMirror BYTE 0			; WB mirror animation
WBAnimTimer REAL4 0.0	; WB animation timer
WBTimer REAL4 0.0		; WB timer
WBPos REAL4 1.0, 3.0	; WB position
WBPosI DWORD 0, 0		; WB integer position
WBPosL REAL4 1.0, 3.0	; WB lerp position
WBPosP REAL4 1.0, 3.0	; WB previous position
WBRot REAL4 0.0, 0.0	; WB rotation + target
WBStack DWORD 0			; WB heapstack for solving
WBStackHandle DWORD 0	; WB heapstack handle that gets locked (if GlobalAlloc)
WBStackSize DWORD 0		; WB heapstack size
WBNext DWORD 0, 0		; WB next cell position
WBTarget REAL4 0.0, 0.0	; WB current target position
WBFinal REAL4 0.0, 0.0	; WB final target position
WBSpeed REAL4 0.0, 0.0	; WB calculated speed
WBSpMul REAL4 0.0		; WB speed multiplier
WBCurSpd REAL4 0.0		; WB current speed

MazeDrawCull DWORD 5	; The 'radius', in cells, to draw

Map BYTE 0				; Map state
MapBRID DWORD 0			; Map bottom-right cell ID (to not draw it)
MapOffset REAL4 0.0, 0.0; Map offset to center it (not yet used)
MapSize REAL4 0.0		; Map size multiplier to fit it into the parchment

NoiseOpacity REAL4 0.1, 0.1	; Used only for endgame noise due to blend problems

EBD BYTE 0				; Eblodryn state
EBDAnim REAL4 0.0		; Eblodryn animation variable
EBDPos REAL4 3.0, 3.0	; Eblodryn position
EBDSound REAL4 0.0		; Eblodryn attack sound gain

Shop BYTE 1				; Shop state
ShopKoluplyk DWORD 78	; Koluplyk's list
ShopTimer REAL4 0.0		; Koluplyk's timer for animation
ShopWall REAL4 3.0		; For moving the shop wall after purchasing

Croa BYTE 0			; Croa state
CroaCC BYTE 0		; Croa subtitles state
CroaTimer REAL4 3.0 ; Croa timer 
CroaCCTimer REAL4 5.0; Croa timer 
CroaPos REAL4 1.5	; For positioning Croa
CroaColor REAL4 0.0, 0.0, 0.0, 0.0	; Croa light color

Trench BYTE 0			; Trench state
TrenchTimer REAL4 0.0	; Trench timer, set in Control with movement
TrenchColor REAL4 1.0, 1.0, 1.0, 1.0	; To use as fog and clear color

IniReturn DB "........", 0	; Ini return dummy string
IniPathAbs DB 256 DUP (0)	; Absolute path to ini file

GetIniSettingsOnFirstFrame BYTE 0	; GetSettings on WM_CREATE had problems

Complete BYTE 0		; Game has been completed

; ----- UNINITIALIZED DATA -----
.DATA?
FPUMode WORD ?	; To load FPU control word

hInstance HINSTANCE ?	; Program instance
hwnd HWND ?		; Window handle
stHwnd HWND ?	; Settings window handle
stFullCheck HWND ?	; Settings window fullscreen checkbox
stResolLabel HWND ?	; Settings window resolution label
stResolCombo HWND ?	; Settings window resolution combobox
stBrigLabel HWND ?	; Settings window brightness label
stBrigTrack HWND ?	; Settings window brightness trackbar
stJoyLabel HWND ?	; Settings window joystick label
stJoyCombo HWND ?	; Settings window joystick combobox
stMSensLabel HWND ?	; Settings window mouse sensitivity label
stMSensTrack HWND ?	; Settings window mouse sensitivity trackbar
stJSensLabel HWND ?	; Settings window joystick sensitivity label
stJSensTrack HWND ?	; Settings window joystick sensitivity trackbar
stVolLabel HWND ?	; Settings window audio volume label
stVolTrack HWND ?	; Settings window audio volume trackbar
stOkBtn HWND ?		; Settings window OK button
GDI HDC ?		; Graphics device context
GLC HANDLE ?	; OpenGL context
RandSeed DD ?	; Random seed for nrandom

joyCaps JOYCAPSAFIX <>	; Joystick capabilities

Maze DWORD ?		; Maze memory
MazeBuffer DWORD ?	; Maze buffer pointer
MazeLevelStr DWORD ?; String, containing the layer number

defKey HKEY ?	; Default registry key

TexBricks DWORD ?	; Textures
TexCompass DWORD ?
TexCompassWorld DWORD ?
TexConcrete DWORD ?
TexConcreteRoof DWORD ?
TexCroa DWORD ?
TexCursor DWORD ?
TexDiamond DWORD ?
TexDirt DWORD ?
TexDoor DWORD ?
TexDoorblur DWORD ?
TexEBD DWORD ?, ?, ?
TexEBDShadow DWORD ?
TexFacade DWORD ?
TexFloor DWORD ?
TexGlyphs DWORD ?
TexHbd DWORD ?
TexKey DWORD ?
TexKoluplyk DWORD ?
TexLamp DWORD ?
TexLight DWORD ?
TexMap DWORD ?
TexMetal DWORD ?
TexMetalFloor DWORD ?
TexMetalRoof DWORD ?
TexMotrya DWORD ?
TexNoise DWORD ?
TexPaper DWORD ?
TexPipe DWORD ?
TexPlanks DWORD ?
TexPlaster DWORD ?
TexRain DWORD ?
TexRoof DWORD ?
TexSigns1 DWORD ?
TexShadow DWORD ?
TexSky DWORD ?
TexTaburetka DWORD ?
TexTileBig DWORD ?
TexTilefloor DWORD ?
TexTone DWORD ?
TexTram DWORD ?
TexTree DWORD ?
TexTutorial DWORD ?
TexTutorialJ DWORD ?
TexVas DWORD ?
TexVebra DWORD ?
TexVignette DWORD ?
TexVignetteRed DWORD ?
TexWall DWORD ?
TexWB DWORD ?
TexWBBK DWORD ?
TexWBBKP DWORD ?
TexWBBK1 DWORD ?
TexWhitewall DWORD ?

TexGlyph DWORD 7 DUP(?)

TexWmblykHappy DWORD ?
TexWmblykNeutral DWORD ?
TexWmblykJumpscare DWORD ?
TexWmblykStr DWORD ?
TexWmblykL1 DWORD ?
TexWmblykL2 DWORD ?
TexWmblykL3 DWORD ?
TexWmblykW1 DWORD ?
TexWmblykW2 DWORD ?

TexVirdyaBlink DWORD ?
TexVirdyaDown DWORD ?
TexVirdyaN DWORD ?
TexVirdyaNeut DWORD ?
TexVirdyaUp DWORD ?

TexKubale DWORD ?
TexKubaleInkblot DWORD 9 DUP(?)

ImgFont DWORD ?
TexFont DWORD 41 DUP(?)

SndAlarm DWORD ?	; Sounds
SndAmb DWORD ?
SndAmbT DWORD ?
SndAmbW DWORD ?, ?, ?, ?
SndCheckpoint DWORD ?
SndDeath DWORD ?
SndDig DWORD ?
SndDistress DWORD ?
SndDoorClose DWORD ?
SndDrip DWORD ?
SndEBD DWORD ?
SndEBDA DWORD ?
SndExit DWORD ?
SndExit1 DWORD ?
SndExplosion DWORD ?
SndHbd DWORD ?
SndHbdO DWORD ?
SndHurt DWORD ?
SndImpact DWORD ?
SndIntro DWORD ?
SndKey DWORD ?
SndKubale DWORD ?
SndKubaleAppear DWORD ?
SndKubaleV DWORD ?
SndMistake DWORD ?
SndMus1 DWORD ?
SndMus2 DWORD ?
SndMus3 DWORD ?
SndMus4 DWORD ?
SndMus5 DWORD ?
SndRand DWORD ?, ?, ?, ?, ?, ?
SndSave DWORD ?
SndScribble DWORD ?
SndSiren DWORD ?
SndSlam DWORD ?
SndSplash DWORD ?
SndStep DWORD ?, ?, ?, ?
SndTram DWORD ?
SndTramAnn DWORD ?, ?, ?
SndTramClose DWORD ?
SndTramOpen DWORD ?
SndVirdya DWORD ?
SndWBAlarm DWORD ?
SndWBAttack DWORD ?
SndWBIdle DWORD ?, ?
SndWBStep DWORD ?, ?, ?, ?
SndWBBK DWORD ?
SndWhisper DWORD ?
SndWmblyk DWORD ?
SndWmblykB DWORD ?
SndWmblykStr DWORD ?
SndWmblykStrM DWORD ?

CurrentFloor DWORD ?	; Pointers for environmental variety
CurrentRoof DWORD ?
CurrentWall DWORD ?
CurrentWallMDL DWORD ?

PixelBuffer DWORD ?		; Experimenting with the default framebuffer
PixelLock DWORD ?

; ----- IMPLEMENTATION -----
.CODE

AlertWB PROTO :BYTE
DrawTram PROTO
EraseTempSave PROTO
ErrorOut PROTO :DWORD
FreeMaze PROTO
GenerateMaze PROTO :DWORD
GetCellMZC PROTO :DWORD, :DWORD, :BYTE
GetMazeCellPos PROTO :REAL4, :REAL4, :DWORD, :DWORD
GetOffset PROTO :DWORD, :DWORD
GetPosition PROTO :DWORD
GetRandomMazePosition PROTO :DWORD, :DWORD
GLE PROTO
Halt PROTO
InitContext PROTO :DWORD
KeyPress PROTO :DWORD, :BYTE
MouseMove PROTO
MoveAndCollide PROTO :DWORD, :DWORD, :DWORD, :DWORD, :REAL4, :BYTE
Render PROTO
RenderUI PROTO
SaveGame PROTO
SetFullscreen PROTO :BYTE
SetMazeLevelStr PROTO :DWORD
SetNoiseOpacity PROTO
Shake PROTO :REAL4
ShowHideCursor PROTO :BYTE
ShowSubtitles PROTO :DWORD
SpawnMazeElements PROTO

; Convert integer (DWORD) value to string
IntToStr PROC StrA:DWORD, Val:SDWORD
	LOCAL Val1:DWORD, Ngtv:BYTE
	
	mov Ngtv, 0
	push ebx
	xor ebx, ebx
	m2m Val1, Val
	.IF (Val < 0)
		inc Ngtv
		mov eax, Val1
		sub eax, Val1
		sub eax, Val1
		mov Val1, eax
	.ENDIF
	.WHILE TRUE
		xor edx, edx
		mov eax, Val1
		mov ecx, 10
		div ecx
		mov Val1, eax
		add dl, 48
		
		push edx
		.IF (ebx)
			mov eax, StrA
			add eax, 1
			invoke RtlMoveMemory, eax, StrA, ebx
		.ENDIF
		pop edx
		mov eax, StrA
		mov BYTE PTR[eax], dl
		inc ebx
		.BREAK .IF (!Val1)
	.ENDW
	mov BYTE PTR[eax+ebx], 0
	.IF (Ngtv)
		mov eax, StrA
		add eax, 1
		invoke RtlMoveMemory, eax, StrA, ebx
		mov eax, StrA
		mov BYTE PTR[eax], 45
	.ENDIF
	mov eax, ebx
	pop ebx
	ret
IntToStr ENDP
; On this episode of horrific code - here's a "float" to string converter.
; Supports values 0.00 - 9.99, made for the in-game settings
FltDWToStr PROC StrA:DWORD, Val:DWORD
	invoke IntToStr, StrA, Val
	mov eax, StrA
	.IF (Val >= 100)
		inc eax
	.ENDIF
	mov ecx, StrA
	add ecx, 2
	.IF (Val < 10)
		inc ecx
	.ENDIF
	invoke RtlMoveMemory, ecx, eax, 2
	mov eax, StrA
	.IF (Val < 100)
		mov BYTE PTR [eax], 48
		.IF (Val < 10)
			mov BYTE PTR [eax+2], 48
		.ENDIF
	.ENDIF
	inc eax
	mov BYTE PTR [eax], 46
	mov BYTE PTR [eax+3], 0
	ret
FltDWToStr ENDP

; Lazy raycast implementation
CheckBlocked PROC XFrom:REAL4, YFrom:REAL4, XTo:REAL4, YTo:REAL4
	LOCAL Direction:REAL4, DirInt:DWORD, Distance:REAL4
	LOCAL CheckX:REAL4, CheckY:REAL4, MazeX:DWORD, MazeY:DWORD
	LOCAL ToMazeX:DWORD, ToMazeY:DWORD
	LOCAL Blocked:DWORD, Iterations:BYTE
	
	mov Blocked, 0
	mov Iterations, 0
	
	m2m CheckX, XFrom
	m2m CheckY, YFrom
	
	.WHILE TRUE
		inc Iterations
		.IF (Iterations == 64)
			print "Raycast maximum iterations reached.", 13, 10
			.BREAK
		.ENDIF
		
		invoke GetDirection, CheckX, CheckY, XTo, YTo
		mov Direction, eax
		fcmp Direction
		.IF (Sign?)
			fld Direction
			fadd PI2
			fstp Direction
		.ENDIF
		
		fld Direction
		fmul R2I
		fistp DirInt
		
		invoke GetMazeCellPos, CheckX, CheckY, ADDR MazeX, ADDR MazeY
		invoke GetMazeCellPos, XTo, YTo, ADDR ToMazeX, ADDR ToMazeY
		
		mov eax, ToMazeX
		.IF (MazeX == eax)
			mov eax, ToMazeY
			.IF (MazeY == eax)
				.BREAK
			.ENDIF
		.ENDIF
		
		print str$(MazeX), 32
		print str$(MazeY), 9
		
		SWITCH DirInt
			CASE 0, 4	;-Y
				invoke GetCellMZC, MazeX, MazeY, MZC_PASSTOP
				.IF !(al)
					inc Blocked
					.BREAK
				.ELSEIF (MazeCrevice)
					mov edx, MazeX
					mov eax, MazeY
					.IF (edx == MazeCrevicePos) && (eax == MazeCrevicePos[4])
						inc Blocked
						.BREAK
					.ENDIF
				.ENDIF
				fld CheckY
				fsub flRaycast
				fstp CheckY
			CASE 1		;-X
				invoke GetCellMZC, MazeX, MazeY, MZC_PASSLEFT
				.IF !(al)
					inc Blocked
					.BREAK
				.ELSE
					.IF (MazeCrevice)
						mov edx, MazeX
						mov eax, MazeY
						.IF (edx == MazeCrevicePos) && (eax == MazeCrevicePos[4])
							inc Blocked
							.BREAK
						.ENDIF
					.ENDIF
				.ENDIF
				fld CheckX
				fsub flRaycast
				fstp CheckX
			CASE 2		;+Y
				inc MazeY
				invoke GetCellMZC, MazeX, MazeY, MZC_PASSTOP
				.IF !(al)
					inc Blocked
					.BREAK
				.ELSE
					.IF (MazeCrevice)
						mov edx, MazeX
						mov eax, MazeY
						.IF (edx == MazeCrevicePos) && (eax == MazeCrevicePos[4])
							inc Blocked
							.BREAK
						.ENDIF
					.ENDIF
				.ENDIF
				fld CheckY
				fadd flRaycast
				fstp CheckY
			CASE 3		;+X
				inc MazeX
				invoke GetCellMZC, MazeX, MazeY, MZC_PASSLEFT
				.IF !(al)
					inc Blocked
					.BREAK
				.ELSE
					.IF (MazeCrevice)
						mov edx, MazeX
						mov eax, MazeY
						.IF (edx == MazeCrevicePos) && (eax == MazeCrevicePos[4])
							inc Blocked
							.BREAK
						.ENDIF
					.ENDIF
				.ENDIF
				fld CheckX
				fadd flRaycast
				fstp CheckX
		ENDSW
		
		invoke DistanceToSqr, CheckX, CheckY, XTo, YTo
		mov Distance, eax
		fcmp Distance, flRaycast
		.IF (Sign?)
			.BREAK
		.ENDIF
	.ENDW
	
	print "DONE", 13, 10
	
	mov eax, Blocked
	ret
CheckBlocked ENDP

; Player collision with boundary from (X1, Y1) to (X2, Y2)
CollidePlayer PROC X1:REAL4, X2:REAL4, Y1:REAL4, Y2:REAL4, Vertical:BYTE
	invoke InRange, camPosNext, camPosNext[8], X1, X2, Y1, Y2
	.IF (al == 1)
		.IF (Vertical != 0)
			fldz
			fstp camCurSpeed
		.ELSE
			fldz
			fstp camCurSpeed[8]
		.ENDIF
		
		fld camPosN	; Second check because I like messing up performance
		fsub camCurSpeed
		fstp camPosNext
		fld camPosN[4]
		fsub camCurSpeed[8]
		fstp camPosNext[8]
		invoke InRange, camPosNext, camPosNext[8], X1, X2, Y1, Y2
		
		.IF (al == 1)
			fld camCurSpeed
			fchs
			fstp camCurSpeed
			fld camCurSpeed[8]
			fchs
			fstp camCurSpeed[8]
		.ENDIF
	.ENDIF
	ret
CollidePlayer ENDP
; Player collision with wall at (PosX, PosY)
CollidePlayerWall PROC PosX:REAL4, PosY:REAL4, Vertical:BYTE
	LOCAL BndX1:REAL4, BndX2:REAL4, BndY1:REAL4, BndY2:REAL4, Dist:REAL4

	.IF (Vertical == 0)	; Set boundary for collision
		fld PosX
		fsub flWMr
		fstp BndX1
		fld PosX
		fadd flWLn
		fstp BndX2
		
		fld PosY
		fsub flWTh
		fstp BndY1
		fld PosY
		fadd flWTh
		fstp BndY2
	.ELSE
		fld PosY
		fsub flWMr
		fstp BndY1
		fld PosY
		fadd flWLn
		fstp BndY2
		
		fld PosX
		fsub flWTh
		fstp BndX1
		fld PosX
		fadd flWTh
		fstp BndX2
	.ENDIF
	
	invoke DistanceToSqr, camPosNext, camPosNext[8], PosX, PosY	; Bad idea?
	mov Dist, eax
	
	fcmp Dist, fl6
	.IF (Sign?)
		; Now kiss
		invoke CollidePlayer, BndX1, BndX2, BndY1, BndY2, Vertical
	.ENDIF
	
	ret
CollidePlayerWall ENDP

; Joystick controls
JoystickButtons PROC JoyInfo:DWORD
	mov ebx, JoyInfo
	assume ebx:PTR JOYINFOEX
	mov eax, [ebx].dwButtons	; Glyphs
	.IF (joystickXInput)
		and eax, JOY_BUTTON3
	.ELSE
		and eax, JOY_BUTTON1
	.ENDIF
	.IF (al != joyGlyph)
		mov joyGlyph, al
		push ebx
		invoke KeyPress, 71, al
		pop ebx
		mov joyUsed, 1
	.ENDIF
	
	mov eax, [ebx].dwButtons	; Crouch
	and eax, JOY_BUTTON5
	.IF (al != joyCrouch)
		mov joyCrouch, al
		push ebx
		invoke KeyPress, 17, al
		pop ebx
		mov joyUsed, 1
	.ENDIF
	
	mov eax, [ebx].dwButtons	; Menu
	.IF (joystickXInput)
		and eax, JOY_BUTTON8
	.ELSE
		and eax, JOY_BUTTON10
	.ENDIF
	shr eax, 7
	.IF (al != joyMenu)
		mov joyMenu, al
		push ebx
		invoke KeyPress, 27, al
		pop ebx
		mov joyUsed, 1
	.ENDIF
	
	mov eax, [ebx].dwButtons	; Confirm
	.IF (joystickXInput)
		and eax, JOY_BUTTON7
	.ELSE
		and eax, JOY_BUTTON9
	.ENDIF
	shr eax, 6
	.IF (al != joyConfirm)
		mov joyConfirm, al
		push ebx
		invoke KeyPress, 13, al
		pop ebx
		mov joyUsed, 1
	.ENDIF
	
	mov eax, [ebx].dwButtons	; LMB
	.IF (joystickXInput)
		and eax, JOY_BUTTON1
	.ELSE
		and eax, JOY_BUTTON2
	.ENDIF
	.IF (al != joyLMB)
		mov joyLMB, al
		.IF (joyLMB)
			mov keyLMB, 1
		.ELSE
			mov keyLMB, 0
		.ENDIF
		push ebx
		invoke KeyPress, 32, al
		pop ebx
		mov joyUsed, 1
	.ENDIF
	
	assume eax:nothing
	ret
JoystickButtons ENDP
JoystickControl PROC JoyInfo:DWORD
	LOCAL joyX:REAL4, joyY:REAL4, dist:REAL4
	mov ebx, JoyInfo
	assume ebx:PTR JOYINFOEX
	
	fild [ebx].dwXpos	; X axis movement
	fdiv fl32768
	fsub fl1
	fstp joyX
	invoke DistanceScalar, joyX, fl0
	mov dist, eax
	fcmp dist, flTenth
	.IF (!Sign?)
		fld flCamSpeed
		fsub camCrouch
		fmul camRight
		fmul joyX
		fadd camCurSpeed
		fstp camCurSpeed
		
		fld flCamSpeed
		fsub camCrouch
		fmul camRight[8]
		fmul joyX
		fadd camCurSpeed[8]
		fstp camCurSpeed[8]
		mov joyUsed, 1
	.ENDIF
	fild [ebx].dwYpos	; Y axis movement
	fdiv fl32768
	fsub fl1
	fchs
	fstp joyY
	invoke DistanceScalar, joyY, fl0
	mov dist, eax
	fcmp dist, flTenth
	.IF (!Sign?)
		fld flCamSpeed
		fsub camCrouch
		fmul camForward
		fmul joyY
		fadd camCurSpeed
		fstp camCurSpeed
		
		fld flCamSpeed
		fsub camCrouch
		fmul camForward[8]
		fmul joyY
		fadd camCurSpeed[8]
		fstp camCurSpeed[8]
		mov joyUsed, 1
	.ENDIF
	
	.IF (joystickXInput)	; X axis look
		fild [ebx].dwUpos
	.ELSE
		fild [ebx].dwZpos
	.ENDIF
	fdiv fl32768
	fsub fl1
	fchs
	fstp joyX
	invoke DistanceScalar, joyX, 0
	mov dist, eax
	fcmp dist, flTenth
	.IF (!Sign?)
		fld joyX
		fmul camJoySpeed
		fmul delta2
		fadd camRot[4]
		fstp camRot[4]
		mov joyUsed, 1
	.ENDIF
	fild [ebx].dwRpos	; Y axis look
	fdiv fl32768
	fsub fl1
	fstp joyY
	invoke DistanceScalar, joyY, 0
	mov dist, eax
	fcmp dist, flTenth
	.IF (!Sign?)
		fld joyY
		fmul camJoySpeed
		fmul delta2
		fadd camRot
		fstp camRot
		mov joyUsed, 1
	.ENDIF
	
	assume ebx:nothing
	ret
JoystickControl ENDP
JoystickMenu PROC JoyInfo:DWORD
	LOCAL joyX:REAL4, joyY:REAL4, dist:REAL4, moved:BYTE
	
	mov moved, 0
	mov ebx, JoyInfo
	assume ebx:PTR JOYINFOEX
	
	fild [ebx].dwXpos	; X axis
	fdiv fl32768
	fsub fl1
	fstp joyX
	invoke DistanceScalar, joyX, fl0
	mov dist, eax
	fcmp dist, flTenth
	.IF (!Sign?)
		xor eax, eax
		mov ax, mousePos
		mov joyY, eax
		fld joyX
		fmul camJoySpeed
		fmul fl10
		fiadd joyY
		fistp joyX
		mov eax, joyX
		mov mousePos, ax
		inc moved
	.ENDIF
	fild [ebx].dwYpos	; Y axis
	fdiv fl32768
	fsub fl1
	fstp joyY
	invoke DistanceScalar, joyY, fl0
	mov dist, eax
	fcmp dist, flTenth
	.IF (!Sign?)
		xor eax, eax
		mov ax, mousePos[2]
		mov joyX, eax
		fld joyY
		fmul camJoySpeed
		fmul fl10
		fiadd joyX
		fistp joyY
		mov eax, joyY
		mov mousePos[2], ax
		inc moved
	.ENDIF
	
	.IF (moved)
		print sword$(mousePos), 32
		mov ax, mousePos[2]
		print sword$(ax), 13, 10
		mov joyUsed, 1
		invoke CreateThread, NULL, 0, OFFSET MouseMove, 0, 0, NULL
	.ENDIF
	
	assume ebx:nothing
	ret
JoystickMenu ENDP

; Control player, called if canControl != 0
Control PROC JoyInfo:DWORD
	LOCAL curSpeed:REAL4, speedMgn:REAL4
	
	mov curSpeed, 0
	fldz
	fst camCurSpeed
	fstp camCurSpeed[8]
	
	.IF (keyUp == 1) || (keyDown == 1)
		fld camForward
		.IF keyDown == 1
			fchs
		.ENDIF
		fadd camCurSpeed
		fstp camCurSpeed
		
		fld camForward[8]
		.IF keyDown == 1
			fchs
		.ENDIF
		fadd camCurSpeed[8]
		fstp camCurSpeed[8]
	.ENDIF
	.IF keyLeft == 1 || keyRight == 1
		fld camRight
		.IF keyLeft == 1
			fchs
		.ENDIF
		fadd camCurSpeed
		fstp camCurSpeed
		
		fld camRight[8]
		.IF keyLeft == 1
			fchs
		.ENDIF
		fadd camCurSpeed[8]
		fstp camCurSpeed[8]
	.ENDIF
	
	.IF (keyCtrl) || (MazeCrevice == 2)
		invoke Lerp, ADDR camCrouch, fl2, delta10
	.ELSE
		invoke Lerp, ADDR camCrouch, 0, delta10
	.ENDIF
	
	.IF !(MazeTramPlr)
		fld camCrouch	; Account for crouch
		fmul flQuarter
		fadd flCamHeight
		fstp camPos[4]
	.ENDIF
	
	.IF (joystickID != -1)
		invoke JoystickControl, JoyInfo
	.ENDIF
	
	fld camCurSpeed	; Tilt
	fmul camRight
	fstp curSpeed
	fld camCurSpeed[8]
	fmul camRight[8]
	fchs
	fadd curSpeed
	fstp curSpeed
	invoke Lerp, ADDR camTilt, curSpeed, delta2
	
	invoke MagnitudeSqr, camCurSpeed, camCurSpeed[8]	; Clamp magnitude
	mov speedMgn, eax
	fcmp speedMgn, fl1
	.IF (!Sign?)
		fld speedMgn
		fsqrt
		fstp curSpeed
		fld camCurSpeed
		fdiv curSpeed
		fstp camCurSpeed
		fld camCurSpeed[8]
		fdiv curSpeed
		fstp camCurSpeed[8]
	.ENDIF
	
	invoke MagnitudeSqr, camCurSpeed, camCurSpeed[8]
	mov curSpeed, eax
	fld curSpeed
	fmul deltaTime
	fstp curSpeed
	
	fld flCamSpeed		; Deltatimize
	fsub camCrouch
	fmul camCurSpeed
	fmul deltaTime
	fstp camCurSpeed
	fld flCamSpeed
	fsub camCrouch
	fmul camCurSpeed[8]
	fmul deltaTime
	fstp camCurSpeed[8]
	
	.IF (Trench)	; Process trench
		fld curSpeed
		fmul deltaTime
		fsubr TrenchTimer
		fstp TrenchTimer
		
		print real4$(TrenchTimer),13, 10
		
		fld camCurSpeed
		fmul flHalf
		fstp camCurSpeed
		fld camCurSpeed[8]
		fmul flHalf
		fstp camCurSpeed[8]
		
		fld curSpeed
		fmul flHalf
		fstp curSpeed
		
		fcmp TrenchTimer
		.IF (Sign?)
			invoke alSourcePlay, SndMistake
			mov Trench, 0
			m2m fade, fl1
			mov fadeState, 1
			invoke glClearColor, 0, 0, 0, 0
			invoke glFogfv, GL_FOG_COLOR, ADDR clBlack
			invoke alSourceStop, SndAmbT
			invoke alSourcePlay, SndAmb
			
			invoke alSourcef, SndWmblykB, AL_PITCH, fl1
			invoke alSourcef, SndWmblykB, AL_GAIN, fl1
			invoke alSourceStop, SndWmblykB
			
			fld fl75
			fstp camFOV
			
			invoke ShowSubtitles, ADDR CCTrench
			
			invoke SpawnMazeElements
		.ENDIF
	.ENDIF
	.IF (MazeHostile >= 8) && (MazeHostile <= 11)
		fld NoiseOpacity
		fmul fl2
		fmul camCurSpeed
		fstp camCurSpeed
		fld NoiseOpacity
		fmul fl2
		fmul camCurSpeed[8]
		fstp camCurSpeed[8]
		
		fld NoiseOpacity
		fmul fl2
		fmul curSpeed
		fstp curSpeed
	.ENDIF
	
	fld curSpeed	; Walk animation
	fmul flStep
	fadd camStep
	fstp camStep
	
	fld curSpeed
	fmul flStep
	fadd camStepSide
	fstp camStepSide
	
	.IF (curSpeed) && (WBBK)
		m2m WBBKSTimer, fl10
	.ENDIF
	
	fld fl3
	fsub camCrouch
	fmul fl04
	fstp curSpeed
	invoke alSourcef, SndStep, AL_GAIN, curSpeed
	invoke alSourcef, SndStep[4], AL_GAIN, curSpeed
	invoke alSourcef, SndStep[8], AL_GAIN, curSpeed
	invoke alSourcef, SndStep[12], AL_GAIN, curSpeed
	
	fcmp camStep, PI	; Loop camStep and play random step sound
	.IF !Sign? && !Zero?
		fld PI
		fsubr camStep
		fstp camStep
		.REPEAT
			invoke nrandom, 4
		.UNTIL (eax != lastStepSnd)
		mov ecx, 4
		mul ecx
		mov lastStepSnd, eax
		invoke alSourcePlay, SndStep[eax]
		fcmp curSpeed, flHalf
		.IF (!Sign?)
			invoke AlertWB, 1
		.ELSE
			invoke AlertWB, 0
		.ENDIF
	.ENDIF
	fcmp camStepSide, PI2	; Loop camStep and play random step sound
	.IF !Sign? && !Zero?
		fld PI2
		fsubr camStepSide
		fstp camStepSide
	.ENDIF
	
	invoke Clamp, camRot, PIHalfN, PIHalf	; Clamp pitch so you can't spindash
	mov camRot, eax
	ret
Control ENDP

; Load all models and textures
CreateModels PROC
	LOCAL hFile:DWORD, dwFileSize:DWORD, dwBytesRead:DWORD, dwHighSize:DWORD
	LOCAL mem:DWORD, numOfChars:DWORD
	
	print "Creating models...", 13, 10
	invoke glNewList, 3, GL_COMPILE_AND_EXECUTE
	invoke glBegin, GL_QUADS
		invoke glTexCoord2f, qdUVBottomLeft, qdUVBottomLeft[4]
		invoke glVertex3f, qdBottomLeft, qdBottomLeft[4], qdBottomLeft[8]
		invoke glTexCoord2f, qdUVBottomRight, qdUVBottomRight[4]
		invoke glVertex3f, qdBottomRight, qdBottomRight[4], qdBottomRight[8]
		invoke glTexCoord2f, qdUVTopRight, qdUVTopRight[4]
		invoke glVertex3f, qdTopRight, qdTopRight[4], qdTopRight[8]
		invoke glTexCoord2f, qdUVTopLeft, qdUVTopLeft[4]
		invoke glVertex3f, qdTopLeft, qdTopLeft[4], qdTopLeft[8]
	invoke glEnd
	invoke glEndList
	
	invoke LoadGCM, ADDR MdlWallM,			1
	invoke LoadGCM, ADDR MdlPlane,			2
	; Quad built in code					3
	invoke LoadGCM, ADDR MdlDoor,			4
	invoke LoadGCM, ADDR MdlDoorFrame,		5
	invoke LoadGCM, ADDR MdlDoorway,		6
	invoke LoadGCM, ADDR MdlLamp,			7
	invoke LoadGCM, ADDR MdlWmblykBody,		8
	invoke LoadGCM, ADDR MdlWmblykHead,		9
	invoke LoadGCM, ADDR MdlWmblykBodyG,	10
	invoke LoadGCM, ADDR MdlWmblykWalk1,	11
	invoke LoadGCM, ADDR MdlWmblykWalk2,	12
	invoke LoadGCM, ADDR MdlWmblykWalk3,	13
	invoke LoadGCM, ADDR MdlWmblykWalk4,	14
	invoke LoadGCM, ADDR MdlWmblykStr1,		15
	invoke LoadGCM, ADDR MdlWmblykStr2,		16
	invoke LoadGCM, ADDR MdlWmblykStr0,		17
	invoke LoadGCM, ADDR MdlWmblykStrL1,	18
	invoke LoadGCM, ADDR MdlWmblykStrL2,	19
	invoke LoadGCM, ADDR MdlWmblykStrL0,	20
	invoke LoadGCM, ADDR MdlWmblykStrW1,	21
	invoke LoadGCM, ADDR MdlWmblykStrW2,	22
	invoke LoadGCM, ADDR MdlWmblykStrW0,	23
	invoke LoadGCM, ADDR MdlWmblykDead,		24
	invoke LoadGCM, ADDR MdlWallT,			25
	invoke LoadGCM, ADDR MdlWallB,			26
	invoke LoadGCM, ADDR MdlStairs,			27
	invoke LoadGCM, ADDR MdlPipe,			28
	invoke LoadGCM, ADDR MdlKubale1,		29
	invoke LoadGCM, ADDR MdlKubale2,		30
	invoke LoadGCM, ADDR MdlKubale3,		31
	invoke LoadGCM, ADDR MdlKubale4,		32
	invoke LoadGCM, ADDR MdlDoorFrameLock,	33
	invoke LoadGCM, ADDR MdlPadlock,		34
	invoke LoadGCM, ADDR MdlKey,			35
	invoke LoadGCM, ADDR MdlGlyphs,			36
	invoke LoadGCM, ADDR MdlWires,			37
	invoke LoadGCM, ADDR MdlCompassWorld,	38
	invoke LoadGCM, ADDR MdlCompassArrow,	39
	invoke LoadGCM, ADDR MdlCityConcrete,	40
	invoke LoadGCM, ADDR MdlCityFacade,		41
	invoke LoadGCM, ADDR MdlCityTerrain,	42
	invoke LoadGCM, ADDR MdlOutsRoad,		43
	invoke LoadGCM, ADDR MdlOutsTerrain,	44
	invoke LoadGCM, ADDR MdlOutsTrees,		45
	invoke LoadGCM, ADDR MdlOutsBunker,		46
	invoke LoadGCM, ADDR MdlSigil1,			47
	invoke LoadGCM, ADDR MdlSigil2,			48
	invoke LoadGCM, ADDR MdlTaburetka,		49
	invoke LoadGCM, ADDR MdlWallTR,			50
	invoke LoadGCM, ADDR MdlPlanks,			51
	invoke LoadGCM, ADDR MdlVasT1,			52
	invoke LoadGCM, ADDR MdlVasT2,			53
	invoke LoadGCM, ADDR MdlVasT3,			54
	invoke LoadGCM, ADDR MdlHbd,			55
	invoke LoadGCM, ADDR MdlHbdS,			56
	invoke LoadGCM, ADDR MdlVirdyaHead,		57
	invoke LoadGCM, ADDR MdlVirdyaBody,		58
	invoke LoadGCM, ADDR MdlVirdyaWalk1,	59
	invoke LoadGCM, ADDR MdlVirdyaWalk2,	60
	invoke LoadGCM, ADDR MdlVirdyaWalk3,	61
	invoke LoadGCM, ADDR MdlVirdyaWalk4,	62
	invoke LoadGCM, ADDR MdlVirdyaWalk5,	63
	invoke LoadGCM, ADDR MdlVirdyaWalk6,	64
	invoke LoadGCM, ADDR MdlVirdyaWalk7,	65
	invoke LoadGCM, ADDR MdlVirdyaWalk8,	66
	invoke LoadGCM, ADDR MdlVirdyaRest,		67
	invoke LoadGCM, ADDR MdlVirdyaBack1,	68
	invoke LoadGCM, ADDR MdlVirdyaBack2,	69
	invoke LoadGCM, ADDR MdlVirdyaBack3,	70
	invoke LoadGCM, ADDR MdlVirdyaBack4,	71
	invoke LoadGCM, ADDR MdlVirdyaBack5,	72
	invoke LoadGCM, ADDR MdlVirdyaBack6,	73
	invoke LoadGCM, ADDR MdlVirdyaH1,		74
	invoke LoadGCM, ADDR MdlVirdyaH2,		75
	invoke LoadGCM, ADDR MdlWallS,			76
	invoke LoadGCM, ADDR MdlSigns1,			77
	invoke LoadGCM, ADDR MdlKoluplykShop1,	78
	invoke LoadGCM, ADDR MdlKoluplykShop2,	79
	invoke LoadGCM, ADDR MdlKoluplykDig1,	80
	invoke LoadGCM, ADDR MdlKoluplykDig2,	81
	invoke LoadGCM, ADDR MdlKoluplykDig3,	82
	invoke LoadGCM, ADDR MdlKoluplykDig4,	83
	invoke LoadGCM, ADDR MdlPlaneC,			84
	invoke LoadGCM, ADDR MdlCheckFloor,		85
	invoke LoadGCM, ADDR MdlCheckWalls,		86
	invoke LoadGCM, ADDR MdlCheckRoof,		87
	invoke LoadGCM, ADDR MdlMotrya1,		88
	invoke LoadGCM, ADDR MdlMotrya2,		89
	invoke LoadGCM, ADDR MdlMotrya3,		90
	invoke LoadGCM, ADDR MdlMotrya4,		91
	invoke LoadGCM, ADDR MdlWallT2,			92
	invoke LoadGCM, ADDR MdlWallW,			93
	invoke LoadGCM, ADDR MdlUpFloor,		94
	invoke LoadGCM, ADDR MdlUpWalls,		95
	invoke LoadGCM, ADDR MdlUpRoof,			96
	invoke LoadGCM, ADDR MdlTerrain,		97
	invoke LoadGCM, ADDR MdlTram,			98
	invoke LoadGCM, ADDR MdlTramD1,			99
	invoke LoadGCM, ADDR MdlTramD2,			100
	invoke LoadGCM, ADDR MdlTramD3,			101
	invoke LoadGCM, ADDR MdlTramD4,			102
	invoke LoadGCM, ADDR MdlTrack,			103
	invoke LoadGCM, ADDR MdlTrackTurn,		104
	invoke LoadGCM, ADDR MdlWmblykTram,		105
	invoke LoadGCM, ADDR MdlCrevice,		106
	invoke LoadGCM, ADDR MdlWmblykCrawl1,	107
	invoke LoadGCM, ADDR MdlWmblykCrawl2,	108
	invoke LoadGCM, ADDR MdlNeqaotor,		109
	invoke LoadGCM, ADDR MdlTorlagg,		110
	invoke LoadGCM, ADDR MdlBorderFloor,	111
	invoke LoadGCM, ADDR MdlBorderWall,		112
	invoke LoadGCM, ADDR MdlSky,			113
	invoke LoadGCM, ADDR MdlWBWalk1,		114
	invoke LoadGCM, ADDR MdlWBWalk2,		115
	invoke LoadGCM, ADDR MdlWBWalk3,		116
	invoke LoadGCM, ADDR MdlWBIdle1,		117
	invoke LoadGCM, ADDR MdlWBIdle2,		118
	invoke LoadGCM, ADDR MdlWBAttack1,		119
	invoke LoadGCM, ADDR MdlWBAttack2,		120
	invoke LoadGCM, ADDR MdlWBAttack3,		121
	invoke LoadGCM, ADDR MdlWBBK,			122
	invoke LoadGCM, ADDR MdlVirdyaWave1,	123
	invoke LoadGCM, ADDR MdlVirdyaWave2,	124
	invoke LoadGCM, ADDR MdlVirdyaWave3,	125
	invoke LoadGCM, ADDR MdlVirdyaWave4,	126
	invoke LoadGCM, ADDR MdlVirdyaWave5,	127
	invoke LoadGCM, ADDR MdlVirdyaWave4,	128	; Ultra lazy
	invoke LoadGCM, ADDR MdlVirdyaWave5,	129
	invoke LoadGCM, ADDR MdlVirdyaWave4,	130
	invoke LoadGCM, ADDR MdlVirdyaWave2,	131
	invoke LoadGCM, ADDR MdlWallD,			132
	invoke LoadGCM, ADDR MdlVebraLook1,		133
	invoke LoadGCM, ADDR MdlVebraLook2,		134
	invoke LoadGCM, ADDR MdlVebraExit1,		135
	invoke LoadGCM, ADDR MdlVebraExit2,		136
	invoke LoadGCM, ADDR MdlVebraExit3,		137
	invoke LoadGCM, ADDR MdlVebraExit4,		138
	invoke LoadGCM, ADDR MdlVebraExit5,		139
	invoke LoadGCM, ADDR MdlVebraExit6,		140

	invoke LoadTexture, ADDR ImgBricks, IMG_GCT
	mov TexBricks, eax
	invoke LoadTexture, ADDR ImgCompass, IMG_GCT5A1
	mov TexCompass, eax
	invoke LoadTexture, ADDR ImgCompassWorld, IMG_GCT5A1
	mov TexCompassWorld, eax
	invoke LoadTexture, ADDR ImgConcrete, IMG_GCT
	mov TexConcrete, eax
	invoke LoadTexture, ADDR ImgConcreteRoof, IMG_GCT
	mov TexConcreteRoof, eax
	invoke LoadTexture, ADDR ImgCroa, IMG_GCT5A1
	mov TexCroa, eax
	invoke LoadTexture, ADDR ImgCursor, IMG_GCT332
	mov TexCursor, eax
	invoke LoadTexture, ADDR ImgDiamond, IMG_GCT
	mov TexDiamond, eax
	invoke LoadTexture, ADDR ImgDirt, IMG_GCT
	mov TexDirt, eax
	invoke LoadTexture, ADDR ImgDoor, IMG_GCT
	mov TexDoor, eax
	invoke LoadTexture, ADDR ImgDoorblur, IMG_GCT
	mov TexDoorblur, eax
	invoke LoadTexture, ADDR ImgEBD1, IMG_GCT4 or IMG_HALFX
	mov TexEBD, eax
	invoke LoadTexture, ADDR ImgEBD2, IMG_GCT4 or IMG_HALFX
	mov TexEBD[4], eax
	invoke LoadTexture, ADDR ImgEBD3, IMG_GCT4 or IMG_HALFX
	mov TexEBD[8], eax
	invoke LoadTexture, ADDR ImgEBDShadow, IMG_GCT332
	mov TexEBDShadow, eax
	invoke LoadTexture, ADDR ImgFacade, IMG_GCT
	mov TexFacade, eax
	invoke LoadTexture, ADDR ImgFloor, IMG_GCT
	mov TexFloor, eax
	invoke LoadTexture, ADDR ImgGlyphs, IMG_GCT
	mov TexGlyphs, eax
	invoke LoadTexture, ADDR ImgHbd, IMG_GCT
	mov TexHbd, eax
	invoke LoadTexture, ADDR ImgKey, IMG_GCT5A1 or IMG_HALFX
	mov TexKey, eax
	invoke LoadTexture, ADDR ImgKoluplyk, IMG_GCT
	mov TexKoluplyk, eax
	invoke LoadTexture, ADDR ImgLamp, IMG_GCT
	mov TexLamp, eax
	invoke LoadTexture, ADDR ImgLight, IMG_GCT
	mov TexLight, eax
	invoke LoadTexture, ADDR ImgMap, IMG_GCT5A1
	mov TexMap, eax
	invoke LoadTexture, ADDR ImgMetal, IMG_GCT
	mov TexMetal, eax
	invoke LoadTexture, ADDR ImgMetalFloor, IMG_GCT
	mov TexMetalFloor, eax
	invoke LoadTexture, ADDR ImgMetalRoof, IMG_GCT
	mov TexMetalRoof, eax
	invoke LoadTexture, ADDR ImgMotrya, IMG_GCT
	mov TexMotrya, eax
	invoke LoadTexture, ADDR ImgNoise, IMG_GCT
	mov TexNoise, eax
	invoke LoadTexture, ADDR ImgPaper, IMG_GCT5A1
	mov TexPaper, eax
	invoke LoadTexture, ADDR ImgPipe, IMG_GCT
	mov TexPipe, eax
	invoke LoadTexture, ADDR ImgPlanks, IMG_GCT
	mov TexPlanks, eax
	invoke LoadTexture, ADDR ImgPlaster, IMG_GCT
	mov TexPlaster, eax
	invoke LoadTexture, ADDR ImgRain, IMG_GCT
	mov TexRain, eax
	invoke LoadTexture, ADDR ImgRoof, IMG_GCT
	mov TexRoof, eax
	invoke LoadTexture, ADDR ImgSigns1, IMG_GCT
	mov TexSigns1, eax
	invoke LoadTexture, ADDR ImgShadow, IMG_GCT
	mov TexShadow, eax
	invoke LoadTexture, ADDR ImgSky, IMG_GCT or IMG_HALFX
	mov TexSky, eax
	invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR
	invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR
	;invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP
	invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP
	invoke LoadTexture, ADDR ImgTaburetka, IMG_GCT
	mov TexTaburetka, eax
	invoke LoadTexture, ADDR ImgTileBig, IMG_GCT
	mov TexTileBig, eax
	invoke LoadTexture, ADDR ImgTilefloor, IMG_GCT
	mov TexTilefloor, eax
	invoke LoadTexture, ADDR ImgTone, IMG_GCT332
	mov TexTone, eax
	invoke LoadTexture, ADDR ImgTram, IMG_GCT
	mov TexTram, eax
	invoke LoadTexture, ADDR ImgTree, IMG_GCT5A1
	mov TexTree, eax
	invoke LoadTexture, ADDR ImgTutorial, IMG_GCT332
	mov TexTutorial, eax
	invoke LoadTexture, ADDR ImgTutorialJ, IMG_GCT332
	mov TexTutorialJ, eax
	invoke LoadTexture, ADDR ImgVas, IMG_GCT
	mov TexVas, eax
	invoke LoadTexture, ADDR ImgVebra, IMG_GCT
	mov TexVebra, eax
	invoke LoadTexture, ADDR ImgVignette, IMG_GCT or IMG_HALFY
	mov TexVignette, eax
	invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR
	invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR
	invoke LoadTexture, ADDR ImgVignetteRed, IMG_GCT or IMG_HALFY
	mov TexVignetteRed, eax
	invoke LoadTexture, ADDR ImgWall, IMG_GCT
	mov TexWall, eax
	invoke LoadTexture, ADDR ImgWB, IMG_GCT or IMG_HALFX
	mov TexWB, eax
	invoke LoadTexture, ADDR ImgWBBK, IMG_GCT
	mov TexWBBK, eax
	invoke LoadTexture, ADDR ImgWBBKP, IMG_GCT
	mov TexWBBKP, eax
	invoke LoadTexture, ADDR ImgWBBK1, IMG_GCT
	mov TexWBBK1, eax
	invoke LoadTexture, ADDR ImgWhitewall, IMG_GCT
	mov TexWhitewall, eax
	
	invoke LoadTexture, ADDR ImgGlyph1, IMG_GCT332 or IMG_HALFX
	mov TexGlyph, eax
	invoke LoadTexture, ADDR ImgGlyph2, IMG_GCT332 or IMG_HALFX
	mov TexGlyph[4], eax
	invoke LoadTexture, ADDR ImgGlyph3, IMG_GCT332 or IMG_HALFX
	mov TexGlyph[8], eax
	invoke LoadTexture, ADDR ImgGlyph4, IMG_GCT332 or IMG_HALFX
	mov TexGlyph[12], eax
	invoke LoadTexture, ADDR ImgGlyph5, IMG_GCT332 or IMG_HALFX
	mov TexGlyph[16], eax
	invoke LoadTexture, ADDR ImgGlyph6, IMG_GCT332 or IMG_HALFX
	mov TexGlyph[20], eax
	invoke LoadTexture, ADDR ImgGlyph7, IMG_GCT332 or IMG_HALFX
	mov TexGlyph[24], eax
	
	invoke LoadTexture, ADDR ImgWmblykHappy, IMG_GCT565 or IMG_HALFX
	mov TexWmblykHappy, eax
	invoke LoadTexture, ADDR ImgWmblykNeutral, IMG_GCT332 or IMG_HALFX
	mov TexWmblykNeutral, eax
	invoke LoadTexture, ADDR ImgWmblykJumpscare, IMG_GCT565 or IMG_HALFY
	mov TexWmblykJumpscare, eax
	invoke LoadTexture, ADDR ImgWmblykStr, IMG_GCT332 or IMG_HALFX
	mov TexWmblykStr, eax
	invoke LoadTexture, ADDR ImgWmblykL1, IMG_GCT332 or IMG_HALFX
	mov TexWmblykL1, eax
	invoke LoadTexture, ADDR ImgWmblykL2, IMG_GCT332 or IMG_HALFX
	mov TexWmblykL2, eax
	invoke LoadTexture, ADDR ImgWmblykL3, IMG_GCT332 or IMG_HALFX
	mov TexWmblykL3, eax
	invoke LoadTexture, ADDR ImgWmblykW1, IMG_GCT565 or IMG_HALFX
	mov TexWmblykW1, eax
	invoke LoadTexture, ADDR ImgWmblykW2, IMG_GCT565 or IMG_HALFX
	mov TexWmblykW2, eax
	
	invoke LoadTexture, ADDR ImgVirdyaBlink, IMG_GCT332 or IMG_HALFY
	mov TexVirdyaBlink, eax
	invoke LoadTexture, ADDR ImgVirdyaDown, IMG_GCT332 or IMG_HALFY
	mov TexVirdyaDown, eax
	invoke LoadTexture, ADDR ImgVirdyaN, IMG_GCT332 or IMG_HALFY
	mov TexVirdyaN, eax
	invoke LoadTexture, ADDR ImgVirdyaNeut, IMG_GCT332 or IMG_HALFY
	mov TexVirdyaNeut, eax
	invoke LoadTexture, ADDR ImgVirdyaUp, IMG_GCT332 or IMG_HALFY
	mov TexVirdyaUp, eax
	
	invoke LoadTexture, ADDR ImgKubale, IMG_GCT565
	mov TexKubale, eax
	
	invoke LoadTexture, ADDR ImgKubaleV1, IMG_GCT332
	mov TexKubaleInkblot, eax
	invoke LoadTexture, ADDR ImgKubaleV2, IMG_GCT332
	mov TexKubaleInkblot[4], eax
	invoke LoadTexture, ADDR ImgKubaleV3, IMG_GCT332
	mov TexKubaleInkblot[8], eax
	invoke LoadTexture, ADDR ImgKubaleV4, IMG_GCT332
	mov TexKubaleInkblot[12], eax
	invoke LoadTexture, ADDR ImgKubaleV5, IMG_GCT332
	mov TexKubaleInkblot[16], eax
	invoke LoadTexture, ADDR ImgKubaleV6, IMG_GCT332
	mov TexKubaleInkblot[20], eax
	invoke LoadTexture, ADDR ImgKubaleV7, IMG_GCT332
	mov TexKubaleInkblot[24], eax
	invoke LoadTexture, ADDR ImgKubaleV8, IMG_GCT332
	mov TexKubaleInkblot[28], eax
	invoke LoadTexture, ADDR ImgKubaleV9, IMG_GCT332
	mov TexKubaleInkblot[32], eax
	
	
	; Font
	invoke CreateFile, ADDR ImgFontPath, GENERIC_READ, FILE_SHARE_READ, 0, \
	OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, 0
    mov hFile, eax
	
    invoke GetFileSize, hFile, ADDR dwHighSize
    mov dwFileSize, eax
    invoke GlobalAlloc, GMEM_MOVEABLE or GMEM_ZEROINIT, dwFileSize
    mov mem, eax
    invoke GlobalLock, mem
    mov ImgFont, eax
    invoke ReadFile, hFile, ImgFont, dwFileSize, ADDR dwBytesRead, 0
    invoke CloseHandle, hFile 
	
	xor ebx, ebx
	.WHILE (ebx < 41)
		mov eax, ebx
		mov ecx, 15
		mul ecx
		add eax, ImgFont
		invoke LoadTexture, eax, IMG_GCT332 or IMG_HALFX
		mov edx, eax
		push edx
		mov eax, ebx
		mov ecx, 4
		mul ecx
		pop edx
		mov TexFont[eax], edx
		invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, 812Fh
		invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, 812Fh
		
		inc ebx
		print str$(ebx), 13, 10
	.ENDW
	
	invoke GlobalUnlock, ImgFont
	invoke GlobalFree, mem
	
	m2m CurrentFloor, TexFloor
	m2m CurrentRoof, TexRoof
	m2m CurrentWall, TexWall
	m2m CurrentWallMDL, 1
	ret
CreateModels ENDP

; Create the window to draw OpenGL context in
CreateWindow PROC
	LOCAL wc:WNDCLASSEX	
	LOCAL msg:MSG
	
	print "Creating window...", 13, 10
	
	invoke GetModuleHandle, NULL	; Get handle for the process
	mov hInstance, eax
	
	mov	  wc.cbSize, SIZEOF WNDCLASSEX	; Fill WNDCLASSEX record
	mov	  wc.style, CS_HREDRAW or CS_VREDRAW
	mov	  wc.lpfnWndProc, OFFSET WndProc
	mov	  wc.cbClsExtra, NULL
	mov	  wc.cbWndExtra, NULL
	m2m	  wc.hInstance, hInstance
	mov	  wc.hbrBackground, COLOR_WINDOW
	mov	  wc.lpszMenuName, NULL
	mov	  wc.lpszClassName, OFFSET ClassName
	invoke GetModuleHandle, NULL
	invoke LoadIcon, eax, 500
	mov	  wc.hIcon, eax
	mov	  wc.hIconSm, eax
	invoke LoadCursor, NULL, IDC_ARROW
	mov	  wc.hCursor, eax
	
	invoke RegisterClassEx, ADDR wc	; Register the window class
	
	; Commence
	invoke CreateWindowEx, 0, ADDR ClassName, ADDR AppName, \
	WS_OVERLAPPEDWINDOW or WS_SIZEBOX, CW_USEDEFAULT, CW_USEDEFAULT, \
	800, 600, NULL, NULL, hInstance, NULL
	mov hwnd, eax
	
	invoke InitCommonControls
	
	invoke ShowWindow, hwnd, SW_SHOWDEFAULT
	
	.WHILE TRUE		; Message loop
		invoke GetMessage, ADDR msg, NULL, 0, 0
		.BREAK .IF (!eax)
		invoke TranslateMessage, ADDR msg
		invoke DispatchMessage, ADDR msg
	.ENDW
	ret
CreateWindow ENDP

; Operate menu
DoMenu PROC
	LOCAL AudSt:SDWORD
	.IF (Menu == 0)
		inc Menu
		mov canControl, 0
		mov camCurSpeed, 0
		mov camCurSpeed[8], 0
		mov focused, 0
		;invoke ShowHideCursor, 1
		
		invoke alGetSourcei, SndAlarm, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndAlarm
		.ENDIF
		invoke alGetSourcei, SndAmb, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndAmb
		.ENDIF
		invoke alGetSourcei, SndDrip, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndDrip
		.ENDIF
		invoke alGetSourcei, SndEBD, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndEBD
		.ENDIF
		invoke alGetSourcei, SndEBDA, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndEBDA
		.ENDIF
		invoke alGetSourcei, SndExit, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndExit
		.ENDIF
		invoke alGetSourcei, SndHbd, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndHbd
		.ENDIF
		invoke alGetSourcei, SndIntro, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndIntro
		.ENDIF
		invoke alGetSourcei, SndKubale, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndKubale
		.ENDIF
		invoke alGetSourcei, SndKubaleAppear, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndKubaleAppear
		.ENDIF
		invoke alGetSourcei, SndKubaleV, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndKubaleV
		.ENDIF
		invoke alGetSourcei, SndMus5, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndMus5
		.ENDIF
		invoke alGetSourcei, SndSiren, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndSiren
		.ENDIF
		invoke alGetSourcei, SndTram, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndTram
		.ENDIF
		invoke alGetSourcei, SndTramAnn, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndTramAnn
		.ENDIF
		invoke alGetSourcei, SndTramAnn[4], AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndTramAnn[4]
		.ENDIF
		invoke alGetSourcei, SndTramAnn[8], AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndTramAnn[8]
		.ENDIF
		invoke alGetSourcei, SndWhisper, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndWhisper
		.ENDIF
		invoke alGetSourcei, SndWBBK, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndWBBK
		.ENDIF
		invoke alGetSourcei, SndWmblyk, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndWmblyk
		.ENDIF
		invoke alGetSourcei, SndWmblykB, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndWmblykB
		.ENDIF
		invoke alGetSourcei, SndWmblykStr, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndWmblykStr
		.ENDIF
		invoke alGetSourcei, SndWmblykStrM, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndWmblykStrM
		.ENDIF
		invoke alGetSourcei, SndAmbW, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndAmbW
		.ENDIF
		invoke alGetSourcei, SndAmbW[4], AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndAmbW[4]
		.ENDIF
		invoke alGetSourcei, SndAmbW[8], AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndAmbW[8]
		.ENDIF
		invoke alGetSourcei, SndAmbW[12], AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndAmbW[12]
		.ENDIF
		ret
	.ELSE
		dec Menu
		.IF (Menu == 1)
			invoke DestroyWindow, stHwnd
			invoke ShowCursor, 0
		.ELSEIF (Menu == 0)
			.IF (playerState == 0) || (playerState == 19)
				mov canControl, 1
			.ENDIF
			mov focused, 1
			;invoke ShowHideCursor, 0
			
			invoke alGetSourcei, SndAlarm, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndAlarm
			.ENDIF
			invoke alGetSourcei, SndAmb, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndAmb
			.ENDIF
			invoke alGetSourcei, SndDrip, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndDrip
			.ENDIF
			invoke alGetSourcei, SndEBD, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndEBD
			.ENDIF
			invoke alGetSourcei, SndEBDA, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndEBDA
			.ENDIF
			invoke alGetSourcei, SndExit, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndExit
			.ENDIF
			invoke alGetSourcei, SndHbd, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndHbd
			.ENDIF
			invoke alGetSourcei, SndIntro, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndIntro
			.ENDIF
			invoke alGetSourcei, SndKubale, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndKubale
			.ENDIF
			invoke alGetSourcei, SndKubaleAppear, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndKubaleAppear
			.ENDIF
			invoke alGetSourcei, SndKubaleV, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndKubaleV
			.ENDIF
			invoke alGetSourcei, SndMus5, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndMus5
			.ENDIF
			invoke alGetSourcei, SndSiren, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndSiren
			.ENDIF
			invoke alGetSourcei, SndTram, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndTram
			.ENDIF
			invoke alGetSourcei, SndTramAnn, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndTramAnn
			.ENDIF
			invoke alGetSourcei, SndTramAnn[4], AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndTramAnn[4]
			.ENDIF
			invoke alGetSourcei, SndTramAnn[8], AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndTramAnn[8]
			.ENDIF
			invoke alGetSourcei, SndWBBK, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndWBBK
			.ENDIF
			invoke alGetSourcei, SndWhisper, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndWhisper
			.ENDIF
			invoke alGetSourcei, SndWmblyk, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndWmblyk
			.ENDIF
			invoke alGetSourcei, SndWmblykB, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndWmblykB
			.ENDIF
			invoke alGetSourcei, SndWmblykStr, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndWmblykStr
			.ENDIF
			invoke alGetSourcei, SndWmblykStrM, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndWmblykStrM
			.ENDIF
			invoke alGetSourcei, SndAmbW, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndAmbW
			.ENDIF
			invoke alGetSourcei, SndAmbW[4], AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndAmbW[4]
			.ENDIF
			invoke alGetSourcei, SndAmbW[8], AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndAmbW[8]
			.ENDIF
			invoke alGetSourcei, SndAmbW[12], AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndAmbW[12]
			.ENDIF
		.ENDIF
		ret
	.ENDIF
	ret
DoMenu ENDP

; Operate playerState, for player cutscenes and more
DoPlayerState PROC
	LOCAL mtplr:REAL4, mtplr2:REAL4
	
	; playerState 0 is for general gameplay
	.IF (playerState == 1)		; Enter maze, setup everything
		mov camRot, 1050253722
		mov camRotL, 1050253722
		mov camRot[4], 1078523331
		mov camPos, 3212836864
		m2m camPos[4], flCamHeight
		mov camPos[8], 3192704205
		mov camPosL, 3212836864
		mov camPosL[8], 3192704205
		
		mov camStep, 0
		mov camStepSide, 0
				
		mov MazeDoor, 0
		
		m2m fade, fl1
		mov fadeState, 1
		
		mov playerState, 2
		ret
	.ELSEIF (playerState == 2)	; Enter continuous
		invoke Lerp, ADDR camRot, 0, delta2
		invoke Lerp, ADDR camPos[8], 3213675725, delta2
		
		fld1
		fchs
		fstp mtplr
		fcmp camPos[8], mtplr
		.IF Sign? && !Zero?
			.IF (MazeHostile != 12)
				mov canControl, 1
				mov playerState, 0
			.ELSE
				mov playerState, 18
			.ENDIF
		.ENDIF
		ret
	.ELSEIF (playerState == 3)	; Exit continuous opendoor
		mov canControl, 0
		mov camCurSpeed, 0
		mov camCurSpeed[8], 0
		
		.IF (MazeLevel == 63)
			invoke Lerp, ADDR camRot, 0, delta2
		.ELSEIF (MazeHostile == 5)
			invoke Lerp, ADDR camRot, flThirdN, delta2
		.ELSE
			invoke Lerp, ADDR camRot, flThird, delta2
		.ENDIF
		invoke LerpAngle, ADDR camRot[4], PI, delta2
		
		.IF (kubale < 29)
			mov kubale, 0
		.ENDIF
		
		invoke Lerp, ADDR camPos, MazeDoorPos, delta2
		invoke Lerp, ADDR camPos[8], MazeDoorPos[4], delta2
		
		.IF (Checkpoint)
			.IF ((MazeHostile == 1) || (Glyphs == 7))
				invoke Lerp, ADDR CheckpointMus, 0, delta2
				invoke alSourcef, SndMus3, AL_GAIN, CheckpointMus
				invoke Lerp, ADDR CheckpointDoor, 3267887104, delta2
				m2m mtplr, CheckpointDoor
			.ELSE
				invoke Lerp, ADDR MazeDoor, 3267887104, delta2
				m2m mtplr, MazeDoor
			.ENDIF
		.ELSE
			invoke Lerp, ADDR MazeDoor, 3267887104, delta2
			m2m mtplr, MazeDoor
		.ENDIF
		fcmp mtplr, fl90N
		.IF Sign? && !Zero?
			fld MazeDoorPos[4]
			fsub fl2
			fstp MazeDoorPos[4]
			mov fade, 0
			mov fadeState, 2
			mov playerState, 4
			.IF (Checkpoint)
				.IF (MazeHostile == 1)
					invoke alSourcePlay, SndAmb
				.ENDIF
				invoke alSourceStop, SndMus3
			.ENDIF
		.ENDIF
		ret
	.ELSEIF (playerState == 4)	; Exit continuous
		invoke LerpAngle, ADDR camRot[4], 1078523331, delta2
		
		invoke Lerp, ADDR camPos, MazeDoorPos, delta2
		
		fld flHalf
		fadd flCamHeight
		fstp mtplr
		
		.IF (MazeHostile < 5)
			invoke Lerp, ADDR camPos[4], mtplr, deltaTime
		.ENDIF
		invoke Lerp, ADDR camPos[8], MazeDoorPos[4], delta2
		
		.IF (Shn)
			invoke alGetSourcef, SndAlarm, AL_GAIN, ADDR mtplr
			invoke Lerp, ADDR mtplr, 0, delta2
			invoke alSourcef, SndAlarm, AL_GAIN, mtplr
		.ENDIF
		
		fcmp fade, fl1
		.IF !Sign? && Zero?
			m2m PMSeed, MazeSeed
			m2m PMW, MazeW
			m2m PMH, MazeH
			
			invoke nrandom, 5
			SWITCH eax
				CASE 0
					inc MazeW
				CASE 1
					inc MazeH
				;CASE 2
				;	inc MazeW
				;	inc MazeH
			ENDSW
			
			.IF (MazeHostile < 5)
				invoke FreeMaze
				invoke GetTickCount
				mov MazeSeed, eax
				invoke GenerateMaze, MazeSeed
			.ELSEIF (MazeHostile == 5)
				.IF (Glyphs == 7)	; Croa ending setup
					print "Croa", 13, 10
					invoke alSourcef, SndAmbT, AL_GAIN, fl2
					invoke alSourcef, SndAmbT, AL_PITCH, flFifth
					invoke alSourcePlay, SndAmbT
					mov MazeHostile, 12
					mov Checkpoint, 0
					mov canControl, 0
					invoke glLightModelfv, GL_LIGHT_MODEL_AMBIENT, ADDR clBlack
					invoke glLightf, GL_LIGHT0, GL_CONSTANT_ATTENUATION, flTenth
					invoke glLightf, GL_LIGHT0, GL_QUADRATIC_ATTENUATION, flHundredth
					;invoke glLightf, GL_LIGHT0, GL_LINEAR_ATTENUATION, fl1
					invoke glLightfv, GL_LIGHT0, GL_DIFFUSE, ADDR clBlack
					invoke glLightfv, GL_LIGHT0, GL_SPECULAR, ADDR clBlack
					m2m camLight[4], fl32
					m2m camLight[8], fl20N
					invoke glLightfv, GL_LIGHT0, GL_POSITION, ADDR camLight
				.ELSE	; Ascension ending setup
					; Maze is already freed
					inc MazeLevel
					mov MazeHostile, 6
					mov Checkpoint, 0
					mov GlyphsInLayer, 0
					mov MotryaTimer, 0
					invoke alSourcef, SndAmbT, AL_GAIN, 0
					invoke alSourcef, SndAmbT, AL_PITCH, flFifth
					invoke alSourcePlay, SndAmbT
					invoke alSourcef, SndVirdya, AL_GAIN, 0
					invoke alSourcePlay, SndVirdya
					invoke alSourcef, SndWBBK, AL_GAIN, 0
					invoke alSourcePlay, SndWBBK
					invoke alSourcePlay, SndMus4
				.ENDIF
			.ENDIF
			
			mov playerState, 5
			m2m MazeLevelPopupTimer, fl2
			mov MazeLevelPopup, 1
		.ENDIF
		ret
	.ELSEIF (playerState == 5)	; Exit wait
		invoke Lerp, ADDR MazeDoor, PI, delta10
		
		fcmp MazeDoor, PI2
		.IF Sign? && !Zero?
			mov playerState, 1
		.ENDIF
		ret
	.ELSEIF (playerState == 6)	; Strangle setup
		mov canControl, 0
		mov camCurSpeed, 0
		mov camCurSpeed[8], 0
		
		m2m camStranglePos, camPos
		m2m camStranglePos[4], camPos[8]
		
		invoke GetDirection, camPosN, camPosN[4], wmblykPos, wmblykPos[4]
		mov camRot[4], eax
		
		mov playerState, 7
		ret
	.ELSEIF (playerState == 7)	; Strangle continuous
		.IF (joyUsed)
			.IF (joystickXInput)
				lea eax, CCSpaceJX
			.ELSE
				lea eax, CCSpaceJD
			.ENDIF
		.ELSE
			lea eax, CCSpace
		.ENDIF
		invoke ShowSubtitles, eax
		
		fild mouseRel[2]
		fmul deltaTime
		fadd wmblykStr
		fstp camRot
		
		fld wmblykStr
		fadd flHalf
		fmul st, st
		fsubr fl09
		fstp mtplr
		
		
		fld camForward
		fmul mtplr
		fadd wmblykPos
		fchs
		fstp camPos
		
		fld camForward[8]
		fmul mtplr
		fadd wmblykPos[4]
		fchs
		fstp camPos[8]
		
		fld wmblykStr
		fmul flHalf
		fabs
		fadd flCamHeight
		fstp camPos[4]
		fld wmblykStr
		fadd flTenth
		fmul flTenth
		fsubr camPos[4]
		fstp camPos[4]
		
		; Screen shake
		invoke nrandom, 5
		mov mtplr, eax
		fild mtplr
		fsub fl2
		fmul flHundredth
		fadd camPos
		fstp camPos
		invoke nrandom, 5
		mov mtplr, eax
		fild mtplr
		fsub fl2
		fmul flHundredth
		fadd camPos[4]
		fstp camPos[4]
		invoke nrandom, 5
		mov mtplr, eax
		fild mtplr
		fsub fl2
		fmul flHundredth
		fadd camPos[8]
		fstp camPos[8]
		
		; Time limit
		fld deltaTime
		fmul flTenth
		fadd fade
		fstp fade
		fcmp fade, fl1
		.IF !Sign?
			mov playerState, 9
		.ENDIF
		invoke Lerp, ADDR vignetteRed, fl1, deltaTime
		
		fld wmblykStr
		fadd flHalf
		fstp mtplr
		invoke alSourcef, SndWmblykB, AL_GAIN, mtplr
		ret
	.ELSEIF (playerState == 8)	; Strangle ogovtuyetsia
		mov ccTimer, 0
	
		invoke Lerp, ADDR camRot, flTenth, deltaTime
		invoke Lerp, ADDR camPos, camStranglePos, deltaTime
		invoke Lerp, ADDR camPos[8], camStranglePos[4], deltaTime
		invoke Lerp, ADDR camPos[4], flCamHeight, deltaTime
		invoke Lerp, ADDR fade, 3184315597, deltaTime
		invoke Lerp, ADDR vignetteRed, 0, delta2
		invoke Lerp, ADDR wmblykStr, 3204448256, delta2
		
		fld wmblykStr
		fadd flHalf
		fstp mtplr
		invoke alSourcef, SndWmblykB, AL_GAIN, mtplr
		
		fcmp fade
		.IF Sign? || Zero?
			mov fade, 0
			mov eax, flCamHeight
			mov camPos[4], eax
			mov playerState, 0
			mov camRot, 0
			mov canControl, 1
			invoke alSourceStop, SndWmblykB
		.ENDIF
		ret
	.ELSEIF (playerState == 9) || (playerState == 10)	; Dead
		invoke Lerp, ADDR camRot, PIHalfN, deltaTime
		invoke EraseTempSave
		.IF (playerState == 9)
			mov canControl, 0
			invoke Lerp, ADDR fade, fl1n2, deltaTime
			fcmp fade, fl1
			.IF !Sign?
				invoke alSourcePlay, SndDeath
				mov MazeTram, 0
				invoke alSourceStop, SndTram
				invoke alSourceStop, SndTramAnn
				invoke alSourceStop, SndTramAnn[4]
				invoke alSourceStop, SndTramAnn[8]
				mov WB, 0
				mov playerState, 10
			.ENDIF
		.ENDIF
		
		invoke alGetSourcef, SndAmb, AL_GAIN, ADDR mtplr
		invoke Lerp, ADDR mtplr, 0, deltaTime
		invoke alSourcef, SndAmb, AL_GAIN, mtplr
		
		invoke alGetSourcef, SndWmblykB, AL_GAIN, ADDR mtplr
		invoke Lerp, ADDR mtplr, 0, deltaTime
		invoke alSourcef, SndWmblykB, AL_GAIN, mtplr
		
		invoke alGetSourcef, SndWmblykStrM, AL_GAIN, ADDR mtplr
		invoke Lerp, ADDR mtplr, 0, deltaTime
		invoke alSourcef, SndWmblykStrM, AL_GAIN, mtplr
	.ELSEIF (playerState == 11) || (playerState == 13) || (playerState == 15) \
	|| (playerState == 17)	; Intro black, abysmal code choises
		.IF (MazeHostile == 11)
			ret
		.ENDIF
		mov fade, 0
		m2m fogDensity, flTenth
		fcmp wmblykBlink
		.IF Sign?
			.IF (playerState == 17)
				invoke GetTickCount
				invoke GenerateMaze, eax
				mov MazeHostile, 0
				mov playerState, 1
				invoke alSourcePlay, SndSiren
				ret
			.ENDIF
			inc playerState
			m2m wmblykBlink, fl4
		.ENDIF
	.ELSEIF (playerState == 12) ; Intro looks around city
		fld deltaTime
		fmul flTenth
		fstp mtplr
		invoke Lerp, ADDR camRot, 3206125978, mtplr
		invoke LerpAngle, ADDR camRot[4], 1077936128, deltaTime
		
		invoke Lerp, ADDR fogDensity, flHalf, mtplr
		
		fcmp wmblykBlink
		.IF Sign?
			inc playerState
			m2m wmblykBlink, fl4
			mov camRot, 0
			m2m camRot[4], PI
		.ENDIF
	.ELSEIF (playerState == 14)	; Intro runs through the outskirts
		fld deltaTime
		fmul fl6
		fsubr camPos[8]
		fstp camPos[8]
		fld delta2
		fmul fl5
		fadd camStep
		fst camStep
		fstp camStepSide
		
		invoke Lerp, ADDR fogDensity, flTenth, deltaTime
		
		fcmp wmblykBlink
		.IF Sign?
			inc playerState
			m2m wmblykBlink, fl4
			m2m fogDensity, flHalf
			m2m camPos[8], 3246391296
		.ENDIF
	.ELSEIF (playerState == 16)	; Intro runs through the woods, towards Maze
		fld deltaTime
		fmul fl6
		fsubr camPos[8]
		fstp camPos[8]
		fld delta2
		fmul fl5
		fadd camStep
		fst camStep
		fstp camStepSide
		
		invoke Lerp, ADDR fogDensity, flTenth, deltaTime
		fcmp wmblykBlink
		.IF Sign?
			inc playerState
			m2m wmblykBlink, fl5
		.ENDIF
	.ENDIF
	
	.IF (playerState >= 11) && (playerState <= 17)	; Intro timer
		fld wmblykBlink
		fsub deltaTime
		fstp wmblykBlink
	.ENDIF
	ret
DoPlayerState ENDP

; Draw the ascend part of ending
DrawAscend PROC
	LOCAL ColCheck:REAL4
	
	invoke Lerp, ADDR NoiseOpacity, NoiseOpacity[4], deltaTime
	
	push NoiseOpacity
	fld NoiseOpacity
	fmul flTenth
	fadd fl1
	fst NoiseOpacity
	fmul camCurSpeed
	fstp camCurSpeed
	fld NoiseOpacity
	fmul camCurSpeed[8]
	fstp camCurSpeed[8]
	pop NoiseOpacity
	
	.IF (MazeHostile == 7)	; Last door opened
		invoke glClearColor, fl1, fl1, fl1, fl1
		invoke Lerp, ADDR camPos, fl1N, deltaTime
		invoke Lerp, ADDR camRot, 0, deltaTime
		invoke LerpAngle, ADDR camRot[4], PI, deltaTime
		
		fld deltaTime
		fmul flThird
		fstp ColCheck
		invoke Lerp, ADDR AscendSky, fl1, ColCheck
		
		m2m AscendColor, AscendSky
		m2m AscendColor[4], AscendSky
		m2m AscendColor[8], AscendSky
		m2m AscendColor[12], AscendSky
		invoke glFogfv, GL_FOG_COLOR, ADDR AscendColor
		fld fogDensity
		fadd delta2
		fstp fogDensity
		
		fld MotryaTimer
		fadd ColCheck
		fstp MotryaTimer
		
		fld camPos[8]
		fsub deltaTime
		fstp camPos[8]
		
		mov camCurSpeed, 0
		mov camCurSpeed[8], 0
		
		.IF (MazeLevel == 0)
			fcmp camPosN[4], fl2
			.IF (!Sign?)
				mov MazeHostile, 8
				m2m NoiseOpacity, flHalf
				mov canControl, 1
				mov camPos, 0
				mov camPos[8], 0
				mov camPosL, 0
				mov camPosL[8], 0
			.ENDIF
		.ENDIF
	.ENDIF
	
	; Collision
	fld flWTh
	fstp ColCheck
	fcmp camPosNext, ColCheck
	.IF (Sign?)
		mov camCurSpeed, 0
	.ENDIF
	fld fl2
	fsub flWTh
	fstp ColCheck
	fcmp camPosNext, ColCheck
	.IF (!Sign?)
		mov camCurSpeed, 0
	.ENDIF
	
	fld flWTh
	fstp ColCheck
	fcmp camPosNext[8], ColCheck
	.IF (Sign?)
		mov camCurSpeed[8], 0
	.ENDIF
	
	fldz
	fsub flDoor
	fsub flDoor
	fstp ColCheck
	invoke CollidePlayerWall, ColCheck, fl12, 0
	
	fld flDoor
	fadd flDoor
	fstp ColCheck
	invoke CollidePlayerWall, ColCheck, fl12, 0
	
	
	invoke alSource3f, SndCheckpoint, AL_POSITION, camPosN, fl3, camPosN[4]
	invoke alSource3f, SndDoorClose, AL_POSITION, camPosN, fl3, camPosN[4]
	invoke alSource3f, SndWBBK, AL_POSITION, camPosN, fl3, camPosN[4]
	invoke alSource3f, SndMus4, AL_POSITION, camPosN, fl3, camPosN[4]
	
	invoke Lerp, ADDR AscendVolume, AscendVolume[4], deltaTime
	invoke alSourcef, SndAmbT, AL_GAIN, AscendVolume
	invoke alSourcef, SndVirdya, AL_GAIN, AscendVolume
	invoke alSourcef, SndMus4, AL_GAIN, AscendVolume
	fld AscendVolume
	fmul flFifth
	fstp ColCheck
	invoke alSourcef, SndWBBK, AL_GAIN, ColCheck
	
	fld fl2
	fadd camPos[8]
	fmul flHalf
	fstp ColCheck
	invoke Clamp, ColCheck, fl4N, 0
	mov ColCheck, eax
	
	fcmp camPosN[4], fl10	; Open / close door
	.IF (!Sign?)
		.IF (MazeHostile == 7)
			invoke Lerp, ADDR MazeDoor, 3267887104, deltaTime
		.ELSE
			invoke Lerp, ADDR MazeDoor, 3267887104, delta2
		.ENDIF
		.IF (AscendDoor == 0)
			mov AscendDoor, 1
			.IF (MazeLevel == 2)
				mov canControl, 0
				mov MazeHostile, 7
				invoke alSourcePlay, SndExit1
				invoke alSourceStop, SndAmbT
				invoke alSourceStop, SndVirdya
				invoke alSourceStop, SndWBBK
				invoke alSourceStop, SndMus4
			.ELSE
				invoke alSourcePlay, SndCheckpoint
			.ENDIF
		.ENDIF
	.ELSE
		invoke Lerp, ADDR MazeDoor, 0, delta2
		.IF (AscendDoor == 1)
			mov AscendDoor, 0
			invoke alSourcePlay, SndDoorClose
		.ENDIF
	.ENDIF
	
	invoke glPushMatrix
		invoke glTranslatef, 0, ColCheck, 0

		invoke glBindTexture, GL_TEXTURE_2D, TexFloor
		invoke glCallList, 94
		invoke glBindTexture, GL_TEXTURE_2D, TexWall
		invoke glCallList, 95
		invoke glBindTexture, GL_TEXTURE_2D, TexRoof
		invoke glCallList, 96
		
		invoke glBindTexture, GL_TEXTURE_2D, TexDoor
		invoke glCallList, 5
		invoke glPushMatrix
			invoke glTranslatef, flDoor, 0, 0
			invoke glRotatef, MazeDoor, 0, fl1, 0
			invoke glCallList, 4
		invoke glPopMatrix
		
		invoke glPushMatrix
			invoke glTranslatef, 0, fl4, fl12
			
			.IF (MazeLevel > 2)
				invoke glBindTexture, GL_TEXTURE_2D, TexFloor
				invoke glCallList, 94
				invoke glBindTexture, GL_TEXTURE_2D, TexWall
				invoke glCallList, 95
				invoke glBindTexture, GL_TEXTURE_2D, TexRoof
				invoke glCallList, 96
			.ENDIF
			
			invoke glBindTexture, GL_TEXTURE_2D, TexDoor
			invoke glCallList, 5
			invoke glTranslatef, flDoor, 0, 0
			invoke glRotatef, MazeDoor, 0, fl1, 0
			invoke glCallList, 4
		invoke glPopMatrix
		
		invoke glPushMatrix
			invoke glTranslatef, 0, fl4N, fl12N

			invoke glBindTexture, GL_TEXTURE_2D, TexFloor
			invoke glCallList, 94
			invoke glBindTexture, GL_TEXTURE_2D, TexWall
			invoke glCallList, 95
			invoke glBindTexture, GL_TEXTURE_2D, TexRoof
			invoke glCallList, 96
			
			invoke glBindTexture, GL_TEXTURE_2D, TexDoor
			invoke glCallList, 5
			invoke glTranslatef, flDoor, 0, 0
			invoke glRotatef, MazeDoor, 0, fl1, 0
			invoke glCallList, 4
		invoke glPopMatrix
	invoke glPopMatrix
	
	fcmp camPos[8], fl13N	; Advance layers
	.IF (Sign?)
		fld camPos[8]
		fadd fl12
		fstp camPos[8]
		fld camPosL[8]
		fadd fl12
		fstp camPosL[8]
		sub MazeLevel, 2
		invoke SetMazeLevelStr, str$(MazeLevel)
		m2m MazeLevelPopupTimer, fl2
		mov MazeLevelPopup, 1
		
		invoke SetNoiseOpacity
		
		fild MazeLevel
		fmul fl2
		fdivr fl3
		fstp AscendVolume[4]
		
		.IF (MazeLevel < 36) && (MazeLevel != 0)
			invoke nrandom, 30
			.IF (al != ccTextLast)
				mov ccTextLast, al
				SWITCH eax
					CASE 0
						invoke ShowSubtitles, ADDR CCAscend1
					CASE 1
						invoke ShowSubtitles, ADDR CCAscend2
					CASE 2
						invoke ShowSubtitles, ADDR CCAscend3
					CASE 3
						invoke ShowSubtitles, ADDR CCAscend4
					CASE 4
						invoke ShowSubtitles, ADDR CCAscend5
					CASE 5
						invoke ShowSubtitles, ADDR CCAscend6
				ENDSW
			.ENDIF
		.ENDIF
	.ENDIF
	ret
DrawAscend ENDP

; Draw the abyss border part of ending
DrawBorder PROC
	LOCAL mtplr:REAL4

	fcmp CroaTimer, fl75
	.IF (!Sign?)
		invoke Lerp, ADDR CroaTimer, 1116995584, delta2
		fld CroaTimer
		fstp camFOV
	.ENDIF
	
	fld deltaTime
	fmul flFifth
	fadd CroaCCTimer
	fstp CroaCCTimer
	
	fld GlyphRot
	fadd deltaTime
	fst GlyphRot
	fsin
	fadd fl3
	fmul flQuarter
	fstp GlyphPos

	invoke glBindTexture, GL_TEXTURE_2D, TexFloor
	invoke glCallList, 111
	invoke glBindTexture, GL_TEXTURE_2D, TexWall
	invoke glCallList, 112
	invoke glBindTexture, GL_TEXTURE_2D, TexDoor
	invoke glCallList, 5
	
	invoke glPushMatrix
		invoke glTranslatef, flDoor, 0, 0
		invoke glCallList, 4
	invoke glPopMatrix
	invoke CollidePlayerWall, 0, flFifth, 0
	invoke CollidePlayerWall, 0, flFifth, 1
	invoke CollidePlayerWall, fl2, 0, 1
	invoke CollidePlayerWall, 3217031168, 1072064102, 0
	invoke CollidePlayerWall, fl1n5, 1072064102, 0
	
	fcmp camPosN[4], fl2n5
	.IF (!Sign?)
		mov canControl, 0
		fld deltaTime
		fmul fl075
		fadd fade
		fstp fade
		invoke Lerp, ADDR ShopTimer, fl10, deltaTime
		fld ShopTimer
		fmul deltaTime
		fadd camPos[4]
		fstp camPos[4]
		mov fadeState, 0
		
		invoke alGetSourcef, SndAmbT, AL_GAIN, ADDR mtplr
		invoke Lerp, ADDR mtplr, 0, deltaTime
		invoke alSourcef, SndAmbT, AL_GAIN, mtplr
		
		fcmp fade, fl1n5
		.IF (!Sign?)
			mov playerState, 17
			mov MazeHostile, 11
			mov NoiseOpacity, 0
			
			invoke RegCreateKeyExA, HKEY_CURRENT_USER, ADDR RegPath, 0, NULL, \
			REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, ADDR defKey, NULL
			mov Complete, 2
			invoke RegSetValueExA, defKey, ADDR RegComplete, 0, REG_BINARY, \
			ADDR Complete, 1
			invoke RegCloseKey, defKey
			; weird not black screns
		.ENDIF
	.ENDIF
	
	invoke glPushMatrix
		invoke glTranslatef, camPosN, 0, camPosN[4]
		invoke glRotatef, CroaCCTimer, 0, fl1, 0
		invoke glScalef, GlyphPos, GlyphPos, GlyphPos
		invoke glColor3f, GlyphPos, GlyphPos, GlyphPos
		invoke glDisable, GL_FOG
		invoke glDisable, GL_LIGHTING
		invoke glBindTexture, GL_TEXTURE_2D, TexSky
		invoke glCallList, 113
		invoke glEnable, GL_FOG
		invoke glEnable, GL_LIGHTING
	invoke glPopMatrix
	invoke glColor3fv, ADDR clWhite
	ret
DrawBorder ENDP

; The Croa have come
DrawCroa PROC
	LOCAL zPos:REAL4, yPosN:REAL4, yPosT:REAL4, fltVal:REAL4
	
	; Use MazeGlyphsPos
	
	fld CroaTimer
	fsub deltaTime
	fstp CroaTimer
	fcmp CroaTimer
	.IF (Sign?)
		.IF (Croa == 0)	; Move in
			invoke alSourcef, SndAlarm, AL_PITCH, fl03
			invoke alSourcef, SndAlarm, AL_GAIN, fl03
			invoke alSourcePlay, SndAlarm
			m2m CroaTimer, fl8
			mov Croa, 1
		.ELSEIF (Croa == 1)	; Settle
			mov CroaTimer, 1108292403 ; 35.8
			mov Croa, 2
		.ELSEIF (Croa == 2)	; Disappear
			mov MazeHostile, 13
			mov fadeState, 1
			m2m fade, fl1
			mov Motrya, 2
			m2m MotryaTimer, fl1
			mov canControl, 1
			mov playerState, 19
			
			invoke alSourceStop, SndAlarm
			invoke alSourcef, SndDistress, AL_PITCH, flHalf
			invoke alSourcePlay, SndDistress
			
			invoke alSourcef, SndAmbT, AL_PITCH, fl1
			
			invoke glLightModelfv, GL_LIGHT_MODEL_AMBIENT, ADDR clDarkGray
			invoke glLightf, GL_LIGHT0, GL_CONSTANT_ATTENUATION, fl1
			invoke glLightf, GL_LIGHT0, GL_QUADRATIC_ATTENUATION, 0
			invoke glLightfv, GL_LIGHT0, GL_DIFFUSE, ADDR clWhite
			invoke glLightfv, GL_LIGHT0, GL_SPECULAR, ADDR clGray
			
			m2m CroaTimer, fl180	; Set FOV to 180
			mov ShopTimer, 0		; Set fall speed to 0
		.ENDIF
	.ENDIF
	
	.IF (CroaCC < 14)
		fld CroaCCTimer
		fsub deltaTime
		fstp CroaCCTimer
		fcmp CroaCCTimer
		.IF (Sign?)
			.IF (CroaCC == 0)
				invoke alSourcePlay, SndMus5
				m2m CroaCCTimer, flHalf
			.ELSEIF (CroaCC == 1)
				invoke ShowSubtitles, ADDR CCCroa1
				mov ccTimer, 1075838976		; 2.5
				mov CroaCCTimer, 1080033280	; 3.5
			.ELSEIF (CroaCC == 2)
				invoke ShowSubtitles, ADDR CCCroa2
				mov ccTimer, 1075000115		; 2.3
				mov CroaCCTimer, 1075838976	; 2.5
			.ELSEIF (CroaCC == 3)
				invoke ShowSubtitles, ADDR CCCroa3
				mov ccTimer, 1075838976		; 2.5
				mov CroaCCTimer, 1080033280	; 3.5
			.ELSEIF (CroaCC == 4)
				invoke ShowSubtitles, ADDR CCCroa4
				mov ccTimer, 1077936128		; 3.0
				mov CroaCCTimer, 1078984704	; 3.25
			.ELSEIF (CroaCC == 5)
				invoke ShowSubtitles, ADDR CCCroa5
				mov ccTimer, 1073741824		; 2.0
				mov CroaCCTimer, 1074790400	; 2.25
			.ELSEIF (CroaCC == 6)
				invoke ShowSubtitles, ADDR CCCroa6
				mov ccTimer, 1080033280		; 3.5
				mov CroaCCTimer, 1083179008	; 4.5
			.ELSEIF (CroaCC == 7)
				invoke ShowSubtitles, ADDR CCCroa7
				mov ccTimer, 1074790400		; 2.25
				mov CroaCCTimer, 1075838976	; 2.5
			.ELSEIF (CroaCC == 8)
				invoke ShowSubtitles, ADDR CCCroa8
				mov ccTimer, 1071644672		; 1.75
				mov CroaCCTimer, 1073741824	; 2.0
			.ELSEIF (CroaCC == 9)
				invoke ShowSubtitles, ADDR CCCroa9
				mov ccTimer, 1076887552		; 2.75
				mov CroaCCTimer, 1077936128	; 3.0
			.ELSEIF (CroaCC == 10)
				invoke ShowSubtitles, ADDR CCCroa10
				mov ccTimer, 1077936128		; 3.0
				mov CroaCCTimer, 1078984704	; 3.25
			.ELSEIF (CroaCC == 11)
				invoke ShowSubtitles, ADDR CCCroa11
				mov ccTimer, 1075838976		; 2.5
				mov CroaCCTimer, 1076887552	; 2.75
			.ELSEIF (CroaCC == 12)
				invoke ShowSubtitles, ADDR CCCroa12
				mov ccTimer, 1080033280		; 3.5
				mov CroaCCTimer, 1084227584	; 5.0
			.ELSEIF (CroaCC == 13)
				invoke ShowSubtitles, ADDR CCCroa13
				mov ccTimer, 1080033280		; 3.0
			.ENDIF
			inc CroaCC
		.ENDIF
	.ENDIF
	
	.IF (Croa)
		fld deltaTime
		fmul flHalf
		fstp fltVal
		invoke Lerp, ADDR CroaPos, fl2, fltVal
		
		invoke Lerp, ADDR AscendSky, fl09, delta2	; Lighting
		fld fltVal
		fmul flTenth
		fadd AscendSky
		fstp AscendSky
		invoke Lerp, ADDR camLight[4], fl2N, deltaTime
		invoke Lerp, ADDR camLight[8], fl2N, deltaTime
		invoke glLightfv, GL_LIGHT0, GL_POSITION, ADDR camLight
		fld AscendSky
		fst AscendColor
		fmul fl075
		fst AscendColor[4]
		fmul fl075
		fstp AscendColor[8]
		invoke glLightfv, GL_LIGHT0, GL_SPECULAR, ADDR AscendColor
		.IF (Croa == 2)
			invoke Lerp, ADDR CroaColor, flHundredth, fltVal
			fld CroaColor
			fadd fltVal
			fst CroaColor
			fmul fl075
			fst CroaColor[4]
			fmul fl075
			fstp CroaColor[8]
			invoke glLightfv, GL_LIGHT0, GL_AMBIENT, ADDR CroaColor
		.ENDIF
		;invoke glLightfv, GL_LIGHT0, GL_AMBIENT, ADDR AscendColor
	.ENDIF
	
	fld MazeGlyphsPos
	fadd deltaTime
	fst MazeGlyphsPos
	fsin
	fmul flHundredth
	fstp yPosT
	
	fld deltaTime
	fmul fl09
	fadd MazeGlyphsPos[4]
	fst MazeGlyphsPos[4]
	fsin 
	fmul flHundredth
	fstp yPosN
	
	fcmp MazeGlyphsPos, PI2
	.IF (!Sign?)
		fld MazeGlyphsPos
		fsub PI2
		fstp MazeGlyphsPos
	.ENDIF
	
	fld fl5
	fsub CroaPos
	fstp zPos
	invoke glEnable, GL_ALPHA_TEST
	invoke glAlphaFunc, GL_GREATER, 0
	invoke glBlendFunc, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
	invoke glBindTexture, GL_TEXTURE_2D, TexCroa
	invoke glPushMatrix
		invoke glTranslatef, CroaPos, yPosT, zPos
		fld CroaPos
		fmul fl8
		fstp fltVal
		invoke glRotatef, fltVal, 0, fl1, 0
		invoke glCallList, 110
	invoke glPopMatrix
	invoke glPushMatrix
		fld CroaPos
		fsubr fl2
		fstp fltVal
		invoke glTranslatef, fltVal, yPosN, zPos
		fld CroaPos
		fmul fl8
		fchs
		fstp fltVal
		invoke glRotatef, fltVal, 0, fl1, 0
		invoke glCallList, 109
	invoke glPopMatrix
	invoke glDisable, GL_ALPHA_TEST
	ret
DrawCroa ENDP

; Draw maze floor and ceiling
DrawFloorRoof PROC List:DWORD, PosX:REAL4, PosY:REAL4
	invoke glBindTexture, GL_TEXTURE_2D, CurrentFloor
	invoke glCallList, List
	
	.IF (Trench)
		ret
	.ENDIF
	invoke glPushMatrix
		invoke glTranslatef, 0, fl2, fl2
		invoke glRotatef, 1127481344, fl1, 0, 0
		invoke glBindTexture, GL_TEXTURE_2D, CurrentRoof
		invoke glCallList, List
	invoke glPopMatrix
	ret
DrawFloorRoof ENDP

; Draw the end floor and ceiling, what is visible when the end door opens
DrawFloorRoofEnd PROC List:DWORD, PosX:REAL4, PosY:REAL4
	invoke glBindTexture, GL_TEXTURE_2D, CurrentFloor
	invoke glCallList, 27
	
	invoke glPushMatrix
			invoke glTranslatef, 0, 1008981770, 0
			invoke glEnable, GL_BLEND
			invoke glDisable, GL_LIGHTING
			invoke glDisable, GL_FOG
			invoke glBlendFunc, GL_ZERO, GL_SRC_COLOR
			invoke glBindTexture, GL_TEXTURE_2D, TexDoorblur
			invoke glCallList, 27
			
			invoke glTranslatef, 0, 3164854026, 0
			invoke glCallList, 27
		invoke glDisable, GL_BLEND
		invoke glEnable, GL_LIGHTING
		invoke glEnable, GL_FOG
	invoke glPopMatrix
	ret
DrawFloorRoofEnd ENDP

; Draw wall and check collision from every wall (in radius)
DrawWall PROC List:DWORD, PosX:REAL4, PosY:REAL4, Vertical:BYTE
	; Draw stuff
	invoke glCallList, List
	.IF (!canControl)
		ret
	.ENDIF
	
	invoke CollidePlayerWall, PosX, PosY, Vertical
	ret
DrawWall ENDP

; Draw save checkpoint
DrawCheckpoint PROC PosX:REAL4, PosY:REAL4
	LOCAL PosX1:REAL4, PosY1:REAL4, PosX2:REAL4, PosY2:REAL4
	
	; Behold, collisions
	fld PosX
	fsub flDoor
	fsub flDoor
	fstp PosX2
	invoke CollidePlayerWall, PosX2, PosY, 0
	
	fld PosX
	fadd flDoor
	fadd flDoor
	fstp PosX1
	invoke CollidePlayerWall, PosX1, PosY, 0
	
	fld PosX
	fadd flDoor
	fadd flWMr
	fstp PosX1
	fld PosY
	fadd fl4
	.IF (MazeLevel == 63)
		fadd fl2
	.ENDIF
	fstp PosY1
	invoke CollidePlayer, PosX, PosX1, PosY, PosY1, 1
	
	fld PosX
	fadd fl2
	fst PosX2
	fsub flDoor
	fsub flWMr
	fstp PosX1
	invoke CollidePlayer, PosX1, PosX2, PosY, PosY1, 1
	
	.IF (MazeLevel != 63)
		fld PosY1
		fadd fl2
		fstp PosY1
		
		fld PosX
		fadd flWMr
		fst PosX2
		fsub flHalf
		fstp PosX1
		invoke CollidePlayer, PosX1, PosX2, PosY, PosY1, 1
		
		fld PosX
		fadd fl2
		fsub flWMr
		fst PosX1
		fadd flHalf
		fstp PosX2
		invoke CollidePlayer, PosX1, PosX2, PosY, PosY1, 1
	.ENDIF
	
	invoke CollidePlayerWall, PosX, PosY1, 0
	
	.IF (Checkpoint > 2) && ((playerState == 0) || (playerState == 19))
		invoke Lerp, ADDR CheckpointMus, flThird, deltaTime
		invoke alSourcef, SndMus3, AL_GAIN, CheckpointMus
	
		invoke DistanceScalar, camPosN[4], PosY1
		mov PosY1, eax
		fcmp PosY1, fl1n2
		.IF (Sign?)
			mov Checkpoint, 4
			fcmp ccTimer
			.IF (Sign?)
				.IF (joyUsed)
					lea eax, CCCheckpointJ
				.ELSE
					lea eax, CCCheckpoint
				.ENDIF
				mov ccText, eax
				m2m ccTimer, flTenth
			.ENDIF
		.ELSEIF (Checkpoint == 4)
			mov Checkpoint, 3
		.ENDIF
	.ENDIF
	
	invoke glPushMatrix
		invoke glTranslatef, CheckpointPos, 0, CheckpointPos[4]
		
		.IF (MazeLevel == 63) && (!Maze) && (Glyphs < 7)
			.IF (playerState == 19)
				invoke Lerp, ADDR MazeDoor, 0, delta2
			.ENDIF
			
			invoke glTranslatef, fl1, 0, fl3
			fld PosY
			fadd fl2
			fadd camPosL[8]
			fchs
			fmul flHalf
			fstp PosX1
			invoke Clamp, PosX1, 0, fl1
			mov PosX1, eax
			fld PosX1
			fmul PI
			fmul R2D
			fstp PosX1
			;invoke glRotatef, PosX1, 0, 0, fl1
			;invoke glRotatef, PosX1, fl1, 0, 0
			invoke glRotatef, PosX1, 0, fl1, 0
			invoke glTranslatef, fl1N, 0, 3225419776
		.ENDIF
		
		invoke glBindTexture, GL_TEXTURE_2D, CurrentWall
		invoke glCallList, 86
		.IF (!Maze)	; Draw door if just loaded in with no maze
			invoke glCallList, 6
			invoke glBindTexture, GL_TEXTURE_2D, TexDoor
			invoke glCallList, 5
			
			invoke glPushMatrix
				invoke glTranslatef, flDoor, 0, 0
				invoke glRotatef, MazeDoor, 0, fl1, 0
				invoke glCallList, 4
			invoke glPopMatrix
			invoke CollidePlayerWall, PosX, PosY, 0
		.ENDIF
		
		invoke glBindTexture, GL_TEXTURE_2D, CurrentFloor
		invoke glCallList, 85
		invoke glBindTexture, GL_TEXTURE_2D, CurrentRoof
		invoke glCallList, 87
		
		invoke glTranslatef, 0, 0, fl6
		
		invoke glPushMatrix
			invoke DrawFloorRoofEnd, 2, PosX, PosY1
			invoke glBindTexture, GL_TEXTURE_2D, CurrentWall
			invoke glCallList, 6
			invoke glBindTexture, GL_TEXTURE_2D, TexDoor
			invoke glCallList, 5
			invoke glTranslatef, flDoor, 0, 0
			invoke glRotatef, CheckpointDoor, 0, fl1, 0
			invoke glCallList, 4
		invoke glPopMatrix
		
		invoke glTranslatef, fl1, 1074580685, flHundredthN
		invoke glScalef, fl06, fl06, fl06
		invoke glEnable, GL_BLEND
		invoke glDisable, GL_LIGHTING
		invoke glDisable, GL_FOG
		invoke glBlendFunc, GL_ONE, GL_ONE
		invoke glBindTexture, GL_TEXTURE_2D, TexTone
		invoke glCallList, 84
		invoke glDisable, GL_BLEND
		invoke glEnable, GL_LIGHTING
		invoke glEnable, GL_FOG
	invoke glPopMatrix
	ret
DrawCheckpoint ENDP

; Draw and process Eblodryn
DrawEBD PROC
	LOCAL animSin:REAL4, yPos:REAL4, xPos:REAL4, xNeg:REAL4, sinOff:REAL4
	LOCAL hairID:BYTE, dist:REAL4, zPos:REAL4

	invoke DistanceToSqr, EBDPos, EBDPos[4], camPosN, camPosN[4]
	mov dist, eax
	
	invoke Clamp, dist, 0, fl10
	mov animSin, eax
	fld fl13
	fsub animSin
	fmul flHalf
	fmul deltaTime
	fstp animSin
	
	.IF (playerState == 0)
		fcmp dist, fl1
		.IF (Sign?)
			fcmp camCrouch, fl1
			.IF (Sign?)
				fld animSin
				fadd delta10
				fstp animSin
				
				invoke Lerp, ADDR EBDSound, fl1, delta10
				fld fade
				fadd deltaTime
				fadd delta2
				fstp fade
				fld vignetteRed
				fadd delta2
				fadd delta2
				fstp vignetteRed
				fcmp fade, fl1
				.IF (!Sign?)
					mov canControl, 0
					mov playerState, 9
					invoke alSourceStop, SndEBD
					invoke alSourceStop, SndEBDA
				.ENDIF
			.ELSE
				.IF (!kubale) && (!virdya)
					invoke Lerp, ADDR fade, 0, deltaTime
					invoke Lerp, ADDR vignetteRed, 0, deltaTime
				.ENDIF
				invoke Lerp, ADDR EBDSound, 0, delta10
			.ENDIF
		.ELSE
			.IF (!kubale) && (!virdya)
				invoke Lerp, ADDR fade, 0, delta2
				invoke Lerp, ADDR vignetteRed, 0, delta2
			.ENDIF
			invoke Lerp, ADDR EBDSound, 0, delta10
		.ENDIF
	.ENDIF
	
	invoke alSourcef, SndEBDA, AL_GAIN, EBDSound
	
	fld EBDAnim
	fadd animSin
	fstp EBDAnim
	fcmp EBDAnim, PI2
	.IF (!Sign?)
		fld EBDAnim
		fsub PI2
		fstp EBDAnim
	.ENDIF
	
	invoke glEnable, GL_BLEND
	invoke glDisable, GL_LIGHTING
	
	invoke glBindTexture, GL_TEXTURE_2D, TexEBDShadow
	invoke glDisable, GL_FOG
	invoke glBlendFunc, GL_ZERO, GL_SRC_COLOR
	invoke glPushMatrix
		invoke glTranslatef, EBDPos, fl2, EBDPos[4]
		invoke glRotatef, fl180, fl1, 0, 0
		invoke glTranslatef, fl1N, flHundredth, fl1N
		invoke glCallList, 2
	invoke glPopMatrix
	invoke glEnable, GL_FOG
	invoke glDisable, GL_CULL_FACE
	invoke glEnable, GL_ALPHA_TEST
	invoke glAlphaFunc, GL_GREATER, 0
	invoke glBlendFunc, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
	mov hairID, 0
	mov sinOff, 0
	.WHILE (hairID < 3)
		invoke glPushMatrix
			invoke glTranslatef, EBDPos, fl2, EBDPos[4]
			.IF (hairID == 0)
				invoke glTranslatef, flFifthN, 0, flFifthN
				invoke glBindTexture, GL_TEXTURE_2D, TexEBD
			.ELSEIF (hairID == 1)
				invoke glTranslatef, flFifth, 0, flFifthN
				invoke glBindTexture, GL_TEXTURE_2D, TexEBD[4]
			.ELSE
				invoke glTranslatef, 0, 0, flFifth
				invoke glBindTexture, GL_TEXTURE_2D, TexEBD[8]
			.ENDIF
			invoke glScalef, fl1, fl1n2, fl1
			invoke glRotatef, fl180, fl1, 0, 0
			invoke GetDirection, EBDPos, EBDPos[4], camPosN, camPosN[4]
			mov animSin, eax
			fld animSin
			fchs
			fmul R2D
			fstp animSin
			invoke glRotatef, animSin, 0, fl1, 0
			
			mov yPos, 0
			mov zPos, 0
			m2m xNeg, flFifthN
			m2m xPos, flFifth
			xor ebx, ebx
			invoke glBegin, GL_QUADS
			.WHILE (ebx < 4)
				invoke glTexCoord2f, 0, yPos
				invoke glVertex3f, xNeg, yPos, zPos
				invoke glTexCoord2f, fl1, yPos
				invoke glVertex3f, xPos, yPos, zPos
				
				fld sinOff
				fadd flThird
				fstp sinOff
				
				fld yPos
				fadd flQuarter
				fstp yPos
				
				fld dist
				fadd fl1
				fdivr yPos
				fstp zPos
				
				fld sinOff
				fadd EBDAnim
				fsin
				fmul flFifth
				fmul yPos
				fst animSin
				fadd flFifthN
				fstp xNeg
				fld animSin
				fadd flFifth
				fstp xPos
				
				invoke glTexCoord2f, fl1, yPos
				invoke glVertex3f, xPos, yPos, zPos
				invoke glTexCoord2f, 0, yPos
				invoke glVertex3f, xNeg, yPos, zPos
				inc ebx
			.ENDW
			invoke glEnd
		invoke glPopMatrix
		inc hairID
	.ENDw
	invoke glDisable, GL_BLEND
	invoke glEnable, GL_LIGHTING
	invoke glEnable, GL_CULL_FACE
	invoke glEnable, GL_FOG
	invoke glDisable, GL_ALPHA_TEST
	invoke glAlphaFunc, GL_ALWAYS, 0
	ret
DrawEBD ENDP

; Draw the exit door and operate it (behavior depends on the checkpoint)
DrawExitDoor PROC PosX:REAL4, PosY:REAL4
	LOCAL PosX1:REAL4, PosY1:REAL4
	
	invoke glCallList, 6
	invoke glBindTexture, GL_TEXTURE_2D, TexDoor
	.IF (MazeLocked > 0)
		invoke glCallList, 33
	.ELSE
		invoke glCallList, 5
	.ENDIF
	.IF (MazeLocked == 1)
		invoke glCallList, 34
	.ENDIF
	
	invoke glPushMatrix
		invoke glTranslatef, flDoor, 0, 0
		invoke glRotatef, MazeDoor, 0, fl1, 0
		invoke glCallList, 4
	invoke glPopMatrix
	
	fld PosX
	fadd fl2
	fstp PosX1
	fld PosY
	fsub fl2
	fstp PosY1
		
	.IF (Checkpoint) && (MazeLocked != 1)
		.IF (Checkpoint == 1)
			.IF (playerState == 0) && (MazeLocked != 1)
				invoke InRange, camPosN, camPosN[4], \
				PosX, PosX1, PosY1, PosY
				
				.IF (al == 1)
					invoke alSource3f, SndCheckpoint, AL_POSITION, \
					PosX, 0, PosY
					invoke alSourcePlay, SndCheckpoint
					invoke alSourceStop, SndAmb
					.IF (MazeLevel != 63)
						mov Motrya, 1
					.ENDIF
					fld PosX
					fadd fl1
					fstp MotryaPos
					fld PosY
					fadd fl5
					fstp MotryaPos[4]
					mov Checkpoint, 2
					mov CheckpointDoor, 0
					m2m CheckpointPos, PosX
					m2m CheckpointPos[4], PosY
					fld MotryaPos
					fchs 
					fstp MazeDoorPos
					fld MotryaPos[4]
					fchs
					fstp MazeDoorPos[4]
				.ENDIF
			.ENDIF
		.ELSEIF (Checkpoint == 2)
			invoke Lerp, ADDR MazeDoor, 3267624960, delta2
			
			fld PosX
			fadd fl1
			fstp PosX1
			fld PosY
			fadd fl2
			fstp PosY1
			invoke alSource3f, SndDoorClose, AL_POSITION, PosX1, 0, PosY
			invoke DistanceToSqr, camPosN, camPosN[4], PosX1, PosY1
			mov PosX1, eax
			fcmp PosX1, flHalf
			.IF (Sign?)
				invoke alSourcePlay, SndDoorClose
				.IF (Motrya)
					invoke ShowSubtitles, ADDR CCSave
				.ENDIF
				mov Checkpoint, 3
				mov playerState, 19
				
				.IF (MazeLevel == 63)
					invoke FreeMaze
					mov EBD, 0
					mov Compass, 0
					mov Map, 0
					mov MazeGlyphs, 0
					mov MazeTeleport, 0
					mov MazeTram, 0
					mov MazeDoor, 0
					mov hbd, 0
					mov kubale, 0
					mov Shop, 0
					mov Shn, 0
					mov virdya, 0
					mov Vebra, 0
					mov wmblyk, 0
					mov WB, 0
					mov WBBK, 0
					mov MazeHostile, 5
					invoke alSourceStop, SndAlarm
					invoke alSourceStop, SndDrip
					invoke alSourceStop, SndEBD
					invoke alSourceStop, SndEBDA
					invoke alSourceStop, SndHbd
					invoke alSourceStop, SndKubale
					invoke alSourceStop, SndKubaleV
					invoke alSourceStop, SndTram
					invoke alSourceStop, SndTramAnn
					invoke alSourceStop, SndTramAnn[4]
					invoke alSourceStop, SndTramAnn[8]
					invoke alSourceStop, SndWhisper
					invoke alSourceStop, SndWmblykB
					mov fade, 0
				.ENDIF
			.ENDIF
		.ELSE
			invoke Lerp, ADDR MazeDoor, 0, delta2
			invoke CollidePlayerWall, PosX, PosY, 0
		.ENDIF
	.ELSE
		invoke CollidePlayerWall, PosX, PosY, 0
		invoke DrawFloorRoofEnd, 2, PosX, PosY
		
		.IF (playerState == 0) && (MazeLocked != 1)
			invoke InRange, camPosN, camPosN[4], \
			PosX, PosX1, PosY1, PosY
			
			.IF (al == 1)
				invoke alSourcePlay, SndExit
				mov playerState, 3
			.ENDIF
		.ENDIF
	.ENDIF
	ret
DrawExitDoor ENDP

; Draw maze with culling
DrawMaze PROC
	LOCAL MazeX: REAL4, MazeY: REAL4, MazeX1: REAL4, MazeY1: REAL4
	LOCAL xFrom:DWORD,yFrom:DWORD, xTo:DWORD,yTo:DWORD, xPos:DWORD,yPos:DWORD
	LOCAL MazeXI: DWORD, MazeYI: DWORD
	LOCAL PassTop: BYTE, PassLeft: BYTE, Rotate: BYTE, Misc: BYTE
	
	fld camPosN
	fmul flHalf
	fistp xPos
	fld camPosN[4]
	fmul flHalf
	fistp yPos
	
	mov eax, yPos
	sub eax, MazeDrawCull
	mul MazeW
	.IF (eax > 2147483647)
		xor eax, eax
	.ENDIF
	mov yFrom, eax
	
	mov eax, xPos
	sub eax, MazeDrawCull
	.IF (eax > 2147483647)
		xor eax, eax
	.ENDIF
	mov xFrom, eax
	add yFrom, eax
	
	
	mov eax, xPos
	add eax, MazeDrawCull
	.IF (eax > MazeWM1)
		mov eax, MazeWM1
	.ENDIF
	mov xTo, eax
	
	mov eax, MazeDrawCull
	add eax, MazeDrawCull
	mul MazeW
	add eax, yFrom
	.IF (eax > MazeSizeM1)
		mov eax, MazeSizeM1
	.ENDIF
	mov yTo, eax
	
	mov ebx, yFrom		; Cull start index
	.WHILE (ebx < yTo)	; to cull end index
		; Get cell
		mov eax, MazeBuffer
		mov dl, BYTE PTR [eax+ebx]
		mov cl, dl
		and dl, MZC_PASSTOP
		and cl, MZC_PASSLEFT
		mov PassTop, dl
		mov PassLeft, cl
		
		invoke GetPosition, ebx	; Get position from pointer to integer values
		mov MazeXI, edx
		mov MazeYI, eax
		.IF (edx >= xTo)	; Cull end X is reached, loop around to xFrom, Y+1
			mov eax, MazeW
			sub eax, xTo
			add eax, xFrom
			add ebx, eax
			.CONTINUE
		.ENDIF
		
		fild MazeXI	; Get world position in floats (REAL4)
		fmul fl2
		fstp MazeX
		fild MazeYI
		fmul fl2
		fstp MazeY
		
		.IF (MazeTram)	; Tram
			mov eax, MazeXI
			.IF (eax >= MazeTramArea) && (eax <= MazeTramArea[4])
				.IF (eax == MazeTramArea) || (eax == MazeTramArea[4])
					invoke glPushMatrix
						invoke glTranslatef, MazeX, 0, MazeY
						invoke glBindTexture, GL_TEXTURE_2D, TexMetal
						mov eax, MazeHM1
						dec eax
						.IF (MazeYI == 0)
							mov eax, MazeXI
							.IF (eax == MazeTramArea)
								invoke glRotatef, fl90N, 0, fl1, 0
								invoke glTranslatef, 0, 0, fl2N
								invoke glCallList, 104
							.ELSE
								invoke glRotatef, 1127481344, 0, fl1, 0
								invoke glTranslatef, fl2N, 0, fl2N
								invoke glCallList, 104
							.ENDIF
						.ELSEIF (MazeYI == eax)
							mov eax, MazeXI
							.IF (eax == MazeTramArea)
								invoke glCallList, 104
							.ELSE
								invoke glRotatef, fl90, 0, fl1, 0
								invoke glTranslatef, fl2N, 0, 0
								invoke glCallList, 104
							.ENDIF
						.ELSE
							invoke glCallList, 103
						.ENDIF
					invoke glPopMatrix
				.ELSE
					mov eax, MazeHM1
					dec eax
					.IF (MazeYI == 0) || (MazeYI == eax)
						invoke glPushMatrix
							invoke glTranslatef, MazeX, 0, MazeY
							invoke glRotatef, fl90, 0, fl1, 0
							invoke glTranslatef, fl2N, 0, 0
							invoke glBindTexture, GL_TEXTURE_2D, TexMetal
							invoke glCallList, 103
						invoke glPopMatrix
					.ENDIF
				.ENDIF
				inc ebx
				.CONTINUE
			.ENDIF
		.ENDIF
		
		invoke glPushMatrix
		invoke glTranslatef, MazeX, 0, MazeY
		; Draw walls
		invoke glBindTexture, GL_TEXTURE_2D, CurrentWall
		.IF (MazeCrevice)
			mov edx, MazeXI
			mov eax, MazeYI
			.IF (edx == MazeCrevicePos) && (eax == MazeCrevicePos[4])
				invoke glCallList, 106
				fld MazeX
				fadd fl2
				fstp MazeX1
				fld MazeY
				fadd fl2
				fstp MazeY1
				fcmp camCrouch, fl1
				.IF (Sign?)
					invoke CollidePlayerWall, MazeX, MazeY, 0
					invoke CollidePlayerWall, MazeX, MazeY1, 0
					invoke CollidePlayerWall, MazeX, MazeY, 1
					invoke CollidePlayerWall, MazeX1, MazeY, 1
				.ELSE
					push MazeX
					push MazeY
					fld MazeX
					fsub flWTh
					fstp MazeX
					fld MazeY
					fsub flWTh
					fstp MazeY
					fld MazeX1
					fadd flWTh
					fstp MazeX1
					fld MazeY1
					fadd flWTh
					fstp MazeY1
					invoke InRange, camPosN, camPosN[4], \
					MazeX, MazeX1, MazeY, MazeY1
					pop MazeY
					pop MazeX
					.IF (al)
						mov MazeCrevice, 2
					.ELSE
						mov MazeCrevice, 1
					.ENDIF
				.ENDIF
			.ENDIF
		.ENDIF
		.IF (ebx == 0)	; Enter door
			invoke glBindTexture, GL_TEXTURE_2D, TexDoor
			invoke glCallList, 5
			invoke glTranslatef, flDoor, 0, 0
			
			.IF (doorSlam == 1) && (playerState == 0)
				fcmp camPosN, fl6
				.IF (!Sign?)
					mov doorSlam, 2
					mov doorSlamRot, 0
				.ELSE
					fcmp camPosN[4], fl6
					.IF (!Sign?)
						mov doorSlam, 2
						mov doorSlamRot, 0
					.ENDIF
				.ENDIF
			.ENDIF
			.IF (doorSlam == 2)
				invoke Lerp, ADDR doorSlamRot, 3250585600, delta2
				invoke DistanceToSqr, fl1, fl0, camPosN, camPosN[4]
				mov MazeX1, eax
				fcmp MazeX1, fl4
				.IF (Sign?)
					invoke alSourcePlay, SndSlam
					invoke AlertWB, 3
					mov doorSlam, 3
				.ENDIF
			.ELSEIF (doorSlam == 3)
				fld delta10
				fmul fl10
				fstp MazeX1
				invoke MoveTowards, ADDR doorSlamRot, 0, MazeX1
				.IF (doorSlamRot == 0)
					mov doorSlam, 0
					print "Slammed door successfully.", 13, 10
				.ENDIF
			.ENDIF
			
			.IF (doorSlam > 1)
				invoke glPushMatrix
				invoke glRotatef, doorSlamRot, 0, fl1, 0
				invoke glCallList, 4
				invoke glPopMatrix
			.ELSE
				invoke glCallList, 4
			.ENDIF
			invoke glTranslatef, 3206964838, 0, 0
			invoke glBindTexture, GL_TEXTURE_2D, CurrentWall
			invoke DrawWall, 6, 0, 0, 0
		.ELSE
			.IF (PassTop == 0)
				mov Misc, 0
				.IF (Trench)
					inc Misc
					mov eax, MazeBuffer
					mov cl, BYTE PTR [eax+ebx]
					and cl, MZC_ROTATED
					.IF !(cl)
						inc Misc
						mov cl, BYTE PTR [eax+ebx]
						and cl, MZC_PIPE
						.IF (cl)
							inc Misc
						.ENDIF
					.ENDIF
				.ENDIF
				.IF(Misc == 3)
					invoke glBindTexture, GL_TEXTURE_2D, TexPlanks
					invoke DrawWall, 1, MazeX, MazeY, 0
					invoke glBindTexture, GL_TEXTURE_2D, CurrentWall
				.ELSE
					invoke DrawWall, CurrentWallMDL, MazeX, MazeY, 0
				.ENDIF
			.ENDIF
		.ENDIF
		.IF (PassLeft == 0)
			mov Misc, 0
			invoke glRotatef, 3266576384, 0, fl1, 0
			
			.IF (Trench)
				inc Misc
				mov eax, MazeBuffer
				mov cl, BYTE PTR [eax+ebx]
				and cl, MZC_ROTATED
				.IF (cl)
					inc Misc
					mov cl, BYTE PTR [eax+ebx]
					and cl, MZC_PIPE
					.IF (cl)
						inc Misc
					.ENDIF
				.ENDIF
			.ENDIF
			.IF(Misc == 3)
				invoke glBindTexture, GL_TEXTURE_2D, TexPlanks
				invoke DrawWall, 1, MazeX, MazeY, 1
				;invoke glBindTexture, GL_TEXTURE_2D, CurrentWall
			.ELSE
				.IF (ebx == 0) && (Shop)	; Shop
					invoke DrawWall, 76, MazeX, MazeY, 1
					invoke DrawFloorRoof, 2, fl1N, 0
					invoke glBindTexture, GL_TEXTURE_2D, TexSigns1
					invoke glCallList, 77
					.IF (ShopKoluplyk < 84)
						invoke glBindTexture, GL_TEXTURE_2D, TexKoluplyk
						invoke glCallList, ShopKoluplyk
						fld ShopTimer
						fsub deltaTime
						fstp ShopTimer
					.ENDIF
						
					.IF (Shop == 1) || (Shop == 2)
						fcmp camPosN, fl2
						.IF (Sign?)
							fcmp camPosN[4], fl2
							.IF (Sign?)
								fcmp ccTimer
								.IF (Sign?)
									.IF (joyUsed)
										lea eax, CCShopJ
									.ELSE
										lea eax, CCShop
									.ENDIF
									mov ccText, eax
									m2m ccTimer, flTenth
								.ENDIF
								mov Shop, 2
							.ELSE
								mov Shop, 1
							.ENDIF
						.ELSE
							mov Shop, 1
						.ENDIF
						
						fcmp ShopTimer
						.IF Sign?
							.IF (ShopKoluplyk == 78)
								inc ShopKoluplyk
							.ELSE
								dec ShopKoluplyk
							.ENDIF
							m2m ShopTimer, fl1
						.ENDIF
					.ELSEIF (Shop == 3)
						invoke MoveTowards, ADDR ShopWall, 0, delta2
						invoke glPushMatrix
						invoke glTranslatef, 0, 0, ShopWall
						invoke glBindTexture, GL_TEXTURE_2D, CurrentWall
						invoke glCallList, CurrentWallMDL
						invoke glPopMatrix
						invoke Shake, flHundredth
						push ShopWall
						fld ShopWall
						fchs
						fstp ShopWall
						invoke alSource3f, SndHbd, AL_POSITION, ShopWall, 0, fl1
						pop ShopWall
						.IF (ShopWall == 0)
							invoke alSourceStop, SndHbd
							mov Shop, 0
						.ENDIF
						
						fcmp ShopTimer
						.IF Sign?
							inc ShopKoluplyk
							m2m ShopTimer, flTenth
						.ENDIF
					.ENDIF
				.ELSE
					mov Misc, 0
					.IF (MazeTram)
						mov eax, MazeTramArea[4]
						inc eax
						.IF (eax == MazeXI)
							inc Misc
						.ENDIF
					.ENDIF
					.IF (!Misc)
						invoke DrawWall, CurrentWallMDL, MazeX, MazeY, 1
					.ENDIF
				.ENDIF
			.ENDIF
			invoke glRotatef, 1119092736, 0, fl1, 0
		.ENDIF
		
		mov Misc, 0
		.IF (MazeTram)
			mov eax, MazeTramArea
			dec eax
			mov ecx, MazeTramArea[4]
			inc ecx
			.IF (MazeXI == eax) || (MazeXI == ecx)
				inc Misc
			.ENDIF
		.ENDIF
		
		.IF (Misc)
			invoke glBindTexture, GL_TEXTURE_2D, CurrentFloor
			invoke glCallList, 2
		.ELSE
			invoke DrawFloorRoof, 2, MazeX, MazeY
		.ENDIF
				
		; Miscellaneous
		.IF (Trench)
			mov eax, MazeBuffer
			mov cl, BYTE PTR [eax+ebx]
			and cl, MZC_LAMP
			.IF (cl)
				invoke glBindTexture, GL_TEXTURE_2D, TexPlanks
				invoke glCallList, 51
			.ENDIF
		.ELSE
			mov eax, MazeBuffer
			mov cl, BYTE PTR [eax+ebx]
			and cl, MZC_ROTATED
			mov Rotate, cl
			.IF (Rotate != 0)
				invoke glRotatef, 3266576384, 0, fl1, 0
			.ENDIF
			
			mov eax, MazeBuffer
			mov cl, BYTE PTR [eax+ebx]
			and cl, MZC_LAMP
			.IF (cl)
				invoke glBindTexture, GL_TEXTURE_2D, TexLamp
				invoke glCallList, 7
			.ENDIF
			
			mov eax, MazeBuffer
			mov cl, BYTE PTR [eax+ebx]
			and cl, MZC_PIPE
			.IF (cl)
				invoke glBindTexture, GL_TEXTURE_2D, TexPipe
				invoke glCallList, 28
			.ENDIF
			
			mov eax, MazeBuffer
			mov cl, BYTE PTR [eax+ebx]
			and cl, MZC_WIRES
			.IF (cl)
				invoke glBindTexture, GL_TEXTURE_2D, TexLamp
				invoke glCallList, 37
			.ENDIF
			
			mov eax, MazeBuffer
			mov cl, BYTE PTR [eax+ebx]
			and cl, MZC_TABURETKA
			.IF (cl)
				invoke glBindTexture, GL_TEXTURE_2D, TexTaburetka
				invoke glCallList, 49
			.ENDIF
		
			.IF (Rotate)
				invoke glRotatef, 1119092736, 0, fl1, 0
			.ENDIF
		.ENDIF
		
		; Draw border walls
		mov eax, MazeWM1
		dec eax
		.IF (eax == MazeXI)
			push MazeX
			fld MazeX
			fadd fl2
			fstp MazeX
			
			invoke glPushMatrix
				invoke glTranslatef, fl2, 0, 0
				invoke glRotatef, 3266576384, 0, fl1, 0
				invoke glBindTexture, GL_TEXTURE_2D, CurrentWall
				invoke DrawWall, CurrentWallMDL, MazeX, MazeY, 1
			invoke glPopMatrix
			pop MazeX
		.ENDIF
		mov eax, MazeHM1
		dec eax
		.IF (eax == MazeYI)
			fld MazeY
			fadd fl2
			fstp MazeY
			invoke glTranslatef, 0, 0, fl2
			invoke glBindTexture, GL_TEXTURE_2D, CurrentWall
			mov eax, MazeWM1
			dec eax
			.IF (eax == MazeXI)	; Exit door
				invoke DrawExitDoor, MazeX, MazeY
			.ELSE
				invoke DrawWall, CurrentWallMDL, MazeX, MazeY, 0
			.ENDIF
		.ENDIF
		invoke glPopMatrix
		
		inc ebx
	.ENDW
	ret
DrawMaze ENDP

; Draw map layout
DrawMap PROC
	LOCAL fltVal:REAL4, fltVal1:REAL4
	
	invoke glPushMatrix
		invoke glTranslatef, camPosN, 1057048494, camPosN[4]
		
		fld camCrouch
		fmul flFifthN
		fstp fltVal
		invoke glTranslatef, 0, fltVal, 0
		
		fld camRot[4]
		fmul R2D
		fstp fltVal
		invoke glRotatef, fltVal, 0, fl1, 0
		invoke glRotatef, fl90, fl1, 0, 0
		invoke glTranslatef, MapOffset, MapOffset[4], 0
		invoke glScalef, fl06, fl06, fl1
		invoke glBindTexture, GL_TEXTURE_2D, 0
		invoke glColor4fv, ADDR clBlack
		
		invoke glScalef, MapSize, MapSize, fl1
		invoke glPushMatrix
			xor ebx, ebx
			.WHILE (ebx < MapBRID)
				.IF (ebx)
					invoke glTranslatef, fl1, 0, 0
					invoke GetPosition, ebx
					.IF (edx == 0)
						invoke glPopMatrix
						invoke glTranslatef, 0, fl1, 0
						invoke glPushMatrix
					.ENDIF
				.ENDIF
				
				invoke GetPosition, ebx
				.IF (eax != MazeHM1)
					mov eax, MazeBuffer
					add eax, ebx
					mov al, BYTE PTR [eax]
					and al, MZC_PASSLEFT
					.IF !(al)
						invoke glPushMatrix
							invoke glScalef, flTenth, fl1, fl1
							invoke glCallList, 3
						invoke glPopMatrix
					.ENDIF
				.ENDIF
					
				invoke GetPosition, ebx
				.IF (edx != MazeWM1)
					mov eax, MazeBuffer
					add eax, ebx
					mov al, BYTE PTR [eax]
					and al, MZC_PASSTOP
					.IF !(al)
						invoke glPushMatrix
							invoke glScalef, fl1, flTenth, fl1
							invoke glCallList, 3
						invoke glPopMatrix
					.ENDIF
				.ENDIF
				inc ebx
			.ENDW
		invoke glPopMatrix
		
		fild MazeHM1
		fchs
		fstp fltVal
		invoke glTranslatef, 0, fltVal, 0
		
		fld camPosN
		fmul flHalf
		fstp fltVal
		fld camPosN[4]
		fmul flHalf
		fstp fltVal1
		invoke glTranslatef, fltVal, fltVal1, 0
		invoke glScalef, flFifth, flFifth, fl1
		invoke glCallList, 3
	invoke glPopMatrix
	ret
DrawMap ENDP

; Draw Motrya that saves the game (checkpoint)
DrawMotrya PROC
	LOCAL dist:REAL4
	
	.IF (Motrya == 2)
		invoke Lerp, ADDR MotryaTimer, 3184315597, delta2
		fcmp MotryaTimer
		.IF (Sign?)
			mov Motrya, 3
			m2m MotryaTimer, fl2
		.ENDIF
		ret
	.ELSEIF (Motrya == 3)
		fld MotryaTimer
		fsub deltaTime
		fstp MotryaTimer
		fcmp MotryaTimer
		.IF (Sign?)
			mov Motrya, 0
			invoke alGetSourcei, SndMus3, AL_SOURCE_STATE, ADDR dist
			.IF (dist != AL_PLAYING)
				mov CheckpointMus, 0
				invoke alSourcef, SndMus3, AL_GAIN, 0
				invoke alSourcePlay, SndMus3
			.ENDIF
		.ENDIF
		ret
	.ENDIF
	
	.IF (Motrya == 1)
		invoke DistanceToSqr, camPosN, camPosN[4], MotryaPos, MotryaPos[4]
		mov dist, eax
		
		fcmp dist, fl6
		.IF (Sign?)
			mov Motrya, 88
			mov Save, 1
			m2m SavePos, MotryaPos
			m2m SavePos[4], MotryaPos[4]
			fld SavePos[4]
			fsub fl4
			fadd fl07N
			fstp SavePos[8]
			mov SaveSize, 0
			invoke alSourcePlay, SndSave
		.ENDIF
	.ELSE
		invoke Shake, SaveSize
	
		fld MotryaTimer
		fsub deltaTime
		fstp MotryaTimer
		
		fcmp MotryaTimer
		.IF (Sign?)
			inc Motrya
			m2m MotryaTimer, flTenth
			.IF (Motrya == 92)
				invoke SaveGame
				mov Motrya, 2
				invoke ShowSubtitles, ADDR CCSaved
				m2m MotryaTimer, fl1
			.ENDIF
		.ENDIF
	.ENDIF
	
	invoke glPushMatrix
		invoke glTranslatef, MotryaPos, 0, MotryaPos[4]
		invoke glBindTexture, GL_TEXTURE_2D, TexMotrya
		.IF (Motrya == 1)
			invoke glCallList, 88
		.ELSE
			invoke glCallList, Motrya
		.ENDIF
	invoke glPopMatrix
	ret
DrawMotrya ENDP

; Draw teleporter to eliminate spaghetti
DrawTeleporter PROC First:BYTE
	LOCAL rotVal:REAL4, PosX:REAL4, PosY:REAL4

	invoke glPushMatrix
		.IF First
			m2m PosX, MazeTeleportPos
			m2m PosY, MazeTeleportPos[4]
		.ELSE
			m2m PosX, MazeTeleportPos[8]
			m2m PosY, MazeTeleportPos[12]
		.ENDIF
		
		invoke glTranslatef, PosX, 0, PosY
		invoke glRotatef, MazeTeleportRot, 0, fl1, 0
		invoke glCallList, 47
		fld MazeTeleportRot
		fchs
		fadd st, st
		fstp rotVal
		invoke glRotatef, rotVal, 0, fl1, 0
		invoke glCallList, 48
		
		invoke DistanceToSqr, camPosN, camPosN[4], PosX, PosY
		mov rotVal, eax
		fcmp rotVal, flFifth
		.IF Sign?
			mov canControl, 0
			mov playerState, 18
			mov fadeState, 2
			invoke Lerp, ADDR camPosN, PosX, deltaTime
			fld camPosN
			fchs
			fstp camPos
			invoke Lerp, ADDR camPosN[4], PosY, deltaTime
			fld camPosN[4]
			fchs
			fstp camPos[8]
			mov camCurSpeed, 0
			mov camCurSpeed[8], 0
			
			fcmp fade, fl1
			.IF !Sign?
				invoke nrandom, 20
				.IF (eax) || (PMSeed == 0) || \
				(MazeLevel == 20) || (MazeLevel == 41) || (MazeLevel == 62) 
					invoke ShowSubtitles, ADDR CCTeleport
					invoke alSourcePlay, SndMistake
					print "Teleported player with "
					.IF First
						print "first teleporter.", 13, 10
						fld MazeTeleportPos[8]
					.ELSE
						print "second teleporter.", 13, 10
						fld MazeTeleportPos
					.ENDIF
					fchs
					fst camPos
					fst camPosNext
					fstp camPosL
					.IF First
						fld MazeTeleportPos[12]
					.ELSE
						fld MazeTeleportPos[4]
					.ENDIF
					fchs
					fst camPos[8]
					fst camPosNext[8]
					fstp camPosL[8]
					mov fadeState, 1
					mov MazeTeleport, 0
					mov canControl, 1
					mov playerState, 0
				.ELSE
					invoke ShowSubtitles, ADDR CCTeleportBad
					invoke alSourcePlay, SndDistress
					print "Teleported player badly.", 13, 10
					invoke FreeMaze
					
					invoke nrandom, 2
					.IF (eax)
						m2m MazeSeed, PMSeed
						m2m MazeW, PMW
						m2m MazeH, PMH
						sub MazeLevel, 2
					.ELSE
						invoke GetTickCount
						mov MazeSeed, eax
					.ENDIF
					invoke GenerateMaze, MazeSeed
					invoke GetRandomMazePosition, ADDR camPosN, ADDR camPosN[4]
					fld camPosN
					fchs
					fst camPos
					fst camPosNext
					fstp camPosL
					fld camPosN[4]
					fchs
					fst camPos[8]
					fst camPosNext[8]
					fstp camPosL[8]
					mov fadeState, 1
					mov MazeTeleport, 0
					mov canControl, 1
					mov playerState, 0
					
					m2m MazeLevelPopupTimer, fl2
					mov MazeLevelPopup, 1
				.ENDIF
			.ENDIF
		.ENDIF
	invoke glPopMatrix
	ret
DrawTeleporter ENDP

; Draw items in the maze like the key, glyphs etc
DrawMazeItems PROC
	LOCAL rotVal:REAL4
	
	.IF (MazeLocked == 1)	; Key
		invoke nrandom, 100
		.IF (eax == 0)
			invoke nrandom, 360
			mov MazeKeyRot[4], eax
			fild MazeKeyRot[4]
			fstp MazeKeyRot[4]
		.ENDIF
		fld deltaTime
		fmul flTenth
		fstp rotVal
		invoke Lerp, ADDR MazeKeyRot, MazeKeyRot[4], rotVal
		invoke glPushMatrix
			invoke glEnable, GL_LIGHTING
			invoke glEnable, GL_FOG
			invoke glEnable, GL_BLEND
			invoke glBlendFunc, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
			invoke glBindTexture, GL_TEXTURE_2D, TexKey
			invoke glTranslatef, MazeKeyPos, 0, MazeKeyPos[4]
			invoke glRotatef, MazeKeyRot, 0, fl1, 0
			invoke glCallList, 35
			invoke glDisable, GL_BLEND
		invoke glPopMatrix
		invoke DistanceToSqr, camPosN, camPosN[4], MazeKeyPos, MazeKeyPos[4]
		mov rotVal, eax
		fcmp rotVal, fl1
		.IF Sign?
			mov MazeLocked, 2
			invoke ShowSubtitles, ADDR CCKey
			invoke alSource3f, SndKey, AL_POSITION, \
			MazeKeyPos, fl1, MazeKeyPos[4]
			invoke alSourcePlay, SndKey
			invoke AlertWB, 2
		.ENDIF
	.ENDIF
	
	.IF (Compass == 1)	; Compass
		invoke glPushMatrix
			invoke glEnable, GL_LIGHTING
			invoke glEnable, GL_FOG
			invoke glBindTexture, GL_TEXTURE_2D, TexCompassWorld
			invoke glTranslatef, CompassPos, 0, CompassPos[4]
			invoke glCallList, 38
		invoke glPopMatrix
		invoke DistanceToSqr, camPosN, camPosN[4], CompassPos, CompassPos[4]
		mov rotVal, eax
		fcmp rotVal, fl1
		.IF Sign?
			mov Compass, 2
			invoke ShowSubtitles, ADDR CCCompass
			invoke alSourcePlay, SndMistake
		.ENDIF
	.ENDIF
	.IF ((Compass == 2) || (Map)) && (playerState == 0)
		fcmp camRot, fl04
		.IF !Sign?
			invoke glPushMatrix
				invoke glDisable, GL_LIGHTING
				invoke glDisable, GL_FOG
				invoke glDisable, GL_DEPTH_TEST
				invoke glEnable, GL_BLEND
				invoke glBlendFunc, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
				invoke glTranslatef, camPosN, flHalf, camPosN[4]
				
				fld camCrouch
				fmul flFifthN
				fstp rotVal
				invoke glTranslatef, 0, rotVal, 0
				
				fld camRot[4]
				fmul R2D
				fstp rotVal
				invoke glRotatef, rotVal, 0, fl1, 0
				invoke glRotatef, fl90, fl1, 0, 0
				.IF (Map)
					invoke glBindTexture, GL_TEXTURE_2D, TexMap
					invoke glTranslatef, 3198744003, 3198744003, 0
					invoke glScalef, 1059648963, 1059648963, fl1
				.ELSE
					invoke glBindTexture, GL_TEXTURE_2D, TexCompass
					invoke glTranslatef, 3190422503, 3190422503, 0
					invoke glScalef, flThird, flThird, fl1
				.ENDIF
				invoke glCallList, 3
			invoke glPopMatrix
			.IF (Compass == 2)
				invoke glPushMatrix
					invoke glTranslatef, camPosN, 1057132380, camPosN[4]
					
					fld camCrouch
					fmul flFifthN
					fstp rotVal
					invoke glTranslatef, 0, rotVal, 0
					
					.IF (MazeLocked == 1)
						invoke GetDirection, MazeKeyPos, MazeKeyPos[4], camPosN, camPosN[4]
						mov rotVal, eax
					.ELSE
						invoke GetDirection, camPos, camPos[8], MazeDoorPos, MazeDoorPos[4]
						mov rotVal, eax
					.ENDIF
					fld rotVal
					fsubr camRot[4]
					fstp rotVal
					invoke Angleify, ADDR rotVal
					invoke Angleify, ADDR CompassRot
					invoke LerpAngle, ADDR CompassRot, rotVal, delta2
					fld camRot[4]
					fsub CompassRot
					fmul R2D
					fstp rotVal
					invoke glRotatef, rotVal, 0, fl1, 0
					.IF (Map)
						invoke glColor4f, fl1, fl1, fl1, flHalf
					.ENDIF
					invoke glBindTexture, GL_TEXTURE_2D, TexCompassWorld
					invoke glCallList, 39
				invoke glPopMatrix
			.ENDIF
			invoke glDisable, GL_BLEND
			.IF (Map)	; Map
				invoke DrawMap
			.ENDIF
			invoke glEnable, GL_DEPTH_TEST
			invoke glEnable, GL_LIGHTING
		.ENDIF
	.ENDIF
	
	invoke glColor4fv, ADDR clWhite
	.IF (MazeGlyphs)	; Glyphs
		fld MazeGlyphsRot
		fadd deltaTime
		fst MazeGlyphsRot
		fsin
		fmul flFifth
		fstp rotVal
		
		invoke Angleify, ADDR MazeGlyphsRot
		
		invoke glPushMatrix
			invoke glDisable, GL_LIGHTING
			invoke glEnable, GL_FOG
			invoke glBindTexture, GL_TEXTURE_2D, TexGlyphs
			invoke glTranslatef, MazeGlyphsPos, rotVal, MazeGlyphsPos[4]
			fld MazeGlyphsRot
			fmul R2D
			fstp rotVal
			invoke glRotatef, rotVal, 0, fl1, 0
			invoke glCallList, 36
		invoke glPopMatrix
		invoke glEnable, GL_LIGHTING
		invoke DistanceToSqr, camPosN, camPosN[4], MazeGlyphsPos, MazeGlyphsPos[4]
		mov rotVal, eax
		fcmp rotVal, fl1
		.IF Sign?
			mov MazeGlyphs, 0
			invoke ShowSubtitles, ADDR CCGlyphRestore
			invoke alSourcePlay, SndMistake
			mov Glyphs, 7
			mov GlyphOffset, 0
			mov GlyphsInLayer, 0
			mov virdyaState, 0
			mov fade, 0
			mov vignetteRed, 0
		.ENDIF
	.ENDIF
	
	.IF (MazeNote) && (MazeNote < 16)
		invoke MagnitudeSqr, MazeNotePos, MazeNotePos[4]
		mov rotVal, eax
		fld rotVal
		fmul R2D
		fstp rotVal
	
		invoke glDisable, GL_LIGHTING
		invoke glEnable, GL_FOG
		invoke glEnable, GL_BLEND
		invoke glBlendFunc, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
		invoke glPushMatrix
			invoke glBindTexture, GL_TEXTURE_2D, TexPaper
			invoke glTranslatef, MazeNotePos, flHundredth, MazeNotePos[4]
			invoke glRotatef, rotVal, 0, fl1, 0
			invoke glRotatef, fl90, fl1, 0, 0
			
			invoke glTranslatef, 3190422503, 3190422503, 0
			invoke glScalef, flThird, flThird, fl1
			invoke glCallList, 3
		invoke glPopMatrix
		invoke glEnable, GL_LIGHTING
		
		invoke DistanceToSqr, camPosN, camPosN[4], MazeNotePos, MazeNotePos[4]
		mov rotVal, eax
		fcmp rotVal, fl06
		.IF (Sign?) && (playerState == 0)
			add MazeNote, 16
			mov canControl, 0
			mov camCurSpeed, 0
			mov camCurSpeed[8], 0
		.ENDIF
	.ENDIF
	
	.IF (MazeTeleport)	; Teleporters
		fld MazeTeleportRot
		fadd delta10
		fstp MazeTeleportRot
		
		fcmp MazeTeleportRot, fl360
		.IF !Sign?
			fld MazeTeleportRot
			fsub fl360
			fstp MazeTeleportRot
		.ENDIF
		
		invoke glDisable, GL_LIGHTING
		invoke glEnable, GL_FOG
		invoke glDisable, GL_BLEND
		invoke glBindTexture, GL_TEXTURE_2D, 0
		invoke glEnable, GL_LIGHTING

		invoke DrawTeleporter, 1
		invoke DrawTeleporter, 0
	.ENDIF
	ret
DrawMazeItems ENDP

; Draw UI noise, made a PROC for intro rain
DrawNoise PROC Texture:DWORD
	LOCAL screenWF: DWORD, screenHF: DWORD
	LOCAL noiseX: DWORD, noiseY: DWORD
	
	invoke glLoadIdentity	; Draw noise
	invoke glBindTexture, GL_TEXTURE_2D, Texture
	
	invoke nrandom, 512	; Random noise offset
	mov noiseX, eax
	invoke nrandom, 512
	mov noiseY, eax
	
	fild noiseX
	fchs
	fstp screenWF
	fild noiseY
	fchs
	fstp screenHF
	invoke glTranslatef, screenWF, screenHF, 0
	
	invoke glScalef, 1140850688, 1140850688, 0
	
	mov eax, screenSize
	mov ecx, 512
	xor edx, edx
	div ecx
	inc eax
	inc eax
	mov noiseX, eax
	mov eax, screenSize[4]
	mov ecx, 512
	xor edx, edx
	div ecx
	inc eax
	inc eax
	mov noiseY, eax
	
	xor ebx, ebx
	.WHILE (ebx < noiseY)
		push ebx
		invoke glPushMatrix
		xor ebx, ebx
		.WHILE (ebx < noiseX)
			invoke glCallList, 3
			invoke glTranslatef, fl1, 0, 0
			inc ebx
		.ENDW
		pop ebx
		invoke glPopMatrix
		invoke glTranslatef, 0, fl1, 0
		inc ebx
	.ENDW
	ret
DrawNoise ENDP

; Draw TextString text at (X, Y)
DrawBitmapText PROC TextString:DWORD, X:REAL4, Y:REAL4, TextAlign:BYTE
	LOCAL Char:BYTE, StrIdx:DWORD, StrLength:DWORD, Carriage:BYTE
	
	mov Carriage, 0
	
	invoke glPushMatrix
	invoke glTranslatef, X, Y, 0
	invoke glScalef, mnFont, mnFont[4], fl1
	
	mov StrLength, 0	; Manually get string length (MASM actually has StrLen)
	mov ebx, TextString
	.WHILE TRUE
		mov al, BYTE PTR [ebx]
		mov Char, al
		.BREAK .IF !Char
		.IF (Char == 35)	; #
			mov Carriage, 1
			.BREAK
		.ENDIF
		inc ebx
		inc StrLength
	.ENDW
		
	.IF (TextAlign != FNT_LEFT)
		.IF (TextAlign == FNT_CENTERED)
			fld mnFontSpacing
			fimul StrLength
			fmul flHalf
			fchs
			fstp StrIdx
		.ENDIF
		invoke glTranslatef, StrIdx, 0, 0
	.ENDIF
	mov StrIdx, 0
	mov bl, 1
	
	.WHILE TRUE
		.BREAK .IF StrLength == 0
		mov eax, TextString
		mov ebx, StrIdx		; For some reason "add eax, StrIdx" doesn't work
		mov bl, BYTE PTR [eax+ebx]	; (trying to get from [eax] crashes it)
		mov Char, bl
		
		.IF (Char > 64) && (Char < 91)
			sub bl, 65
			mov eax, ebx
			mov ebx, 4
			mul ebx
			invoke glBindTexture, GL_TEXTURE_2D, TexFont[eax]
			invoke glCallList, 3
		.ELSEIF (Char > 47) && (Char < 58)
			sub bl, 22
			mov eax, ebx
			mov ebx, 4
			mul ebx
			invoke glBindTexture, GL_TEXTURE_2D, TexFont[eax]
			invoke glCallList, 3
		.ELSE
			xor ebx, ebx
			mov bl, Char
			SWITCH ebx
				CASE 46
					invoke glBindTexture, GL_TEXTURE_2D, TexFont[144]
					invoke glCallList, 3
				CASE 44
					invoke glBindTexture, GL_TEXTURE_2D, TexFont[148]
					invoke glCallList, 3
				CASE 63
					invoke glBindTexture, GL_TEXTURE_2D, TexFont[156]
					invoke glCallList, 3
				CASE 33
					invoke glBindTexture, GL_TEXTURE_2D, TexFont[152]
					invoke glCallList, 3
				CASE 45
					invoke glBindTexture, GL_TEXTURE_2D, TexFont[160]
					invoke glCallList, 3
					
			ENDSW
		.ENDIF
		
		invoke glTranslatef, mnFontSpacing, 0, 0
		
		inc StrIdx
		dec StrLength
		mov bl, Char
	.ENDW
	
	invoke glPopMatrix
	
	.IF (Carriage)
		fld Y
		fadd mnFont
		fadd mnFont[4]
		fstp StrLength
		mov eax, StrIdx
		inc eax
		add eax, TextString
		mov StrIdx, eax
		invoke DrawBitmapText, StrIdx, X, StrLength, TextAlign
	.ENDIF
	ret
DrawBitmapText ENDP

; Draw placed glyphs
DrawGlyphs PROC
	LOCAL glyph4:DWORD
	xor ebx, ebx
	mov bl, GlyphsInLayer
	mov eax, 4
	mul ebx
	mov glyph4, eax
	xor ebx, ebx
	invoke glDisable, GL_LIGHTING
	invoke glDisable, GL_FOG
	invoke glEnable, GL_BLEND
	invoke glBlendFunc, GL_ONE_MINUS_DST_COLOR, GL_ONE_MINUS_SRC_COLOR
	.WHILE (ebx < glyph4)
		invoke glPushMatrix
			mov eax, ebx
			add eax, eax
			invoke glTranslatef, GlyphPos[eax], flHundredth, GlyphPos[eax+4]
			invoke glRotatef, GlyphRot[ebx], 0, fl1, 0
			invoke glTranslatef, flFifthN, 0, flHalfN
			invoke glRotatef, 1119092736, fl1, 0, 0
			invoke glScalef, fl04, fl09, fl09
			xor eax, eax
			mov al, GlyphOffset
			add eax, ebx
			invoke glBindTexture, GL_TEXTURE_2D, TexGlyph[eax]
			invoke glCallList, 3
		invoke glPopMatrix
		add ebx, 4
	.ENDW
	invoke glEnable, GL_LIGHTING
	invoke glEnable, GL_FOG
	invoke glDisable, GL_BLEND
	ret
DrawGlyphs ENDP

; Huenbergondel
DrawHbd PROC
	LOCAL PosXF:REAL4, PosYF:REAL4, PosOff:DWORD

	fld hbdTimer
	fsub deltaTime
	fstp hbdTimer
	
	fcmp hbdTimer
	.IF (Sign?)
		.IF hbd == 1
			invoke alSourcePlay, SndHbdO
			invoke alSource3f, SndHbdO, AL_POSITION, hbdPosF, 0, hbdPosF[4]
			mov hbdMdl, 55
			invoke nrandom, 4
			mov ebx, 4
			mul ebx
			mov hbdRot, eax
				
			.IF (hbdRot == 0) || (hbdRot == 4)
				invoke GetOffset, hbdPos, hbdPos[4]
			.ELSEIF (hbdRot == 8)
				mov eax, hbdPos[4]
				add eax, 1
				invoke GetOffset, hbdPos, eax
			.ELSEIF (hbdRot == 12)
				mov eax, hbdPos
				add eax, 1
				invoke GetOffset, eax, hbdPos[4]
			.ENDIF
			
			mov PosOff, eax
			add eax, MazeBuffer
			mov al, BYTE PTR [eax]
			.IF (hbdRot == 0) || (hbdRot == 8)
				and al, MZC_PASSTOP
			.ELSE
				and al, MZC_PASSLEFT
			.ENDIF
			
			.IF (MazeCrevice)
				push eax
				invoke GetOffset, MazeCrevicePos, MazeCrevicePos[4]
				.IF (PosOff == eax)
					pop eax
					mov eax, 0
				.ELSE
					pop eax
				.ENDIF
			.ENDIF
			
			.IF (al)
				m2m hbdTimer, fl1
				inc hbd
			.ENDIF
		.ELSEIF hbd == 2
			invoke alSourcePlay, SndHbd
			SWITCH hbdRot
				CASE 0
					dec hbdPos[4]
				CASE 4
					dec hbdPos
				CASE 8
					inc hbdPos[4]
				CASE 12
					inc hbdPos
			ENDSW
			m2m hbdTimer, fl1
			inc hbd
		.ELSEIF hbd == 3
			invoke alSourceStop, SndHbd
			m2m hbdTimer, flHalf
			inc hbd
		.ELSE
			mov hbdMdl, 56
			m2m hbdTimer, fl4
			mov hbd, 1
		.ENDIF
	.ENDIF
	
	invoke DistanceToSqr, hbdPosF, hbdPosF[4], camPosNext, camPosNext[8]
	mov PosXF, eax
	
	fcmp PosXF, fl1
	.IF (Sign?) && (!Zero?)	; Chocar con jugador
		.IF (hbd == 3)
			fcmp PosXF, fl09
			.IF (Sign?) && (playerState == 0)
				invoke alSourcePlay, SndImpact
				mov playerState, 9
				mov fadeState, 2
			.ENDIF
			.IF (playerState == 9)
				invoke Lerp, ADDR camPos[4], 3184315597, delta2			
			.ENDIF
		.ENDIF
		fld camCurSpeed
		fchs
		fstp camCurSpeed
		fld camCurSpeed[8]
		fchs
		fstp camCurSpeed[8]
	.ENDIF

	invoke glPushMatrix	; Draw
		fild hbdPos
		fmul fl2
		fadd fl1
		fstp PosXF
		fild hbdPos[4]
		fmul fl2
		fadd fl1
		fstp PosYF
		
		.IF (hbd != 1)
			.IF (hbd == 3)
				invoke alSource3f, SndHbd, AL_POSITION, hbdPosF, 0, hbdPosF[4]
			.ENDIF
		
			invoke MoveTowards, ADDR hbdPosF, PosXF, delta2
			invoke MoveTowards, ADDR hbdPosF[4], PosYF, delta2
			
			mov eax, hbdRot
			fld rotations[eax]
			fstp PosXF
			invoke MoveTowards, ADDR hbdRotF, PosXF, delta10
		.ENDIF
		
		fld hbdRotF
		fmul R2D
		fstp PosXF
		
		invoke glTranslatef, hbdPosF, 0, hbdPosF[4]
		invoke glRotatef, PosXF, 0, fl1, 0
		invoke glBindTexture, GL_TEXTURE_2D, TexHbd
		invoke glCallList, hbdMdl
	invoke glPopMatrix
	ret
DrawHbd ENDP

; Draw Kubale
DrawKubale PROC
	invoke glPushMatrix
		invoke glTranslatef, kubalePos, 0, kubalePos[4]
		invoke glRotatef, kubaleDir, 0, fl1, 0
		invoke glBindTexture, GL_TEXTURE_2D, TexKubale
		invoke glCallList, kubale
	invoke glPopMatrix
	ret
DrawKubale ENDP

; Process Kubale AI
KubaleAI PROC
	LOCAL distance:REAL4, lookAt:REAL4, dotProduct:REAL4, dotX:REAL4, dotY:REAL4
	LOCAL nextPosX:REAL4, nextPosY:REAL4, mazePosX:SWORD, mazePosY:SWORD
	LOCAL cellCntX:REAL4, cellCntY:REAL4, teleportAttempts:BYTE
	LOCAL PosX:DWORD, PosY:DWORD
	
	.IF (playerState != 0)
		invoke Lerp, ADDR kubaleRun, 0, delta10
		invoke Lerp, ADDR kubaleVision, 0, delta2
		fcmp kubaleVision, flHundredth
		.IF (Sign?)
			mov kubaleVision, 0
		.ENDIF
		invoke alSourcef, SndKubaleV, AL_GAIN, kubaleVision
		invoke alSourcef, SndKubale, AL_GAIN, kubaleRun
		ret
	.ENDIF
	
	invoke DistanceToSqr, kubalePos, kubalePos[4], camPosNext, camPosNext[8]
	mov distance, eax
	invoke GetDirection, kubalePos, kubalePos[4], camPosN, camPosN[4]
	mov lookAt, eax
	
	fcmp distance, fl1000	; If Kubale is too far away, teleport
	.IF !Sign?
		mov teleportAttempts, 0
		.REPEAT
			print "TELEPORTING", 13, 10
			invoke GetRandomMazePosition, ADDR kubalePos, ADDR kubalePos[4]
			
			inc teleportAttempts
			
			invoke DistanceToSqr, kubalePos, kubalePos[4], \
			camPosNext, camPosNext[8]
			mov distance, eax
			fcmp distance, fl32
		.UNTIL (!Sign?) || (teleportAttempts > 8)
		ret
	.ENDIF
	
	fcmp distance, flThird	; Collide with player
	.IF Sign?
		fld camCurSpeed
		fchs
		fstp camCurSpeed
		fld camCurSpeed[8]
		fchs
		fstp camCurSpeed[8]
	.ENDIF
	
	fld camPosN
	fsub kubalePos
	fstp dotX
	fld camPosN[4]
	fsub kubalePos[4]
	fstp dotY
	
	invoke Normalize, ADDR dotX, ADDR dotY
	fld dotX
	fmul camForward
	fstp dotX
	fld dotY
	fmul camForward[8]
	fadd dotX
	fstp dotProduct
	
	fcmp dotProduct, flThird
	.IF (Sign?)	; If not visible
		fld lookAt	; Rotate
		fmul R2D
		fstp kubaleDir
		
		fcmp distance, flKubaleTh
		.IF !Sign?
			push distance
			
			fld deltaTime	; Get speed to move
			fmul distance
			fmul fl1n5
			fadd delta2
			fstp distance
			
			fld lookAt
			fsin
			fmul distance
			fstp kubaleSpeed
			
			fld lookAt
			fcos
			fmul distance
			fstp kubaleSpeed[4]
			
			invoke MoveAndCollide, ADDR kubalePos, ADDR kubalePos[4], \
			ADDR kubaleSpeed, ADDR kubaleSpeed[4], flFifth, 1
			
			invoke nrandom, 4
			add eax, 29
			mov kubale, eax
			
			invoke Lerp, ADDR kubaleRun, fl1, delta10
			
			pop distance
		.ELSE
			invoke Lerp, ADDR kubaleRun, 0, delta10
		.ENDIF
		
		fcmp distance, fl2
		.IF (Sign?)
			invoke Lerp, ADDR kubaleVision, fl1, delta2
			invoke Lerp, ADDR vignetteRed, fl1, deltaTime
			fld deltaTime
			fadd fade
			fstp fade
			fcmp fade, fl1
			.IF !Sign?
				mov playerState, 9
			.ENDIF
		.ELSE
			invoke Lerp, ADDR kubaleVision, 0, delta2
			fcmp kubaleVision, flHundredth
			.IF (Sign?)
				mov kubaleVision, 0
			.ENDIF
			.IF (!virdyaSound)
				invoke Lerp, ADDR vignetteRed, 0, deltaTime
				invoke Lerp, ADDR fade, 0, deltaTime
			.ENDIF
		.ENDIF
	.ELSE
		invoke Lerp, ADDR kubaleVision, 0, delta2
		fcmp kubaleVision, flHundredth
		.IF (Sign?)
			mov kubaleVision, 0
		.ENDIF
		invoke Lerp, ADDR kubaleRun, 0, delta10
		.IF (!virdyaSound)
			invoke Lerp, ADDR vignetteRed, 0, deltaTime
			invoke Lerp, ADDR fade, 0, deltaTime
		.ENDIF
	.ENDIF
	
	invoke alSourcef, SndKubaleV, AL_GAIN, kubaleVision
	invoke alSourcef, SndKubale, AL_GAIN, kubaleRun
	invoke alSource3f, SndKubale, AL_POSITION, kubalePos, 0, kubalePos[4]
	
	fcmp distance, fl75
	.IF (Sign?)
		invoke DrawKubale
	.ENDIF
	ret
KubaleAI ENDP

; Spawn Kubale into the layer with random position
MakeKubale PROC
	mov kubale, 29
	
	invoke alSourcePlay, SndKubale
	invoke alSourcePlay, SndKubaleV
	
	invoke GetRandomMazePosition, ADDR kubalePos, ADDR kubalePos[4]
	ret
MakeKubale ENDP

; Kubale light flicker appearance
KubaleEvent PROC
	LOCAL tempStuff:DWORD
	
	fld kubaleDir
	fsub deltaTime
	fstp kubaleDir
	
	SWITCH kubale
		CASE 2	; Flickering
			invoke nrandom, 6
			mov tempStuff, eax
			fild tempStuff
			fmul flTenth
			fadd flHalf
			fstp fogDensity
		CASE 3	; Going dark
			invoke Lerp, ADDR fogDensity, fl12, delta10
	ENDSW
	
	fcmp kubaleDir
	.IF (Sign?) && (playerState == 0)
		SWITCH kubale
			CASE 1	; Waited
				invoke alSourcePlay, SndKubaleAppear
				m2m kubaleDir, fl1
				mov kubale, 2
			CASE 2	; Flickered
				m2m kubaleDir, fl2
				mov kubale, 3
			CASE 3	; Waited in darkness
				m2m fade, fl1
				mov fadeState, 1
				invoke MakeKubale
		ENDSW
	.ENDIF
	ret
KubaleEvent ENDP

; Draw the light flare that represents the save (checkpoint)
DrawSave PROC
	LOCAL rotVal:REAL4
	
	invoke Lerp, ADDR SaveSize, fl1, deltaTime
	invoke Lerp, ADDR SavePos[4], SavePos[8], deltaTime
	
	invoke DistanceToSqr, camPosN, camPosN[4], SavePos, SavePos[8]
	mov rotVal, eax
	fcmp rotVal, fl2
	.IF (Sign?)
		mov Save, 2
		fcmp ccTimer
		.IF (Sign?)
			.IF (joyUsed)
				lea eax, CCSaveEraseJ
			.ELSE
				lea eax, CCSaveErase
			.ENDIF
			mov ccText, eax
			m2m ccTimer, flTenth
		.ENDIF
	.ELSEIF (Save == 2)
		mov Save, 1
	.ENDIF

	invoke GetDirection, SavePos, SavePos[4], camPosN, camPosN[4]
	mov rotVal, eax
	fld rotVal
	fmul R2D
	fstp rotVal
	
	invoke glPushMatrix
		invoke glTranslatef, SavePos, fl1, SavePos[4]
		invoke glRotatef, rotVal, 0, fl1, 0
		invoke glScalef, SaveSize, SaveSize, SaveSize
		
		invoke RandomFloat, ADDR rotVal, 1
		fld rotVal
		fmul flTenth
		fadd fl09
		fmul SaveSize
		fstp rotVal
		
		invoke glDisable, GL_DEPTH_TEST
		invoke glDisable, GL_LIGHTING
		;invoke glDisable, GL_FOG
		invoke glEnable, GL_BLEND
		invoke glBlendFunc, GL_ONE, GL_ONE
		invoke glBindTexture, GL_TEXTURE_2D, TexLight
		invoke glColor3f, rotVal, rotVal, rotVal
		invoke glCallList, 84
		invoke glEnable, GL_DEPTH_TEST
		invoke glEnable, GL_LIGHTING
		;invoke glEnable, GL_FOG
		invoke glDisable, GL_BLEND
	invoke glPopMatrix
	ret
DrawSave ENDP

; Draw tram and operate it
DrawTram PROC
	LOCAL rotVal:REAL4, deltaVal:REAL4, deltaHalf:REAL4
	
	mov eax, MazeTramRot
	mov eax, rotations[eax]
	mov rotVal, eax
	invoke Angleify, ADDR MazeTramRot[4] 
	invoke MoveTowardsAngle, ADDR MazeTramRot[4], rotVal, delta2
	invoke Angleify, ADDR MazeTramRot[4] 
	
	invoke DistanceScalar, MazeTramRot[4], rotVal
	mov deltaVal, eax
	fld PIHalf
	fsub deltaVal
	fmul delta2
	fstp deltaVal
	
	.IF (MazeTramPlr > 1)
		fld MazeTramPos
		fchs
		fstp camPos
		fld MazeTramPos[8]
		fchs
		fstp camPos[8]
		m2m camPos[4], flTramH
		
		fld rotVal
		fsub MazeTramRot[4]
		fmul delta2
		fadd camRot[4]
		fstp camRot[4]
		
		fld MazeTramSpeed
		fmul flHundredth
		fstp rotVal
		invoke Shake, rotVal
		.IF (MazeTramPlr == 3)
			.IF (joyUsed)
				lea eax, CCTramExitJ
			.ELSE
				lea eax, CCTramExit
			.ENDIF
			mov ccText, eax
			m2m ccTimer, flTenth
		.ENDIF
	.ENDIF
	
	fld deltaTime
	fmul flHalf
	fstp deltaHalf
	
	invoke alSourcef, SndTram, AL_PITCH, MazeTramSpeed
	invoke alSource3f, SndTram, AL_POSITION, MazeTramPos, fl2, MazeTramPos[8]
	mov eax, MazeTramSnd
	invoke alSource3f, SndTramAnn[eax], AL_POSITION, \
	MazeTramPos, fl1, MazeTramPos[8]
	
	.IF (MazeTram == 1)
		invoke MoveTowards, ADDR MazeTramSpeed, fl1, deltaHalf
		
		fild MazeHM1
		fstp rotVal
		invoke DistanceScalar, MazeTramPos[8], rotVal
		mov rotVal, eax
		fcmp rotVal, flHalf
		.IF (Sign?)
			mov MazeTram, 2
		.ENDIF
	.ELSEIF (MazeTram == 2)
		invoke MoveTowards, ADDR MazeTramSpeed, 0, deltaTime
		.IF (!MazeTramSpeed)
			m2m MazeTeleportRot, flHalf
			mov MazeTram, 3
		.ENDIF
	.ELSEIF (MazeTram == 3)
		.IF (MazeTramDoors < 102)
			fld MazeTeleportRot
			fsub deltaTime
			fstp MazeTeleportRot
			fcmp MazeTeleportRot
			.IF (Sign?)
				.IF (MazeTramDoors == 99)
					invoke alSource3f, SndTramOpen, AL_POSITION, \
					MazeTramPos, fl2, MazeTramPos[8]
					invoke alSourcePlay, SndTramOpen
				.ENDIF
				m2m MazeTeleportRot, flTenth
				inc MazeTramDoors
			.ENDIF
		.ELSE
			mov MazeTram, 4
			m2m MazeTeleportRot, fl4
		.ENDIF
	.ELSEIF (MazeTram == 4)
		.IF (MazeTramPlr < 2)
			invoke DistanceToSqr, MazeTramPos, MazeTramPos[8], \
			camPosN, camPosN[4]
			mov rotVal, eax
			fcmp rotVal, fl3
			.IF (Sign?)
				mov MazeTramPlr, 1
				fcmp ccTimer
				.IF (Sign?)
					.IF (joyUsed)
						lea eax, CCTramJ
					.ELSE
						lea eax, CCTram
					.ENDIF
					mov ccText, eax
					m2m ccTimer, flTenth
				.ENDIF
			.ELSE
				mov MazeTramPlr, 0
			.ENDIF
			.IF (wmblyk == 11)
				invoke DistanceToSqr, MazeTramPos, MazeTramPos[8], \
				wmblykPos, wmblykPos[4]
				mov rotVal, eax
				fcmp rotVal, fl5
				.IF (Sign?)
					mov wmblyk, 0
					mov WmblykTram, 1
					invoke alSourceStop, SndWmblykB
				.ENDIF
			.ENDIF
		.ELSEIF (MazeTramPlr == 2)
			mov MazeTramPlr, 3
		.ENDIF
	
		fld MazeTeleportRot
		fsub deltaTime
		fstp MazeTeleportRot
		fcmp MazeTeleportRot
		.IF (Sign?)
			.IF (MazeTramPlr == 1)
				mov MazeTramPlr, 0
			.ELSEIF (MazeTramPlr == 3)
				mov MazeTramPlr, 2
			.ENDIF
			mov MazeTram, 5
			m2m MazeTeleportRot, flTenth
			
			invoke alSource3f, SndTramClose, AL_POSITION, \
			MazeTramPos, fl2, MazeTramPos[8]
			invoke alSourcePlay, SndTramClose
		.ENDIF
	.ELSEIF (MazeTram == 5)
		.IF (MazeTramDoors > 99)
			fld MazeTeleportRot
			fsub deltaTime
			fstp MazeTeleportRot
			fcmp MazeTeleportRot
			.IF (Sign?)
				m2m MazeTeleportRot, flTenth
				dec MazeTramDoors
			.ENDIF
		.ELSE
			mov MazeTram, 6
		.ENDIF
	.ELSEIF (MazeTram == 6)
		invoke MoveTowards, ADDR MazeTramSpeed, fl1, deltaHalf
		mov eax, fl1
		.IF (MazeTramSpeed == eax)
			mov MazeTram, 1
			invoke nrandom, 8
			SWITCH eax
				CASE 0
					invoke alSourcePlay, SndTramAnn
					mov MazeTramSnd, 0
				CASE 1
					invoke alSourcePlay, SndTramAnn[4]
					mov MazeTramSnd, 4
				CASE 2
					invoke alSourcePlay, SndTramAnn[8]
					mov MazeTramSnd, 8
			ENDSW
		.ENDIF
	.ENDIF
	
	fild MazeTramArea
	fmul fl2
	fsub flWTh
	fstp rotVal
	fcmp camPosNext, rotVal
	.IF (!Sign?)
		fild MazeTramArea[4]
		fadd fl1
		fmul fl2
		fadd flWTh
		fstp rotVal
		fcmp camPosNext, rotVal
		.IF (Sign?)
			mov camCurSpeed, 0
		.ENDIF
	.ENDIF
	
	xor ebx, ebx
	SWITCH MazeTramRot
		CASE 0
			invoke DistanceScalar, MazeTramPos[8], fl1
			mov rotVal, eax
			fcmp rotVal, fl2
			.IF (Sign?)
				mov MazeTramRot, 4
				inc ebx
			.ENDIF
			
			fild MazeTramArea[4]
			fmul fl2
			fadd fl1
			fstp rotVal
			invoke MoveTowards, ADDR MazeTramPos, rotVal, deltaVal
		CASE 4
			fild MazeTramArea
			fmul fl2
			fadd fl1
			fstp rotVal
			invoke DistanceScalar, MazeTramPos, rotVal
			mov rotVal, eax
			fcmp rotVal, fl2
			.IF (Sign?)
				mov MazeTramRot, 8
				inc ebx
			.ENDIF
			
			invoke MoveTowards, ADDR MazeTramPos[8], fl1, deltaVal
		CASE 8
			fild MazeHM1
			fsub fl1
			fmul fl2
			fadd fl1
			fstp rotVal
			invoke DistanceScalar, MazeTramPos[8], rotVal
			mov rotVal, eax
			fcmp rotVal, fl2
			.IF (Sign?)
				mov MazeTramRot, 12
				inc ebx
			.ENDIF
			
			fild MazeTramArea
			fmul fl2
			fadd fl1
			fstp rotVal
			invoke MoveTowards, ADDR MazeTramPos, rotVal, deltaVal
		CASE 12
			fild MazeTramArea[4]
			fmul fl2
			fadd fl1
			fstp rotVal
			invoke DistanceScalar, MazeTramPos, rotVal
			mov rotVal, eax
			fcmp rotVal, fl2
			.IF (Sign?)
				mov MazeTramRot, 0
				inc ebx
			.ENDIF
		
			fild MazeHM1
			fsub fl1
			fmul fl2
			fadd fl1
			fstp rotVal
			invoke MoveTowards, ADDR MazeTramPos[8], rotVal, deltaVal
	ENDSW
	
	fld MazeTramRot[4]
	fsin
	fmul deltaVal
	fmul MazeTramSpeed
	fsubr MazeTramPos
	fstp MazeTramPos
	fld MazeTramRot[4]
	fcos
	fmul deltaVal
	fmul MazeTramSpeed
	fsubr MazeTramPos[8]
	fstp MazeTramPos[8]
	
	fld MazeTramRot[4]
	fmul R2D
	fstp rotVal
	invoke glPushMatrix
		invoke glTranslatef, MazeTramPos, 0, MazeTramPos[8]
		invoke glRotatef, rotVal, 0, fl1, 0
		
		;invoke glColor4f, fl1, fl1, fl1, flTenth
		;invoke glDisable, GL_BLEND
		invoke glBindTexture, GL_TEXTURE_2D, TexTram
		invoke glCallList, 98
		invoke glCallList, MazeTramDoors
		
		.IF (WmblykTram)
			invoke glDisable, GL_LIGHTING
			invoke glDisable, GL_FOG
			invoke glBindTexture, GL_TEXTURE_2D, TexWmblykNeutral
			invoke glCallList, 105
			invoke glEnable, GL_LIGHTING
			invoke glEnable, GL_FOG
		.ENDIF
	invoke glPopMatrix
	ret
DrawTram ENDP

; Draw Vebra exiting the layer
DrawVebra PROC
	LOCAL PosX:REAL4, PosY:REAL4, Dist:REAL4

	fld VebraTimer
	fsub deltaTime
	fstp VebraTimer
	
	fcmp VebraTimer
	.IF (Sign?)
		.IF (Vebra < 135)
			m2m VebraTimer, fl1
			inc Vebra
			.IF (Vebra == 135)
				mov Vebra, 133
			.ENDIF
		.ELSE
			m2m VebraTimer, flTenth
			inc Vebra
			.IF (Vebra == 139)
				invoke alSource3f, SndDoorClose, AL_POSITION, PosX, 0, PosY
				invoke alSourcePlay, SndDoorClose
			.ELSEIF (Vebra == 140)
				m2m VebraTimer, flThird
			.ELSEIF (Vebra == 141)
				mov Vebra, 0
				mov MazeDoor, 0
				ret
			.ENDIF
		.ENDIF
	.ENDIF
	
	fld MazeDoorPos
	fchs
	fstp PosX
	fld MazeDoorPos[4]
	fchs
	fstp PosY
	
	.IF (Vebra < 135) && (playerState != 1) && (playerState != 5)
		invoke DistanceToSqr, camPos, camPos[8], MazeDoorPos, MazeDoorPos[4]
		mov Dist, eax
		fcmp Dist, fl32
		.IF (Sign?)
			invoke CheckBlocked, camPosN, camPosN[4], PosX, PosY
			.IF (!eax)
				mov Vebra, 135
				m2m VebraTimer, flTenth
				print "I'm outta here", 13, 10
				invoke alSource3f, SndCheckpoint, AL_POSITION, PosX, 0, PosY
				invoke alSourcePlay, SndCheckpoint
			.ENDIF
			fcmp Dist, fl13
			.IF (Sign?)
				mov Vebra, 135
				m2m VebraTimer, flTenth
				print "I'm outta here", 13, 10
				invoke alSource3f, SndCheckpoint, AL_POSITION, PosX, 0, PosY
				invoke alSourcePlay, SndCheckpoint
			.ENDIF
		.ENDIF
	.ELSEIF (Vebra >= 135) && (Vebra <= 138)
		fld delta2
		fmul fl2
		fstp Dist
		invoke Lerp, ADDR MazeDoor, 3267887104, Dist
	.ELSE
		fld delta2
		fmul fl2
		fstp Dist
		invoke Lerp, ADDR MazeDoor, 0, Dist
	.ENDIF
	
	invoke glPushMatrix
		invoke glTranslatef, PosX, 0, PosY
		invoke glBindTexture, GL_TEXTURE_2D, TexVebra
		;.IF (Vebra == 138)
		;	invoke glColor3f, fl075, fl075, fl075
		;.ELSEIF (Vebra == 139)
		;	invoke glColor3f, flHalf, flHalf, flHalf
		;.ELSEIF (Vebra == 140)
		;	invoke glColor3f, flThird, flThird, flThird
		;.ENDIF
		invoke glCallList, Vebra
		invoke glColor3fv, ADDR clWhite
	invoke glPopMatrix
	ret
DrawVebra ENDP

; Draw ending wasteland
DrawWasteland PROC
	LOCAL deltaHalf:REAL4, TerrX:REAL4, TerrY:REAL4, TerrI:SDWORD
	LOCAL TerrX1:REAL4, TerrY1:REAL4
	
	fld deltaTime
	fmul flHalf
	fstp deltaHalf
	.IF (MazeHostile == 8)	; Fade in
		invoke Lerp, ADDR MotryaTimer, flTenthN, deltaHalf
		invoke Lerp, ADDR fogDensity, fl06, deltaTime
		invoke Lerp, ADDR AscendColor, clTrench, deltaTime
		invoke Lerp, ADDR AscendColor[4], clTrench[4], deltaTime
		invoke Lerp, ADDR AscendColor[8], clTrench[8], deltaTime
		invoke glClearColor, AscendColor, AscendColor[4], AscendColor[8], fl1
		invoke glFogfv, GL_FOG_COLOR, ADDR AscendColor
		
		fcmp MotryaTimer
		.IF (Sign?)
			mov MotryaTimer, 0
			mov MazeHostile, 9
		.ENDIF
	.ELSEIF (MazeHostile == 9)	; Faded in, play music
		invoke Lerp, ADDR fogDensity, fl03, deltaHalf
		fcmp fogDensity, flHalf
		.IF (Sign?)
			mov MazeHostile, 10
			invoke alSourcePlay, SndMus1
		.ENDIF
	.ELSEIF (MazeHostile == 10)	; Fade out
		fcmp NoiseOpacity
		.IF (Sign?)
			mov canControl, 0
			mov playerState, 17
			mov MazeHostile, 11
			
			invoke RegCreateKeyExA, HKEY_CURRENT_USER, ADDR RegPath, 0, NULL, \
			REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, ADDR defKey, NULL
			mov Complete, 1
			invoke RegSetValueExA, defKey, ADDR RegComplete, 0, REG_BINARY, \
			ADDR Complete, 1
			invoke RegCloseKey, defKey
		.ENDIF
	.ENDIF
	
	fld deltaTime
	fmul flHundredth
	fmul fl1n5
	fadd vignetteRed
	fst vignetteRed
	fst fade
	fmul flHalf
	fadd flHalf
	fsubr fl1
	fstp NoiseOpacity
	
	fld NoiseOpacity
	fmul fl6
	fadd fl5
	fst MotryaDist
	fmul st, st
	fsub fl10
	fst TerrX1	; Min distance
	fadd fl13
	fstp TerrY1	; Max distance
	
	push MotryaDist
	fld MotryaDist
	fmul st, st
	fstp MotryaDist
	print real4$(MotryaDist), 32
	pop MotryaDist
	print real4$(TerrX1), 32
	print real4$(TerrY1), 13, 10
	
	
	invoke DistanceToSqr, MotryaPos, MotryaPos[4], camPosN, camPosN[4]
	mov deltaHalf, eax
	xor bl, bl
	fcmp deltaHalf, TerrX1
	.IF (Sign?)
		inc bl
	.ENDIF
	fcmp deltaHalf, TerrY1
	.IF (!Sign?)
		inc bl
	.ENDIF
	.IF (bl)
		fld camForward
		fmul MotryaDist
		fsubr camPosN
		fstp MotryaPos
		
		fld camForward[8]
		fmul MotryaDist
		fsubr camPosN[4]
		fstp MotryaPos[4]
	.ENDIF
	
	xor FPUMode, FPU_ZERO
	fldcw FPUMode
	
	fld camPosN
	fdiv fl20
	fistp TerrI
	fild TerrI
	fmul fl20
	fstp TerrX
	fld camPosN[4]
	fdiv fl20
	fistp TerrI
	fild TerrI
	fmul fl20
	fstp TerrY
	
	or FPUMode, FPU_ZERO
	fldcw FPUMode
	
	invoke glBindTexture, GL_TEXTURE_2D, TexConcreteRoof
	invoke glPushMatrix
		invoke glTranslatef, TerrX, 0, TerrY
		invoke glCallList, 97
		invoke glTranslatef, fl20N, 0, 0
		invoke glCallList, 97
		invoke glTranslatef, 0, 0, fl20N
		invoke glCallList, 97
		invoke glTranslatef, fl20, 0, 0
		invoke glCallList, 97
		invoke glTranslatef, fl20, 0, 0
		invoke glCallList, 97
		invoke glTranslatef, 0, 0, fl20
		invoke glCallList, 97
		invoke glTranslatef, 0, 0, fl20
		invoke glCallList, 97
		invoke glTranslatef, fl20N, 0, 0
		invoke glCallList, 97
		invoke glTranslatef, fl20N, 0, 0
		invoke glCallList, 97
	invoke glPopMatrix
	
	invoke glBindTexture, GL_TEXTURE_2D, TexMotrya
	invoke glColor3fv, ADDR clDarkGray
	invoke glPushMatrix
		invoke glTranslatef, MotryaPos, 0, MotryaPos[4]
		;invoke MagnitudeSqr, RubblePos, RubblePos[4]
		;invoke glRotatef, eax, 0, fl1, 0
		;invoke glBindTexture, GL_TEXTURE_2D, TexFloor
		;invoke glCallList, 98
		;invoke glBindTexture, GL_TEXTURE_2D, TexFacade
		;invoke glCallList, 99
		invoke GetDirection, MotryaPos, MotryaPos[4], camPosN, camPosN[4]
		mov deltaHalf, eax
		fld deltaHalf
		fmul R2D
		fstp deltaHalf
		invoke glRotatef, deltaHalf, 0, fl1, 0
		invoke glCallList, 88
	invoke glPopMatrix
	invoke glColor3fv, ADDR clWhite
	ret
DrawWasteland ENDP

; Create and prepare WB (stack, sound, etc)
WBCreate PROC
	.IF (WBStack)	; Free stack if it's there
		print "Freeing stack "
		print str$(WBStack), 13, 10
		invoke HSFree, WBStack, WBStackHandle
		mov WBStack, 0
		print "Stack freed successfully.", 13, 10
	.ENDIF
	
	print "Creating new stack.", 13, 10
	mov eax, MazeSize
	mov ecx, 2	; (X, Y)
	mul ecx
	mov WBStackSize, eax
	invoke HSCreate, eax	; Create new stack
	mov WBStack, eax
	mov WBStackHandle, ecx
	
	mov eax, WBStackSize
	inc eax
	mov ecx, 4
	mul ecx
	print "Stack size (in bytes): "
	print str$(WBStackSize), 13, 10
	
	.IF (!WBStack)
		print "STACK DIDN'T CREATE", 13, 10
		ret
	.ENDIF
	
	mov WB, 1
	invoke GetRandomMazePosition, ADDR WBPos, ADDR WBPos[4]
	invoke alSourcef, SndWmblykB, AL_GAIN, fl2
	invoke alSourcef, SndWmblykB, AL_PITCH, flHalf
	invoke alSourcePlay, SndWmblykB
	ret
WBCreate ENDP
; Solve path from (FromX, FromY) to (ToX, ToY), in maze cells
WBSolve PROC FromX:DWORD, FromY:DWORD, ToX:DWORD, ToY:DWORD
	LOCAL DeltaX:SDWORD, DeltaY:SDWORD, PosX:DWORD, PosY:DWORD, Vis:BYTE
	LOCAL TempC:BYTE
	
	mov eax, ToX
	mov ecx, ToY
	.IF (FromX == eax) && (FromY == ecx)
		mov WB, 3
		ret
	.ENDIF
	
	print "Entered WBSolve", 13, 10
	
	invoke HSClear, WBStack
	
	xor ebx, ebx	; Clear visited
	.WHILE (ebx < MazeSize)
		mov eax, MazeBuffer
		mov al, BYTE PTR [eax+ebx]
		and al, MZC_VISITED
		.IF (al)
			mov eax, MazeBuffer
			xor BYTE PTR [eax+ebx], MZC_VISITED
		.ENDIF
		inc ebx
	.ENDW
	
	m2m PosX, ToX
	m2m PosY, ToY
	
	print "Started solving.", 13, 10
	invoke GetOffset, PosX, PosY	; Set start to visited
	add eax, MazeBuffer
	or BYTE PTR [eax], MZC_VISITED
	.WHILE TRUE
		; Behold, the ULTIMATE SPAGHETTI
		mov Vis, 0
		.IF (PosY > 0)							; y > 0
			mov eax, PosY
			dec eax
			invoke GetOffset, PosX, eax
			add eax, MazeBuffer
			mov al, BYTE PTR [eax]
			and al, MZC_VISITED
			.IF (!al)							; ![x, y-1].Visited
				invoke GetOffset, PosX, PosY
				add eax, MazeBuffer
				mov al, BYTE PTR [eax]
				and al, MZC_PASSTOP
				.IF (al)						; [x, y].PassTop
					mov DeltaX, 0				; (0, -1)
					mov DeltaY, -1
					mov Vis, 1
					;print "(0, -1)", 13, 10
				.ENDIF
			.ENDIF
		.ENDIF
		.IF (!Vis)
			mov eax, MazeWM1
			.IF (PosX < eax)					; x < w-1
				mov eax, PosX
				inc eax
				invoke GetOffset, eax, PosY
				add eax, MazeBuffer
				mov al, BYTE PTR [eax]
				mov TempC, al
				and al, MZC_VISITED
				.IF (!al)						; ![x+1, y].Visited
					mov al, TempC
					and al, MZC_PASSLEFT
					.IF (al)					; [x+1, y].PassLeft
						mov DeltaX, 1			; (1, 0)
						mov DeltaY, 0
						mov Vis, 1
						;print "(1, 0)", 13, 10
					.ENDIF
				.ENDIF
			.ENDIF
			
			.IF (!Vis)
				mov eax, MazeHM1
				.IF (PosY < eax)				; y < h-1
					mov eax, PosY
					inc eax
					invoke GetOffset, PosX, eax
					add eax, MazeBuffer
					mov al, BYTE PTR [eax]
					mov TempC, al
					and al, MZC_VISITED
					.IF (!al)					; ![x, y+1].Visited
						mov al, TempC
						and al, MZC_PASSTOP
						.IF (al)				; [x, y+1].PassTop
							mov DeltaX, 0		; (0, 1)
							mov DeltaY, 1
							mov Vis, 1
							;print "(0, 1)", 13, 10
						.ENDIF
					.ENDIF
				.ENDIF
				
				.IF (!Vis)
					.IF (PosX > 0)				; x > 0
						mov eax, PosX
						dec eax
						invoke GetOffset, eax, PosY
						add eax, MazeBuffer
						mov al, BYTE PTR [eax]
						and al, MZC_VISITED
						.IF (!al)				; ![x-1, y].Visited
							invoke GetOffset, PosX, PosY
							add eax, MazeBuffer
							mov al, BYTE PTR [eax]
							and al, MZC_PASSLEFT
							.IF (al)			; [x, y].PassLeft
								mov DeltaX, -1	; (-1, 0)
								mov DeltaY, 0
								mov Vis, 1
								;print "(-1, 0)", 13, 10
							.ENDIF
						.ENDIF
					.ENDIF
					
					.IF (!Vis)
						mov eax, WBStack
						mov eax, DWORD PTR [eax]
						.IF (eax <= 8)
							print "No way found.", 13, 10
							ret
						.ENDIF
						
						mov eax, WBStack
						mov eax, DWORD PTR [eax]
						invoke HSPop, WBStack, ADDR PosY	; Step back
						invoke HSPop, WBStack, ADDR PosX
						.CONTINUE
					.ENDIF
				.ENDIF
			.ENDIF
		.ENDIF
		
		mov eax, WBStack
		mov eax, DWORD PTR [eax]
		.IF (eax < WBStackSize)
			invoke HSPush, WBStack, PosX	; Save pos to stack
			invoke HSPush, WBStack, PosY
		.ELSE
			print "PUSH LIMIT REACHED", 13, 10	; Somehow does happen
		.ENDIF
		
		mov eax, DeltaX
		add PosX, eax
		mov eax, DeltaY
		add PosY, eax
		
		invoke GetOffset, PosX, PosY	; Set start to visited
		add eax, MazeBuffer
		or BYTE PTR [eax], MZC_VISITED
		
		mov eax, FromX
		mov ecx, FromY
		.IF (PosX == eax) && (PosY == ecx)	; Found
			print "Found way.", 13, 10
			.BREAK
		.ENDIF
	.ENDW
	
	xor ebx, ebx	; Clear visited
	.WHILE (ebx < MazeSize)
		mov eax, MazeBuffer
		mov al, BYTE PTR [eax+ebx]
		and al, MZC_VISITED
		.IF (al)
			mov eax, MazeBuffer
			xor BYTE PTR [eax+ebx], MZC_VISITED
		.ENDIF
		inc ebx
	.ENDW
	ret
WBSolve ENDP
; Call WBSolve to solve from WBPos to (ToX, ToY) in world coords
WBSetSolve PROC ToX:REAL4, ToY:REAL4
	LOCAL ToXM:DWORD, ToYM:DWORD
	
	print "Entered WBSetSolve", 13, 10

	invoke GetMazeCellPos, ToX, ToY, ADDR ToXM, ADDR ToYM
	
	m2m WBFinal, ToX
	m2m WBFinal[4], ToY
	
	invoke WBSolve, WBPosI, WBPosI[4], ToXM, ToYM
	m2m WBNext, WBPosI
	m2m WBNext[4], WBPosI[4]
	
	mov WB, 2
	ret
WBSetSolve ENDP
; Sound alert WB (0 - 4)
AlertWB PROC Loudness:BYTE
	LOCAL distancePlayer:REAL4, rndVal:REAL4, XR:REAL4, YR:REAL4
	
	.IF (WB == 0)
		ret
	.ENDIF
	
	invoke DistanceToSqr, WBPos, WBPos[4], camPosN, camPosN[4]
	mov distancePlayer, eax
	
	.IF (Loudness)
		fcmp distancePlayer, fl1
		.IF (Sign?)
			mov WB, 4
			ret
		.ENDIF
		fcmp distancePlayer, fl3
		.IF (Sign?)
			invoke WBSetSolve, camPosN, camPosN[4]
			ret
		.ENDIF
	.ENDIF
	
	.IF (Loudness == 0)
		invoke RandomFloat, ADDR rndVal, 2
		fld rndVal
		fadd fl2
		fstp rndVal
		fcmp distancePlayer, rndVal
		.IF (Sign?)
			invoke RandomFloat, ADDR rndVal, 1
			fld distancePlayer
			fmul flTenth
			fmul rndVal
			fadd camPosN
			fstp XR
			invoke RandomFloat, ADDR rndVal, 1
			fld distancePlayer
			fmul flTenth
			fmul rndVal
			fadd camPosN[4]
			fstp YR
			invoke WBSetSolve, XR, YR
		.ENDIF
	.ELSEIF (Loudness == 1)
		invoke RandomFloat, ADDR rndVal, 10
		fld rndVal
		fadd fl20
		fstp rndVal
		fcmp distancePlayer, rndVal
		.IF (Sign?)
			invoke RandomFloat, ADDR rndVal, 1
			fld distancePlayer
			fmul flTenth
			fmul rndVal
			fadd camPosN
			fstp XR
			invoke RandomFloat, ADDR rndVal, 1
			fld distancePlayer
			fmul flTenth
			fmul rndVal
			fadd camPosN[4]
			fstp YR
			invoke WBSetSolve, XR, YR
			
			invoke nrandom, 5
			.IF (!eax)
				invoke alSourcePlay, SndWBAlarm
			.ENDIF
		.ENDIF
		.IF (WB == 2) || (WB == 3)
			fld WBSpMul
			fadd fl1
			fstp WBSpMul
		.ENDIF
	.ELSEIF (Loudness == 2)	; Loud
		invoke alSourcePlay, SndWBAlarm
		invoke WBSetSolve, camPosN, camPosN[4]
	.ELSEIF (Loudness == 3)	; Near
		mov WB, 4
	.ENDIF
	
	print "Alert level "
	print sbyte$(Loudness), 13, 10
	ret
AlertWB ENDP
; Check if player is in front of WB, if Rand - randomize result chance
WBFront PROC Rand:BYTE
	LOCAL dirVal:REAL4, fltVal:REAL4

	invoke GetDirection, WBPos, WBPos[4], camPosN, camPosN[4]
	mov dirVal, eax
	invoke DistanceScalar, dirVal, WBRot
	mov dirVal, eax
	invoke Angleify, ADDR dirVal
	fld dirVal
	fabs
	fstp dirVal
	
	.IF (Rand)
		invoke RandomFloat, ADDR fltVal, 2
		fld fltVal
		fadd PIHalf
		fstp fltVal
		
		print real4$(fltVal), 32
		print real4$(dirVal), 13, 10
	
		fcmp dirVal, fltVal
	.ELSE
		fcmp dirVal, fl09
	.ENDIF
	.IF (Sign?)
		mov eax, 1
	.ELSE
		xor eax, eax
	.ENDIF
	ret
WBFront ENDP
; WB close movement, far movement with solving is in DrawWB, WB == 2
WBMove PROC Speed:REAL4
	LOCAL deltaSpd:REAL4, fltVal:REAL4
	
	invoke Lerp, ADDR WBSpMul, Speed, delta2
	fld WBSpMul
	fmul deltaTime
	fstp deltaSpd
		
	invoke DistanceToSqr, WBPos, WBPos[4], WBTarget, WBTarget[4]
	mov fltVal, eax
	fcmp fltVal, flTenth
	.IF (!Sign?)
		fcmp WBCurSpd, flTenth
		.IF (!Sign?)
			.IF (WBAnim != 1)
				mov WBAnim, 1
				mov WBAnimTimer, 0
			.ENDIF
		.ELSE
			mov WBAnim, 0
		.ENDIF

		invoke GetDirection, WBPos, WBPos[4], WBTarget, WBTarget[4]
		mov WBRot[4], eax
		invoke MoveTowardsAngle, ADDR WBRot, WBRot[4], deltaSpd
		
		fld WBRot[4]
		fsin
		fmul deltaSpd
		fstp WBSpeed
		fld WBRot[4]
		fcos
		fmul deltaSpd
		fstp WBSpeed[4]
		invoke MoveAndCollide, ADDR WBPos, ADDR WBPos[4], \
		ADDR WBSpeed, ADDR WBSpeed[4], flHalf, 1
		
		;invoke MoveTowards, ADDR WBPos, WBTarget, deltaSpd
		;invoke MoveTowards, ADDR WBPos[4], WBTarget[4], deltaSpd
	.ELSE
		mov WBSpMul, 0
	.ENDIF
	ret
WBMove ENDP
; Draw and process WB
DrawWB PROC
	LOCAL PlrX:DWORD, PlrY:DWORD, degRot:REAL4
	LOCAL distanceFinal:REAL4, distancePlayer:REAL4, fltVal:REAL4
	
	or FPUMode, FPU_ZERO
	fldcw FPUMode
	fld WBPos	; Maze cell position
	fmul flHalf
	fistp WBPosI
	fld WBPos[4]
	fmul flHalf
	fistp WBPosI[4]
	xor FPUMode, FPU_ZERO
	fldcw FPUMode
	
	invoke DistanceToSqr, WBPos, WBPos[4], camPosNext, camPosNext[8]
	mov distancePlayer, eax
	
	fcmp distancePlayer, flThird	; Collide with player
	.IF (Sign?) && (!Menu)
		fld camCurSpeed
		fchs
		fstp camCurSpeed
		fld camCurSpeed[8]
		fchs
		fstp camCurSpeed[8]
		
		.IF (WB != 2)
			m2m WBTarget, WBPos
			m2m WBTarget[4], WBPos[4]
		.ENDIF

		fld WBSpeed
		fchs
		fstp WBSpeed
		fld WBSpeed[4]
		fchs
		fstp WBSpeed[4]
		
		; Check if collision is in front
		mov fltVal, 0
		fld camCurSpeed
		fabs
		fstp degRot
		fcmp degRot, deltaTime
		.IF (!Sign?)
			inc fltVal
		.ENDIF
		fld camCurSpeed[8]
		fabs
		fstp degRot
		fcmp degRot, deltaTime
		.IF (!Sign?)
			inc fltVal
		.ENDIF
		.IF (fltVal)
			invoke WBFront, 1
			.IF (eax)
				invoke AlertWB, 3
			.ENDIF
		.ENDIF
	.ENDIF
	
	fld WBTimer
	fsub deltaTime
	fstp WBTimer
	fcmp WBTimer
	.IF (Sign?)
		.IF (WB == 1)		; Wander
			invoke nrandom, 3
			.IF (!eax)
				invoke GetRandomMazePosition, ADDR PlrX, ADDR PlrY
				
				invoke WBSetSolve, PlrX, PlrY
				print "Random maze position", 13, 10
			.ELSE
				invoke RandomFloat, ADDR fltVal, 2
				fld fltVal
				fadd fl3
				fstp WBTimer
				mov WB, 1
				
				invoke RandomFloat, ADDR fltVal, 1	; Get random position near
				fld fltVal
				fmul fl2
				fadd WBPos
				fstp WBTarget
				invoke RandomFloat, ADDR fltVal, 1
				fld fltVal
				fmul fl2
				fadd WBPos[4]
				fstp WBTarget[4]
			.ENDIF
		.ELSEIF (WB == 3)	; Close searching
			invoke RandomFloat, ADDR fltVal, 2
			fld fltVal
			fadd fl4
			fstp WBTimer
			mov WB, 1
		.ENDIF
	.ENDIF
	
	.IF (WB == 1)		; Wander
		invoke WBMove, fl2
	.ELSEIF (WB == 2)	; Rushing
		mov WBAnim, 1
		
		invoke DistanceToSqr, WBPos, WBPos[4], WBFinal, WBFinal[4]
		mov distanceFinal, eax
		fld distanceFinal
		fmul flFifth
		fadd fl2
		fstp degRot
		
		invoke Clamp, degRot, 0, fl8
		mov degRot, eax
		invoke Lerp, ADDR WBSpMul, degRot, delta2
		
		fld WBSpMul
		fmul deltaTime
		fstp degRot
		
		invoke GetDirection, WBPos, WBPos[4], WBTarget, WBTarget[4]
		mov WBRot[4], eax
		invoke MoveTowardsAngle, ADDR WBRot, WBRot[4], degRot
		invoke MoveTowards, ADDR WBPos, WBTarget, degRot
		invoke MoveTowards, ADDR WBPos[4], WBTarget[4], degRot
		
		mov degRot, 0
		
		.IF (WBStack)
			mov eax, WBNext
			mov ecx, WBNext[4]
			.IF (WBPosI == eax) && (WBPosI[4] == ecx)
				print "STACK IS "
				print str$(WBStack), 13, 10
				
				mov eax, WBStack
				mov eax, DWORD PTR [eax]
				
				push eax
				print str$(eax), 32
				print "STACK OFFSET", 13, 10
				pop eax
				.IF (eax > 4)	; If stack is not empty
					print "Popping stack", 13, 10
					invoke HSPop, WBStack, ADDR WBNext[4]
					invoke HSPop, WBStack, ADDR WBNext
					fild WBNext
					fmul fl2
					fadd fl1
					fstp WBTarget
					fild WBNext[4]
					fmul fl2
					fadd fl1
					fstp WBTarget[4]
					print "Proceeding to ["
					print str$(WBNext)
					print ", "
					mov eax, WBNext[4]
					print str$(eax)
					print "].", 13, 10
				.ELSE
					inc degRot
				.ENDIF
			.ENDIF
		.ENDIF
		
		fcmp distancePlayer, fl2
		.IF (Sign?)
			inc degRot
		.ENDIF
		
		.IF (degRot)
			print "Found you.", 13, 10
			mov WBAnim, 0
			mov WB, 3
			invoke RandomFloat, ADDR fltVal, 2
			fld fltVal
			fadd fl3
			fstp fltVal
			m2m WBTimer, fltVal
			fcmp WBTimer, fl1n2
			.IF (Sign?)
				mov WB, 4
			.ENDIF
		.ENDIF
	.ELSEIF (WB == 3)	; Close searching
		invoke RandomFloat, ADDR fltVal, 1
		fcmp fltVal, fl075
		.IF (!Sign?)
			invoke RandomFloat, ADDR fltVal, 1	; Get random position near
			fld fltVal
			fmul flHalf
			fadd WBPos
			fstp WBTarget
			invoke RandomFloat, ADDR fltVal, 1
			fld fltVal
			fmul flHalf
			fadd WBPos[4]
			fstp WBTarget[4]
		.ENDIF
		invoke WBMove, fl4
	.ELSEIF (WB == 4)	; Attacking	player
		invoke WBFront, 0
		.IF (eax)
			.IF (WBAnim != 2)
				invoke alSource3f, SndWBAttack, AL_POSITION, WBPosL,0,WBPosL[4]
				invoke alSourcePlay, SndWBAttack
				mov WBAnim, 2
				mov WBFrame, 119
				m2m WBAnimTimer, flFifth
			.ENDIF
		.ELSE
			invoke GetDirection, WBPos, WBPos[4], camPosN, camPosN[4]
			mov WBRot[4], eax
			invoke MoveTowardsAngle, ADDR WBRot, WBRot[4], delta10
		.ENDIF
	.ENDIF
	
	invoke alSource3f, SndWBAlarm, AL_POSITION, WBPosL, 0, WBPosL[4]
	invoke alSource3f, SndWBIdle, AL_POSITION, WBPosL, 0, WBPosL[4]
	invoke alSource3f, SndWBIdle[4], AL_POSITION, WBPosL, 0, WBPosL[4]
	
	invoke alSource3f, SndWmblykB, AL_POSITION, WBPosL, 0, WBPosL[4]
	
	fld deltaTime		; Animate
	.IF (WBAnim == 1)	
		fmul WBCurSpd
		fmul flHalf
	.ENDIF
	fsubr WBAnimTimer
	fstp WBAnimTimer
	
	fcmp WBAnimTimer
	.IF (Sign?)
		invoke nrandom, 12
		SWITCH eax
			CASE 0
				invoke alGetSourcei, SndWBIdle[4], AL_SOURCE_STATE, ADDR degRot
				.IF (degRot != AL_PLAYING)
					invoke alSourcePlay, SndWBIdle
				.ENDIF
			CASE 1
				invoke alGetSourcei, SndWBIdle, AL_SOURCE_STATE, ADDR degRot
				.IF (degRot != AL_PLAYING)
					invoke alSourcePlay, SndWBIdle[4]
				.ENDIF
		ENDSW
	
		inc WBFrame
		.IF (WBAnim == 0)	; Idle
			.IF (WBFrame >= 119)
				mov WBFrame, 117
				invoke RandomFloat, ADDR WBAnimTimer, 1
				fld WBAnimTimer
				fadd fl1
				fstp WBAnimTimer
			.ELSE
				m2m WBAnimTimer, flTenth
			.ENDIF
		.ELSEIF (WBAnim == 1)	; Walk
			.IF (WBFrame >= 117)
				mov WBFrame, 114
				mov al, WBMirror
				not al
				mov WBMirror, al
				
				invoke nrandom, 4
				xor edx, edx
				mov ebx, 4
				mul ebx
				mov ebx, eax
				
				invoke alSource3f, SndWBStep[ebx], AL_POSITION,\
				WBPosL, 0, WBPosL[4]
				invoke alSourcePlay, SndWBStep[ebx]
			.ENDIF
			m2m WBAnimTimer, flFifth
		.ELSEIF (WBAnim == 2)	; Attack
			.IF (WBFrame >= 122)
				mov WBAnim, 0
				mov WBFrame, 117
				mov WB, 3
				m2m WBTimer, fl3
			.ELSEIF (WBFrame == 121) && (playerState == 0)
				fcmp distancePlayer, fl075
				.IF (Sign?)
					invoke WBFront, 0
					.IF (eax)
						invoke alSource3f, SndHurt, AL_POSITION, \
						WBPosL, 0, WBPosL[4]
						invoke alSourcePlay, SndHurt
						mov playerState, 9
						mov fadeState, 2
						mov canControl, 0
						mov camCurSpeed, 0
						mov camCurSpeed[8], 0
					.ENDIF
				.ENDIF
			.ENDIF
			m2m WBAnimTimer, flTenth
		.ENDIF
	.ENDIF
	
	invoke Lerp, ADDR WBPosL, WBPos, delta10
	invoke Lerp, ADDR WBPosL[4], WBPos[4], delta10
	
	invoke DistanceToSqr, WBPosL, WBPosL[4], WBPosP, WBPosP[4]	; Get speed
	mov WBCurSpd, eax
	fld WBCurSpd
	fmul fl1000
	fstp WBCurSpd
	
	m2m WBPosP, WBPosL
	m2m WBPosP[4], WBPosL[4]
	
	invoke glPushMatrix	; Draw
		invoke glTranslatef, WBPosL, 0, WBPosL[4]
		fld WBRot
		fmul R2D
		fstp degRot
		invoke glRotatef, degRot, 0, fl1, 0
		invoke glScalef, fl09, fl09, fl09
		.IF (WBMirror)
			invoke glScalef, fl1N, fl1, fl1
			invoke glCullFace, GL_FRONT
		.ENDIF
		invoke glBindTexture, GL_TEXTURE_2D, TexWB
		invoke glCallList, WBFrame
		.IF (WBMirror)
			invoke glCullFace, GL_BACK
		.ENDIF
	invoke glPopMatrix
	ret
DrawWB ENDP

; Check if WBBK is either too far (Th1) or not being looked at at distance Th2
CheckWBBKVisible PROC Dist:REAL4, Th1:REAL4, Th2:REAL4
	LOCAL dotX:REAL4, dotY:REAL4
	
	fcmp Dist, Th1
	.IF (!Sign?)
		xor eax, eax
		ret
	.ENDIF
	
	fcmp Dist, Th2
	.IF (!Sign?)
		fld camPosN
		fsub WBBKPos
		fstp dotX
		fld camPosN[4]
		fsub WBBKPos[4]
		fstp dotY
		
		invoke Normalize, ADDR dotX, ADDR dotY
		fld dotX
		fmul camForward
		fstp dotX
		fld dotY
		fmul camForward[8]
		fadd dotX
		fstp dotX
			
		fcmp dotX, flThird
		.IF (Sign?)
			xor eax, eax
			ret
		.ENDIF
	.ENDIF
	
	mov eax, 1
	ret
CheckWBBKVisible ENDP
; Draw Webubychko
DrawWBBK PROC
	LOCAL rotDir:REAL4, dist:REAL4, invis:BYTE
	
	invoke GetDirection, WBBKPos, WBBKPos[4], camPosN, camPosN[4]	; Direction
	mov rotDir, eax
	invoke DistanceToSqr, WBBKPos, WBBKPos[4], camPosNext, camPosNext[8]
	mov dist, eax
	
	fld deltaTime
	fmul flQuarter
	fsubr WBBKTimer
	fstp WBBKTimer
	fcmp WBBKTimer
	.IF Sign?
		m2m WBBKTimer, PI
		
		invoke nrandom, 1
		.IF !(eax)
			invoke RandomFloat, ADDR WBBKSndPos[8], 6
			fld camPosN
			fadd WBBKSndPos[8]
			fstp WBBKSndPos[8]
			invoke RandomFloat, ADDR WBBKSndPos[12], 6
			fld camPosN[4]
			fadd WBBKSndPos[12]
			fstp WBBKSndPos[12]
			
			;.WHILE (eax == WBBKSndID)
				invoke nrandom, 4
				mov ecx, 4
				mul ecx
			;.ENDW
			mov WBBKSndID, eax
			invoke alSourcePlay, SndAmbW[eax]
			print "Played sound "
			print str$(WBBKSndID), 13, 10
		.ENDIF
	.ENDIF
	
	.IF (WBBK < 3)	; Abstracted
		.IF (WBBK == 1)
			
			invoke Lerp, ADDR WBBKSndPos, WBBKSndPos[8], delta2
			invoke Lerp, ADDR WBBKSndPos[4], WBBKSndPos[12], delta2
			mov eax, WBBKSndID
			invoke alSource3f, SndAmbW[eax], AL_POSITION, WBBKSndPos, 0, WBBKSndPos[4]
			
			fld WBBKTimer	; Distance factor
			fsin
			fmul fl2
			fadd fl4
			fstp WBBKDist
			
			invoke Angleify, ADDR WBBKCamDir
			invoke LerpAngle, ADDR WBBKCamDir, camRot[4], deltaTime
			
			fld WBBKCamDir	; Position
			fsin
			fmul WBBKDist
			fsubr camPosN
			fstp WBBKPos
			
			fld WBBKCamDir
			fcos
			fmul WBBKDist
			fsubr camPosN[4]
			fstp WBBKPos[4]
			
			fld WBBKSTimer
			fsub deltaTime
			fstp WBBKSTimer
			fcmp WBBKSTimer
			.IF (Sign?)
				mov WBBK, 2
				print "WEBUBYCHKO", 13, 10
				invoke alSourcePlay, SndWBBK
				invoke alSource3f, SndWBBK, AL_POSITION, WBBKPos, 0, WBBKPos[4]
			.ENDIF
		.ELSEIF (WBBK == 2)	; Jumpscare
			fld rotDir
			fsin
			fmul delta10
			fsubr WBBKPos
			fstp WBBKPos
			fld rotDir
			fcos
			fmul delta10
			fsubr WBBKPos[4]
			fstp WBBKPos[4]
			
			invoke alSource3f, SndWBBK, AL_POSITION, WBBKPos, 0, WBBKPos[4]
			
			fcmp dist, flThird
			.IF (Sign?)
				mov WBBK, 1
				m2m WBBKSTimer, fl10
				invoke alSourceStop, SndWBBK
			.ENDIF
		.ENDIF
		
		fld rotDir
		fmul R2D
		fstp rotDir
		invoke glPushMatrix
			invoke glDisable, GL_LIGHTING
			invoke glEnable, GL_BLEND
			invoke glBlendFunc, GL_ONE, GL_ONE
			invoke glTranslatef, WBBKPos, fl075, WBBKPos[4]
			invoke glRotatef, rotDir, 0, fl1, 0
			.IF (WBBK == 1)
				invoke glBindTexture, GL_TEXTURE_2D, TexWBBK
			.ELSE
				invoke glBindTexture, GL_TEXTURE_2D, TexWBBK1
			.ENDIF
			invoke glCallList, 84
			invoke glEnable, GL_LIGHTING
		invoke glPopMatrix
	.ELSE	; Unabstracted
		invoke CheckWBBKVisible, dist, fl20, fl8
		.IF (!al)
			m2m WBRot, rotDir
			fcmp dist, fl5
			.IF (!Sign?)
				invoke GetRandomMazePosition, ADDR WBBKPos, ADDR WBBKPos[4]
				.WHILE TRUE
					invoke DistanceToSqr, WBBKPos, WBBKPos[4], \
					camPosNext, camPosNext[8]
					mov dist, eax
					invoke CheckWBBKVisible, dist, fl20, fl5
					.IF (al)
						invoke GetRandomMazePosition, \
						ADDR WBBKPos, ADDR WBBKPos[4]
						print "TELEPORTING", 13, 10
					.ELSE
						invoke nrandom, 1
						mov WBMirror, al
						.BREAK
					.ENDIF
				.ENDW
			.ENDIF
		.ENDIF
		
		fld WBBKPos
		fsub fl1
		fstp rotDir
		fld WBBKPos[4]
		fsub fl1
		fstp dist
		invoke CollidePlayerWall, rotDir, dist, 0
		invoke CollidePlayerWall, rotDir, dist, 1
		push rotDir
		fld rotDir
		fadd fl2
		fstp rotDir
		invoke CollidePlayerWall, rotDir, dist, 1
		pop rotDir
		fld dist
		fadd fl2
		fstp dist
		invoke CollidePlayerWall, rotDir, dist, 0
		
		xor FPUMode, FPU_ZERO
		fldcw FPUMode
		fld WBRot
		fmul R2I
		fistp rotDir
		fild rotDir
		fmul fl90
		fstp rotDir
		or FPUMode, FPU_ZERO
		fldcw FPUMode
		
		invoke glPushMatrix
			invoke glTranslatef, WBBKPos, 0, WBBKPos[4]
			invoke glRotatef, rotDir, 0, fl1, 0
			.IF (WBMirror)
				invoke glScalef, fl1N, fl1, fl1
			.ENDIF
			invoke glBindTexture, GL_TEXTURE_2D, TexWBBKP
			invoke glCallList, 122
		invoke glPopMatrix
	.ENDIF
	ret
DrawWBBK ENDP

; Shuffle Wmblyk's direction pool, placing the opposite direction at the end
WmblykShuffle PROC
	LOCAL opp:BYTE

	invoke nrandom, 4
	mov ebx, eax
	invoke nrandom, 4
	mov cl, wmblykDirS[ebx]
	mov dl, wmblykDirS[eax]
	mov wmblykDirS[ebx], dl
	mov wmblykDirS[eax], cl
	
	mov eax, wmblykDirI
	add eax, 8
	.IF (eax > 12)
		sub eax, 16
	.ENDIF
	mov opp, al
	xor ebx, ebx
	.WHILE (ebx < 4)
		xor ecx, ecx
		mov cl, wmblykDirS[ebx]
		.IF (cl == opp)
			mov cl, wmblykDirS[ebx]
			mov dl, wmblykDirS[3]
			mov wmblykDirS[ebx], dl
			mov wmblykDirS[3], cl
			.BREAK
		.ENDIF
		inc ebx
	.ENDW
	
	
	ret
WmblykShuffle ENDP

; Draw and process Wmblyk the strangler
DrawWmblykAngry PROC
	LOCAL MazeX:DWORD, MazeY:DWORD, MazeI:DWORD, WalkX:REAL4, WalkY:REAL4
	LOCAL ChoosePath: DWORD, ChooseByte:BYTE, face:DWORD
	LOCAL wXsp:REAL4
	LOCAL wYsp:REAL4
	LOCAL dirDeg:REAL4
	LOCAL distance:REAL4
	LOCAL kubaleClose:BYTE
	
	LOCAL posDiffX:REAL4, posDiffY:REAL4
	LOCAL audPosX:REAL4, audPosY:REAL4
	
	.IF (wmblyk != 13)
		invoke alSource3f, SndWmblykB, AL_POSITION, wmblykPos, 0, wmblykPos[4]
	.ENDIF
	
	fld wmblykBlink	; --wmblykBlink
	fsub deltaTime
	fstp wmblykBlink
	.IF (wmblyk == 11)
		m2m face, TexWmblykNeutral
		
		fcmp wmblykBlink
		.IF Sign?
			m2m wmblykBlink, flWmblykAnim
			inc wmblykAnim
		.ENDIF
		
		; Animate walking
		.IF (wmblykAnim < 107)
			.IF (wmblykAnim >= 15)
				mov wmblykAnim, 11
			.ENDIF
		.ELSE
			.IF (wmblykAnim >= 109)
				mov wmblykAnim, 107
			.ENDIF
		.ENDIF
		
		.IF (MazeCrevice)
			fild MazeCrevicePos
			fmul fl2
			fadd fl1
			fstp MazeX
			fild MazeCrevicePos[4]
			fmul fl2
			fadd fl1
			fstp MazeY
			invoke DistanceToSqr, wmblykPos, wmblykPos[4], \
			MazeX, MazeY
			mov MazeX, eax
			fcmp MazeX, fl1n2
			.IF (Sign?)
				.IF (wmblykAnim < 107)
					mov wmblykAnim, 107
				.ENDIF
			.ELSE
				.IF (wmblykAnim > 107)
					mov wmblykAnim, 11
				.ENDIF
			.ENDIF
		.ENDIF
	
		; Walk algorithm
		fld wmblykPos
		fmul flHalf
		fistp MazeX
		fld wmblykPos[4]
		fmul flHalf
		fistp MazeY
		
		xor FPUMode, FPU_ZERO
		fldcw FPUMode
		
		fld wmblykPos
		fmul flHalf
		fisub MazeX
		fstp WalkX
		fld wmblykPos[4]
		fmul flHalf
		fisub MazeY
		fstp WalkY
		
		or FPUMode, FPU_ZERO
		fldcw FPUMode
		
		mov ChoosePath, 0
		invoke DistanceScalar, WalkX, flHalf
		mov WalkX, eax
		fcmp WalkX, flTenth
		.IF Sign?
			inc ChoosePath
		.ENDIF
		invoke DistanceScalar, WalkY, flHalf
		mov WalkY, eax
		fcmp WalkY, flTenth
		.IF Sign?
			inc ChoosePath
		.ENDIF
		
		mov kubaleClose, 0
		.IF (kubale > 28)
			invoke DistanceToSqr, wmblykPos, wmblykPos[4], kubalePos, kubalePos[4]
			mov WalkY, eax
			fcmp WalkY, flHalf
			.IF Sign? || Zero?
				print "Close to Kubale", 13, 10
				mov ChoosePath, 2
				mov wmblykTurn, 0
				mov kubaleClose, 1
			.ENDIF
		.ENDIF
		
		.IF (ChoosePath != 2) && (wmblykTurn == 1)
			mov wmblykTurn, 0
		.ENDIF
		
		.IF (ChoosePath == 2) && (wmblykTurn == 0)
			mov wmblykTurn, 1
			print "TURN", 13, 10
			mov ChoosePath, 0
			mov ChooseByte, 0
			invoke WmblykShuffle
			
			.WHILE (ChoosePath == 0)
				xor ebx, ebx
				mov bl, ChooseByte
				.IF (kubaleClose)
					mov ebx, 3
				.ENDIF
				xor eax, eax
				mov al, wmblykDirS[ebx]
				mov wmblykDirI, eax
						
				mov ChoosePath, 1
				.IF (wmblykDirI == 0)
					invoke GetOffset, MazeX, MazeY
					mov edx, eax
					mov eax, MazeBuffer
					mov cl, BYTE PTR [eax+edx]; ECX = Maze[x, y]
					and cl, MZC_PASSTOP
					.IF (cl == 0)
						print "Top blocked", 13, 10
						mov ChoosePath, 0
					.ENDIF
				.ELSEIF (wmblykDirI == 4)
					invoke GetOffset, MazeX, MazeY
					mov edx, eax
					mov eax, MazeBuffer
					mov cl, BYTE PTR [eax+edx]; ECX = Maze[x, y]
					and cl, MZC_PASSLEFT
					.IF (cl == 0)
						print "Left blocked", 13, 10
						mov ChoosePath, 0
					.ENDIF
				.ELSEIF (wmblykDirI == 8)
					inc MazeY
					invoke GetOffset, MazeX, MazeY
					mov edx, eax
					mov eax, MazeBuffer
					mov cl, BYTE PTR [eax+edx]; ECX = Maze[x, y+1]
					and cl, MZC_PASSTOP
					mov eax, MazeY
					.IF (cl == 0) || (eax == MazeHM1)
						print "Bottom blocked", 13, 10
						mov ChoosePath, 0
						dec MazeY
					.ENDIF
				.ELSEIF (wmblykDirI == 12)
					inc MazeX
					invoke GetOffset, MazeX, MazeY
					mov ebx, eax
					mov eax, MazeBuffer
					mov cl, BYTE PTR [eax+ebx]; ECX = Maze[x+1, y]
					and cl, MZC_PASSLEFT
					mov eax, MazeX
					.IF (cl == 0) || (eax == MazeWM1)
						print "Right blocked", 13, 10
						mov ChoosePath, 0
						dec MazeX
					.ENDIF
				.ENDIF
				
				inc ChooseByte
				.IF (ChooseByte > 3)
					.BREAK
				.ENDIF
			.ENDW
		.ENDIF
		.IF (wmblykDirI == 16)
			mov wmblykDirI, 0
		.ELSE
			mov eax, wmblykDirI
			invoke LerpAngle, ADDR wmblykDir, rotations[eax], delta10
			mov eax, wmblykDirI
			fld rotations[eax]
			fsin
			fchs
			fmul delta2
			fmul fl2
			fstp wXsp
			fld rotations[eax]
			fcos
			fchs
			fmul delta2
			fmul fl2
			fstp wYsp
			
			fld wmblykPos
			fadd wXsp
			fstp wmblykPos
			fld wmblykPos[4]
			fadd wYsp
			fstp wmblykPos[4]
		.ENDIF
		
		.IF (playerState == 0)
			invoke DistanceToSqr, wmblykPos, wmblykPos[4], camPosN, camPosN[4]
			mov distance, eax
			fcmp distance, fl1n2
			.IF Sign?
				mov wmblyk, 12
				mov playerState, 6
				fldz
				fstp wmblykStr
				mov wmblykStrState, 14
				fld1
				fadd flTenth
				fstp wmblykBlink
				invoke alSourcePlay, SndWmblykStr
				invoke alSourcePlay, SndWmblykStrM
			.ENDIF
		.ENDIF
	.ELSEIF (wmblyk == 12)
		invoke GetDirection, wmblykPos, wmblykPos[4], camPosN, camPosN[4]
		mov dirDeg, eax
		
		; This needs to be set everytime I want to use FPU?!?
		fstcw FPUMode
		or FPUMode, FPU_ZERO
		fldcw FPUMode
		
		fld wmblykBlink
		fmul wmblykStrAnim
		fistp wmblykAnim
		
		mov eax, wmblykStrState	; Animate strangling
		add wmblykAnim, eax
		fld deltaTime
		fmul flThird
		fsubr wmblykStr
		fstp wmblykStr
		
		.IF (playerState != 9) && (playerState != 10)
			invoke Lerp, ADDR wmblykStrM, fl1, deltaTime
			invoke alSourcef, SndWmblykStrM, AL_GAIN, wmblykStrM
		.ENDIF
		
		fcmp wmblykStr, flDoor
		.IF !Sign?
			xor ebx, ebx
			print sbyte$(Complete), 13, 10
			.IF (Complete)
				.IF (Glyphs == 6) && (GlyphsInLayer == 1)
					invoke DistanceToSqr, wmblykPos, wmblykPos[4], \
					GlyphPos, GlyphPos[4]
					mov distance, eax
					fcmp distance, fl1
					.IF (Sign?)
						inc ebx
					.ENDIF
				.ENDIF
			.ENDIF
			.IF (ebx)
				invoke alSourceStop, SndWmblykB
				invoke alSourceStop, SndWmblykStr
				invoke alSourceStop, SndWmblykStrM
				mov fade, 0
				mov vignetteRed, 0
				mov wmblyk, 14
				mov playerState, 18
				m2m face, TexWmblykL2
				fld camForward
				fsubr wmblykPos
				fchs
				fstp camPos
				fld camForward[8]
				fsubr wmblykPos[4]
				fchs
				fstp camPos[8]
				invoke alSource3f, SndSplash, AL_POSITION, camPosN, 0, camPosN[4]
				invoke alSourcePlay, SndSplash
			.ELSE
				mov wmblykAnim, 24
				mov playerState, 8
				mov wmblyk, 13
				m2m camPos[4], fl1N
				m2m face, TexWmblykL1
			.ENDIF
		.ELSE
			fcmp wmblykStr, flFifth
			.IF !Sign?
				m2m face, TexWmblykL1
				fcmp wmblykStr, flThird
				.IF !Sign?
					m2m face, TexWmblykL2
				.ENDIF
				.IF (wmblykStrState != 17)
					fld1
					fadd flTenth
					fstp wmblykBlink
					mov wmblykStrState, 17
				.ENDIF
			.ELSE
				invoke LerpAngle, ADDR wmblykDir, dirDeg, delta10
				m2m face, TexWmblykStr
				fcmp wmblykStr, flTenthN
				.IF Sign?
					m2m face, TexWmblykW1
					fcmp wmblykStr, flFifthN
					.IF Sign?
						m2m face, TexWmblykW2
						.IF (wmblykStrState != 20)
							fld1
							fadd flTenth
							fstp wmblykBlink
							mov wmblykStrState, 20
						.ENDIF
						fcmp wmblykStr, fl07N
						.IF Sign?
							.IF (playerState != 9) && (playerState != 10)
								mov canControl, 0
								mov playerState, 9
							.ENDIF
						.ENDIF
					.ENDIF
				.ELSE
					.IF (wmblykStrState != 14)
						fld1
						fadd flTenth
						fstp wmblykBlink
						mov wmblykStrState, 14
					.ENDIF
				.ENDIF
			.ENDIF
			fcmp wmblykBlink, flHalf
			.IF Sign?
				fld fl09
				fstp wmblykBlink
			.ENDIF
		.ENDIF
		
	.ELSEIF (wmblyk == 13)
		mov wmblykAnim, 24
		invoke glColor3fv, ADDR clBlack
		
		invoke DistanceToSqr, wmblykPos, wmblykPos[4], camPosN, camPosN[4]
		mov distance, eax
		fcmp distance, fl32
		.IF !Sign? && !Zero?
			mov wmblyk, 0
			invoke alSourceStop, SndWmblykStrM
		.ENDIF
		
		fcmp wmblykStrM
		.IF Sign? || Zero?
			invoke alSourceStop, SndWmblykStrM
		.ELSE
			invoke alSourcef, SndWmblykStrM, AL_GAIN, wmblykStrM
			invoke Lerp, ADDR wmblykStrM, 3184315597, deltaTime
		.ENDIF
	.ELSEIF (wmblyk >= 14)
		m2m face, TexWmblykL1
		mov wmblykAnim, 19
		.IF (wmblyk == 14)
			fld camForward
			fmul flFifth
			fsubr wmblykPos
			fchs
			fstp camPos
			fld camForward[8]
			fmul flFifth
			fsubr wmblykPos[4]
			fchs
			fstp camPos[8]
			fld1
			fadd flTenth
			fchs
			fstp camPos[4]
			mov wmblyk, 15
			m2m wmblykBlink, fl1
		.ELSEIF (wmblyk == 15)
			fcmp wmblykBlink
			.IF (Sign?)
				mov wmblykStealth, 0
				mov wmblyk, 16
			.ENDIF
		.ELSEIF (wmblyk == 16)
			fld deltaTime
			fmul flHalf
			fadd wmblykStealth
			fstp wmblykStealth
			fcmp wmblykStealth, fl1n5
			.IF (!Sign?)
				invoke alSourceStop, SndAmb
				m2m fade, fl1
				mov playerState, 9
				mov wmblyk, 17
				mov CCDeath[4], 71
				mov CCDeath[5], 65
				mov CCDeath[6], 89
				mov CCDeath[7], 46
				mov CCDeath[8], 0
			.ENDIF
		.ENDIF
	.ENDIF
	
	invoke glDisable, GL_LIGHTING
	invoke glDisable, GL_FOG
	invoke glBindTexture, GL_TEXTURE_2D, face
	invoke glPushMatrix
		invoke glTranslatef, wmblykPos, 0, wmblykPos[4]
		fld wmblykDir
		fmul R2D
		fstp dirDeg
		invoke glRotatef, dirDeg, 0, fl1, 0
		
		.IF (wmblyk >= 14)
			invoke glDisable, GL_DEPTH_TEST
		.ENDIF
		invoke glCallList, wmblykAnim
		
		invoke glEnable, GL_BLEND
		.IF (wmblyk == 16)
			invoke glBlendFunc, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
			invoke glColor4f, fl1, fl1, fl1, wmblykStealth
			invoke glBindTexture, GL_TEXTURE_2D, TexWmblykL3
			invoke glCallList, wmblykAnim
			invoke glEnable, GL_DEPTH_TEST
			invoke glColor4fv, ADDR clWhite
		.ENDIF
		invoke glBlendFunc, GL_ZERO, GL_SRC_COLOR
		invoke glScalef, fl2, fl2, fl2
		invoke glTranslatef, 3204448256, 1017370378, 3204448256
		invoke glRotatef, 1119092736, fl1, 0, 0
		
		invoke glColor3fv, ADDR clWhite
		invoke glBindTexture, GL_TEXTURE_2D, TexShadow
		invoke glCallList, 3
	invoke glPopMatrix
	ret
DrawWmblykAngry ENDP

; Turn Wmblyk into his stealthy state
MakeWmblykStealthy PROC
	LOCAL randTime:DWORD
	print "Wmblyk is stealthy", 13, 10
	
	mov wmblykStealthy, 1
	invoke nrandom, 7
	add eax, 4
	mov randTime, eax
	fild randTime
	fstp wmblykBlink
	ret
MakeWmblykStealthy ENDP

; Draw and process Wmblyk the jumpscarer (plus stealthy)
DrawWmblyk PROC
	LOCAL tX:REAL4, tY: REAL4, distance:REAL4
	LOCAL rotDiff:REAL4
	LOCAL blink: DWORD
	
	invoke GetDirection, wmblykPos, wmblykPos[4], camPosN, camPosN[4]
	mov tX, eax
	
	invoke Angleify, ADDR wmblykDir
	.IF (wmblyk == 10)
		invoke LerpAngle, ADDR wmblykDir, tX, delta10
		fld tX
		fsin
		fmul delta2
		fsubr wmblykPos
		fstp wmblykPos
		fld tX
		fcos
		fmul delta2
		fsubr wmblykPos[4]
		fstp wmblykPos[4]
	.ELSE
		.IF (wmblykStealthy == 0)
			invoke LerpAngle, ADDR wmblykDir, tX, delta2
		.ELSE
			m2m wmblykDir, tX
		.ENDIF
	.ENDIF
	
	fld wmblykDir
	fmul R2D
	fstp tY
	
	invoke DistanceToSqr, wmblykPos, wmblykPos[4], camPosN, camPosN[4]
	mov distance, eax
	
	fld wmblykBlink	; Timer
	fsub deltaTime
	fstp wmblykBlink
	
	fcmp wmblykBlink
	.IF Sign? && !Zero?
		.IF (wmblykStealthy == 0)
			.IF (wmblyk == 10)
				mov wmblyk, 1
				fld1
				fstp wmblykJumpscare
				invoke nrandom, 2
				invoke alSourcePlay, SndWmblyk
				.IF (eax == 0)
					invoke MakeWmblykStealthy
				.ENDIF
				ret
			.ENDIF
			invoke glColor4f, 0, 0, 0, 0
			
			invoke nrandom, 3
			add eax, 2
			mov blink, eax
			fild blink
			fstp wmblykBlink
		.ELSEIF (wmblykStealthy == 1)	; Waited for appearing
			print "Wmblyk will now appear.", 13, 10
			m2m wmblykBlink, fl1
			m2m wmblykStealth, camRot[4]
			mov wmblykStealthy, 2
		.ELSEIF (wmblykStealthy == 2)	; Waited for turn
			print "Wmblyk has appeared.", 13, 10
			m2m wmblykStealth, fl2
			mov wmblykStealthy, 3
		.ELSEIF (wmblykStealthy == 4)	; LOOGAME
			invoke nrandom, 1
			.IF (eax == 0)
				invoke MakeWmblykStealthy
			.ENDIF
		.ENDIF
	.ENDIF
	
	.IF (wmblykStealthy == 2)
		invoke DistanceScalar, wmblykStealth, camRot[4]
		mov rotDiff, eax
		
		mov blink, 0
		fcmp rotDiff, fl1
		.IF !Sign? && !Zero?
			inc blink
		.ELSE
			invoke DistanceScalar, camRot, 0
			fcmp camRot, fl1
			.IF !Sign? && !Zero?
				inc blink
			.ENDIF
		.ENDIF
		
		.IF (blink > 0)	; Camera rotated
			m2m wmblykBlink, fl1
			m2m wmblykStealth, camRot[4]
		.ENDIF
	.ELSEIF (wmblykStealthy == 3)
		mov blink, 0
		fcmp distance, fl1
		.IF !Sign? && !Zero?
			inc blink
		.ELSE
			fcmp distance, flTenth
			.IF Sign? && !Zero?
				inc blink
			.ENDIF
		.ENDIF
		
		.IF (blink > 0)	; Camera moved too far
			fld camForward
			fmul flHalf
			fadd camPosN
			fstp wmblykPos
			fld camForward[8]
			fmul flHalf
			fadd camPosN[4]
			fstp wmblykPos[4]
			
			invoke GetDirection, wmblykPos, wmblykPos[4], camPosN, camPosN[4]
			mov tX, eax
		.ENDIF
		
		invoke DistanceScalar, tX, camRot[4]	; Almost dot product
		mov rotDiff, eax
		invoke DistanceScalar, rotDiff, PI
		mov rotDiff, eax
		
		fcmp rotDiff, fl2	; If camera looks at Wmblyk
		.IF Sign? && !Zero?
			mov wmblykStealthy, 4
			m2m wmblykStealth, fl1
			m2m wmblykBlink, fl1
		.ENDIF
		
		invoke DistanceScalar, camRot, 0	; If camera looks up/down too much
		fcmp camRot, fl1
		.IF !Sign? && !Zero?
			mov wmblykStealthy, 4
			m2m wmblykStealth, fl1
			m2m wmblykBlink, fl1
		.ENDIF
	.ELSEIF (wmblykStealthy == 4)
		fld delta10
		fmul flHalf
		fstp rotDiff
		invoke Lerp, ADDR wmblykStealth, 0, rotDiff
	.ENDIF
	
	.IF (wmblykStealthy == 0) || (wmblykStealthy >= 3)
		invoke glDisable, GL_LIGHTING
		invoke glDisable, GL_FOG
		invoke glBindTexture, GL_TEXTURE_2D, TexWmblykNeutral
		invoke glPushMatrix
			invoke glTranslatef, wmblykPos, 0, wmblykPos[4]
			
			.IF (wmblykStealthy == 4)
				invoke glEnable, GL_BLEND
				invoke glBlendFunc, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
				invoke glColor4f, wmblykStealth, wmblykStealth, wmblykStealth, wmblykStealth
			.ENDIF
			
			invoke glPushMatrix
				invoke glRotatef, tY, 0, fl1, 0
				invoke glCallList, wmblyk
			invoke glPopMatrix
			
			invoke glPushMatrix
				invoke glTranslatef, 0, 1070050836, 0
				fld tX
				fmul R2D
				fstp tX
				invoke glRotatef, tX, 0, fl1, 0
				
				; Grab
				.IF (wmblykStealthy == 0)
					fcmp distance, fl1
					.IF (Sign? && !Zero?) && (wmblyk == 8)
						mov wmblyk, 10
						fld flTenth
						fstp wmblykBlink
					.ENDIF
				.ENDIF
				
				;print real4$(tX), 13, 10
				fld distance
				fadd fl2
				fdivr fl1
				fmul fl90N
				fstp tX
				fld camCrouch
				fmul fl10
				fsubr tX
				fstp tX
				invoke glRotatef, tX, fl1, 0, 0
				invoke glCallList, 9
			invoke glPopMatrix
			
			.IF (wmblykStealthy == 0)
				invoke glColor3fv, ADDR clWhite
			
				invoke glEnable, GL_BLEND
				invoke glBlendFunc, GL_ZERO, GL_SRC_COLOR
				invoke glScalef, fl2, fl2, fl2
				invoke glTranslatef, 3204448256, 1017370378, 3204448256
				invoke glRotatef, 1119092736, fl1, 0, 0
				invoke glBindTexture, GL_TEXTURE_2D, TexShadow
				invoke glCallList, 3
			.ENDIF
			;invoke glDisable, GL_BLEND
			
		invoke glPopMatrix
		.IF (wmblykStealthy == 4)
			invoke glColor4fv, ADDR clWhite
		.ENDIF
	.ENDIF
	ret
DrawWmblyk ENDP

; Draw  in the trench
DrawVas PROC
	LOCAL Dir:REAL4, DirRnd:DWORD

	invoke glPushMatrix
		invoke glTranslatef, vasPos, 0, vasPos[4]
		
		invoke GetDirection, vasPos, vasPos[4], camPosN, camPosN[4]
		mov Dir, eax
		
		fld Dir
		fsin
		fmul deltaTime
		fmul fl07N
		fadd vasPos
		fstp vasPos
		
		fld Dir
		fcos
		fmul deltaTime
		fmul fl07N
		fadd vasPos[4]
		fstp vasPos[4]
		
		invoke nrandom, 20
		mov DirRnd, eax
		fld Dir
		fmul R2D
		fsub fl10
		fiadd DirRnd
		fstp Dir
		invoke glRotatef, Dir, 0, fl1, 0
		
		invoke DistanceToSqr, vasPos, vasPos[4], camPosN, camPosN[4]
		mov Dir, eax
		fcmp Dir, fl1
		.IF (Sign?)
			mov al, fullscreen
			not al
			mov fullscreen, al
			invoke SetFullscreen, fullscreen
		.ENDIF
		fcmp Dir, flHalf
		.IF (Sign?)
			invoke LockWorkStation
			invoke ErrorOut, ADDR ErrorPF
		.ENDIF
		
		invoke glBindTexture, GL_TEXTURE_2D, TexVas
		invoke nrandom, 3
		add eax, 52
		invoke glCallList, eax
		
		invoke alSource3f, SndWmblykB, AL_POSITION, vasPos, 0, vasPos[4]
		
		fld Dir
		fmul flTenth
		fstp Dir
		invoke Clamp, Dir, 0, fl1
		mov Dir, eax
		
		fld clTrench
		fmul Dir
		fstp TrenchColor
		fld clTrench[4]
		fmul Dir
		fstp TrenchColor[4]
		fld clTrench[8]
		fmul Dir
		fstp TrenchColor[8]
	invoke glPopMatrix
	ret
DrawVas ENDP

; Make Virdya react to something at (PosX, PosY) with distance threshold Dist
VirdyaReact PROC PosX:REAL4, PosY:REAL4, Dist:REAL4
	LOCAL distance:REAL4

	invoke DistanceToSqr, virdyaPos, virdyaPos[4], PosX, PosY
	mov distance, eax
	fcmp distance, Dist
	.IF (Sign?)
		invoke nrandom, 100
		.IF (eax)
			m2m virdyaBlink, fl1
		.ELSE
			mov virdyaBlink, 1
		.ENDIF
		
		.IF (!kubaleVision)
			invoke Lerp, ADDR fade, 0, delta2
			invoke Lerp, ADDR vignetteRed, 0, delta2
		.ENDIF
		invoke Lerp, ADDR virdyaSound, 0, delta2
		fcmp virdyaSound, flHundredth
		.IF (Sign?)
			mov virdyaSound, 0
		.ENDIF
		
		mov virdyaState, 2
		m2m virdyaFace, TexVirdyaN
		invoke GetDirection, virdyaPos, virdyaPos[4], \
		PosX, PosY
		mov virdyaRot, eax
		
		fld virdyaRot
		fsub virdyaRotL
		fmul R2D
		fstp virdyaRotL[8]
		
		mov virdyaRotL[4], 0
		
		fld virdyaRot
		fsin
		fmul deltaTime
		fchs
		fstp virdyaSpeed
		
		fld virdyaRot
		fcos
		fmul deltaTime
		fchs
		fstp virdyaSpeed[4]
		
		.IF (virdya < 68)
			mov virdya, 68
		.ENDIF
		mov al, 1
	.ELSE
		xor al, al
	.ENDIF
	ret
VirdyaReact ENDP
; Draw Virdya 
DrawVirdya PROC
	LOCAL rand:SDWORD, rotDeg:REAL4, headHeight:REAL4, randRot:DWORD
	LOCAL distance:REAL4, collided:BYTE, curSpeed:REAL4, close:BYTE

	invoke Angleify, ADDR virdyaRot
	invoke Angleify, ADDR virdyaRotL
	.IF (virdyaState == 0)
		invoke LerpAngle, ADDR virdyaRotL, virdyaRot, deltaTime
	.ELSEIF (virdyaState == 1) || (virdyaState == 3)
		invoke LerpAngle, ADDR virdyaRotL, virdyaRot, delta10
	.ELSE
		invoke LerpAngle, ADDR virdyaRotL, virdyaRot, delta2
	.ENDIF
	invoke Lerp, ADDR virdyaRotL[4], virdyaHeadRot, delta2
	invoke Lerp, ADDR virdyaRotL[8], virdyaHeadRot[4], delta2
	
	invoke DistanceToSqr, virdyaPos, virdyaPos[4], \
	camPosNext, camPosNext[8]
	mov distance, eax
	
	fcmp distance, flFifth	; Collide with player
	.IF Sign?
		invoke GetDirection, virdyaPos, virdyaPos[4], \
		camPosN, camPosN[4]
		mov headHeight, eax
		
		fld headHeight
		fcos
		fabs
		fmul camCurSpeed
		fstp camCurSpeed
		fld headHeight
		fsin
		fabs
		fmul camCurSpeed[8]
		fstp camCurSpeed[8]
	.ENDIF
	fcmp distance, flQuarter
	.IF (Sign?) && (virdyaState == 1)
		mov virdya, 58
		mov virdyaState, 0
		invoke GetDirection, virdyaPos, virdyaPos[4], \
		camPosN, camPosN[4]
		mov virdyaRot, eax
		mov virdyaHeadRot, 3240099840
		mov virdyaHeadRot[4], 0
		mov virdyaSpeed, 0
		mov virdyaSpeed[4], 0
	.ENDIF
	
	
	invoke MoveAndCollide, ADDR virdyaPos, ADDR virdyaPos[4], \
	ADDR virdyaSpeed, ADDR virdyaSpeed[4], flHalf, 0
	mov collided, al
	
	fld virdyaTimer	; Behavior timer
	fsub deltaTime
	fstp virdyaTimer
	fcmp virdyaTimer
	.IF (Sign?)
		.IF (virdyaState == 0)	; Standing chill
			invoke nrandom, 6
			mov rand, eax
			push rand
			add rand, 2
			fild rand
			fmul flTenth
			fstp virdyaTimer
			pop rand
			
			.IF (rand < 2)
				invoke RandomFloat, ADDR virdyaHeadRot, 25
				fld virdyaHeadRot
				fsub fl10
				fstp virdyaHeadRot
				invoke RandomFloat, ADDR virdyaHeadRot[4], 45
				
				.IF (rand == 0)
					mov headHeight, 0
					fcmp distance, fl6
					.IF (Sign?)
						mov headHeight, 1
					.ELSE
						mov virdya, 58
						mov virdyaState, 1
						mov virdyaTimer, 0
						m2m virdyaDest, camPosN
						m2m virdyaDest[4], camPosN[4]
						mov virdyaHeadRot, 3240099840
						mov virdyaHeadRot[4], 0
					.ENDIF
					
					invoke nrandom, 2
					.IF (eax) && (headHeight == 1)	; Look at player
						invoke GetDirection, virdyaPos, virdyaPos[4], \
						camPosN, camPosN[4]
						mov virdyaRot, eax
						mov virdyaHeadRot, 3240099840
						mov virdyaHeadRot[4], 0
					.ELSE
						invoke RandomRange, 90
						mov randRot, eax
						fild randRot
						fmul D2R
						fadd virdyaRot
						fstp virdyaRot
					.ENDIF
				.ENDIF
			.ELSEIF (rand == 2)
				mov virdya, 58
				mov virdyaState, 1
				mov virdyaTimer, 0
				invoke RandomFloat, ADDR randRot, 6
				fld virdyaPos
				fadd randRot
				fstp virdyaDest
				invoke RandomFloat, ADDR randRot, 6
				fld virdyaPos[4]
				fadd randRot
				fstp virdyaDest[4]
			.ELSEIF (rand == 3)
				invoke nrandom, 2
				SWITCH eax
					CASE 0
						mov virdya, 67
					CASE 1
						mov virdya, 58
				ENDSW
			.ELSEIF (rand == 4)
				mov eax, virdyaFace
				.IF (eax != TexVirdyaN) && (Glyphs == 7)
					fcmp distance, fl8
					.IF (Sign?)
						.IF (virdyaEmote == 0)
							print "Virdya emotes.", 13, 10
							mov virdya, 123
							mov virdyaState, 4
							mov virdyaSpeed, 0
							mov virdyaSpeed[4], 0
							
							m2m virdyaTimer, flFifth
							invoke nrandom, 8
							add eax, 6
							mov virdyaEmote, al
						.ELSE
							dec virdyaEmote
						.ENDIF
					.ELSE
						invoke nrandom, 4
						add eax, 3
						mov virdyaEmote, al
					.ENDIF
				.ENDIF
			.ENDIF
		.ELSEIF (virdyaState == 1)	; Walking
			inc virdya
			m2m virdyaTimer, flTenth
			.IF (virdya == 67)
				mov virdya, 59
			.ENDIF
		.ELSEIF (virdyaState == 2) && (virdya >= 68) && (virdya <= 73)
			inc virdya
			m2m virdyaTimer, flFifth
			.IF (virdya == 74)
				mov virdya, 68
			.ENDIF
		.ELSEIF (virdyaState == 4)	; Waving
			inc virdya
			m2m virdyaTimer, flTenth
			.IF (virdya == 132)
				mov virdyaState, 0
				mov virdya, 58
			.ENDIF
		.ENDIF
	.ENDIF
	
	mov headHeight, 1068457001
	.IF (virdyaState == 0)	; Standing process
		mov virdyaSpeed, 0
		mov virdyaSpeed[4], 0
		invoke Lerp, ADDR virdyaSound, 0, delta2
		fcmp virdyaSound, flHundredth
		.IF (Sign?)
			mov virdyaSound, 0
		.ENDIF
		.IF (playerState == 0) && (!kubaleVision)
			invoke Lerp, ADDR fade, 0, delta2
			invoke Lerp, ADDR vignetteRed, 0, delta2
		.ENDIF
	.ELSEIF (virdyaState == 1)	; Walking process
		fild virdya
		fsin
		fmul flHundredth
		fmul flHalf
		fsubr headHeight
		fstp headHeight
		
		invoke GetDirection, virdyaPos, virdyaPos[4], \
		virdyaDest, virdyaDest[4]
		mov virdyaRot, eax
		
		fld virdyaRot
		fsin
		fmul deltaTime
		fstp virdyaSpeed
		
		fld virdyaRot
		fcos
		fmul deltaTime
		fstp virdyaSpeed[4]
		
		.IF (collided)
			mov virdyaState, 0
			mov virdya, 58
		.ENDIF
			
		invoke DistanceToSqr, virdyaPos, virdyaPos[4], virdyaDest, virdyaDest[4]
		mov randRot, eax
		fcmp randRot, flFifth
		.IF (Sign?)
			mov virdyaState, 0
			mov virdya, 58
		.ENDIF
		invoke Lerp, ADDR virdyaSound, 0, delta2
		fcmp virdyaSound, flHundredth
		.IF (Sign?)
			mov virdyaSound, 0
		.ENDIF
	.ELSEIF (virdyaState == 2)	; Glyph placed process
		.IF (GlyphsInLayer) && (Glyphs == 6)
			invoke DistanceToSqr, virdyaPos, virdyaPos[4], GlyphPos, GlyphPos[4]
			mov distance, eax
			m2m virdyaDest, GlyphPos
			m2m virdyaDest[4], GlyphPos[4]
		.ELSE
			m2m virdyaDest, camPosN
			m2m virdyaDest[4], camPosN[4]
		.ENDIF
		
		invoke GetDirection, virdyaPos, virdyaPos[4], \
		virdyaDest, virdyaDest[4]
		mov virdyaRot, eax
		fld virdyaRot
		fsub virdyaRotL
		fmul R2D
		fstp virdyaRotL[8]
		
		fld distance
		fadd fl2
		fdivr fl1
		fmul fl90N
		fstp virdyaRotL[4]
		
		fcmp distance, fl5
		.IF (Sign?)
			fld virdyaRot
			fsin
			fmul deltaTime
			fmul fl07N
			fstp virdyaSpeed
			
			fld virdyaRot
			fcos
			fmul deltaTime
			fmul fl07N
			fstp virdyaSpeed[4]
			
			invoke DistanceToSqr, virdyaPos, virdyaPos[4], \
			virdyaPosPrev, virdyaPosPrev[4]
			mov curSpeed, eax
			fld curSpeed
			fmul fl1000
			fstp curSpeed
			print real4$(deltaTime), 9
			print real4$(curSpeed), 13, 10
			fcmp curSpeed, deltaTime
			.IF (!Sign?)
				.IF (virdya == 58)
					mov virdya, 68
				.ENDIF
			.ELSE
				mov virdya, 58
			.ENDIF
		.ELSE
			mov virdyaSpeed, 0
			mov virdyaSpeed[4], 0
			mov virdya, 58
		.ENDIF
	.ELSEIF (virdyaState == 3)	; Defensive process
		invoke GetDirection, virdyaPos, virdyaPos[4], \
		camPosN, camPosN[4]
		mov virdyaRot, eax
		
		fld virdyaRot
		fsub virdyaRotL
		fmul R2D
		fstp virdyaRotL[8]
		
		fld distance
		fadd fl2
		fdivr fl1
		fmul fl90N
		fstp virdyaRotL[4]
		fld camCrouch
		fmul fl10
		fsubr virdyaRotL[4]
		fstp virdyaRotL[4]
		
		.IF (playerState == 0)
			mov close, 0
			invoke CheckBlocked, virdyaPos, virdyaPos[4], camPosN, camPosN[4]
			mov ecx, distance
			.IF ((ecx < fl12) && !(eax)) || (ecx < fl2)
				mov virdya, 74
				fcmp distance, fl10
				.IF (Sign?)
					mov virdya, 75
					fld deltaTime
					fmul flFifth
					fadd fade
					fstp fade
					fcmp fade, fl1
					.IF (!Sign?)
						mov canControl, 0
						mov playerState, 9
					.ENDIF
					invoke Lerp, ADDR virdyaSound, fl1, deltaTime
					invoke Lerp, ADDR vignetteRed, fl1, deltaTime
					fld camCurSpeed
					fmul flThird
					fstp camCurSpeed
					fld camCurSpeed[8]
					fmul flThird
					fstp camCurSpeed[8]
					
					mov close, 1
					
					fcmp distance, fl2
					.IF (Sign?)
						fld virdyaRot
						fsin
						fmul deltaTime
						fmul flTenth
						fchs
						fstp virdyaSpeed
						
						fld virdyaRot
						fcos
						fmul deltaTime
						fmul flTenth
						fchs
						fstp virdyaSpeed[4]
					.ENDIF
				.ENDIF
			.ELSE
				mov virdya, 58
			.ENDIF
			.IF !(close)
				.IF (!kubaleVision)
					invoke Lerp, ADDR fade, 0, delta2
					invoke Lerp, ADDR vignetteRed, 0, delta2
				.ENDIF
				invoke Lerp, ADDR virdyaSound, 0, delta2
				fcmp virdyaSound, flHundredth
				.IF (Sign?)
					mov virdyaSound, 0
				.ENDIF
			.ENDIF
		.ELSE
			invoke Lerp, ADDR virdyaSound, 0, delta2
			fcmp virdyaSound, flHundredth
			.IF (Sign?)
				mov virdyaSound, 0
			.ENDIF
		.ENDIF
	.ELSEIF (virdyaState == 4)	; Waving process
		invoke GetDirection, virdyaPos, virdyaPos[4], \
		camPosN, camPosN[4]
		mov virdyaRot, eax
		mov virdyaHeadRot[4], 0
		
		fld distance
		fadd fl2
		fdivr fl1
		fmul fl90N
		fstp virdyaHeadRot
		fld camCrouch
		fmul fl10
		fsubr virdyaHeadRot
		fstp virdyaHeadRot
	.ENDIF
	
	.IF (Glyphs < 7) && (Glyphs >= 5) && (virdyaState != 2)	; React to glyphs
		.IF (GlyphsInLayer)
			invoke DistanceToSqr, virdyaPos, virdyaPos[4], GlyphPos, GlyphPos[4]
			mov distance, eax
			fcmp distance, fl10
			.IF (Sign?) || (Glyphs == 5)
				mov virdyaState, 2
				mov virdya, 58
				mov virdyaBlink, 0
			.ENDIF
		.ENDIF
	.ELSEIF (Glyphs < 5)
		fld camCrouch
		fmul fl10
		fsubr fl32
		fstp rotDeg
		fcmp distance, rotDeg
		.IF (Sign?) && (virdyaState != 3)
			print "Virdya is going apeshit", 13, 10
			mov virdyaState, 3
			mov virdya, 58
			mov virdyaBlink, 0
			mov virdyaSpeed, 0
			mov virdyaSpeed[4], 0
		.ENDIF
		fcmp distance, fl32
		.IF !(Sign?) && (virdyaState == 3)
			print "Virdya is fine", 13, 10
			mov virdyaState, 0
			mov virdya, 58
		.ENDIF
	.ENDIF
	
	mov close, 0
	.IF (wmblyk == 11) || (wmblyk == 12)	; React to Wmblyk
		invoke VirdyaReact, wmblykPos, wmblykPos[4], fl2
		add close, al
	.ENDIF
	.IF (WB)
		invoke VirdyaReact, WBPosL, WBPosL[4], fl4
		add close, al
	.ENDIF
	.IF (kubale > 1)
		invoke VirdyaReact, kubalePos, kubalePos[4], fl6
		add close, al
	.ENDIF
	.IF (Glyphs == 7) && (virdyaState > 1) && (!close) && (virdyaState != 4)
		mov virdyaState, 0
	.ENDIF
	
	fld virdyaBlink
	fsub deltaTime
	fstp virdyaBlink
	fcmp virdyaBlink
	.IF (Sign?)	; Blink and facial timer
		push virdyaFace
		invoke nrandom, 5
		.IF (eax == 0)
			pop eax
			mov eax, TexVirdyaBlink
		.ELSE
			pop eax
		.ENDIF
		.IF (eax == TexVirdyaBlink)
			.IF (virdyaState < 2) || (virdyaState == 4)
				invoke nrandom, 3
				inc eax
				mov rand, eax
				fild rand
				fstp virdyaBlink
				invoke nrandom, 8
				SWITCH eax
					CASE 0
						m2m virdyaFace, TexVirdyaDown
					CASE 1
						m2m virdyaFace, TexVirdyaUp
					DEFAULT
						m2m virdyaFace, TexVirdyaNeut
				ENDSW
			.ELSE
				invoke nrandom, 5
				inc eax
				mov rand, eax
				fild rand
				fstp virdyaBlink
				invoke nrandom, 8
				m2m virdyaFace, TexVirdyaN
			.ENDIF
		.ELSE
			m2m virdyaBlink, flTenth
			m2m virdyaFace, TexVirdyaBlink
			.IF (rand == 1) && (virdyaState == 1)
				mov virdyaState, 0
			.ENDIF
		.ENDIF
	.ENDIF
	
	m2m virdyaPosPrev, virdyaPos
	m2m virdyaPosPrev[4], virdyaPos[4]
	
	invoke alSourcef, SndVirdya, AL_GAIN, virdyaSound
	
	fld virdyaRotL
	fmul R2D
	fstp rotDeg

	invoke glPushMatrix
		invoke glTranslatef, virdyaPos, 0, virdyaPos[4]
		invoke glRotatef, rotDeg, 0, fl1, 0
		invoke glDisable, GL_CULL_FACE
		invoke glLightModeli, GL_LIGHT_MODEL_TWO_SIDE, 1
		invoke glBindTexture, GL_TEXTURE_2D, virdyaFace
		invoke glCallList, virdya
		
		invoke glPushMatrix
			invoke glTranslatef, 0, headHeight, 3178611343
			invoke glRotatef, virdyaRotL[8], 0, fl1, 0
			invoke glRotatef, virdyaRotL[4], fl1, 0, 0
			invoke glCallList, 57
		invoke glPopMatrix
			
		invoke glEnable, GL_CULL_FACE
		invoke glLightModeli, GL_LIGHT_MODEL_TWO_SIDE, 0
		
		invoke glEnable, GL_BLEND
		invoke glDisable, GL_LIGHTING
		invoke glDisable, GL_FOG
		invoke glBlendFunc, GL_ZERO, GL_SRC_COLOR
		invoke glScalef, fl2, fl2, fl2
		invoke glTranslatef, 3204448256, 1008981770, 3204448256
		invoke glRotatef, 1119092736, fl1, 0, 0
		
		invoke glColor3fv, ADDR clWhite
		invoke glBindTexture, GL_TEXTURE_2D, TexShadow
		invoke glCallList, 3
		invoke glDisable, GL_BLEND
		invoke glEnable, GL_LIGHTING
		invoke glEnable, GL_FOG
	invoke glPopMatrix
	ret
DrawVirdya ENDP

; Erase saved data
EraseSave PROC
	m2m MotryaTimer, fl1
	mov Motrya, 2
	mov Save, 0
	
	invoke RegCreateKeyExA, HKEY_CURRENT_USER, ADDR RegPath, 0, NULL, \
	REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, ADDR defKey, NULL
	.IF (eax != ERROR_SUCCESS)
		print "Failed to create registry key.", 13, 10
	.ENDIF
	
	invoke RegDeleteValueA, defKey, ADDR RegLayer
	invoke RegDeleteValueA, defKey, ADDR RegCompass
	invoke RegDeleteValueA, defKey, ADDR RegGlyphs
	invoke RegDeleteValueA, defKey, ADDR RegFloor
	invoke RegDeleteValueA, defKey, ADDR RegWall
	invoke RegDeleteValueA, defKey, ADDR RegRoof
	invoke RegDeleteValueA, defKey, ADDR RegMazeW
	invoke RegDeleteValueA, defKey, ADDR RegMazeH
	
	invoke RegCloseKey, defKey
	ret
EraseSave ENDP

; Erase current progress save data
EraseTempSave PROC
	invoke RegCreateKeyExA, HKEY_CURRENT_USER, ADDR RegPath, 0, NULL, \
	REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, ADDR defKey, NULL
	invoke RegDeleteValueA, defKey, ADDR RegCurLayer
	invoke RegDeleteValueA, defKey, ADDR RegCurWidth
	invoke RegDeleteValueA, defKey, ADDR RegCurHeight
	invoke RegCloseKey, defKey
	ret
EraseTempSave ENDP

; Show error message and halt
ErrorOut PROC lpText:DWORD
	LOCAL Code:DWORD
	invoke GetLastError
	mov Code, eax
	print "Windows error code: "
	print str$(Code), 13, 10
	invoke MessageBox, hwnd, lpText, ADDR ErrorCaption, MB_OK
	invoke Halt
	ret
ErrorOut ENDP

; Free all loaded audio from memory
FreeAllAudio PROC
	invoke FreeAudio, ADDR SndAmb
	invoke FreeAudio, ADDR SndDrip
	invoke FreeAudio, ADDR SndExit
	invoke FreeAudio, ADDR SndKey
	invoke FreeAudio, ADDR SndKubale
	invoke FreeAudio, ADDR SndKubaleAppear
	invoke FreeAudio, ADDR SndKubaleV
	invoke FreeAudio, ADDR SndMistake
	invoke FreeAudio, ADDR SndScribble
	invoke FreeAudio, ADDR SndWmblyk
	invoke FreeAudio, ADDR SndWmblykB
	invoke FreeAudio, ADDR SndWmblykStr
	invoke FreeAudio, ADDR SndWmblykStrM
	
	invoke alcMakeContextCurrent, NULL
	invoke alcDestroyContext, AudioContext
	invoke alcCloseDevice, AudioDevice
	print "Freed audio", 13, 10
	ret
FreeAllAudio ENDP

; Free the OpenGL context and release DC
FreeContext PROC
	invoke wglMakeCurrent, GDI, NULL
	invoke wglDeleteContext, GLC
	invoke ReleaseDC, hwnd, GDI
	print "Freed context", 13, 10
	ret
FreeContext ENDP

; Free maze data from memory (if you're lucky)
FreeMaze PROC
	invoke GlobalUnlock, MazeBuffer
	;.IF eax == 0
	;	invoke ErrorOut, ADDR ErrorMazeBuffer
	;.ENDIF
	invoke GlobalFree, Maze
	;.IF eax != 0
	;	invoke ErrorOut, ADDR ErrorMaze
	;.ENDIF
	mov Maze, 0
	mov MazeSize, 0
	mov MazeSizeM1, 0
	print "Freed maze", 13, 10
	ret
FreeMaze ENDP

; Bitwise AND maze cell with maze constanc (MZC)
GetCellMZC PROC X:DWORD, Y:DWORD, MZC:BYTE
	invoke GetOffset, X, Y
	add eax, MazeBuffer
	mov al, BYTE PTR [eax]
	and al, MZC
	ret
GetCellMZC ENDP

; Calculate deltaTime
GetDelta PROC
	LOCAL diff: DWORD
	LOCAL fps: REAL4
	
	invoke QueryPerformanceCounter, ADDR tick
	mov eax, tick
	sub eax, lastTime
	mov diff, eax

	.IF (diff == 0) || (lastTime == 0)
		m2m lastTime, tick
		ret
	.ENDIF
	
	.IF (Menu == 0) && (MazeNote < 16)
		fild diff
		fidiv perfFreq
	.ELSE
		fldz
	.ENDIF
	.IF (debugF)
		fmul fl4
	.ENDIF
	fstp deltaTime
	
	fld deltaTime
	fmul fl2
	fst delta2
	fmul fl10
	fstp delta10
	
	
	mov eax, tick
	mov lastTime, eax
	ret
GetDelta ENDP

; Get maze cell position from world position 
GetMazeCellPos PROC PosX:REAL4, PosY:REAL4, PosXPtr:DWORD, PosYPtr:DWORD
	LOCAL PosXI:DWORD, PosYI:DWORD

	fstcw FPUMode
	or FPUMode, FPU_ZERO
	fldcw FPUMode
		fld PosX
		fmul flHalf
		fistp PosXI
		fld PosY
		fmul flHalf
		fistp PosYI
	xor FPUMode, FPU_ZERO
	fldcw FPUMode
	
	mov eax, PosXPtr
	m2m DWORD PTR [eax], PosXI
	mov eax, PosYPtr
	m2m DWORD PTR [eax], PosYI
	ret
GetMazeCellPos ENDP

; Get the pointer offset for use in 2D array (maze) and return to EAX
GetOffset PROC PosX: DWORD, PosY: DWORD
	LOCAL TestX:DWORD, TestY:DWORD

	mov eax, PosX
	mov TestX, eax
	.IF (eax < 0)
		mov TestX, 0
	.ELSEIF (eax > MazeWM1)
		m2m TestX, MazeWM1
	.ENDIF
	mov eax, PosY
	mov TestY, eax
	.IF (eax < 0)
		mov TestY, 0
	.ELSEIF (eax > MazeHM1)
		m2m TestY, MazeHM1
	.ENDIF
	
	mov eax, MazeW
	mul TestY
	add eax, TestX
	ret
GetOffset ENDP

; Get the position from pointer offset, return X to EDX, Y to EAX
GetPosition PROC PosOffset: DWORD
	mov eax, PosOffset
	mov ecx, MazeW
	xor edx, edx
	div ecx
	ret
GetPosition ENDP

; Get saved settings from settings.ini and apply them
GetSettings PROC
	LOCAL bdTh:DWORD, bdH:DWORD
	LOCAL pcbData:DWORD
	LOCAL joyInfo:JOYINFO
	
	; Get absolute path to settings.ini
	invoke GetFullPathNameA, ADDR IniPath, LENGTH IniPathAbs, ADDR IniPathAbs, 0
	; Width & height
	invoke GetPrivateProfileInt, ADDR IniGraphics, ADDR IniWidth, 800, \
	ADDR IniPathAbs
	mov winW, ax
	
	invoke GetPrivateProfileInt, ADDR IniGraphics, ADDR IniHeight, 600, \
	ADDR IniPathAbs
	mov winH, ax
	
	m2m winWS, winW
	m2m winHS, winH
	
	invoke GetSystemMetrics, SM_CXSIZEFRAME
	add ax, ax
	add winW, ax
	add winH, ax
	invoke GetSystemMetrics, SM_CYCAPTION
	add winH, ax
	
	invoke SetWindowPos, hwnd, HWND_TOPMOST, 0, 0, winW, winH, \
	SWP_NOZORDER or SWP_FRAMECHANGED or SWP_SHOWWINDOW or SWP_NOMOVE
	
	; Fullscreen
	invoke GetPrivateProfileString, ADDR IniGraphics, ADDR IniFullscreen, \
	ADDR IniFalse, ADDR IniReturn, 9, ADDR IniPathAbs
	.IF (IniReturn == 116) || (IniReturn == 84) ; t or T
		mov fullscreen, -1
		invoke SetFullscreen, fullscreen
	.ENDIF
	
	; Brightness
	invoke GetPrivateProfileString, ADDR IniGraphics, ADDR IniBrightness, \
	ADDR Ini05, ADDR IniReturn, 9, ADDR IniPathAbs
	print ADDR IniReturn, 13, 10
	invoke ParseFloat, ADDR IniReturn
	mov Gamma, eax
	
	; Joystick ID
	mov joystickXInput, 0
	invoke GetPrivateProfileInt, ADDR IniControls, ADDR IniJoystickID, -1, \
	ADDR IniPathAbs
	mov joystickID, eax
	invoke joyGetPos, joystickID, ADDR joyInfo
	.IF (eax != JOYERR_NOERROR)
		mov joystickID, -1
	.ELSE
		invoke joyGetDevCapsA, joystickID, ADDR joyCaps, SIZEOF JOYCAPSAFIX
		print str$(eax), 13, 10
		mov eax, joyCaps.wMaxAxes
		print str$(eax), 13, 10
		print str$(joyCaps.wCaps), 13, 10
		mov eax, joyCaps.wCaps
		and eax, JOYCAPS_HASU
		.IF (eax)
			mov joystickXInput, 1
			print "XInput", 13, 10
		.ENDIF
	.ENDIF
	print "Will use joystick ID "
	print str$(joystickID), 13, 10
	
	; Joystick Sensitivity
	invoke GetPrivateProfileString, ADDR IniControls, \
	ADDR IniJoystickSensitivity, ADDR Ini20, ADDR IniReturn, 9, ADDR IniPathAbs
	invoke ParseFloat, ADDR IniReturn
	mov camJoySpeed, eax
	
	; Mouse Sensitivity
	invoke GetPrivateProfileString, ADDR IniControls, \
	ADDR IniMouseSensitivity, ADDR Ini03, ADDR IniReturn, 9, ADDR IniPathAbs
	invoke ParseFloat, ADDR IniReturn
	mov camTurnSpeed, eax
	
	; Audio volume
	invoke GetPrivateProfileString, ADDR IniAudio, \
	ADDR IniVolume, ADDR Ini10, ADDR IniReturn, 9, ADDR IniPathAbs
	invoke ParseFloat, ADDR IniReturn
	invoke alListenerf, AL_GAIN, eax
	
	
	invoke RegCreateKeyExA, HKEY_CURRENT_USER, ADDR RegPath, 0, NULL, \
	REG_OPTION_NON_VOLATILE, KEY_READ, NULL, ADDR defKey, NULL
	invoke RegQueryValueExA, defKey, ADDR RegComplete, 0, NULL, \
	ADDR Complete, ADDR pcbData
	invoke RegCloseKey, defKey
	ret
GetSettings ENDP

; Get global window center with position
GetWindowCenter PROC
	mov cx, 2
	
	mov ax, winW
	xor edx, edx
	div cx
	mov winWH, ax
	push ax
	mov ax, winH
	xor edx, edx
	div cx
	mov winHH, ax
	
	add ax, winY
	mov winCY, ax
	pop ax
	add ax, winX
	mov winCX, ax
	
	fild winWH
	fstp winWHF
	fild winHH
	fstp winHHF
	ret
GetWindowCenter ENDP

; Get random position in maze (REAL4) for items
GetRandomMazePosition PROC XPtr:DWORD, YPtr:DWORD
	LOCAL XPos:DWORD, YPos:DWORD
	
	mov eax, MazeWM1
	sub eax, 2	; don't want it near the end nor start
	invoke nrandom, eax
	inc eax
	mov ecx, 2
	mul ecx		; *2 = to world coords
	inc eax		; center
	mov XPos, eax
	
	mov eax, MazeHM1
	sub eax, 2
	invoke nrandom, eax
	inc eax
	mov ecx, 2
	mul ecx		; *2 = to world coords
	inc eax		; center
	mov YPos, eax
	
	.IF (MazeCrevice)
		mov eax, MazeCrevicePos
		mov ecx, 2
		mul ecx
		inc eax
		push eax
		mov eax, MazeCrevicePos[4]
		mov ecx, 2
		mul ecx
		inc eax
		pop ecx
		.IF (ecx == XPos) && (eax == YPos)
			print "Crevice pos object stuck", 13, 10
			invoke GetRandomMazePosition, XPtr, YPtr
			ret
		.ENDIF
	.ENDIF
	.IF (MazeTram)
		mov eax, MazeTramArea
		mov ecx, 2
		mul ecx
		inc eax
		push eax
		mov eax, MazeTramArea[4]
		mov ecx, 2
		mul ecx
		inc eax
		pop ecx
		.IF (XPos >= ecx) && (XPos <= eax)
			print "Tram area object stuck", 13, 10
			invoke GetRandomMazePosition, XPtr, YPtr
			ret
		.ENDIF
	.ENDIF
	fild XPos
	fstp XPos
	fild YPos
	fstp YPos
	
	mov eax, XPtr
	mov ecx, XPos
	mov REAL4 PTR [eax], ecx
	mov eax, YPtr
	mov ecx, YPos
	mov REAL4 PTR [eax], ecx
	ret
GetRandomMazePosition ENDP

; Setup shop to sell map and stuff for drawing the map
SetupShopMap PROC
	LOCAL Diff:DWORD

	mov Shop, 1
	mov ShopKoluplyk, 78
	
	m2m MapOffset, fl03N
	m2m MapOffset[4], fl03N
	
	m2m MapBRID, MazeSize
	dec MapBRID
	
	; TODO: Make map centered, don't know how
	mov eax, MazeW
	.IF (eax > MazeH)
		fild MazeWM1
		fdivr fl1
		fstp MapSize
	.ELSE
		fild MazeHM1
		fdivr fl1
		fstp MapSize
	.ENDIF
	ret
SetupShopMap ENDP

; Spawns maze elements (items, monsters) depending on layer
SpawnMazeElements PROC
	LOCAL PosX:DWORD, PosY:DWORD
	
	.IF (MazeLevel > 1)
		invoke nrandom, 6	; Random environment
		SWITCH eax
			CASE 0
				m2m CurrentWall, TexWall
			CASE 1
				m2m CurrentWall, TexMetal
			CASE 2
				m2m CurrentWall, TexWhitewall
			CASE 3
				m2m CurrentWall, TexBricks
			CASE 4
				m2m CurrentWall, TexConcrete
			CASE 5
				m2m CurrentWall, TexPlaster
		ENDSW
		invoke nrandom, 6
		SWITCH eax
			CASE 0
				m2m CurrentWallMDL, 1
			CASE 1
				m2m CurrentWallMDL, 25
			CASE 2
				m2m CurrentWallMDL, 26
			CASE 3
				m2m CurrentWallMDL, 92
			CASE 4
				m2m CurrentWallMDL, 93
			CASE 5
				m2m CurrentWallMDL, 132
		ENDSW
		invoke nrandom, 3
		SWITCH eax
			CASE 0
				m2m CurrentRoof, TexRoof
			CASE 1
				m2m CurrentRoof, TexMetalRoof
			CASE 2
				m2m CurrentRoof, TexConcreteRoof
		ENDSW
		invoke nrandom, 5
		SWITCH eax
			CASE 0
				m2m CurrentFloor, TexFloor
			CASE 1
				m2m CurrentFloor, TexMetalFloor
			CASE 2
				m2m CurrentFloor, TexTilefloor
			CASE 3
				m2m CurrentFloor, TexDiamond
			CASE 4
				m2m CurrentFloor, TexTileBig
		ENDSW
	.ENDIF
	
	; Random env sounds, hijacks Wmblyk's labels
	invoke nrandom, 6
	mov wmblyk, eax
	.IF (wmblyk < 2)
		invoke nrandom, MazeW
		mov ebx, 2
		mul ebx
		mov PosX, eax
		fild PosX
		fstp wmblykPos
		invoke nrandom, MazeH
		mov ebx, 2
		mul ebx
		mov PosY, eax
		fild PosY
		fstp wmblykPos[4]
		print real4$(wmblykPos), 32
		mov eax, wmblykPos[4]
		print real4$(eax), 13, 10
		
		SWITCH wmblyk
			CASE 0
				invoke alSource3f, SndDrip, AL_POSITION, \
				wmblykPos, fl2, wmblykPos[4]
				invoke alSourcePlay, SndDrip
			CASE 1
				invoke alSource3f, SndWhisper, AL_POSITION, \
				wmblykPos, fl2, wmblykPos[4]
				invoke alSourcePlay, SndWhisper
		ENDSW
	.ENDIF
	
		
	invoke nrandom, 10
	.IF (eax > 6) && (MazeLevel > 4)	; Maze crevice
		print "Spawned crevice", 13, 10
		mov MazeCrevice, 1
		mov eax, MazeWM1
		sub eax, 2	; Don't want it near the end nor start
		invoke nrandom, eax
		inc eax
		mov MazeCrevicePos, eax
		
		mov eax, MazeHM1
		sub eax, 2
		invoke nrandom, eax
		inc eax
		mov MazeCrevicePos[4], eax
	.ENDIF
	
	.IF (MazeHostile == 1)
		invoke nrandom, 3
		.IF (MazeW > 13) && (!MazeCrevice) && (al)
			invoke GetCellMZC, 0, 0, MZC_PASSTOP	; Test for trench
			.IF !(al)								; Spawn tram
				mov MazeTram, 1
				xor edx, edx
				mov eax, MazeW
				mov ebx, 3
				div ebx
				mov MazeTramArea, eax
				add eax, eax
				mov MazeTramArea[4], eax
				
				xor ebx, ebx
				.WHILE (ebx < MazeHM1)
					invoke GetOffset, MazeTramArea, ebx
					add eax, MazeBuffer
					.IF (ebx != 0)
						mov BYTE PTR [eax], MZC_PASSTOP or MZC_PASSLEFT
					.ENDIF
					
					inc MazeTramArea
					invoke GetOffset, MazeTramArea, ebx
					add eax, MazeBuffer
					mov BYTE PTR [eax], 0
					dec MazeTramArea
					
					invoke GetOffset, MazeTramArea[4], ebx
					add eax, MazeBuffer
					mov BYTE PTR [eax], MZC_PASSTOP
					.IF (ebx == 0)
						mov BYTE PTR [eax], 0
					.ENDIF
					
					inc MazeTramArea[4]
					invoke GetCellMZC, MazeTramArea[4], ebx, MZC_ROTATED
					.IF (al)
						invoke GetOffset, MazeTramArea[4], ebx
						add eax, MazeBuffer
						xor BYTE PTR [eax], MZC_ROTATED
					.ENDIF
					dec MazeTramArea[4]
					
					inc ebx
				.ENDW
				
				inc MazeTramArea
				dec MazeTramArea[4]
				
				fild MazeTramArea
				fmul fl2
				fadd fl1
				fstp MazeTramPos
				fild MazeHM1
				fstp MazeTramPos[8]
				
				invoke alSourcePlay, SndTram
			.ENDIF
		.ENDIF
		
		invoke nrandom, 3	; Door slam event
		.IF !(al)
			print "Will slam door", 13, 10
			mov doorSlam, 1
		.ENDIF
	
		invoke nrandom, MazeLevel	; Key
		.IF (al > 7)
			print "Locked maze", 13, 10
			mov MazeLocked, 1
			invoke GetRandomMazePosition, ADDR MazeKeyPos, \
			ADDR MazeKeyPos[4]
		.ENDIF
		
		.IF (Glyphs < 5)
			invoke nrandom, 3	; Glyphs
			.IF (al == 0) || (Glyphs == 0)
				print "Spawned glyphs", 13, 10
				mov MazeGlyphs, 1
				invoke GetRandomMazePosition, \
				ADDR MazeGlyphsPos, ADDR MazeGlyphsPos[4]
			.ENDIF
		.ENDIF
		
		.IF (Compass != 2) && (MazeLevel > 11)	; Compass
			mov Compass, 0
			invoke nrandom, 2
			.IF (al == 0)
				print "Spawned compass", 13, 10
				mov Compass, 1
				invoke GetRandomMazePosition, \
				ADDR CompassPos, ADDR CompassPos[4]
			.ENDIF
		.ENDIF
		
		SWITCH MazeLevel	; Notes
			CASE 8
				mov MazeNote, 1
				m2m MazeNotePos, fl1
				m2m MazeNotePos[4], fl3
				invoke GetOffset, 0, 1
				add eax, MazeBuffer
				or BYTE PTR [eax], MZC_PASSTOP
			CASE 12
				mov MazeNote, 2
				invoke GetRandomMazePosition, \
				ADDR MazeNotePos, ADDR MazeNotePos[4]
			CASE 16
				mov MazeNote, 3
				invoke GetRandomMazePosition, \
				ADDR MazeNotePos, ADDR MazeNotePos[4]
			CASE 23
				mov MazeNote, 4
				invoke GetRandomMazePosition, \
				ADDR MazeNotePos, ADDR MazeNotePos[4]
			CASE 36
				mov MazeNote, 5
				invoke GetRandomMazePosition, \
				ADDR MazeNotePos, ADDR MazeNotePos[4]
			CASE 41
				mov MazeNote, 6
				invoke GetRandomMazePosition, \
				ADDR MazeNotePos, ADDR MazeNotePos[4]
			CASE 62
				mov MazeNote, 7
				invoke GetRandomMazePosition, \
				ADDR MazeNotePos, ADDR MazeNotePos[4]
		ENDSW
		
		mov wmblyk, 0
		mov wmblykStealthy, 0
		mov wmblykBlink, 0
		.IF (MazeLevel > 6)
			invoke nrandom, 2
			.IF (al == 0)
				invoke GetRandomMazePosition, \
				ADDR wmblykPos, ADDR wmblykPos[4]
				
				print "Spawned Wmblyk", 13, 10
				mov wmblyk, 8
				invoke nrandom, 2
				.IF (al == 0)
					invoke MakeWmblykStealthy
				.ENDIF
				.IF (MazeLevel > 9)
					invoke nrandom, 2
					.IF (al == 0)
						mov wmblykStealthy, 0
						mov wmblyk, 11
						mov wmblykTurn, 0
						mov wmblykAnim, 11
						invoke alSourcef, SndWmblykB, AL_GAIN, fl1
						invoke alSourcef, SndWmblykB, AL_PITCH, fl1
						invoke alSourcePlay, SndWmblykB
						print "Wmblyk is angry", 13, 10
					.ENDIF
				.ENDIF
			.ENDIF
		.ENDIF
		
		.IF (MazeLevel > 12) && (!MazeTram)
			invoke nrandom, 4
			.IF (!al)
				print "Spawned Kubale", 13, 10
				invoke nrandom, 10
				.IF (al == 0) || (kubaleAppeared == 0)
					mov kubaleAppeared, 1
					invoke nrandom, 6
					add eax, 2
					mov kubale, eax
					fild kubale
					fstp kubaleDir
					mov kubale, 1
				.ELSE
					invoke MakeKubale
				.ENDIF
			.ENDIF
		.ENDIF
		
		.IF (MazeSize > 90) && (!MazeTram)
			invoke nrandom, 10
			.IF (!al)
				print "Shnurpshik will be projected", 13, 10
				mov Shn, 1
				m2m ShnTimer, fl75
			.ENDIF
		.ENDIF
		
		invoke nrandom, 20	; Vebra
		.IF (!al) && (!MazeLocked)
			print "Spawned Vebra", 13, 10
			mov Vebra, 133
		.ENDIF
		
		invoke nrandom, 3	; Virdya
		.IF (MazeLevel > 15) && (!al)
			print "Spawned Virdya", 13, 10
			mov virdya, 63
			mov virdyaState, 0
			m2m virdyaFace, TexVirdyaNeut
			mov virdyaSound, 0
			invoke alSourcePlay, SndVirdya
			invoke GetRandomMazePosition, ADDR virdyaPos, ADDR virdyaPos[4]
		.ENDIF
		
		invoke RandomRange2, 28, 56
		.IF (MazeLevel > eax) && (!kubale) && (!MazeCrevice)
			.IF (!wmblyk) || (wmblykStealthy)
				print "Spawned WB", 13, 10
				invoke WBCreate
			.ENDIF
		.ENDIF
		
		invoke RandomRange2, 9, 78
		.IF (MazeLevel > eax)
			print "Spawned Eblodryn", 13, 10
			mov EBD, 1
			invoke GetRandomMazePosition, ADDR EBDPos, ADDR EBDPos[4]
			invoke alSource3f, SndEBD, AL_POSITION, EBDPos, 0, EBDPos[4]
			invoke alSourcef, SndEBDA, AL_GAIN, 0
			invoke alSourcePlay, SndEBD
			invoke alSourcePlay, SndEBDA
		.ENDIF
		
		; Huenbergondel
		.IF (MazeLevel > 21)&&(!kubale)&&(!virdya)&&(!WB)
			.IF (MazeType == 1)
				invoke nrandom, 2
				.IF (al)
					print "Spawned WB", 13, 10
					invoke WBCreate 
				.ENDIF
			.ELSEIF (!wmblyk) || (wmblykStealthy)
				print "Spawned Huenbergondel", 13, 10
				mov hbd, 1
				
				m2m PosX, MazeWM1
				sub PosX, 1
				m2m PosY, MazeHM1
				sub PosY, 1
				
				xor ebx, ebx
				.WHILE !ebx
					inc ebx
					invoke nrandom, PosX
					add eax, 1
					mov hbdPos, eax
					invoke nrandom, PosY
					add eax, 1
					mov hbdPos[4], eax
					.IF MazeCrevice
						mov eax, MazeCrevicePos
						mov ecx, MazeCrevicePos[4]
						.IF (hbdPos == eax) && (hbdPos[4] == ecx)	
							print "Huenbergondel stuck in crevice", 13, 10
							xor ebx, ebx
						.ELSE
							inc ebx
						.ENDIF
					.ENDIF
					.IF MazeTram
						mov eax, MazeTramArea
						mov ecx, MazeTramArea[4]
						.IF (hbdPos >= eax) && (hbdPos <= ecx)
							print "Huenbergondel stuck in tram area", 13, 10
							xor ebx, ebx
						.ELSE
							inc ebx
						.ENDIF
					.ENDIF
				.ENDW
				
				fild hbdPos
				fmul fl2
				fadd fl1
				fstp hbdPosF
				fild hbdPos[4]
				fmul fl2
				fadd fl1
				fstp hbdPosF[4]
			.ENDIF
		.ENDIF
		
		.IF (MazeLevel > 17) && (!MazeTram) && (!Vebra)	; Teleporters
			invoke nrandom, 3
			.IF (!al)
				print "Spawned teleporters", 13, 10
				mov MazeTeleport, 1
				invoke GetRandomMazePosition, \
				ADDR MazeTeleportPos, ADDR MazeTeleportPos[4]
				invoke GetRandomMazePosition, \
				ADDR MazeTeleportPos[8], ADDR MazeTeleportPos[12]
			.ENDIF
		.ENDIF
	
		.IF (MazeSize > 80)	; Shop
			invoke nrandom, 2
			.IF ((Glyphs >= 5) || (MazeGlyphs)) && (eax)
				invoke SetupShopMap
			.ENDIF
		.ENDIF
	
		.IF (MazeLevel > 17) && (MazeSize < 128) && (!MazeTram)	; WBBK
			invoke nrandom, 13
			.IF (!eax)
				mov hbd, 0
				mov kubale, 0
				mov MazeGlyphs, 0
				mov MazeLocked, 0
				mov Shop, 0
				mov wmblyk, 0
				mov virdya, 0
				
				mov WBBK, 1
				invoke nrandom, 3
				.IF (!eax)
					print "Webubychko is unabstracted", 13, 10
					mov WBBK, 3
					m2m WBBKPos, fl13
					m2m WBBKPos[4], fl13
				.ENDIF
				
				invoke glLightModelfv, GL_LIGHT_MODEL_AMBIENT, ADDR clBlack
				invoke glLightf, GL_LIGHT0, GL_CONSTANT_ATTENUATION, 0
				invoke glLightf, GL_LIGHT0, GL_QUADRATIC_ATTENUATION, fl2
				
				invoke alSourceStop, SndAmb
				invoke alSourceStop, SndWmblykB
				invoke alSourcef, SndAmbT, AL_PITCH, flFifth
				invoke alSourcePlay, SndAmbT
				invoke alSourcef, SndStep, AL_PITCH, flThird
				invoke alSourcef, SndStep[4], AL_PITCH, flThird
				invoke alSourcef, SndStep[8], AL_PITCH, flThird
				invoke alSourcef, SndStep[12], AL_PITCH, flThird
			.ENDIF
		.ENDIF
	.ENDIF
	
	.IF (MazeLevel == 21) || (MazeLevel == 42) || (MazeLevel == 63)
		mov Checkpoint, 1
	.ENDIF
	
	fcmp ccTimer
	.IF Sign?
		invoke nrandom, 20
		.IF (al == ccTextLast)
			ret
		.ENDIF
		mov ccTextLast, al
		SWITCH eax
			CASE 0
				invoke ShowSubtitles, ADDR CCRandom1
			CASE 1
				invoke ShowSubtitles, ADDR CCRandom2
			CASE 2
				invoke ShowSubtitles, ADDR CCRandom3
			CASE 3
				invoke ShowSubtitles, ADDR CCRandom4
			CASE 4
				invoke ShowSubtitles, ADDR CCRandom5
			CASE 5
				invoke ShowSubtitles, ADDR CCRandom6
		ENDSW
	.ENDIF
	ret
SpawnMazeElements ENDP

; Sets up the environment for the trench
SpawnTrench PROC
	LOCAL PosX:DWORD, PosY:DWORD, WallCheck:BYTE
	
	print "Trench", 13, 10
	mov Trench, 1
	fild MazeLevel
	fsqrt
	fmul flHundredth
	fmul fl2
	fstp TrenchTimer
	
	m2m CurrentWall, TexDirt
	m2m CurrentFloor, TexDirt
	mov CurrentWallMDL, 50
	
	fld fl6
	fmul fl10
	fstp camFOV
	
	invoke alSourcePlay, SndAmbT
	invoke alSourcef, SndWmblykB, AL_PITCH, flFifth
	invoke alSourcef, SndWmblykB, AL_GAIN, fl10
	invoke alSourcePlay, SndWmblykB
	invoke alSourceStop, SndAmb
	
	invoke alSourceStop, SndSiren	; DEBUG
	mov MazeHostile, 1
	
	;invoke GetRandomMazePosition, ADDR vasPos, ADDR vasPos[4]
	fild MazeHM1
	fmul fl2
	fsub fl1
	fstp vasPos[4]
	m2m vasPos, fl1
			
	xor ebx, ebx	; Let's iterate a second time because poor code decisions
	.WHILE (ebx < MazeSize)
		invoke GetPosition, ebx
		mov PosX, edx
		mov PosY, eax
		
		.IF (PosX == 0)
			mov eax, MazeBuffer
			or BYTE PTR [eax+ebx], MZC_PASSTOP
		.ENDIF
	
		mov eax, MazeBuffer
		mov cl, BYTE PTR [eax+ebx]
		and cl, MZC_PASSTOP
		mov WallCheck, 0
		.IF !(cl)
			inc WallCheck
		.ENDIF
		
		mov cl, BYTE PTR [eax+ebx]
		and cl, MZC_LAMP
		.IF (cl)
			xor BYTE PTR [eax+ebx], MZC_LAMP
		.ENDIF
		
		mov cl, BYTE PTR [eax+ebx]
		and cl, MZC_PIPE
		.IF (cl)
			xor BYTE PTR [eax+ebx], MZC_PIPE
		.ENDIF
		
		invoke nrandom, 2
		.IF (eax)
			inc PosY
			invoke GetOffset, PosX, PosY
			
			add eax, MazeBuffer
			mov cl, BYTE PTR [eax]
			and cl, MZC_PASSTOP
			
			.IF !(cl) && (WallCheck)
				mov eax, MazeBuffer
				or BYTE PTR [eax+ebx], MZC_LAMP
			.ENDIF
		.ENDIF
		
		invoke nrandom, 5
		.IF !(eax)
			mov eax, MazeBuffer
			or BYTE PTR [eax+ebx], MZC_PIPE
		.ENDIF
		inc ebx
	.ENDW
	ret
SpawnTrench ENDP

; Set all states to 0 and do the final touches
FinishMazeGeneration PROC
	LOCAL PosX:DWORD, PosY:DWORD, PoolX:DWORD, PoolY:DWORD
	
	fild MazeWM1
	fsub fl1
	fmul fl2
	fadd fl1
	fchs
	fstp MazeDoorPos
	fild MazeHM1
	fsub fl1
	fmul fl2
	fadd fl1
	fchs
	fstp MazeDoorPos[4]
	print real4$(MazeDoorPos), 32
	mov eax, MazeDoorPos[4]
	print real4$(eax), 13, 10
	
	inc MazeLevel
	invoke SetMazeLevelStr, str$(MazeLevel)
	
	mov Checkpoint, 0
	mov doorSlam, 0
	mov EBD, 0
	mov GlyphsInLayer, 0
	mov hbd, 0
	mov kubale, 0
	mov MazeCrevice, 0
	mov MazeGlyphs, 0
	mov MazeLocked, 0
	mov MazeNote, 0
	mov MazeTeleport, 0
	mov MazeTram, 0
	mov Map, 0
	mov Save, 0
	mov Shop, 0
	mov Shn, 0
	mov Vebra, 0
	mov virdya, 0
	mov vignetteRed, 0
	mov WB, 0
	mov wmblyk, 0
	mov wmblykStealthy, 0
	mov WmblykTram, 0
	
	.IF (WBBK)
		mov WBBK, 0
		invoke glLightModelfv, GL_LIGHT_MODEL_AMBIENT, \
		ADDR clDarkGray
		invoke glLightf, GL_LIGHT0, GL_CONSTANT_ATTENUATION, fl1
		invoke glLightf, GL_LIGHT0, GL_QUADRATIC_ATTENUATION, 0
		
		invoke alSourceStop, SndAmbT
		invoke alSourcef, SndAmbT, AL_PITCH, fl1
		invoke alSourcePlay, SndAmb
		invoke alSourcef, SndStep, AL_PITCH, fl1
		invoke alSourcef, SndStep[4], AL_PITCH, fl1
		invoke alSourcef, SndStep[8], AL_PITCH, fl1
		invoke alSourcef, SndStep[12], AL_PITCH, fl1
	.ENDIF
	
	invoke alSourceStop, SndAlarm
	invoke alSourceStop, SndEBD
	invoke alSourceStop, SndEBDA
	invoke alSourceStop, SndHbd
	invoke alSourceStop, SndKubale
	invoke alSourceStop, SndKubaleV
	invoke alSourceStop, SndVirdya
	invoke alSourceStop, SndTram
	invoke alSourceStop, SndWmblykB
	invoke alSourceStop, SndWBBK
	
	mov al, Glyphs
	sub al, 7
	mov bl, -4
	mul bl
	mov GlyphOffset, al
	
	.IF (MazeLevel > 22)
		invoke nrandom, 10
		.IF (eax == 0)
			invoke SpawnTrench
		.ENDIF
	.ENDIF
	
	.IF (MazeSize > 64)	; Center room
		invoke nrandom, 20
		.IF !(eax)
			fild MazeWM1
			fmul flThird
			fistp PosX
			fild MazeHM1
			fmul flThird
			fistp PosY
			m2m PoolX, PosX
			m2m PoolY, PosY
			mov ebx, PoolX
			add PosX, ebx
			mov ebx, PoolY
			add PosY, ebx
			.WHILE (ebx < PosY)
				mov ecx, PoolX
				.WHILE (ecx < PosX)
					invoke GetOffset, ecx, ebx
					add eax, MazeBuffer
					or BYTE PTR [eax], MZC_PASSTOP
					or BYTE PTR [eax], MZC_PASSLEFT
					inc ecx
				.ENDW
				inc ebx
			.ENDW
		.ENDIF
	.ENDIF
	
	invoke RegCreateKeyExA, HKEY_CURRENT_USER, ADDR RegPath, 0, NULL, \
	REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, ADDR defKey, NULL
	invoke RegSetValueExA, defKey, ADDR RegCurLayer, 0, REG_DWORD, \
	ADDR MazeLevel, 4
	invoke RegSetValueExA, defKey, ADDR RegCurWidth, 0, REG_DWORD, \
	ADDR MazeW, 4
	invoke RegSetValueExA, defKey, ADDR RegCurHeight, 0, REG_DWORD, \
	ADDR MazeH, 4
	invoke RegCloseKey, defKey

	.IF !(Trench)
		invoke SpawnMazeElements
	.ENDIF
	ret
FinishMazeGeneration ENDP

; Generates the maze and spawns maze elements with the procedures above
GenerateMaze PROC Seed:DWORD
	LOCAL PosX: DWORD, PosY: DWORD, PoolI: BYTE, StackCntr: DWORD
	LOCAL PoolX: DWORD, PoolY: DWORD, ByteChosen: BYTE, MazePoolCopy: DWORD
	
	print "Generating maze with size "
	print str$(MazeW), 32
	print str$(MazeH), 9
	print str$(MazeSize), 13, 10
	print "Seed: "
	print str$(Seed), 13, 10
	
	invoke alSourceStop, SndDrip
	invoke alSourceStop, SndWhisper
	invoke alSourceStop, SndWmblykB
	
	mov eax, MazeW
	mul MazeH
	mov MazeSize, eax
	
	mov eax, MazeW
	dec eax
	mov MazeWM1, eax
	
	mov eax, MazeH
	dec eax
	mov MazeHM1, eax
	
	mov eax, MazeW
	mul MazeHM1
	mov MazeSizeM1, eax
	
	invoke GlobalAlloc, GMEM_MOVEABLE or GMEM_ZEROINIT, MazeSize ; Create array
	mov Maze, eax
    invoke GlobalLock, Maze
    mov MazeBuffer, eax
	
	xor ebx, ebx	; Clear all cells, doubtfully necessary 
	.WHILE (ebx < MazeSize)
		mov eax, MazeBuffer
		mov BYTE PTR [eax+ebx], 0
		inc ebx
	.ENDW
	
	invoke nrandom, 10
	.IF (al > 2)
		mov MazeType, 0
	.ELSE
		mov MazeType, al
		print "Maze type is: "
		print sbyte$(MazeType), 13, 10
	.ENDIF
	
	invoke nseed, Seed
	invoke nrandom, MazeWM1	; Position = Random(Width), Random(Height)
	mov PosX, eax
	invoke nrandom, MazeHM1
	mov PosY, eax
	
	.IF (MazeLevel == 0)
		mov PosX, 0
		mov PosY, 0
	.ENDIF
	print "Random position "
	print str$(PosX), 32
	print str$(PosY), 13, 10
	
	mov StackCntr, 0	; Count the stack
	
	.WHILE TRUE
		.REPEAT
			mov MazePool, 0	; Create pool, in which we'll add possible ways
			
			.IF (PosY > 0)	; 0, -1
				mov eax, PosY
				sub eax, 1
				mov PoolY, eax
				
				invoke GetOffset, PosX, PoolY	;(x, y-1)
				mov ebx, eax				; EBX will hold offset (x, y)
				mov eax, MazeBuffer
				mov cl, BYTE PTR [eax+ebx]	; CL = Maze[x, y-1]
				and cl, MZC_VISITED
				.IF (cl == 0)			; if !CL.Visited
					add MazePool, 00000001h	; [0, -1]
				.ENDIF
			.ENDIF
			.IF (PosX > 0)	; -1, 0
				mov eax, PosX
				sub eax, 1
				mov PoolX, eax
				
				invoke GetOffset, PoolX, PosY	;(x-1, y)
				mov ebx, eax				; EBX will hold offset (x, y)
				mov eax, MazeBuffer
				mov cl, BYTE PTR [eax+ebx]	; CL = Maze[x-1, y]
				and cl, MZC_VISITED
				.IF (cl == 0)				; if !CL.Visited
					add MazePool, 00000100h	; [-1, 0]
				.ENDIF
			.ENDIF
			
			mov ebx, MazeHM1
			sub ebx, 1
			.IF (PosY < ebx)	; 0, 1
				mov eax, PosY
				add eax, 1
				mov PoolY, eax
				
				invoke GetOffset, PosX, PoolY	;(x, y+1)
				mov ebx, eax				; EBX will hold offset (x, y)
				mov eax, MazeBuffer
				mov cl, BYTE PTR [eax+ebx]	; CL = Maze[x, y+1]
				and cl, MZC_VISITED
				.IF (cl == 0)				; if !CL.Visited
					add MazePool, 00010000h	; [0, 1]
				.ENDIF
			.ENDIF
			
			mov ebx, MazeWM1
			sub ebx, 1
			.IF (PosX < ebx)	; 1, 0
				mov eax, PosX
				add eax, 1
				mov PoolX, eax
				
				invoke GetOffset, PoolX, PosY	;(x+1, y)
				mov ebx, eax				; EBX will hold offset (x, y)
				mov eax, MazeBuffer
				mov cl, BYTE PTR [eax+ebx]	; CL = Maze[x+1, y]
				and cl, MZC_VISITED
				.IF (cl == 0)				; if !CL.Visited
					add MazePool, 01000000h	; [1, 0]
				.ENDIF
			.ENDIF
			
			.IF (MazeLevel == 0) && (PosX == 0) && (PosY == 0)
				mov MazePool, 01000000h
			.ENDIF
			
			;print "Pos: "
			;print str$(PosX), 32
			;print str$(PosY)
			;print ", MazePool is "
			;print uhex$(MazePool), 13, 10
			
			.IF (MazePool == 0)	; No direction to draw from
				;print "No direction, MazePool is "
				;print str$(MazePool), 13, 10
				.IF (StackCntr == 0) ; This is the end, the bitter, bitter end
					print "Back to start", 13, 10
					
					invoke FinishMazeGeneration
					ret
				.ENDIF
				
				pop PosY	; Continue our journey
				pop PosX
				dec StackCntr
			.ENDIF
		.UNTIL (MazePool != 0)
		
		;print "Found way", 13, 10
		
		mov PoolI, -8
		mov ByteChosen, 0	; Pool index = random(Pool.Length)
		.WHILE (ByteChosen == 0)
			.IF (MazeType == 1)
				add PoolI, 8
			.ELSE
				invoke nrandom, 4
				mov ebx, 8
				mul ebx
				mov PoolI, al	; Random shift amount
			.ENDIF
			
			mov cl, PoolI
			mov ebx, MazePool
			shr ebx, cl
			mov ByteChosen, bl
			
			.IF (ByteChosen == 0)
				.CONTINUE
			.ENDIF
			
			invoke GetOffset, PosX, PosY	; Maze[x, y].Visited = true
			add eax, MazeBuffer
			or BYTE PTR [eax], MZC_VISITED
			
			; Offset (Pool[Pool index])
			.IF (PoolI == 0)		; [0, -1]
				invoke GetOffset, PosX, PosY
				add eax, MazeBuffer
				or BYTE PTR [eax], MZC_PASSTOP
				dec PosY
				;print "Going up", 13, 10
			.ELSEIF (PoolI == 8)	; [-1, 0]
				invoke GetOffset, PosX, PosY
				add eax, MazeBuffer
				or BYTE PTR [eax], MZC_PASSLEFT
				dec PosX
				;print "Going left", 13, 10
			.ELSEIF (PoolI == 16)	; [0, 1]
				inc PosY
				invoke GetOffset, PosX, PosY
				add eax, MazeBuffer
				or BYTE PTR [eax], MZC_PASSTOP
				;print "Going down", 13, 10
			.ELSE					; [1, 0]
				inc PosX
				invoke GetOffset, PosX, PosY
				add eax, MazeBuffer
				or BYTE PTR [eax], MZC_PASSLEFT
				;print "Going right", 13, 10
			.ENDIF
			
			invoke GetOffset, PosX, PosY	; Maze[x, y].Visited = true
			mov ebx, eax
			add ebx, MazeBuffer
			.IF (MazeType == 2)
				invoke nrandom, 10
			.ELSE
				xor eax, eax
			.ENDIF
			.IF !(eax)
				or BYTE PTR [ebx], MZC_VISITED
			.ENDIF
			
			invoke nrandom, 32	; Misc
			.IF (eax == 0)
				or BYTE PTR [ebx], MZC_LAMP 
			.ENDIF
			invoke nrandom, 30
			.IF (eax == 0)
				or BYTE PTR [ebx], MZC_PIPE 
			.ENDIF
			invoke nrandom, 29
			.IF (eax == 0)
				or BYTE PTR [ebx], MZC_WIRES 
			.ENDIF
			
			invoke nrandom, 33
			.IF (MazeLevel == 0) && (PosX == 1) && (PosY == 0)
				xor eax, eax
			.ENDIF
			.IF (eax == 0)
				or BYTE PTR [ebx], MZC_TABURETKA
			.ENDIF
			invoke nrandom, 2
			.IF (eax)
				or BYTE PTR [ebx], MZC_ROTATED
			.ENDIF
			
			push PosX
			push PosY
			inc StackCntr
		.ENDW
	.ENDW
	ret
GenerateMaze ENDP

; Check for GL errors and call ErrorOut if found any
GLE PROC
	LOCAL glE
	invoke glGetError
	mov glE, eax
	.IF glE != 0
		print hex$(glE), 13, 10
		invoke ErrorOut, ADDR ErrorOpenGL
	.ENDIF
	ret
GLE ENDP

; Quit program, freeing resources
Halt PROC
	print sbyte$(Menu), 13, 10
	invoke HeapUnlock, Heap
	invoke FreeMaze
	invoke FreeAllAudio
	invoke FreeLibraries
	invoke FreeContext
	print "Successfully freed everything, posting quit message", 13, 10
	invoke PostQuitMessage, 0
	ret
Halt ENDP

; Initialize audio libraries and load sounds
InitAudio PROC
	; i don wana make an ogg parser noo
	invoke LoadLibraries, OFFSET ErrorOut
	invoke InitOpenAL
	
	invoke LoadAudio, ADDR SndAlarmPath, ADDR SndAlarm
	invoke LoadAudio, ADDR SndAmbPath, ADDR SndAmb
	invoke LoadAudio, ADDR SndAmbTPath, ADDR SndAmbT
	invoke LoadAudio, ADDR SndCheckpointPath, ADDR SndCheckpoint
	invoke LoadAudio, ADDR SndDeathPath, ADDR SndDeath
	invoke LoadAudio, ADDR SndDigPath, ADDR SndDig
	invoke LoadAudio, ADDR SndDistressPath, ADDR SndDistress
	invoke LoadAudio, ADDR SndDoorClosePath, ADDR SndDoorClose
	invoke LoadAudio, ADDR SndDripPath, ADDR SndDrip
	invoke LoadAudio, ADDR SndEBDPath, ADDR SndEBD
	invoke LoadAudio, ADDR SndEBDAPath, ADDR SndEBDA
	invoke LoadAudio, ADDR SndExitPath, ADDR SndExit
	invoke LoadAudio, ADDR SndExit1Path, ADDR SndExit1
	invoke LoadAudio, ADDR SndExplosionPath, ADDR SndExplosion
	invoke LoadAudio, ADDR SndHbdPath, ADDR SndHbd
	invoke LoadAudio, ADDR SndHbdOPath, ADDR SndHbdO
	invoke LoadAudio, ADDR SndHurtPath, ADDR SndHurt
	invoke LoadAudio, ADDR SndImpactPath, ADDR SndImpact
	invoke LoadAudio, ADDR SndIntroPath, ADDR SndIntro
	invoke LoadAudio, ADDR SndStep1, ADDR SndStep
	invoke LoadAudio, ADDR SndStep2, ADDR SndStep[4]
	invoke LoadAudio, ADDR SndStep3, ADDR SndStep[8]
	invoke LoadAudio, ADDR SndStep4, ADDR SndStep[12]
	invoke LoadAudio, ADDR SndKeyPath, ADDR SndKey
	invoke LoadAudio, ADDR SndKubalePath, ADDR SndKubale
	invoke LoadAudio, ADDR SndKubaleAppearPath, ADDR SndKubaleAppear
	invoke LoadAudio, ADDR SndKubaleVPath, ADDR SndKubaleV
	invoke LoadAudio, ADDR SndMistakePath, ADDR SndMistake
	invoke LoadAudio, ADDR SndRand1Path, ADDR SndRand
	invoke LoadAudio, ADDR SndRand2Path, ADDR SndRand[4]
	invoke LoadAudio, ADDR SndRand3Path, ADDR SndRand[8]
	invoke LoadAudio, ADDR SndRand4Path, ADDR SndRand[12]
	invoke LoadAudio, ADDR SndRand5Path, ADDR SndRand[16]
	invoke LoadAudio, ADDR SndRand6Path, ADDR SndRand[20]
	invoke LoadAudio, ADDR SndSavePath, ADDR SndSave
	invoke LoadAudio, ADDR SndScribblePath, ADDR SndScribble
	invoke LoadAudio, ADDR SndSirenPath, ADDR SndSiren
	invoke LoadAudio, ADDR SndSlamPath, ADDR SndSlam
	invoke LoadAudio, ADDR SndSplashPath, ADDR SndSplash
	invoke LoadAudio, ADDR SndTramPath, ADDR SndTram
	invoke LoadAudio, ADDR SndTramAnn1Path, ADDR SndTramAnn
	invoke LoadAudio, ADDR SndTramAnn2Path, ADDR SndTramAnn[4]
	invoke LoadAudio, ADDR SndTramAnn3Path, ADDR SndTramAnn[8]
	invoke LoadAudio, ADDR SndTramClosePath, ADDR SndTramClose
	invoke LoadAudio, ADDR SndTramOpenPath, ADDR SndTramOpen
	invoke LoadAudio, ADDR SndVirdyaPath, ADDR SndVirdya
	invoke LoadAudio, ADDR SndWBAlarmPath, ADDR SndWBAlarm
	invoke LoadAudio, ADDR SndWBAttackPath, ADDR SndWBAttack
	invoke LoadAudio, ADDR SndWBIdle1Path, ADDR SndWBIdle
	invoke LoadAudio, ADDR SndWBIdle2Path, ADDR SndWBIdle[4]
	invoke LoadAudio, ADDR SndWBStep1Path, ADDR SndWBStep
	invoke LoadAudio, ADDR SndWBStep2Path, ADDR SndWBStep[4]
	invoke LoadAudio, ADDR SndWBStep3Path, ADDR SndWBStep[8]
	invoke LoadAudio, ADDR SndWBStep4Path, ADDR SndWBStep[12]
	invoke LoadAudio, ADDR SndWBBKPath, ADDR SndWBBK
	invoke LoadAudio, ADDR SndWhisperPath, ADDR SndWhisper
	invoke LoadAudio, ADDR SndWmblykPath, ADDR SndWmblyk
	invoke LoadAudio, ADDR SndWmblykBPath, ADDR SndWmblykB
	invoke LoadAudio, ADDR SndWmblykStrPath, ADDR SndWmblykStr
	invoke LoadAudio, ADDR SndWmblykStrMPath, ADDR SndWmblykStrM
	
	invoke LoadAudio, ADDR SndAmbW1Path, ADDR SndAmbW
	invoke LoadAudio, ADDR SndAmbW2Path, ADDR SndAmbW[4]
	invoke LoadAudio, ADDR SndAmbW3Path, ADDR SndAmbW[8]
	invoke LoadAudio, ADDR SndAmbW4Path, ADDR SndAmbW[12]
	
	invoke LoadAudio, ADDR SndMus1Path, ADDR SndMus1
	invoke alSourcef, SndMus1, AL_GAIN, flHalf
	invoke LoadAudio, ADDR SndMus2Path, ADDR SndMus2
	invoke alSourcef, SndMus2, AL_GAIN, flHalf
	invoke LoadAudio, ADDR SndMus3Path, ADDR SndMus3
	invoke alSourcef, SndMus3, AL_GAIN, 0
	invoke alSourcei, SndMus3, AL_LOOPING, AL_TRUE
	invoke LoadAudio, ADDR SndMus4Path, ADDR SndMus4
	invoke alSourcef, SndMus4, AL_GAIN, 0
	invoke alSourcei, SndMus4, AL_LOOPING, AL_TRUE
	invoke LoadAudio, ADDR SndMus5Path, ADDR SndMus5
	invoke alSourcef, SndMus5, AL_GAIN, flHalf
	
	invoke alSourcei, SndAlarm, AL_LOOPING, AL_TRUE
	invoke alSourcei, SndAmb, AL_LOOPING, AL_TRUE
	invoke alSourcei, SndAmbT, AL_LOOPING, AL_TRUE
	invoke alSourcei, SndEBD, AL_LOOPING, AL_TRUE
	invoke alSourcef, SndEBD, AL_ROLLOFF_FACTOR, fl4
	invoke alSourcei, SndEBDA, AL_LOOPING, AL_TRUE
	invoke alSourcei, SndDrip, AL_LOOPING, AL_TRUE
	invoke alSourcef, SndDrip, AL_ROLLOFF_FACTOR, fl2
	invoke alSourcei, SndHbd, AL_LOOPING, AL_TRUE
	invoke alSourcef, SndHbd, AL_ROLLOFF_FACTOR, fl3
	invoke alSourcei, SndKubale, AL_LOOPING, AL_TRUE
	invoke alSourcef, SndKubale, AL_GAIN, 0
	invoke alSourcef, SndKubaleAppear, AL_ROLLOFF_FACTOR, fl2
	invoke alSourcei, SndKubaleV, AL_LOOPING, AL_TRUE
	invoke alSourcef, SndKubaleV, AL_GAIN, 0
	invoke alSourcei, SndSiren, AL_LOOPING, AL_TRUE
	invoke alSourcef, SndSiren, AL_GAIN, 0
	invoke alSource3f, SndSlam, AL_POSITION, fl1, fl1, 0
	invoke alSourcei, SndTram, AL_LOOPING, AL_TRUE
	invoke alSourcef, SndTram, AL_ROLLOFF_FACTOR, fl1n5
	invoke alSourcef, SndTramClose, AL_ROLLOFF_FACTOR, fl1n5
	invoke alSourcef, SndTramOpen, AL_ROLLOFF_FACTOR, fl1n5
	invoke alSourcef, SndTramAnn, AL_ROLLOFF_FACTOR, fl3
	invoke alSourcef, SndTramAnn[4], AL_ROLLOFF_FACTOR, fl3
	invoke alSourcef, SndTramAnn[8], AL_ROLLOFF_FACTOR, fl3
	invoke alSourcef, SndVirdya, AL_GAIN, 0
	invoke alSourcei, SndVirdya, AL_LOOPING, AL_TRUE
	invoke alSourcei, SndWBBK, AL_LOOPING, AL_TRUE
	invoke alSourcef, SndWBBK, AL_ROLLOFF_FACTOR, fl10
	invoke alSourcef, SndWBAlarm, AL_ROLLOFF_FACTOR, fl1n5
	invoke alSourcef, SndWBIdle, AL_ROLLOFF_FACTOR, fl4
	invoke alSourcef, SndWBIdle[4], AL_ROLLOFF_FACTOR, fl4
	invoke alSourcef, SndWBStep, AL_ROLLOFF_FACTOR, fl3
	invoke alSourcef, SndWBStep[4], AL_ROLLOFF_FACTOR, fl3
	invoke alSourcef, SndWBStep[8], AL_ROLLOFF_FACTOR, fl3
	invoke alSourcef, SndWBStep[12], AL_ROLLOFF_FACTOR, fl3
	invoke alSourcei, SndWhisper, AL_LOOPING, AL_TRUE
	invoke alSourcef, SndWhisper, AL_ROLLOFF_FACTOR, fl2
	invoke alSourcei, SndWmblykB, AL_LOOPING, AL_TRUE
	invoke alSourcef, SndWmblykB, AL_ROLLOFF_FACTOR, fl4
	invoke alSourcei, SndWmblykStrM, AL_LOOPING, AL_TRUE
	invoke alSourcef, SndWmblykStrM, AL_GAIN, 0
	
	invoke alGetError
	print str$(eax), 13, 10
	
	invoke alSourcePlay, SndIntro
	ret
InitAudio ENDP

; Initialize OpenGL context
InitContext PROC WindowHandle:DWORD
	LOCAL PFD:PIXELFORMATDESCRIPTOR
	LOCAL PixelFormat:DWORD
	LOCAL testPerf:LARGE_INTEGER
	
	print "Initializing OpenGL drawing context...", 13, 10
	
	invoke GetDC, WindowHandle	; Get device context
	mov GDI, eax
	.IF GDI == 0
		invoke ErrorOut, ADDR ErrorDC
	.ENDIF
	
	mov PFD.nSize, SIZEOF PIXELFORMATDESCRIPTOR	; Fill PFD record
	mov PFD.nVersion, 1
	mov PFD.dwFlags, \
	PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER
	mov PFD.iPixelType, PFD_TYPE_RGBA
	mov PFD.cColorBits, 24
	mov PFD.cAccumBits, 0
	mov PFD.cStencilBits, 0
	mov PFD.iLayerType, PFD_MAIN_PLANE
	
	invoke ChoosePixelFormat, GDI, ADDR PFD
	mov PixelFormat, eax
	.IF PixelFormat == 0
		invoke ErrorOut, ADDR ErrorPF
	.ENDIF
	
	invoke SetPixelFormat, GDI, PixelFormat, ADDR PFD
	.IF eax == 0
		invoke ErrorOut, ADDR ErrorPFS
	.ENDIF
	
	invoke wglCreateContext, GDI
	mov GLC, eax
	.IF GLC == 0
		invoke ErrorOut, ADDR ErrorGLC
	.ENDIF
	
	invoke wglMakeCurrent, GDI, GLC
	.IF eax == 0
		invoke ErrorOut, ADDR ErrorGLCC
	.ENDIF
	
	;invoke glDrawBuffer, GL_FRONT_LEFT
	;invoke glReadBuffer, GL_FRONT_LEFT
	
	invoke glEnable, GL_CULL_FACE
	invoke glShadeModel, GL_SMOOTH
	invoke glEnable, GL_DEPTH_TEST
	invoke glDepthFunc, GL_LEQUAL
	
	invoke glEnable, GL_LIGHTING
	invoke glEnable, GL_LIGHT0
	invoke glLightfv, GL_LIGHT0, GL_SPECULAR, ADDR clGray
	invoke glLightf, GL_LIGHT0, GL_CONSTANT_ATTENUATION, fl1
	
	invoke glEnable, GL_FOG
	invoke glEnable, GL_TEXTURE_2D
	
	invoke glMaterialf, GL_FRONT, GL_SHININESS, flShine
	invoke glMaterialfv, GL_FRONT, GL_SPECULAR, ADDR clGray
	
	invoke QueryPerformanceFrequency, ADDR perfFreq
	.IF (perfFreq == 0)
		print "Performance frequency is 0, trying LARGE_INTEGER.", 13, 10
		invoke QueryPerformanceFrequency, ADDR testPerf
		m2m perfFreq, testPerf.LowPart
	.ENDIF
	print "Performance frequency "
	print sdword$(perfFreq), 13, 10
	
	ret
InitContext ENDP

; Handle key press (key down, key up)
KeyPress PROC Key:DWORD, State:BYTE
	LOCAL param:DWORD

	mov al, State
	.IF Key == 87
		mov keyUp, al
		ret
	.ELSEIF Key == 83
		mov keyDown, al
		ret
	.ELSEIF Key == 65
		mov keyLeft, al
		ret
	.ELSEIF Key == 68
		mov keyRight, al
		ret
	.ELSEIF Key == 17
		mov keyCtrl, al
		ret
	.ELSEIF Key == 13
		.IF (Shop == 2)
			.IF (Glyphs >= 5)
				sub Glyphs, 5
				mov Shop, 3
				invoke alSourcePlay, SndHbd
				invoke AlertWB, 3
				invoke alSource3f, SndDig, AL_POSITION, fl1N, 0, fl1
				invoke alSourcePlay, SndDig
				invoke alSourcePlay, SndMistake
				;mov al, Glyphs
				;sub al, 7
				;mov bl, -4
				;imul bl
				;mov GlyphOffset, al
				mov ShopKoluplyk, 80
				mov ShopTimer, 0
				m2m ShopWall, fl3
				mov Map, 1
				.IF (Glyphs == 0)
					invoke ShowSubtitles, ADDR CCGlyphNone
				.ELSE
					invoke ShowSubtitles, ADDR CCShopBuy
				.ENDIF
			.ELSE
				invoke ShowSubtitles, ADDR CCShopNo
			.ENDIF
		.ENDIF
		.IF (!State)
			.IF (MazeTramPlr == 1)
				mov MazeTramPlr, 2
			.ELSEIF (MazeTramPlr == 3)
				mov MazeTramPlr, 0
				fld MazeTramRot[4]
				fcos
				fmul fl2
				fsubr camPos
				fstp camPos
				m2m camPos[4], flCamHeight
			.ENDIF
		.ENDIF
		.IF (Checkpoint == 4)
			mov canControl, 0
			mov playerState, 3
			invoke alSourcePlay, SndExit
			mov Checkpoint, 3
		.ENDIF
		.IF (Save == 2)
			invoke alSourcePlay, SndDistress
			invoke EraseSave
		.ENDIF
		ret
	.ELSEIF Key == 27
		.IF (playerState >= 11) && (playerState <= 17) && (MazeHostile != 11)
			invoke alSourceStop, SndIntro
			invoke alSourcePlay, SndSiren
			mov MazeHostile, 0
			mov playerState, 1
			; Something is incredibly fucked up either here or (more likely) in 
			; the FinishMazeGeneration function where it checks for the top wall
			; at [0, 1]. Removing (or keeping) conditional debug code and even
			; some comments may result in arbitrary crashes and I don't know why
			invoke GetTickCount
			invoke GenerateMaze, eax
			ret
		.ENDIF
		.IF (State)
			.IF (MazeNote > 16)
				mov MazeNote, 0
				mov canControl, 1
				ret
			.ENDIF
			invoke DoMenu
		.ENDIF
	.ELSEIF Key == 115
		.IF (!State)
			mov al, fullscreen
			not al
			mov fullscreen, al
			invoke SetFullscreen, fullscreen
		.ENDIF
		ret
	.ELSEIF Key == 32
		.IF (keySpace != al) && (Menu == 0)
			mov al, State
			mov keySpace, al
			.IF (State) && (playerState != 9) && (playerState != 10)
				fild MazeLevel
				fsqrt
				fdivr fl04
				fadd wmblykStr
				fstp wmblykStr
			.ENDIF
		.ENDIF
		ret
	.ELSEIF Key == 71
		.IF (State) && (canControl) && (Maze) && (MazeTramPlr < 2)
			.IF (Glyphs != 0)
				dec Glyphs
				xor eax, eax
				mov al, GlyphsInLayer
				
				mov ebx, 8
				mul ebx
				m2m GlyphPos[eax], camPosN
				m2m GlyphPos[eax+4], camPosN[4]
				
				invoke nrandom, 360
				mov param, eax
				
				xor eax, eax
				mov al, GlyphsInLayer
				mov ebx, 4
				mul ebx
				
				fild param
				fstp GlyphRot[eax]
				
				inc GlyphsInLayer
				invoke alSourcePlay, SndScribble
				invoke AlertWB, 2
				.IF (Glyphs == 0)
					invoke alSourcePlay, SndMistake
				.ENDIF
			.ENDIF
			.IF (Glyphs == 0)
				invoke ShowSubtitles, ADDR CCGlyphNone
			.ELSE
				mov al, Glyphs
				add al, 48
				mov CCGlyph[14], al
				invoke ShowSubtitles, ADDR CCGlyph
			.ENDIF
		.ENDIF
		ret
	; DEBUG BINDINGS FOR TESTING
	.ELSEIF Key == 70
		.IF (debugF != al)
			mov debugF, al
			.IF (debugF)
				invoke alSourcef, SndAlarm, AL_PITCH, fl4
				invoke alSourcef, SndAmb, AL_PITCH, fl4
				invoke alSourcef, SndExplosion, AL_PITCH, fl4
				invoke alSourcef, SndExit, AL_PITCH, fl4
				invoke alSourcef, SndImpact, AL_PITCH, fl4
				invoke alSourcef, SndIntro, AL_PITCH, fl4
				invoke alSourcef, SndKubaleAppear, AL_PITCH, fl4
				invoke alSourcef, SndMus1, AL_PITCH, fl4
				invoke alSourcef, SndMus5, AL_PITCH, fl4
				invoke alSourcef, SndSiren, AL_PITCH, fl4
			.ELSE
				invoke alSourcef, SndAlarm, AL_PITCH, fl1
				invoke alSourcef, SndAmb, AL_PITCH, fl1
				invoke alSourcef, SndExplosion, AL_PITCH, fl1
				invoke alSourcef, SndExit, AL_PITCH, fl1
				invoke alSourcef, SndImpact, AL_PITCH, fl1
				invoke alSourcef, SndIntro, AL_PITCH, fl1
				invoke alSourcef, SndKubaleAppear, AL_PITCH, fl1
				invoke alSourcef, SndMus1, AL_PITCH, fl1
				invoke alSourcef, SndMus5, AL_PITCH, fl1
				invoke alSourcef, SndSiren, AL_PITCH, fl1
			.ENDIF
		.ENDIF
		ret
	.ELSEIF Key == 69
		.IF (State == 0)
			print "Spawned Eblodryn", 13, 10
			mov EBD, 1
			invoke GetRandomMazePosition, ADDR EBDPos, ADDR EBDPos[4]
			invoke alSource3f, SndEBD, AL_POSITION, EBDPos, 0, EBDPos[4]
			invoke alSourcef, SndEBDA, AL_GAIN, 0
			invoke alSourcePlay, SndEBD
			invoke alSourcePlay, SndEBDA
		.ENDIF
		ret
	.ELSEIF Key == 84
		.IF (State == 0)
			fld MazeDoorPos
			fstp camPos
			fld MazeDoorPos[4]
			fstp camPos[8]
		.ENDIF
		ret
	.ELSEIF Key == 85
		.IF (State == 0)
			mov EBD, 1
		.ENDIF
		ret
	.ELSEIF Key == 75
		.IF (State == 0)
			m2m kubaleDir, fl1
			mov kubale, 1
		.ENDIF
		ret
	.ELSEIF Key == 219
		.IF (State == 0)
			inc MazeW
		.ENDIF
		ret
	.ELSEIF Key == 221
		.IF (State == 0)
			inc MazeH
		.ENDIF
		ret
	.ELSEIF Key == 220
		.IF (State == 0)
			invoke WBCreate
		.ENDIF
		ret
	.ELSEIF Key == 117
		.IF (State == 0)
			invoke SaveGame
		.ENDIF
		ret
	.ELSEIF Key == 89
		.IF (State == 0)
			.IF !(wmblyk)
				m2m wmblykPos, fl1
				m2m wmblykPos[4], fl1
			.ENDIF
			mov wmblyk, 11
			invoke alSourcePlay, SndWmblykB
			mov wmblykAnim, 11
			mov wmblykBlink, 0
		.ENDIF
		ret
	.ELSEIF Key == 66
		.IF (State == 0)
			mov Glyphs, 7
		.ENDIF
		ret
	.ELSEIF Key == 78
		.IF (State == 0)
			mov hbd, 0
			mov kubale, 0
			mov wmblyk, 0
		.ENDIF
		ret
	.ELSEIF Key == 67
		.IF (State == 0)
			mov Compass, 2
			mov MazeLocked, 2
		.ENDIF
		ret
	.ELSEIF Key == 73
		.IF (State == 0)
			invoke alSourceStop, SndSiren
			invoke alSourcePlay, SndAmb
			mov MazeHostile, 1
		.ENDIF
		ret
	.ELSEIF Key == 88
		.IF (State == 0)
			fld1
			fchs
			fstp camPos
			fld1
			fchs
			fstp camPos[8]
		.ENDIF
	.ELSEIF Key == 90
		.IF (State == 0)
			inc MazeLevel
			print str$(MazeLevel), 13, 10
		.ENDIF
	.ELSEIF Key == 190
		.IF (State == 0)
			add MazeLevel, 5
			print str$(MazeLevel), 13, 10
		.ENDIF
	.ELSEIF Key == 188
		.IF (State == 0)
			sub MazeLevel, 5
			print str$(MazeLevel), 13, 10
		.ENDIF
	.ELSEIF Key == 86
		.IF (State == 0)
			m2m virdyaPos, camPosN
			m2m virdyaPos[4], camPosN[4]
			mov virdya, 67
			invoke alSourcePlay, SndVirdya
			mov Vebra, 133
		.ENDIF
	.ENDIF
	
	ret
KeyPress ENDP

; Check if the game was saved and load it
LoadGame PROC
	LOCAL pcbData:DWORD, tempLevel:DWORD
	
	invoke RegCreateKeyExA, HKEY_CURRENT_USER, ADDR RegPath, 0, NULL, \
	REG_OPTION_NON_VOLATILE, KEY_READ, NULL, ADDR defKey, NULL
	.IF (eax != ERROR_SUCCESS)
		print "Failed to create registry key.", 13, 10
		ret
	.ENDIF
	
	mov pcbData, 4
	invoke RegQueryValueExA, defKey, ADDR RegCurLayer, 0, NULL, \
	ADDR MazeLevel, ADDR pcbData
	.IF (eax == ERROR_SUCCESS)	; Load temporary progress
		invoke RegQueryValueExA, defKey, ADDR RegCurWidth, 0, NULL, \
		ADDR MazeW, ADDR pcbData
		invoke RegQueryValueExA, defKey, ADDR RegCurHeight, 0, NULL, \
		ADDR MazeH, ADDR pcbData
		
		invoke RegCloseKey, defKey
		
		invoke ShowSubtitles, ADDR CCLoad
		invoke alSourcePlay, SndDistress
		invoke alSourcePlay, SndAmb
		
		dec MazeLevel
		
		invoke nrandom, 5
		.IF (!eax) && (MazeLevel > 1)
			dec MazeLevel
		.ENDIF
		mov MazeHostile, 1
		
		invoke GetTickCount
		mov MazeSeed, eax
		invoke GenerateMaze, MazeSeed	; This reopens and closes the registry
		
		invoke GetRandomMazePosition, ADDR camPosN, ADDR camPosN[4]
		fld camPosN
		fst camPosNext
		fchs
		fst camPosL
		fstp camPos
		fld camPosN[4]
		fst camPosNext[8]
		fchs
		fst camPosL[8]
		fstp camPos[8]
	.ELSE	; Load from checkpoint
		invoke RegQueryValueExA, defKey, ADDR RegLayer, 0, NULL, \
		ADDR MazeLevel, ADDR pcbData
		.IF (eax != ERROR_SUCCESS)
			print "Failed to read layer value (DWORD).", 13, 10
			print str$(MazeLevel), 13, 10
			ret
		.ENDIF
	
		invoke RegQueryValueExA, defKey, ADDR RegFloor, 0, NULL, \
		ADDR CurrentFloor, ADDR pcbData
		invoke RegQueryValueExA, defKey, ADDR RegWall, 0, NULL, \
		ADDR CurrentWall, ADDR pcbData
		invoke RegQueryValueExA, defKey, ADDR RegRoof, 0, NULL, \
		ADDR CurrentRoof, ADDR pcbData
		invoke RegQueryValueExA, defKey, ADDR RegMazeW, 0, NULL, \
		ADDR MazeW, ADDR pcbData
		invoke RegQueryValueExA, defKey, ADDR RegMazeH, 0, NULL, \
		ADDR MazeH, ADDR pcbData
		
		invoke RegCloseKey, defKey
		
		invoke alSourcePlay, SndMus3
		mov Checkpoint, 3
		mov Save, 1
		mov MazeHostile, 1
		
		m2m camPos, fl1N
		m2m camPosL, fl1N
		fld fl3
		fchs
		fstp camPos[8]
		
		m2m MazeDoorPos, fl1N
		fld fl5
		fchs
		fstp MazeDoorPos[4]
	.ENDIF
	
	invoke RegCreateKeyExA, HKEY_CURRENT_USER, ADDR RegPath, 0, NULL, \
	REG_OPTION_NON_VOLATILE, KEY_READ, NULL, ADDR defKey, NULL
	mov pcbData, 1
	invoke RegQueryValueExA, defKey, ADDR RegCompass, 0, NULL, \
	ADDR Compass, ADDR pcbData
	invoke RegQueryValueExA, defKey, ADDR RegGlyphs, 0, NULL, \
	ADDR Glyphs, ADDR pcbData
	invoke RegCloseKey, defKey
	
	invoke SetCursorPos, winCX, winCY
	mov camRot, 0
	invoke SetMazeLevelStr, str$(MazeLevel)
	m2m MazeLevelPopupTimer, fl2
	mov MazeLevelPopup, 1
	
	invoke alSourceStop, SndIntro
	mov playerState, 2
	mov fadeState, 1
	ret
LoadGame ENDP

; Handle mouse movement (pos)
MouseMove PROC
	LOCAL winCYB:SWORD
	
	fild mousePos
	fstp msX
	fild mousePos[2]
	fstp msY
		
	mov ax, mousePos	; X mouse = Y cam
	add ax, winX
	sub ax, winCX
	mov mouseRel, ax
	
	mov ax, mousePos[2]	; Y mouse = X cam
	add ax, winY
	sub ax, winCY
	mov mouseRel[2], ax
	
	m2m winCYB, winCY
	add winCYB, 64
	
	.IF (!focused) || (!canControl)
		ret
	.ENDIF
	
	fild mouseRel
	fmul camTurnSpeed
	fmul deltaTime
	fsubr camRot[4]
	fstp camRot[4]
	
	fild mouseRel[2]
	fmul camTurnSpeed
	fmul deltaTime
	fadd camRot
	fstp camRot
	
	; Loop the direction once it has rotated fully
	invoke Angleify, ADDR camRot[4]
	invoke Angleify, ADDR camRotL[4]
	ret
MouseMove ENDP

; A unified collision algorithm for multiple entities
MoveAndCollide PROC PosXPtr:DWORD, PosYPtr:DWORD, SpeedXPtr:DWORD, SpeedYPtr:DWORD, WallSize:REAL4, Bounce:BYTE
	LOCAL PosXF:REAL4, PosYF:REAL4, SpdXF:REAL4, SpdYF:REAL4
	LOCAL NextPosX:REAL4, NextPosY:REAL4, DistanceX:REAL4, DistanceY:REAL4
	LOCAL MazePosX:DWORD, MazePosY:DWORD, CellCntX:REAL4, CellCntY:REAL4
	LOCAL SideX:REAL4, SideY:REAL4
	LOCAL Collided:DWORD, ColX:BYTE, ColY:BYTE
	
	mov eax, PosXPtr
	m2m PosXF, REAL4 PTR [eax]
	mov eax, PosYPtr
	m2m PosYF, REAL4 PTR [eax]
	mov eax, SpeedXPtr
	m2m SpdXF, REAL4 PTR [eax]
	mov eax, SpeedYPtr
	m2m SpdYF, REAL4 PTR [eax]

	fld PosXF	; Get next position
	fsub SpdXF
	fstp NextPosX
	fld PosYF
	fsub SpdYF
	fstp NextPosY
	
	; Collide with maze (janky, but that's a feature)
	invoke GetMazeCellPos, NextPosX, NextPosY, ADDR MazePosX, ADDR MazePosY
	
	fild MazePosX	; Get maze cell center
	fmul fl2
	fadd fl1
	fstp CellCntX
	fild MazePosY
	fmul fl2
	fadd fl1
	fstp CellCntY
	
	mov Collided, 0
	
	; Spaghetti
	fld NextPosX	; Get distance to cell center and act
	fsub CellCntX
	fst CellCntX
	fabs
	fstp DistanceX
	
	fld NextPosY
	fsub CellCntY
	fst CellCntY
	fabs
	fstp DistanceY
	
	mov ColX, 0
	mov ColY, 0
	
	fcmp DistanceX, WallSize
	.IF !Sign?
		fcmp CellCntX
		.IF Sign?
			invoke GetCellMZC, MazePosX, MazePosY, MZC_PASSLEFT
			.IF !(al)	; Collides X-
				inc ColX
			.ELSEIF (!Bounce)	; Check corners
				fcmp DistanceY, WallSize
				.IF (!Sign?) && (MazePosX > 0)
					mov ebx, MazePosY
					fcmp CellCntY
					.IF Sign? && (ebx > 0)
						dec MazePosY
						invoke GetCellMZC, MazePosX, MazePosY, MZC_PASSLEFT
						inc MazePosY
						.IF !(al)	; Collides Y- left
							inc ColY
						.ENDIF
					.ELSEIF (ebx < MazeHM1)
						inc MazePosY
						invoke GetCellMZC, MazePosX, MazePosY, MZC_PASSLEFT
						dec MazePosY
						.IF !(al)	; Collides Y+ left
							inc ColY
						.ENDIF
					.ENDIF
				.ENDIF
			.ENDIF
		.ELSE
			inc MazePosX
			invoke GetCellMZC, MazePosX, MazePosY, MZC_PASSLEFT
			.IF !(al)	; Collides X+
				inc ColX
			.ELSEIF (!Bounce)	; Check corners
				mov ebx, MazePosX
				fcmp DistanceY, WallSize
				.IF (!Sign?) && (ebx < MazeWM1)
					mov ebx, MazePosY
					fcmp CellCntY
					.IF Sign? && (ebx > 0)
						dec MazePosY
						invoke GetCellMZC, MazePosX, MazePosY, MZC_PASSLEFT
						inc MazePosY
						.IF !(al)	; Collides Y- left
							inc ColY
						.ENDIF
					.ELSEIF (ebx < MazeHM1)
						inc MazePosY
						invoke GetCellMZC, MazePosX, MazePosY, MZC_PASSLEFT
						dec MazePosY
						.IF !(al)	; Collides Y- left
							inc ColY
						.ENDIF
					.ENDIF
				.ENDIF
			.ENDIF
			dec MazePosX
		.ENDIF
	.ENDIF
	
	fcmp DistanceY, WallSize
	.IF !Sign?
		fcmp CellCntY
		.IF Sign?
			invoke GetCellMZC, MazePosX, MazePosY, MZC_PASSTOP
			.IF !(al)	; Collides Y-
				inc ColY
			.ELSEIF (!Bounce)	; Check corners
				fcmp DistanceX, WallSize
				.IF (!Sign?) && (MazePosY > 0)
					mov ebx, MazePosX
					fcmp CellCntX
					.IF Sign? && (ebx > 0)
						dec MazePosX
						invoke GetCellMZC, MazePosX, MazePosY, MZC_PASSTOP
						inc MazePosX
						.IF !(al)	; Collides X- left
							inc ColX
						.ENDIF
					.ELSEIF (ebx < MazeWM1)
						inc MazePosX
						invoke GetCellMZC, MazePosX, MazePosY, MZC_PASSTOP
						dec MazePosX
						.IF !(al)	; Collides X+ left
							inc ColX
						.ENDIF
					.ENDIF
				.ENDIF
			.ENDIF
		.ELSE
			inc MazePosY
			invoke GetCellMZC, MazePosX, MazePosY, MZC_PASSTOP
			.IF !(al)	; Collides Y+
				inc ColY
			.ELSEIF (!Bounce)	; Check corners
				mov ebx, MazePosY
				fcmp DistanceX, WallSize
				.IF (!Sign?) && (ebx < MazeHM1)
					mov ebx, MazePosX
					fcmp CellCntX
					.IF Sign? && (ebx > 0)
						dec MazePosX
						invoke GetCellMZC, MazePosX, MazePosY, MZC_PASSTOP
						inc MazePosX
						.IF !(al)	; Collides X- left
							inc ColX
						.ENDIF
					.ELSEIF (ebx < MazeHM1)
						inc MazePosX
						invoke GetCellMZC, MazePosX, MazePosY, MZC_PASSTOP
						dec MazePosX
						.IF !(al)	; Collides X- left
							inc ColX
						.ENDIF
					.ENDIF
				.ENDIF
			.ENDIF
		.ENDIF
	.ENDIF
	
	.IF (MazeCrevice)
		.IF (!ColX) && (!ColY)
			fild MazeCrevicePos
			fmul fl2
			fst CellCntX
			fsub WallSize
			fstp MazePosX
			fild MazeCrevicePos[4]
			fmul fl2
			fst CellCntY
			fsub WallSize
			fstp MazePosY
			fld CellCntX
			fadd flWLn
			fstp CellCntX
			fld CellCntY
			fadd flWLn
			fstp CellCntY
			invoke InRange, NextPosX, NextPosY, \
			MazePosX, CellCntX, MazePosY, CellCntY
			.IF (al)
				mov ColX, 1
				mov ColY, 1
			.ENDIF
		.ENDIF
	.ENDIF
	
	.IF (ColX)
		.IF (Bounce)
			fld SpdXF
			fchs
		.ELSE
			fldz
		.ENDIF
		fstp SpdXF
		inc Collided
	.ENDIF
	.IF (ColY)
		.IF (Bounce)
			fld SpdYF
			fchs
		.ELSE
			fldz
		.ENDIF
		fstp SpdYF
		inc Collided
	.ENDIF
	
	fld PosXF	; Move
	fsub SpdXF
	fstp PosXF
	fld PosYF
	fsub SpdYF
	fstp PosYF
	
	mov eax, PosXPtr
	m2m REAL4 PTR [eax], PosXF
	mov eax, PosYPtr
	m2m REAL4 PTR [eax], PosYF
	mov eax, SpeedXPtr
	m2m REAL4 PTR [eax], SpdXF
	mov eax, SpeedYPtr
	m2m REAL4 PTR [eax], SpdYF
	
	mov eax, Collided
	ret
MoveAndCollide ENDP

; Process Windows messages sent to the settings window
SettingsProc PROC hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	LOCAL tempDW:DWORD

	.IF (uMsg == WM_CREATE)
		invoke SetWindowPos, hWnd, HWND_TOPMOST, 0, 0, 0, 0, \
		SWP_FRAMECHANGED or SWP_SHOWWINDOW or SWP_NOSIZE or SWP_NOMOVE
	.ELSEIF (uMsg == WM_DESTROY)
		.IF (Menu == 2)
			invoke DoMenu
		.ENDIF
	.ELSEIF uMsg==WM_COMMAND
		.IF (wParam == 100)
			invoke EnableWindow, stResolCombo, 1
			invoke IsDlgButtonChecked, stHwnd, wParam
			lea ebx, IniFalse
			push eax
			.IF (al)
				invoke EnableWindow, stResolCombo, 0
				lea ebx, IniTrue
			.ENDIF
			invoke WritePrivateProfileStringA, ADDR IniGraphics, \
			ADDR IniFullscreen, ebx, ADDR IniPathAbs
			pop eax
			invoke SetFullscreen, al
		.ELSEIF (wParam == 115)
			invoke DestroyWindow, stHwnd
		.ELSE
			mov eax, wParam
			shr eax, 16
			.IF (ax == CBN_SELCHANGE)
				mov eax, wParam
				.IF (ax == 102)		; Resolution selector
					invoke SendMessage, lParam, CB_GETCURSEL, 0, 0
					invoke SendMessage, lParam, CB_GETLBTEXT, eax, ADDR SettStr
					xor ebx, ebx
					lea eax, SettStr
					.WHILE TRUE
						inc ebx
						.IF (BYTE PTR [eax+ebx] == 120) || (!BYTE PTR [eax+ebx])
							mov BYTE PTR [eax+ebx], 0	; End the width string
							.BREAK
						.ENDIF
					.ENDW
					inc ebx
					
					invoke WritePrivateProfileStringA, ADDR IniGraphics, \
					ADDR IniWidth, ADDR SettStr, ADDR IniPathAbs
					lea eax, SettStr
					add eax, ebx
					invoke WritePrivateProfileStringA, ADDR IniGraphics, \
					ADDR IniHeight, eax, ADDR IniPathAbs
					
					invoke GetSettings	; Don't wanna write an int parser
				.ELSEIF (ax == 109)	; Joystick
					invoke SendMessage, lParam, CB_GETCURSEL, 0, 0
					dec eax
					invoke IntToStr, ADDR SettStr, eax
					invoke WritePrivateProfileStringA, ADDR IniControls, \
					ADDR IniJoystickID, ADDR SettStr, ADDR IniPathAbs
					
					invoke GetSettings
				.ENDIF
			.ENDIF
		.ENDIF
	.ELSEIF uMsg==WM_HSCROLL
		mov eax, lParam
		.IF (eax == stBrigTrack)
			invoke SendMessage, stBrigTrack, TBM_GETPOS, 0, 0
			
			mov tempDW, eax
			fild tempDW
			fmul flHundredth
			fstp Gamma
			
			invoke FltDWToStr, ADDR SettStr, tempDW
			invoke WritePrivateProfileStringA, ADDR IniGraphics, \
			ADDR IniBrightness, ADDR SettStr, ADDR IniPathAbs
		.ELSEIF (eax == stMSensTrack)
			invoke SendMessage, stMSensTrack, TBM_GETPOS, 0, 0
			
			mov tempDW, eax
			fild tempDW
			fmul flHundredth
			fstp camTurnSpeed
			
			invoke FltDWToStr, ADDR SettStr, tempDW
			invoke WritePrivateProfileStringA, ADDR IniControls, \
			ADDR IniMouseSensitivity, ADDR SettStr, ADDR IniPathAbs
		.ELSEIF (eax == stJSensTrack)
			invoke SendMessage, stJSensTrack, TBM_GETPOS, 0, 0
			
			mov tempDW, eax
			fild tempDW
			fmul flHundredth
			fstp camJoySpeed
			
			invoke FltDWToStr, ADDR SettStr, tempDW
			invoke WritePrivateProfileStringA, ADDR IniControls, \
			ADDR IniJoystickSensitivity, ADDR SettStr, ADDR IniPathAbs
		.ELSEIF (eax == stVolTrack)
			invoke SendMessage, stVolTrack, TBM_GETPOS, 0, 0
			
			mov tempDW, eax
			push tempDW
			
			fild tempDW
			fmul flHundredth
			fstp tempDW
			
			invoke alListenerf, AL_GAIN, tempDW
			
			pop tempDW
			
			invoke FltDWToStr, ADDR SettStr, tempDW
			invoke WritePrivateProfileStringA, ADDR IniAudio, \
			ADDR IniVolume, ADDR SettStr, ADDR IniPathAbs
		.ENDIF
	.ENDIF

	invoke DefWindowProc, hWnd, uMsg, wParam, lParam
	ret
SettingsProc ENDP
; Create settings window
OpenSettings PROC
	LOCAL wc:WNDCLASSEX, msg:MSG, font:HFONT
	LOCAL maxW:DWORD, scrW:DWORD, scrH:DWORD
	LOCAL dm:DEVMODEA
	
	print "Creating settings window...", 13, 10
	
	mov	  wc.cbSize, SIZEOF WNDCLASSEX	; Fill WNDCLASSEX record
	mov	  wc.style, CS_HREDRAW or CS_VREDRAW
	mov	  wc.lpfnWndProc, OFFSET SettingsProc
	mov	  wc.cbClsExtra, NULL
	mov	  wc.cbWndExtra, NULL
	m2m	  wc.hInstance, hInstance
	mov	  wc.hbrBackground, COLOR_WINDOW
	mov	  wc.lpszMenuName, NULL
	mov	  wc.lpszClassName, OFFSET ClassSett
	invoke GetModuleHandle, NULL
	invoke LoadIcon, eax, 500
	mov	  wc.hIcon, eax
	mov	  wc.hIconSm, eax
	invoke LoadCursor, NULL, IDC_ARROW
	mov	  wc.hCursor, eax
	
	invoke RegisterClassEx, ADDR wc	; Register the window class
	
	; Commence
	invoke CreateWindowEx, 0, ADDR ClassSett, ADDR MenuSettings, \
	WS_POPUPWINDOW or WS_CAPTION, CW_USEDEFAULT, CW_USEDEFAULT, \
	200, 346, hwnd, NULL, hInstance, NULL
	mov stHwnd, eax
	
	mov maxW, 200
	xor eax, eax
	invoke GetSystemMetrics, SM_CXSIZEFRAME
	add ax, ax
	sub maxW, eax
	sub maxW, 6
	
	invoke ShowCursor, 1
	invoke ShowWindow, stHwnd, SW_SHOWDEFAULT
	
	; Create all elements
	invoke CreateWindowEx, NULL, ADDR ClassButton, ADDR MenuFullscreen, \
	WS_CHILD or WS_VISIBLE or BS_AUTOCHECKBOX or BS_LEFTTEXT, 4, 6, maxW, 15, \
	stHwnd, 100, hInstance, NULL
	mov stFullCheck, eax
	invoke SendMessage, stFullCheck, BM_SETCHECK, fullscreen, 0
	
	invoke CreateWindowEx, NULL, ADDR ClassStatic, ADDR MenuResolution, \
	WS_CHILD or WS_VISIBLE, 6, 26, maxW, 15, \
	stHwnd, NULL, hInstance, NULL
	mov stResolLabel, eax
	invoke CreateWindowEx, NULL, ADDR ClassCombo, NULL, \
	WS_CHILD or WS_VISIBLE or CBS_DROPDOWNLIST or CBS_HASSTRINGS or WS_VSCROLL,\
	6, 42, maxW, 256, stHwnd, 102, hInstance, NULL
	mov stResolCombo, eax
	invoke CreateWindowEx, NULL, ADDR ClassStatic, ADDR MenuBrightness, \
	WS_CHILD or WS_VISIBLE, 6, 66, maxW, 20, stHwnd, NULL, hInstance, NULL
	mov stBrigLabel, eax
	invoke CreateWindowEx, NULL, ADDR ClassTrackbar, NULL, \
	WS_CHILD or WS_VISIBLE, 6, 82, maxW, 20, \
	stHwnd, 104, hInstance, NULL
	mov stBrigTrack, eax
	
	invoke CreateWindowEx, NULL, ADDR ClassStatic, NULL, \
	WS_CHILD or WS_VISIBLE or SS_SUNKEN, 6, 108, maxW, 2, stHwnd, NULL, \
	hInstance, NULL
	
	invoke CreateWindowEx, NULL, ADDR ClassStatic, ADDR MenuMouseSensitivity, \
	WS_CHILD or WS_VISIBLE, 6, 116, maxW, 15, stHwnd, NULL, hInstance, NULL
	mov stMSensLabel, eax
	invoke CreateWindowEx, NULL, ADDR ClassTrackbar, NULL,\
	WS_CHILD or WS_VISIBLE, 6, 132, maxW, 20, \
	stHwnd, 107, hInstance, NULL
	mov stMSensTrack, eax
	
	invoke CreateWindowEx, NULL, ADDR ClassStatic, ADDR MenuJoystick, \
	WS_CHILD or WS_VISIBLE, 6, 156, maxW, 15, stHwnd, NULL, hInstance, NULL
	mov stJoyLabel, eax
	invoke CreateWindowEx, NULL, ADDR ClassCombo, NULL, \
	WS_CHILD or WS_VISIBLE or CBS_DROPDOWNLIST or CBS_HASSTRINGS or WS_VSCROLL,\
	6, 172, maxW, 256, stHwnd, 109, hInstance, NULL
	mov stJoyCombo, eax
	invoke CreateWindowEx, NULL, ADDR ClassStatic,ADDR MenuJoystickSensitivity,\
	WS_CHILD or WS_VISIBLE, 6, 196, maxW, 15, stHwnd, NULL, hInstance, NULL
	mov stJSensLabel, eax
	invoke CreateWindowEx, NULL, ADDR ClassTrackbar, NULL,\
	WS_CHILD or WS_VISIBLE, 6, 212, maxW, 20, \
	stHwnd, 111, hInstance, NULL
	mov stJSensTrack, eax
	
	invoke CreateWindowEx, NULL, ADDR ClassStatic, NULL, \
	WS_CHILD or WS_VISIBLE or SS_SUNKEN, 6, 238, maxW, 2, stHwnd, NULL, \
	hInstance, NULL
	
	invoke CreateWindowEx, NULL, ADDR ClassStatic, ADDR MenuAudioVolume, \
	WS_CHILD or WS_VISIBLE, 6, 246, maxW, 15, stHwnd, NULL, hInstance, NULL
	mov stVolLabel, eax
	invoke CreateWindowEx, NULL, ADDR ClassTrackbar, NULL,\
	WS_CHILD or WS_VISIBLE, 6, 262, maxW, 20, \
	stHwnd, 114, hInstance, NULL
	mov stVolTrack, eax
	
	invoke CreateWindowEx, NULL, ADDR ClassButton, ADDR MenuOK, \
	WS_CHILD or WS_VISIBLE, 64, 286, 64, 24, \
	stHwnd, 115, hInstance, NULL
	mov stOkBtn, eax
	
	; Populate resolution combobox
	mov dm.dmSize, SIZEOF DEVMODEA
	mov maxW, 0		; Corresponding resolution index
	mov scrW, 0
	mov scrH, 0
	xor ebx, ebx
	RESENUM:
	invoke EnumDisplaySettingsA, NULL, ebx, ADDR dm
	.IF (eax)
		mov eax, dm.dmPelsWidth
		mov ecx, dm.dmPelsHeight
		.IF (scrW != eax) || (scrH != ecx)
			invoke RtlZeroMemory, ADDR SettStr, 16
			invoke IntToStr, ADDR SettStr, dm.dmPelsWidth
			lea ecx, SettStr
			add eax, ecx
			mov BYTE PTR [eax], 120	; 'x'
			inc eax
			invoke IntToStr, eax, dm.dmPelsHeight
			invoke SendMessage, stResolCombo, CB_ADDSTRING, 0, ADDR SettStr
			m2m scrW, dm.dmPelsWidth
			m2m scrH, dm.dmPelsHeight
			mov eax, dm.dmPelsWidth
			mov ecx, dm.dmPelsHeight
			.IF (winWS == ax) && (winHS == cx)
				invoke SendMessage, stResolCombo, CB_SETCURSEL, maxW, 0
			.ENDIF
			inc maxW
		.ENDIF
		inc ebx
		jmp RESENUM
	.ENDIF
	.IF (fullscreen)
		invoke EnableWindow, stResolCombo, 0
	.ENDIF
	
	; Populate joystick combobox
	invoke SendMessage, stJoyCombo, CB_ADDSTRING, 0, ADDR MenuDisabled
	invoke joyGetNumDevs
	mov maxW, eax
	xor ebx, ebx
	.WHILE (ebx < maxW)
		invoke joyGetDevCapsA, ebx, ADDR joyCaps, SIZEOF JOYCAPSAFIX
		.IF (eax == JOYERR_NOERROR)
			invoke SendMessage, stJoyCombo, CB_ADDSTRING, 0, ADDR joyCaps.szPname
		.ENDIF
		inc ebx
	.ENDW
	mov eax, joystickID
	inc eax
	invoke SendMessage, stJoyCombo, CB_SETCURSEL, eax, 0
	
	; Configure trackbars
	invoke SendMessage, stBrigTrack, TBM_SETRANGE, TRUE, 6553600	; 0 - 100
	invoke SendMessage, stMSensTrack, TBM_SETRANGE, TRUE, 6553600
	invoke SendMessage, stJSensTrack, TBM_SETRANGE, TRUE, 45875200	; 0 - 700
	invoke SendMessage, stVolTrack, TBM_SETRANGE, TRUE, 13107200	; 0 - 200
	fld Gamma
	fmul fl100
	fistp maxW
	invoke SendMessage, stBrigTrack, TBM_SETPOS, TRUE, maxW
	fld camTurnSpeed
	fmul fl100
	fistp maxW
	invoke SendMessage, stMSensTrack, TBM_SETPOS, TRUE, maxW
	fld camJoySpeed
	fmul fl100
	fistp maxW
	invoke SendMessage, stJSensTrack, TBM_SETPOS, TRUE, maxW
	invoke alGetListenerf, AL_GAIN, ADDR maxW
	fld maxW
	fmul fl100
	fistp maxW
	invoke SendMessage, stVolTrack, TBM_SETPOS, TRUE, maxW
	
	; Set font
	invoke CreateFont, 15, 0, 0, 0, FW_DONTCARE, FALSE, FALSE, FALSE, \
	ANSI_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, \
	DEFAULT_PITCH or FF_DONTCARE, ADDR FontName
	mov font, eax
	invoke SendMessage, stFullCheck, WM_SETFONT, font, TRUE
	invoke SendMessage, stResolLabel, WM_SETFONT, font, TRUE
	invoke SendMessage, stResolCombo, WM_SETFONT, font, TRUE
	invoke SendMessage, stBrigLabel, WM_SETFONT, font, TRUE
	invoke SendMessage, stMSensLabel, WM_SETFONT, font, TRUE
	invoke SendMessage, stJoyLabel, WM_SETFONT, font, TRUE
	invoke SendMessage, stJoyCombo, WM_SETFONT, font, TRUE
	invoke SendMessage, stJSensLabel, WM_SETFONT, font, TRUE
	invoke SendMessage, stVolLabel, WM_SETFONT, font, TRUE
	invoke SendMessage, stOkBtn, WM_SETFONT, font, TRUE
	ret
OpenSettings ENDP

; Process and draw Shnurpshik
ProcessShn PROC
	LOCAL fltVal:REAL4, teleportAttempts:BYTE

	fld ShnTimer
	fsub deltaTime
	fstp ShnTimer
	fcmp ShnTimer
	.IF (Sign?)
		.IF (Shn == 1)
			invoke ShowSubtitles, ADDR CCShn1
			m2m ShnTimer, fl48
			mov Shn, 2
		.ELSEIF (Shn == 2)
			invoke ShowSubtitles, ADDR CCShn2
			invoke alSourcef, SndAlarm, AL_GAIN, 0
			invoke alSourcePlay, SndAlarm
			m2m ShnTimer, fl48
			mov Shn, 3
		.ELSEIF (Shn == 3)
			invoke ShowSubtitles, ADDR CCShn3
			invoke alSourcef, SndAlarm, AL_GAIN, fl1
			invoke alSourcePlay, SndAlarm
			invoke alSourcePlay, SndWBBK
			invoke alSourcePlay, SndMistake
			mov Shn, 4
			m2m fade, fl1
			mov Shop, 0
			mov hbd, 0
			invoke alSourceStop, SndHbd
			mov kubale, 0
			invoke alSourceStop, SndKubale
			mov virdya, 0
			mov wmblyk, 0
			invoke alSourceStop, SndVirdya
			.IF (playerState == 7)
				mov playerState, 0
				invoke alSourceStop, SndWmblykB
				invoke alSourceStop, SndWmblykStrM
			.ENDIF
			
			mov teleportAttempts, 0
			.REPEAT
				invoke GetRandomMazePosition, ADDR ShnPos, ADDR ShnPos[4]
				
				inc teleportAttempts
				
				invoke DistanceToSqr, ShnPos, ShnPos[4], camPosN, camPosN[8]
				mov fltVal, eax
				fcmp fltVal, fl32
			.UNTIL (!Sign?) || (teleportAttempts > 8)
		.ENDIF
	.ENDIF
	
	.IF (playerState == 0)
		.IF (Shn == 2)
			fld deltaTime
			fmul flTenth
			fstp fltVal
			invoke Lerp, ADDR fogDensity, fl06, fltVal
		.ELSEIF (Shn == 3)
			fld fl48
			fsub ShnTimer
			fmul flThousandth
			fstp fltVal
			invoke alSourcef, SndAlarm, AL_GAIN, fltVal
			
			fld deltaTime
			fmul flTenth
			fstp fltVal
			invoke Lerp, ADDR fogDensity, fl075, fltVal
		.ELSEIF (Shn == 4)
			m2m fogDensity, fl1
			invoke Lerp, ADDR fade, 0, deltaTime
			invoke alSource3f, SndWBBK, AL_POSITION, ShnPos, 0, ShnPos[4]
		
			invoke GetDirection, ShnPos, ShnPos[4], camPosN, camPosN[4]
			mov fltVal, eax
			
			fld fltVal
			fsin
			fmul deltaTime
			fmul fl2
			fsubr ShnPos
			fstp ShnPos
			
			fld fltVal
			fcos
			fmul deltaTime
			fmul fl2
			fsubr ShnPos[4]
			fstp ShnPos[4]
			
			fld fltVal
			fmul R2D
			fstp fltVal
			invoke glPushMatrix
				invoke glTranslatef, ShnPos, 0, ShnPos[4]
				invoke glRotatef, fltVal, 0, fl1, 0
				invoke glBindTexture, GL_TEXTURE_2D, TexVas
				invoke nrandom, 3
				add eax, 52
				invoke glCallList, eax
				invoke glDisable, GL_FOG
				invoke glDisable, GL_LIGHTING
				invoke glDisable, GL_CULL_FACE
				invoke glEnable, GL_BLEND
				invoke glBlendFunc, GL_DST_COLOR, GL_ZERO
				invoke nrandom, 9
				mov ebx, 4
				mul ebx
				lea ebx, TexKubaleInkblot
				add eax, ebx
				invoke glBindTexture, GL_TEXTURE_2D, [eax]
				invoke glTranslatef, flHalf, flHalf, flHalf
				invoke glCallList, 84
				invoke glTranslatef, fl1N, 0, 0
				invoke glScalef, fl1N, fl1, fl1
				invoke glCallList, 84
				invoke glEnable, GL_FOG
				invoke glEnable, GL_LIGHTING
				invoke glEnable, GL_CULL_FACE
				invoke glDisable, GL_BLEND
			invoke glPopMatrix
			
			invoke DistanceToSqr, ShnPos, ShnPos[4], camPosN, camPosN[4]
			mov fltVal, eax
			fcmp fltVal, flHalf
			.IF (Sign?)
				invoke alSourcePlay, SndWmblyk
				print "Teleported player badly.", 13, 10
				invoke FreeMaze
				
				m2m MazeSeed, PMSeed
				m2m MazeW, PMW
				m2m MazeH, PMH
				sub MazeLevel, 2
					
				invoke GenerateMaze, MazeSeed
				invoke GetRandomMazePosition, ADDR camPosN, ADDR camPosN[4]
				fld camPosN
				fchs
				fst camPos
				fst camPosNext
				fstp camPosL
				fld camPosN[4]
				fchs
				fst camPos[8]
				fst camPosNext[8]
				fstp camPosL[8]
				mov fadeState, 1
				mov canControl, 1
				mov playerState, 0
				
				m2m fade, fl1
				mov fadeState, 1
				
				m2m MazeLevelPopupTimer, fl2
				mov MazeLevelPopup, 1
			.ENDIF
		.ENDIF
	.ENDIF
	ret
ProcessShn ENDP

; Render frame
Render PROC
	LOCAL camRotDeg:REAL4
	LOCAL camSin:REAL4
	LOCAL camCos:REAL4
	LOCAL joyInfo:JOYINFOEX
	
	invoke GetDelta
	
	invoke glFogf, GL_FOG_DENSITY, fogDensity
	
	; Camera control
	fld camRotL[4]
	fsin
	fst camForward
	fst camRight[8]
	fchs
	fstp camSin
	
	fld camRotL[4]
	fcos
	fst camCos
	fst camForward[8]
	fchs
	fstp camRight
	
	invoke alListener3f, AL_POSITION, camPosN, 0, camPosN[4]
	fld camForward
	fstp camListener
	fld camForward[8]
	fstp camListener[8]
	invoke alListenerfv, AL_ORIENTATION, ADDR camListener
	
	
	.IF (joystickID != -1)
		mov joyInfo.dwSize, SIZEOF JOYINFOEX
		mov joyInfo.dwFlags, JOY_RETURNX or JOY_RETURNY or JOY_RETURNZ \
		or JOY_RETURNR or JOY_RETURNU or JOY_RETURNBUTTONS
		invoke joyGetPosEx, joystickID, ADDR joyInfo
		.IF (eax != JOYERR_NOERROR)
			mov joystickID, -1
		.ELSE
			invoke JoystickButtons, ADDR joyInfo
			.IF (Menu)
				invoke JoystickMenu, ADDR joyInfo
			.ENDIF
		.ENDIF
	.ENDIF
	.IF (canControl)
		invoke Control, ADDR joyInfo
	.ENDIF
	
	.IF focused == 1	; Mouse control
		invoke SetCursorPos, winCX, winCY
	.ENDIF
	
	invoke glClear, GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT
	
	invoke glMatrixMode, GL_PROJECTION
	invoke glLoadIdentity
	invoke gluPerspective, DWORD PTR camFOV, DWORD PTR camFOV+4, \
	DWORD PTR camAspect, DWORD PTR camAspect+4, \
	DWORD PTR dbNear, DWORD PTR dbNear+4, DWORD PTR dbFar, DWORD PTR dbFar+4
	
	invoke glMatrixMode, GL_MODELVIEW
	
	invoke DoPlayerState	; Cutscenes, etc
	
	.IF (MazeHostile == 0)	; Play siren
		fild MazeLevel
		fmul flTenth
		fsubr fl1
		fstp camRotDeg
		invoke Lerp, ADDR MazeSiren, camRotDeg, delta2
		invoke alSourcef, SndSiren, AL_GAIN, MazeSiren
		
		fld MazeSirenTimer
		fsub deltaTime
		fstp MazeSirenTimer
		
		fcmp MazeSirenTimer
		.IF Sign?
			mov MazeHostile, 2
			m2m MazeSirenTimer, fl10
		.ENDIF
	.ELSEIF (MazeHostile == 1)	; Normal gameplay
		.IF (playerState == 0)
			fld MazeRandTimer
			fsub deltaTime
			fstp MazeRandTimer
			
			fcmp MazeRandTimer
			.IF (Sign?)
				invoke RandomFloat, ADDR MazeRandTimer, 20
				fld MazeRandTimer
				fadd fl32
				fstp MazeRandTimer
				invoke RandomFloat, ADDR MazeRandPos, 3
				invoke RandomFloat, ADDR MazeRandPos[4], 3
				fld camPosN
				fadd MazeRandPos
				fstp MazeRandPos
				fld camPosN[4]
				fadd MazeRandPos[4]
				fstp MazeRandPos[4]
				invoke nrandom, 6
				mov ebx, 4
				mul ebx
				mov ebx, eax
				
				invoke alSource3f, SndRand[ebx], AL_POSITION, \
				MazeRandPos, fl2, MazeRandPos[4]
				invoke alSourcePlay, SndRand[ebx]
				print "Playing random noise "
				print str$(ebx), 13, 10
			.ENDIF
		.ENDIF
	.ELSEIF (MazeHostile == 2)	; Stop siren
		invoke Lerp, ADDR MazeSiren, 0, delta2
		invoke alSourcef, SndSiren, AL_GAIN, MazeSiren
		
		fld MazeSirenTimer
		fsub deltaTime
		fstp MazeSirenTimer
		
		fcmp MazeSirenTimer
		.IF Sign?
			mov MazeHostile, 3
			fild MazeLevel
			fmul flTenth
			fstp MazeSirenTimer
			
			fild MazeLevel
			fmul flHundredth
			fsubr fl1
			fstp camRotDeg
			invoke alSourcef, SndExplosion, AL_GAIN, camRotDeg
			invoke alSourcePlay, SndExplosion
			
			invoke alSourceStop, SndSiren
		.ENDIF
	.ELSEIF (MazeHostile == 3)	; Wait for impact
		fld MazeSirenTimer
		fsub deltaTime
		fstp MazeSirenTimer
		
		fcmp MazeSirenTimer
		.IF Sign?
			mov MazeHostile, 4
			m2m MazeSirenTimer, fl3
			
			fild MazeLevel
			fmul flHundredth
			fsubr fl1
			fstp camRotDeg
			
			invoke alSourcef, SndImpact, AL_GAIN, camRotDeg
			invoke alSourcePlay, SndImpact
			
			invoke SetNoiseOpacity 
			
			fld camRotDeg
			fmul flTenth
			fstp camRotDeg
			m2m MazeSiren, camRotDeg
		.ENDIF
	.ELSEIF (MazeHostile == 4)	; Shake screen
		fld MazeSirenTimer
		fsub deltaTime
		fstp MazeSirenTimer
		
		invoke Lerp, ADDR MazeSiren, 0, delta2
		invoke Shake, MazeSiren
		
		fcmp MazeSirenTimer
		.IF Sign?
			mov MazeHostile, 1
			invoke alSourcePlay, SndAmb
			invoke nrandom, 2
			.IF (eax)
				invoke alSourcePlay, SndMus2
			.ENDIF
		.ENDIF
	.ENDIF
	
	invoke glLoadIdentity
	
	.IF (MazeHostile != 12)
		invoke glLightfv, GL_LIGHT0, GL_POSITION, ADDR camLight	; Draw light
	.ENDIF
	
	.IF (Trench)
		fld delta2
		fmul fl4
		fstp camRotDeg
	.ELSEIF (MazeHostile >= 8) && (MazeHostile <= 11)
		fld delta10
		fmul NoiseOpacity
		fstp camRotDeg
	.ELSE
		m2m camRotDeg, delta10
	.ENDIF
	invoke Lerp, ADDR camRotL, camRot, camRotDeg
	invoke LerpAngle, ADDR camRotL[4], camRot[4], camRotDeg
	
	fld camRotL[4]
	fmul R2D
	fchs
	fstp camRotDeg
	invoke glRotatef, camRotDeg, 0, fl1, 0
	fld camRotL
	fmul R2D
	fstp camRotDeg
	invoke glRotatef, camRotDeg, camCos, 0, camSin
	invoke Lerp, ADDR camTilt, 0, delta2
	invoke glRotatef, camTilt, camSin, 0, camCos
	
	
	fld camStepSide	; Walk animation
	fsin
	fstp camRotDeg
	invoke glRotatef, camRotDeg, 0, fl1, 0
	fld camStep
	fmul fl2
	fsin
	fmul flHalf
	fstp camRotDeg
	invoke glRotatef, camRotDeg, camCos, 0, camSin
	
	invoke Lerp, ADDR camPosL, camPos, delta10
	invoke Lerp, ADDR camPosL[4], camPos[4], delta10
	invoke Lerp, ADDR camPosL[8], camPos[8], delta10
	
	fld camPos
	fchs
	fstp camPosN
	fld camPos[8]
	fchs
	fstp camPosN[4]
	
	invoke glTranslatef, camPosL, camPosL[4], camPosL[8]
	
	fld camPosN	; Set next pos for collision
	fsub camCurSpeed
	fstp camPosNext
	fld camPosN[4]
	fsub camCurSpeed[8]
	fstp camPosNext[8]
	
	.IF (playerState == 12)
		invoke glBindTexture, GL_TEXTURE_2D, TexRoof
		invoke glCallList, 40
		invoke glBindTexture, GL_TEXTURE_2D, TexFacade
		invoke glCallList, 41
		invoke glBindTexture, GL_TEXTURE_2D, TexFloor
		invoke glCallList, 42
	.ELSEIF (playerState == 14)
		invoke glBindTexture, GL_TEXTURE_2D, TexRoof
		invoke glCallList, 43
		invoke glBindTexture, GL_TEXTURE_2D, TexFloor
		invoke glCallList, 44
		invoke glEnable, GL_BLEND
		invoke glEnable, GL_ALPHA_TEST
		invoke glBlendFunc, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
		invoke glAlphaFunc, GL_GREATER, 0
		invoke glBindTexture, GL_TEXTURE_2D, TexTree
		invoke glCallList, 45
		invoke glDisable, GL_BLEND
		invoke glDisable, GL_ALPHA_TEST
		invoke glAlphaFunc, GL_ALWAYS, 0
	.ELSEIF (playerState == 16)
		invoke glBindTexture, GL_TEXTURE_2D, TexDoor
		invoke glCallList, 46
		invoke glBindTexture, GL_TEXTURE_2D, TexFloor
		invoke glCallList, 44
		invoke glEnable, GL_BLEND
		invoke glEnable, GL_ALPHA_TEST
		invoke glBlendFunc, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
		invoke glAlphaFunc, GL_GREATER, 0
		invoke glBindTexture, GL_TEXTURE_2D, TexTree
		invoke glCallList, 45
		invoke glDisable, GL_BLEND
		invoke glDisable, GL_ALPHA_TEST
		invoke glAlphaFunc, GL_ALWAYS, 0
	.ENDIF
	
	.IF (Maze)
		invoke DrawMaze	; Draw maze
	.ENDIF
	.IF (MazeHostile == 6) || (MazeHostile == 7)	; Ascend
		invoke DrawAscend
	.ELSEIF (MazeHostile >= 8) && (MazeHostile <= 11)	; Wasteland
		invoke DrawWasteland
	.ELSEIF (MazeHostile == 12)	; Croa
		invoke DrawCroa
	.ELSEIF (MazeHostile == 13)	; Border
		invoke DrawBorder
	.ENDIF
	.IF (Checkpoint > 1)
		invoke DrawCheckpoint, CheckpointPos, CheckpointPos[4]
	.ENDIF
	
	.IF (MazeLevel == 1)
		invoke glPushMatrix
			invoke glTranslatef, 0, 0, 1072902963
			invoke glRotatef, fl90N, fl1, 0, 0
			invoke glEnable, GL_BLEND
			invoke glDisable, GL_LIGHTING
			invoke glDisable, GL_FOG
			invoke glBlendFunc, GL_ZERO, GL_SRC_COLOR
			invoke glTranslatef, 0, flHundredth, 0
			.IF (joyUsed)
				mov eax, TexTutorialJ
			.ELSE
				mov eax, TexTutorial
			.ENDIF
			invoke glBindTexture, GL_TEXTURE_2D, eax
			invoke glCallList, 2
			invoke glDisable, GL_BLEND
			invoke glEnable, GL_LIGHTING
			invoke glEnable, GL_FOG
		invoke glPopMatrix
	.ENDIF
	
	.IF (MazeTram)
		invoke DrawTram
	.ENDIF
	
	.IF (Motrya)
		invoke DrawMotrya
	.ENDIF
	
	.IF (Save)
		invoke DrawSave
	.ENDIF
	
	.IF (Trench)
		invoke glFogfv, GL_FOG_COLOR, ADDR TrenchColor
		invoke glClearColor, TrenchColor, TrenchColor[4], \
		TrenchColor[8], TrenchColor[12]
		invoke DrawVas
	.ENDIF
	
	.IF (GlyphsInLayer > 0)
		invoke DrawGlyphs
	.ENDIF
	
	.IF (virdya)
		invoke DrawVirdya
	.ENDIF
	
	.IF (hbd)
		invoke DrawHbd
	.ENDIF
	
	.IF (Vebra)
		invoke DrawVebra
	.ENDIF
	
	.IF (WB)
		invoke DrawWB
	.ENDIF
	
	.IF (WBBK)
		invoke DrawWBBK
	.ENDIF
	
	.IF (kubale > 28)
		invoke KubaleAI	; Drawing goes from KubaleAI
	.ELSEIF (kubale > 0)
		invoke KubaleEvent
	.ENDIF
	
	.IF (EBD)
		invoke DrawEBD
	.ENDIF
	
	.IF (wmblyk == 8) || (wmblyk == 10)
		invoke DrawWmblyk
	.ELSEIF (wmblyk > 10)
		invoke DrawWmblykAngry
	.ENDIF
	
	invoke glDisable, GL_BLEND
	invoke DrawMazeItems
	
	.IF (Shn)
		invoke ProcessShn
	.ENDIF
	
	;invoke MoveAndCollide, ADDR camPosN, ADDR camPosN[4], \
	;ADDR camCurSpeed, ADDR camCurSpeed[8], flHalf, 0
	;fld camPosN
	;fchs
	;fstp camPos
	;fld camPosN[4]
	;fchs
	;fstp camPos[8]
	
	fld camPos	; Move camera by speed
	fadd camCurSpeed
	fstp camPos
	fld camPos[8]
	fadd camCurSpeed[8]
	fstp camPos[8]
	
	invoke RenderUI
	
	invoke SwapBuffers, GDI
	
	invoke glFlush
	
	ret
Render ENDP

; Render user interface
RenderUI PROC
	LOCAL screenWD: REAL8, screenHD: REAL8
	LOCAL screenWF: REAL4, screenHF: REAL4
	LOCAL btnOffY:REAL4, btnOffX: REAL4, btnOffYS:REAL4, btnA:REAL4
	LOCAL btnOffXE:REAL4, btnOffYE:REAL4
	
	invoke glMatrixMode, GL_PROJECTION
	invoke glLoadIdentity
	fild screenSize
	fst screenWF
	fstp screenWD
	fild screenSize[4]
	fst screenHF
	fstp screenHD
	
	invoke gluOrtho2D, 0, 0, DWORD PTR screenWD, DWORD PTR screenWD+4, DWORD PTR screenHD, DWORD PTR screenHD+4, 0, 0
	
	invoke glMatrixMode, GL_MODELVIEW
	invoke glLoadIdentity
	
	
	invoke glDisable, GL_DEPTH_TEST
	invoke glDisable, GL_LIGHTING
	invoke glDisable, GL_FOG
	
	invoke glEnable, GL_BLEND	; Draw vignette
	invoke glBlendFunc, GL_ZERO, GL_SRC_COLOR
	invoke glBindTexture, GL_TEXTURE_2D, TexVignette
	invoke glScalef, screenWF, screenHF, 0
	invoke glCallList, 3
	invoke glBlendFunc, GL_ZERO, GL_ONE_MINUS_SRC_COLOR
	invoke glColor3f, vignetteRed, vignetteRed, vignetteRed
	invoke glBindTexture, GL_TEXTURE_2D, TexVignetteRed
	invoke glCallList, 3
	
	invoke glBindTexture, GL_TEXTURE_2D, 0	; Gamma (not really)
	invoke glBlendFunc, GL_DST_COLOR, GL_SRC_COLOR
	invoke glColor3f, Gamma, Gamma, Gamma
	invoke glCallList, 3
	
	.IF (fadeState == 1)	; Fade in
		;fld deltaTime
		;fmul flHalf
		;fsubr fade
		;fstp fade
		
		invoke Lerp, ADDR fade, 3184315597, delta2
		fld fade
		fadd flHalf
		fstp fogDensity
		fcmp fade
		.IF Sign? && !Zero?	; fade < 0.0
			fldz
			fstp fade
			mov fadeState, 0
		.ENDIF
	.ELSEIF (fadeState == 2); Fade out
		;fld deltaTime
		;fmul flHalf
		;fadd fade
		;fstp fade
		
		invoke Lerp, ADDR fade, 1066192077, delta2
		fld fade
		fadd flHalf
		fstp fogDensity
		fcmp fade, fl1
		.IF !Sign? && !Zero?; fade > 1.0
			fld1
			fstp fade
			mov fadeState, 0
		.ENDIF
	.ENDIF
	invoke glBindTexture, GL_TEXTURE_2D, 0
	invoke glBlendFunc, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
	invoke glColor4f, 0, 0, 0, fade
	invoke glCallList, 3
	
	; Motrya flash
	.IF (Motrya == 2) || ((MazeHostile > 6) && (MazeHostile < 12))
		invoke glBlendFunc, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
		invoke glColor4f, fl1, fl1, fl1, MotryaTimer
		invoke glCallList, 3
	.ENDIF
	
	.IF (wmblyk == 1)	; Wmblyk jumpscare
		invoke glBindTexture, GL_TEXTURE_2D, TexWmblykJumpscare
		invoke glColor4f, fl1, fl1, fl1, wmblykJumpscare
		invoke glCallList, 3
		
		invoke Lerp, ADDR wmblykJumpscare, 3184315597, delta2
		fcmp wmblykJumpscare
		.IF Sign? && !Zero?	; wmblykJumpscare < 0.0
			fldz
			fstp wmblykJumpscare
			.IF (wmblykStealthy == 0)
				mov wmblyk, 0
			.ELSE
				mov wmblyk, 8
			.ENDIF
		.ENDIF
	.ENDIF
	
	.IF (kubale > 28)	; Kubale visions
		invoke nrandom, 9
		mov ebx, 4
		mul ebx
		lea ebx, TexKubaleInkblot
		add eax, ebx
		invoke glBindTexture, GL_TEXTURE_2D, [eax]
		
		invoke glColor4f, kubaleVision, kubaleVision, kubaleVision, fl1
		invoke glBlendFunc, GL_ZERO, GL_ONE_MINUS_SRC_COLOR
		invoke glScalef, flHalf, fl1, fl1
		invoke glCallList, 3
		invoke glDisable, GL_CULL_FACE
		invoke glTranslatef, fl2, 0, 0
		invoke glScalef, 3212836864, fl1, fl1
		invoke glCallList, 3
		invoke glEnable, GL_CULL_FACE
	.ENDIF
	invoke glColor4f, fl1, fl1, fl1, fl1
	
	fcmp ccTimer	; Subtitles
	.IF !Sign?
		fld ccTimer
		fsub deltaTime
		fstp ccTimer
		
		fld screenWF
		fmul flHalf
		fstp btnOffX
		fld screenHF
		fadd fl90N
		fstp btnOffY
		invoke glLoadIdentity
		invoke glBlendFunc, GL_ONE_MINUS_DST_COLOR, GL_ONE_MINUS_SRC_COLOR
		invoke DrawBitmapText, ccText, btnOffX, btnOffY, FNT_CENTERED
	.ENDIF
	
	.IF (MazeLevelPopup != 0)
		invoke glLoadIdentity
		invoke glBlendFunc, GL_ONE_MINUS_DST_COLOR, GL_ONE_MINUS_SRC_COLOR
		invoke glTranslatef, 1090519040, 1090519040, 0
		invoke DrawBitmapText, ADDR CCLevel, 0, MazeLevelPopupY, FNT_LEFT
		invoke DrawBitmapText, MazeLevelStr, 1123024896, MazeLevelPopupY, FNT_LEFT
		fld MazeLevelPopupTimer
		fsub deltaTime
		fstp MazeLevelPopupTimer
		fld delta2
		fmul fl2
		fstp btnA
		.IF (MazeLevelPopup == 1)
			invoke Lerp, ADDR MazeLevelPopupY, 0, btnA
			fcmp MazeLevelPopupTimer
			.IF Sign?
				mov MazeLevelPopup, 2
				m2m MazeLevelPopupTimer, fl2
			.ENDIF
		.ELSE
			invoke Lerp, ADDR MazeLevelPopupY, 3258974208, btnA
			fcmp MazeLevelPopupTimer
			.IF Sign?
				mov MazeLevelPopup, 0
			.ENDIF
		.ENDIF
	.ENDIF
	
	.IF (playerState == 10)	; Death screen
		fld screenWF
		fmul flHalf
		fstp btnOffX
		fld screenHF
		fmul flHalf
		fsub fl32
		fstp btnOffY
		
		invoke glLoadIdentity
		invoke glBlendFunc, GL_ONE_MINUS_DST_COLOR, GL_ONE_MINUS_SRC_COLOR
		invoke DrawBitmapText, ADDR CCDeath, btnOffX, btnOffY, FNT_CENTERED
		
		fld btnOffX
		fsub fl32
		fstp btnOffX
		fld btnOffY
		fadd fl32
		fadd fl32
		fstp btnOffY
		invoke DrawBitmapText, ADDR CCLevel, btnOffX, btnOffY, FNT_CENTERED
		fld btnOffX
		fadd fl90
		fstp btnOffX
		invoke DrawBitmapText, MazeLevelStr, btnOffX, btnOffY, FNT_LEFT
	.ELSEIF (playerState == 13)	; GreatCorn presents
		fld screenWF
		fmul flHalf
		fstp btnOffX
		fld screenHF
		fmul flHalf
		fstp btnOffY
		
		invoke glLoadIdentity
		invoke glBlendFunc, GL_ONE_MINUS_DST_COLOR, GL_ONE_MINUS_SRC_COLOR
		invoke DrawBitmapText, ADDR CCIntro1, btnOffX, btnOffY, FNT_CENTERED
	.ELSEIF (playerState == 15)	; Something something
		fld screenWF
		fmul flHalf
		fstp btnOffX
		fld screenHF
		fmul flHalf
		fsub fl32
		fstp btnOffY
		
		invoke glLoadIdentity
		invoke glBlendFunc, GL_ONE_MINUS_DST_COLOR, GL_ONE_MINUS_SRC_COLOR
		invoke DrawBitmapText, ADDR CCIntro2, btnOffX, btnOffY, FNT_CENTERED
		
		fld btnOffY
		fadd fl32
		fadd fl32
		fstp btnOffY
		invoke DrawBitmapText, ADDR CCIntro3, btnOffX, btnOffY, FNT_CENTERED
	.ELSEIF (playerState == 17)	; MASMZE-3D
		fld screenWF
		fmul flHalf
		fstp btnOffX
		fld screenHF
		fmul flHalf
		fstp btnOffY
		
		invoke glLoadIdentity
		invoke glBlendFunc, GL_ONE_MINUS_DST_COLOR, GL_ONE_MINUS_SRC_COLOR
		invoke DrawBitmapText, ADDR AppName, btnOffX, btnOffY, FNT_CENTERED
	.ENDIF
	
	.IF (MazeNote > 16)
		invoke glLoadIdentity	; BG
		invoke glScalef, screenWF, screenHF, 0
		invoke glBindTexture, GL_TEXTURE_2D, 0
		invoke glColor4f, 0, 0, 0, flHalf
		invoke glBlendFunc, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
		invoke glCallList, 3
		
		invoke glLoadIdentity
		fld screenWF
		fsub flPaper
		fmul flHalf
		fstp btnOffX
		fld screenHF
		fsub flPaper
		fmul flHalf
		fstp btnOffY
		invoke glTranslatef, btnOffX, btnOffY, 0
		invoke glScalef, 1142947840, 1142947840, 0
		invoke glBindTexture, GL_TEXTURE_2D, TexPaper
		invoke glColor4f, fl1, fl1, fl1, fl1
		invoke glCallList, 3
		
		fld btnOffX
		fadd fl100
		fadd fl10
		fstp btnOffX
		fld btnOffY
		fadd fl10
		fstp btnOffY
		invoke glLoadIdentity
		invoke glBlendFunc, GL_ZERO, GL_ONE_MINUS_SRC_COLOR
		
		.IF (MazeNote == 17)	; Notes
			invoke DrawBitmapText, ADDR Note1, btnOffX, btnOffY, FNT_LEFT
		.ELSEIF (MazeNote == 18)
			invoke DrawBitmapText, ADDR Note2, btnOffX, btnOffY, FNT_LEFT
		.ELSEIF (MazeNote == 19)
			invoke DrawBitmapText, ADDR Note3, btnOffX, btnOffY, FNT_LEFT
		.ELSEIF (MazeNote == 20)
			invoke DrawBitmapText, ADDR Note4, btnOffX, btnOffY, FNT_LEFT
		.ELSEIF (MazeNote == 21)
			invoke DrawBitmapText, ADDR Note5, btnOffX, btnOffY, FNT_LEFT
		.ELSEIF (MazeNote == 22)
			invoke DrawBitmapText, ADDR Note6, btnOffX, btnOffY, FNT_LEFT
		.ELSEIF (MazeNote == 23)
			invoke DrawBitmapText, ADDR Note7, btnOffX, btnOffY, FNT_LEFT
		.ENDIF
		
		invoke glLoadIdentity
		invoke glBlendFunc, GL_ONE_MINUS_DST_COLOR, GL_ONE_MINUS_SRC_COLOR
		invoke glTranslatef, 1090519040, 1090519040, 0
		.IF (joyUsed)
			lea eax, CCEscapeJ
		.ELSE
			lea eax, CCEscape
		.ENDIF
		invoke DrawBitmapText, eax, 0, 0, FNT_LEFT
	.ENDIF
	
	.IF (Menu == 1)
		invoke glLoadIdentity	; BG
		invoke glScalef, screenWF, screenHF, 0
		invoke glBindTexture, GL_TEXTURE_2D, 0
		invoke glColor4f, 0, 0, 0, flHalf
		invoke glBlendFunc, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
		invoke glCallList, 3
		
		invoke glLoadIdentity	; Cursor
		invoke glBlendFunc, GL_ONE_MINUS_DST_COLOR, GL_ONE_MINUS_SRC_COLOR
		invoke glTranslatef, msX, msY, 0
		invoke glScalef, 1098907648, 1098907648, fl1
		invoke glBindTexture, GL_TEXTURE_2D, TexCursor
		invoke glColor4f, fl1, fl1, fl1, fl1
		invoke glCallList, 3
		
		invoke glLoadIdentity	; Maze layer
		invoke glBlendFunc, GL_ONE_MINUS_DST_COLOR, GL_ONE_MINUS_SRC_COLOR
		invoke glTranslatef, 1090519040, 1090519040, 0
		invoke DrawBitmapText, ADDR CCLevel, 0, 0, FNT_LEFT
		invoke DrawBitmapText, MazeLevelStr, 1123024896, 0, FNT_LEFT
		
		; Buttons
		invoke glLoadIdentity
		
		fld screenWF
		fsub mnButton
		fmul flHalf
		fst btnOffX
		fadd mnButton
		fstp btnOffXE
		
		fld screenHF
		fsub mnButton[4]
		fmul flHalf
		fst btnOffY
		fadd mnButton[4]
		fstp btnOffYE
		
		invoke glTranslatef, btnOffX, btnOffY, 0
		invoke glScalef, mnButton, mnButton[4], fl1
		
		invoke glBindTexture, GL_TEXTURE_2D, 0
		
		; RESUME
		invoke InRange, msX, msY, btnOffX, btnOffXE, btnOffY, btnOffYE
		.IF (al == 0)
			fld1
		.ELSE
			fld fl06
			.IF (keyLMB == 1)
				invoke DoMenu
			.ENDIF
		.ENDIF
		fstp btnA
		invoke glColor3f, btnA, btnA, btnA
		invoke glCallList, 3
		
		; OPTIONS
		fld fl12
		fadd btnOffYE
		fst btnOffYS
		fadd mnButton[4]
		fstp btnOffYE
		invoke InRange, msX, msY, btnOffX, btnOffXE, btnOffYS, btnOffYE
		.IF (al == 0)
			fld1
		.ELSE
			fld fl06
			.IF (keyLMB == 1)
				inc Menu
				invoke OpenSettings
			.ENDIF
		.ENDIF
		fstp btnA
		invoke glColor3f, btnA, btnA, btnA
		invoke glTranslatef, 0, mnFontSpacing, 0
		invoke glCallList, 3
		
		; EXIT
		fld fl12
		fadd btnOffYE
		fst btnOffYS
		fadd mnButton[4]
		fstp btnOffYE
		invoke InRange, msX, msY, btnOffX, btnOffXE, btnOffYS, btnOffYE
		.IF (al == 0)
			fld1
		.ELSE
			fld fl06
			.IF (keyLMB == 1)
				invoke DestroyWindow, hwnd
			.ENDIF
		.ENDIF
		fstp btnA
		invoke glColor3f, btnA, btnA, btnA
		invoke glTranslatef, 0, mnFontSpacing, 0
		invoke glCallList, 3
		
		; Text
		fld screenWF
		fmul flHalf
		fstp btnOffX
		
		invoke glLoadIdentity
		invoke glTranslatef, btnOffX, btnOffY, 0
		invoke glBlendFunc, GL_ONE_MINUS_DST_COLOR, GL_ONE_MINUS_SRC_COLOR
		invoke glColor4fv, ADDR clWhite
		
		invoke DrawBitmapText, ADDR MenuPaused, 0, 3267362816, FNT_CENTERED
		
		invoke glBlendFunc, GL_ZERO, GL_ONE_MINUS_SRC_COLOR
		; RESUME
		invoke DrawBitmapText, ADDR MenuResume, 0, 1090519040, FNT_CENTERED		; 8
		
		; GAMMA
		invoke DrawBitmapText, ADDR MenuSettings, 0, 1116209152, FNT_CENTERED	; 68
		
		; EXIT
		invoke DrawBitmapText, ADDR MenuExit, 0, 1124073472, FNT_CENTERED		; 128
	.ELSEIF (Menu == 2)
		
	
		jmp SETEND
	
		fld screenWF
		fmul flHalf
		fadd fl96
		fst btnOffX
		fadd mnFont[4]
		fstp btnOffXE
		
		fld screenHF
		fmul flHalf
		fsub fl96
		fsub mnButton[4]
		fst btnOffY
		fadd mnFont[4]
		fstp btnOffYE
		
		
		invoke glLoadIdentity
		
		invoke glTranslatef, btnOffX, btnOffY, 0
		invoke glScalef, mnFont[4], mnFont[4], fl1
		
		; FULLSCREEN
		invoke glBindTexture, GL_TEXTURE_2D, 0
		invoke glBlendFunc, GL_ONE_MINUS_DST_COLOR, GL_ONE_MINUS_SRC_COLOR
		
		invoke InRange, msX, msY, btnOffX, btnOffXE, btnOffY, btnOffYE
		.IF (al == 0)
			fld1
		.ELSE
			fld fl06
			.IF (keyLMB == 1)
				mov al, fullscreen
				not al
				mov fullscreen, al
				invoke SetFullscreen, fullscreen
			.ENDIF
		.ENDIF
		fstp btnA
		invoke glColor3f, btnA, btnA, btnA
		invoke glCallList, 3
		
		.IF (fullscreen)
			invoke glBlendFunc, GL_ZERO, GL_ONE_MINUS_SRC_COLOR
			invoke glScalef, flHalf, flHalf, fl1
			invoke glTranslatef, flHalf, flHalf, 0
			invoke glCallList, 3
			invoke glBlendFunc, GL_ONE_MINUS_DST_COLOR, GL_ONE_MINUS_SRC_COLOR
		.ENDIF
		
		fld screenWF
		fsub mnButton
		fmul flHalf
		fstp btnOffX
		fld screenHF
		fmul flHalf
		fsub fl96
		fst btnOffY
		fadd mnButton[4]
		fstp btnOffYE
		
		invoke glLoadIdentity
		invoke glTranslatef, btnOffX, btnOffY, 0
		invoke glScalef, mnButton, mnButton[4], fl1
		
		invoke InRange, msX, msY, btnOffX, btnOffXE, btnOffY, btnOffYE
		.IF (al == 0)
			fld1
		.ELSE
			fld fl06
			.IF (keyLMB == 1)
				
			.ENDIF
		.ENDIF
		fstp btnA
		invoke glColor3f, btnA, btnA, btnA
		invoke glCallList, 3
		
		
		fld screenWF
		fmul flHalf
		fstp btnOffX
		fld screenHF
		fmul flHalf
		fstp btnOffY
		invoke glLoadIdentity
		invoke glTranslatef, btnOffX, btnOffY, 0
		invoke glBlendFunc, GL_ONE_MINUS_DST_COLOR, GL_ONE_MINUS_SRC_COLOR
		invoke glColor4fv, ADDR clWhite
		
		; SETTINGS
		invoke DrawBitmapText, ADDR MenuSettings, 0, 3275751424, FNT_CENTERED
		; FULLSCREEN
		invoke DrawBitmapText, ADDR MenuFullscreen, 3271557120, 3272605696, FNT_LEFT
		; RESOLUTION
		invoke DrawBitmapText, ADDR MenuResolution, 0, 3266314240, FNT_CENTERED
		
		SETEND:
	.ENDIF
	
	invoke glBlendFunc, GL_DST_COLOR, GL_SRC_COLOR
	invoke DrawNoise, TexNoise
	.IF (MazeHostile > 4)
		invoke glBlendFunc, GL_SRC_COLOR, GL_ONE
		invoke glColor3f, NoiseOpacity, NoiseOpacity, NoiseOpacity
		invoke DrawNoise, TexNoise
	.ENDIF
	
	.IF (playerState == 12) || (playerState == 14) || (playerState == 16)
		invoke glBlendFunc, GL_SRC_COLOR, GL_ONE
		invoke DrawNoise, TexRain
	.ENDIF
	
	invoke glDisable, GL_BLEND
	
	
	
	;invoke glGenTextures, 1, ADDR PixelLock
	;invoke glBindTexture, GL_TEXTURE_2D, PixelLock
	
	;invoke HeapAlloc, Heap, 0, winSize
	;invoke GlobalAlloc, GMEM_MOVEABLE or GMEM_ZEROINIT, winSize
	;mov PixelBuffer, eax
	;invoke GlobalLock, PixelBuffer
    ;mov PixelLock, eax
	
	;invoke glReadPixels, 0, 0, winWH, winHH, GL_RGB, GL_UNSIGNED_BYTE, PixelBuffer
	;invoke glCopyTexImage2D, GL_TEXTURE_2D, 0, GL_RGB, 0, 0, winWH, winHH, 0
	
	;invoke glLoadIdentity
	;invoke glScalef, screenWF, screenHF, 0
	
	;invoke glCallList, 3
	
	;invoke glPixelZoom, fl2, fl2
	;invoke glDrawPixels, winWH, winHH, GL_RGB, GL_UNSIGNED_BYTE, PixelBuffer
	;invoke GlobalUnlock, PixelLock
	;invoke GlobalFree, PixelBuffer
	
	;invoke glDeleteTextures, 1, ADDR PixelLock
	
	;invoke GLE
	;invoke HeapFree, Heap, 0, PixelBuffer
	
	
	invoke glEnable, GL_FOG
	invoke glEnable, GL_LIGHTING
	invoke glEnable, GL_DEPTH_TEST
	
	.IF (keyLMB == 1)	; Mouse
		mov keyLMB, 2
	.ENDIF
	ret
RenderUI ENDP

; Handle window resize
Resize PROC SizeW: SWORD, SizeH: SWORD
	print "Resolution changed to: "
	print sword$(SizeW), "x"
	print sword$(SizeH), 13, 10
	
	xor eax, eax
	mov ax, SizeW
	mov screenSize, eax
	mov ax, SizeH
	mov screenSize[4], eax
	
	push ebx
	xor ebx, ebx
	mov bx, SizeW
	mul ebx
	mov ebx, 3
	mul ebx
	mov winSize, eax
	print "WINDOW SIZE: "
	print str$(winSize), 13, 10
	pop ebx
	
	invoke glViewport, 0, 0, SizeW, SizeH
	fild SizeW
	fild SizeH
	fdiv
	fstp camAspect
	ret
Resize ENDP

; Save current progress into registry
SaveGame PROC
	invoke EraseTempSave

	invoke RegCreateKeyExA, HKEY_CURRENT_USER, ADDR RegPath, 0, NULL, \
	REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, ADDR defKey, NULL
	.IF (eax != ERROR_SUCCESS)
		print "Failed to create registry key.", 13, 10
	.ENDIF
	
	invoke RegSetValueExA, defKey, ADDR RegLayer, 0, REG_DWORD, \ 
	ADDR MazeLevel, 4
	.IF (eax != ERROR_SUCCESS)
		print "Failed to save layer value (DWORD).", 13, 10
	.ENDIF
	.IF (Compass == 2)
		invoke RegSetValueExA, defKey, ADDR RegCompass, 0, REG_BINARY, \ 
		ADDR Compass, 1
	.ENDIF
	invoke RegSetValueExA, defKey, ADDR RegGlyphs, 0, REG_BINARY, ADDR Glyphs, 1
	invoke RegSetValueExA, defKey, ADDR RegFloor, 0, REG_DWORD, \ 
	ADDR CurrentFloor, 4
	invoke RegSetValueExA, defKey, ADDR RegWall, 0, REG_DWORD, \ 
	ADDR CurrentWall, 4
	invoke RegSetValueExA, defKey, ADDR RegRoof, 0, REG_DWORD, \ 
	ADDR CurrentRoof, 4
	invoke RegSetValueExA, defKey, ADDR RegMazeW, 0, REG_DWORD, \ 
	ADDR MazeW, 4
	invoke RegSetValueExA, defKey, ADDR RegMazeH, 0, REG_DWORD, \ 
	ADDR MazeH, 4
	
	invoke RegCloseKey, defKey
	ret
SaveGame ENDP

; Set fullscreen mode to _FS
SetFullscreen PROC _FS:BYTE
	LOCAL fullScreenX: DWORD, fullScreenY: DWORD
	LOCAL winRect: RECT
	
	print "Setting fullscreen: "
	print sbyte$(_FS), 13, 10
	.IF (_FS)
		invoke GetWindowRect, hwnd, ADDR winRect
		mov eax, winRect.right
		mov ebx, winRect.left
		sub eax, ebx
		mov windowSize, eax
		mov eax, winRect.bottom
		mov ebx, winRect.top
		sub eax, ebx
		mov windowSize[4], eax
		
		mov eax, winRect.left
		mov windowPos, eax
		mov eax, winRect.top
		mov windowPos[4], eax
	
		invoke GetSystemMetrics, SM_CXSCREEN
		mov fullScreenX, eax
		invoke GetSystemMetrics, SM_CYSCREEN
		mov fullScreenY, eax
		invoke SetWindowLongA, hwnd, GWL_STYLE, WS_POPUP
		invoke SetWindowPos, hwnd, HWND_TOPMOST, 0, 0, \
		fullScreenX, fullScreenY, \
		SWP_NOZORDER or SWP_FRAMECHANGED or SWP_SHOWWINDOW
	.ELSE
		invoke SetWindowLongA, hwnd, GWL_STYLE, WS_OVERLAPPEDWINDOW
		invoke SetWindowPos, hwnd, HWND_TOPMOST, windowPos, windowPos[4], \
		windowSize, windowSize[4], \
		SWP_NOZORDER or SWP_FRAMECHANGED or SWP_SHOWWINDOW
	.ENDIF
	ret
SetFullscreen ENDP

; To not mess with int to string conversion, simply call this with str$
SetMazeLevelStr PROC String:DWORD
	m2m MazeLevelStr, String
	ret
SetMazeLevelStr ENDP

; Set noise opacity (used for ending only)
SetNoiseOpacity PROC
	.IF (!MazeLevel)
		m2m NoiseOpacity[4], fl1
		ret
	.ENDIF
	fild MazeLevel
	fmul flTenth
	fdivr fl1
	fstp NoiseOpacity[4]
	ret
SetNoiseOpacity ENDP

; Shake screen
Shake PROC Amplitude:REAL4
	LOCAL shakeVal:DWORD
	
	invoke nrandom, 10
	mov shakeVal, eax
	fild shakeVal
	fsub fl5
	fmul flFifth
	fmul Amplitude
	fadd camRotL
	fstp camRotL
	
	invoke nrandom, 10
	mov shakeVal, eax
	fild shakeVal
	fsub fl5
	fmul flFifth
	fmul Amplitude
	fadd camRotL[4]
	fstp camRotL[4]
	ret
Shake ENDP

; Tried to make it a little more universal, but ShowCursor works badly
ShowHideCursor PROC Show:BYTE
	LOCAL ci:CURSORINFO
	mov ci.cbSize, SIZEOF CURSORINFO
	invoke GetCursorInfo, ADDR ci
	
	.IF (Show == 0)
		;.WHILE (ci.flags > 0)
			invoke ShowCursor, 0
		;	invoke GetCursorInfo, ADDR ci
		;	print str$(ci.flags), 13, 10
		;.ENDW
	.ELSE
		;.WHILE (ci.flags == 0)
		;	invoke ShowCursor, 1
		;	invoke GetCursorInfo, ADDR ci
		;	print str$(ci.flags), 13, 10
		;.ENDW
	.ENDIF
	ret
ShowHideCursor ENDP

; Show subtitles, 2 seconds by default, change ccTimer to get different duration
ShowSubtitles PROC String:DWORD
	m2m ccText, String
	m2m ccTimer, fl2
	ret
ShowSubtitles ENDP

; Process Windows messages sent to the application window
WndProc PROC hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	LOCAL lw:SWORD
	LOCAL hw:SWORD
	
	.IF uMsg==WM_CREATE
		invoke InitContext, hWnd
		invoke CreateModels
		print "Finished initializing",13,10
		invoke InitAudio
		invoke LoadGame
		invoke ShowCursor, 0
	.ELSEIF uMsg==WM_DESTROY
		invoke Halt
	.ELSEIF uMsg==WM_PAINT
		invoke Render
	.ELSEIF uMsg==WM_KEYDOWN
		mov joyUsed, 0
		invoke KeyPress, wParam, 1
	.ELSEIF uMsg==WM_KEYUP
		invoke KeyPress, wParam, 0
	.ELSEIF uMsg==WM_SIZE
		mov eax, lParam
		mov winW, ax
		mov ecx, lParam
		shr ecx, 16
		mov winH, cx
		invoke GetWindowCenter
		invoke Resize, winW, winH
	.ELSEIF uMsg==WM_MOVE
		mov eax, lParam
		mov winX, ax
		mov ecx, lParam
		shr ecx, 16
		mov winY, cx
		invoke GetWindowCenter
		
		.IF (GetIniSettingsOnFirstFrame == 0)
			mov GetIniSettingsOnFirstFrame, 1
			invoke GetSettings
		.ENDIF
	.ELSEIF uMsg==WM_MOUSEMOVE
		; There has to be a way to map DWORD to 2 consecutive words
		mov eax, lParam
		mov mousePos, ax
		mov eax, lParam
		shr eax, 16
		mov mousePos[2], ax
		;mov joyUsed, 0
		invoke CreateThread, NULL, 0, OFFSET MouseMove, 0, 0, NULL
	.ELSEIF uMsg==WM_SETFOCUS
		;invoke ShowHideCursor, 0
		.IF (Menu == 2)
			invoke SetWindowPos, stHwnd, HWND_TOPMOST, 0, 0, 0, 0, \
			SWP_FRAMECHANGED or SWP_SHOWWINDOW or SWP_NOSIZE or SWP_NOMOVE
		.ENDIF
	.ELSEIF uMsg==WM_LBUTTONDOWN
		.IF (Menu == 0) && (focused == 0)
			mov focused, 1
			;invoke ShowHideCursor, 0
		.ENDIF
		mov keyLMB, 1
		mov joyUsed, 0
	.ELSEIF uMsg==WM_LBUTTONUP
		mov keyLMB, 0
	.ELSEIF uMsg==WM_KILLFOCUS
		.IF (Menu == 0) && (focused == 1)
			mov focused, 0
			;invoke ShowHideCursor, 1
		.ENDIF
	.ELSE
		invoke DefWindowProc,hWnd,uMsg,wParam,lParam
		ret
	.ENDIF
	
	xor eax, eax
	ret
WndProc ENDP

; Main code
start:
	invoke HSInit
	
	invoke HSCreate, 4
	mov WBStack, eax
	print str$(WBStack), 13, 10
	invoke HSPush, WBStack, 5
	invoke HSPush, WBStack, 8
	print str$(WBStack), 13, 10
	invoke HSPop, WBStack, ADDR WBStackHandle
	print str$(WBStackHandle), 13, 10
	invoke HSPop, WBStack, ADDR WBStackHandle
	print str$(WBStackHandle), 13, 10
	invoke HSPush, WBStack, 1
	invoke HSPush, WBStack, 6
	invoke HSPop, WBStack, ADDR WBStackHandle
	print str$(WBStackHandle), 13, 10
	invoke HSPop, WBStack, ADDR WBStackHandle
	print str$(WBStackHandle), 13, 10

	finit
	fwait
	
	fstcw FPUMode
	print sword$(FPUMode), 13, 10
	or FPUMode, FPU_ZERO
	print sword$(FPUMode), 13, 10
	fldcw FPUMode
	
	invoke GetTickCount
	invoke nseed, eax
	invoke CreateWindow
	
	print "Exited window procedure.", 13, 10
	
	; Terminate process for the system not to yell that it stopped working
	invoke GetCurrentProcess
	invoke TerminateProcess, eax, 0
end start