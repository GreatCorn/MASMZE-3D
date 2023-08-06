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

; Include libraries (I couldn't configure ML to compile without absolute path,
; change this to whatever directory you have MASM32 in)
include E:\masm32\include\windows.inc

include E:\masm32\include\gdi32.inc
includelib E:\masm32\lib\gdi32.lib
include E:\masm32\include\glu32.inc
includelib E:\masm32\lib\glu32.lib
include E:\masm32\include\kernel32.inc
includelib E:\masm32\lib\kernel32.lib
include E:\masm32\include\masm32.inc
includelib E:\masm32\lib\masm32.lib
include E:\masm32\include\msvcrt.inc
includelib E:\masm32\lib\msvcrt.lib
include E:\masm32\include\opengl32.inc
includelib E:\masm32\lib\opengl32.lib
include E:\masm32\include\user32.inc
includelib E:\masm32\lib\user32.lib

include E:\masm32\macros\macros.asm

; Include project files
include audio.inc
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

.CONST

ClassName DB "FMain", 0		; Window class name
AppName DB "MASMZE-3D", 0	; App name & caption

ErrorCaption DB "ERROR", 0	; Error specifications
ErrorDC DB "Can't get device context.", 0
ErrorPF DB "Can't choose pixel format.", 0
ErrorPFS DB "Can't set pixel format.", 0
ErrorGLC DB "Can't create GL context.", 0
ErrorGLCC DB "Can't make GL context current.", 0
ErrorOpenGL DB "OpenGL error occured.", 0

CCDeath DB "YOU DIED.", 0	; Subtitles and miscellaneous strings

CCLevel DB "LAYER:", 0

; Random subtitles to show when entering a layer
CCRandom1 DB "I REMEMBER THIS PLACE.", 0
CCRandom2 DB "IT SMELLS WET HERE.", 0
CCRandom3 DB "THE AIR TASTES STAGNANT.", 0
CCRandom4 DB "DAMPNESS CLINGS TO THE WALLS.", 0
CCRandom5 DB "SOMETHING WATCHES FROM AFAR.", 0
CCRandom6 DB "THE WALLS VIBRATE SLIGHTLY.", 0

CCTrench DB "THE CYCLE CONTINUES.", 0

CCCompass DB "PICKED UP COMPASS.", 0	; Functional subtitles
CCGlyphNone DB "THE ABYSS IMMURES THINE MALEFACTIONS.", 0
CCGlyphRestore DB "THINE EXCULPATION BETIDES.", 0
CCKey DB "PICKED UP KEY.", 0
CCShop DB "PRESS ENTER TO BUY MAP FOR 5 GLYPHS", 0
CCShopBuy DB "THANK YOU FOR YOUR PURCHASE", 0
CCShopNo DB "NOT ENOUGH GLYPHS", 0
CCSpace DB "MASH SPACE TO FIGHT BACK", 0
CCTeleport DB "REALITY BENDS, FRACTURES EMERGE", 0

CCIntro1 DB "GREATCORN PRESENTS", 0
CCIntro2 DB "A GAME WRITTEN IN X86 ASSEMBLY", 0
CCIntro3 DB "WITH MASM32 AND OPENGL", 0

MenuBrightness DB "BRIGHTNESS", 0	; Menu-related strings
MenuSettings DB "SETTINGS", 0
MenuPaused DB "MASMZE-3D IS PAUSED", 0
MenuResume DB "RESUME", 0
MenuSensitivity DB "SENSITIVITY", 0
MenuExit DB "EXIT", 0
MenuSettingsWIP1 DB "SETTINGS ARE WORK IN PROGRESS", 0
MenuSettingsWIP2 DB "PLEASE USE THE SETTINGS.INI FILE", 0
MenuSettingsWIP3 DB "PRESS ESC TO GO BACK", 0

IniPath DB "settings.ini", 0	; Ini-related strings
IniGraphics DB "Graphics", 0
IniFullscreen DB "Fullscreen", 0
IniWidth DB "Width", 0
IniHeight DB "Height", 0
IniBrightness DB "Brightness", 0
IniControls DB "Controls", 0
IniSensitivity DB "Sensitivity", 0
IniFalse DB "false", 0
IniTrue DB "true", 0
Ini03 DB "0.3", 0
Ini05 DB "0.5", 0

; Resource paths
ImgBricks DB "GFX\bricks.gct", 0	; Images
ImgCompass DB "GFX\compass.gct", 0
ImgCompassWorld DB "GFX\compassWorld.gct", 0
ImgCursor DB "GFX\cursor.gct", 0
ImgDirt DB "GFX\dirt.gct", 0
ImgDoor DB "GFX\door.gct", 0
ImgDoorblur DB "GFX\doorblur.gct", 0
ImgFacade DB "GFX\facade.gct", 0
ImgFloor DB "GFX\floor.gct", 0
ImgGlyphs DB "GFX\glyphs.gct", 0
ImgHbd DB "GFX\hbd.gct", 0
ImgKey DB "GFX\key.gct", 0
ImgKoluplyk DB "GFX\koluplyk.gct", 0
ImgLamp DB "GFX\lamp.gct", 0
ImgMap DB "GFX\map.gct", 0
ImgMetal DB "GFX\metal.gct", 0
ImgMetalFloor DB "GFX\metalFloor.gct", 0
ImgMetalRoof DB "GFX\metalRoof.gct", 0
ImgNoise DB "GFX\noise.gct", 0
ImgPipe DB "GFX\pipe.gct", 0
ImgPlanks DB "GFX\planks.gct", 0
ImgRain DB "GFX\rain.gct", 0
ImgRoof DB "GFX\roof.gct", 0
ImgSigns1 DB "GFX\signs1.gct", 0
ImgShadow DB "GFX\shadow.gct", 0
ImgTaburetka DB "GFX\taburetka.gct", 0
ImgTilefloor DB "GFX\tilefloor.gct", 0
ImgTree DB "GFX\tree.gct", 0
ImgVas DB "GFX\vas.gct", 0
ImgVignette DB "GFX\vignette.gct", 0
ImgVignetteRed DB "GFX\vignetteRed.gct", 0
ImgWall DB "GFX\wall.gct", 0
ImgWBBK DB "GFX\WBBK.gct", 0
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
MdlWires DB "GFX\wires.gcm", 0

MdlCityConcrete DB "GFX\cityConcrete.gcm", 0
MdlCityFacade DB "GFX\cityFacade.gcm", 0
MdlCityTerrain DB "GFX\cityTerrain.gcm", 0
MdlOutsBunker DB "GFX\outskirtsBunker.gcm", 0
MdlOutsRoad DB "GFX\outskirtsRoad.gcm", 0
MdlOutsTerrain DB "GFX\outskirtsTerrain.gcm", 0
MdlOutsTrees DB "GFX\outskirtsTrees.gcm", 0

MdlWallB DB "GFX\wallB.gcm", 0
MdlWallM DB "GFX\wallM.gcm", 0
MdlWallS DB "GFX\wallS.gcm", 0
MdlWallT DB "GFX\wallT.gcm", 0
MdlWallTR DB "GFX\wallTR.gcm", 0

MdlWmblykBody DB "GFX\wmblykBody.gcm", 0
MdlWmblykBodyG DB "GFX\wmblykBodyG.gcm", 0
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

MdlHbd DB "GFX\hbd.gcm", 0
MdlHbdS DB "GFX\hbdS.gcm", 0

SndAmbPath DB "SFX\amb.gcs", 0		; Sounds
SndAmbTPath DB "SFX\ambT.gcs", 0
SndDeathPath DB "SFX\death.gcs", 0
SndDigPath DB "SFX\dig.gcs", 0
SndDripPath DB "SFX\drip.gcs", 0
SndExitPath DB "SFX\exit.gcs", 0
SndExplosionPath DB "SFX\explosion.gcs", 0
SndHbdPath DB "SFX\hbd.gcs", 0
SndHbdOPath DB "SFX\hbdO.gcs", 0
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
SndMus2Path DB "SFX\mus2.gcs", 0
SndScribblePath DB "SFX\scribble.gcs", 0
SndSirenPath DB "SFX\siren.gcs", 0
SndSlamPath DB "SFX\slam.gcs", 0
SndVirdyaPath DB "SFX\virdya.gcs", 0
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
flCamSpeed REAL4 3.0	; Default camera speed
flDoor REAL4 0.65		; Door offset
flStep REAL4 6.0		; Step animation speed
flShine REAL4 64.0		; Environment shininess
flWTh REAL4 0.4			; Wall thickness
flWMr REAL4 0.15		; Wall margin
flWLn REAL4 2.15		; Wall length
flKubaleTh REAL4 0.7	; Kubale thiccness
flRaycast REAL4 1.0		; Raycast resolution

mnButton REAL4 256.0, 48.0	; Menu button size
mnFont REAL4 16.0, 32.0		; Menu font size
mnFontSpacing REAL4 1.25	; Menu font spacing (in scaled units)

; Array of 4-direction angles in radians to iterate through
rotations REAL4 0.0, 1.5707, 3.1415, -1.5707


; ----- INITIALIZED DATA -----
.DATA
CCGlyph DB "PLACED GLYPH. ? REMAINING.", 0	; For replacing ? with number

canControl BYTE 0			; Boolean to enable/disable player control
focused BYTE 1				; Window focus
fullscreen BYTE 0			; Boolean to store if the game is fullscreen
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
keyLMB BYTE 0
debugF BYTE 0

msX REAL4 0.0	; Mouse position as REAL4
msY REAL4 0.0
winX SWORD 0	; Window position
winY SWORD 0
winW SWORD 0	; Window size
winH SWORD 0
winWH SWORD 0
winHH SWORD 0
winCX SWORD 0	; Window center
winCY SWORD 0
winWHF REAL4 0.0
winHHF REAL4 0.0
winSize DWORD 0

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

lastStepSnd DWORD 0		; Last step sound index, to not repeat it

mouseRel SWORD 0, 0		; Mouse position, relative to screen center
mousePos SWORD 0, 0		; Absolute mouse position

ccTimer REAL4 -1.0	; Subtitles timer
ccText DWORD 0		; Subtitles text pointer	
ccTextLast BYTE 255	; Last subtitles index, to not repeat it

wmblyk DWORD 0				; Wmblyk's state
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

MazeW DWORD 6		; Maze size
MazeH DWORD 6
MazeWM1 DWORD 0		; Maze size - (1, 1)
MazeHM1 DWORD 0
MazePool DWORD 0	; Used when generating maze
MazeSize DWORD 0	; Maze byte size
MazeSizeM1 DWORD 0	; Maze - (1, 1) byte size
MazeDoor REAL4 0.0			; Maze end door value, used for rotating
MazeDoorPos REAL4 0.0, 0.0	; Maze end door cell center position in REAL4
MazeGlyphs BYTE 0			; Maze glyphs item
MazeGlyphsPos REAL4 0.0, 0.0; Glyphs item position in layer
MazeGlyphsRot REAL4 0.0		; Glyphs item rotation
MazeLocked BYTE 0	; Locked layer, 0 = not locked, 1 = locked, 2 = unlocked
MazeKeyPos REAL4 0.0, 0.0	; Key position
MazeKeyRot REAL4 0.0, 0.0	; Key rotation
MazeHostile BYTE 0			; Used with intro
MazeSiren REAL4 0.0			; Siren gain etc (intro)
MazeSirenTimer REAL4 51.0	; Siren timer (intro)
MazeTeleport BYTE 0
MazeTeleportPos REAL4 0.0, 0.0, 0.0, 0.0
MazeTeleportRot REAL4 0.0

MazeLevel DWORD 0	; Current maze layer
MazeLevelPopup BYTE 0	; Maze layer popup, 0 = none, 1 = down, 2 = up
MazeLevelPopupY REAL4 -48.0
MazeLevelPopupTimer REAL4 0.0

WBBK BYTE 0				; WBBK state
WBBKCamDir REAL4 0.0	; WBBK cam direction for lerping
WBBKDist REAL4 4.0		; WBBK distance factor
WBBKPos REAL4 1.0, 5.0	; WBBK position to draw at
WBBKSndID DWORD 5		; WBBK last ambient sound ID
WBBKSndPos REAL4 0.0, 0.0, 0.0, 0.0	; WBBK sound position
WBBKTimer REAL4 0.0		; WBBK general-purpose timer

MazeDrawCull DWORD 5	; The 'radius', in cells, to draw

Map BYTE 0				; Map state
MapBRID DWORD 0			; Map bottom-right cell ID (to not draw it)
MapOffset REAL4 0.0, 0.0; Map offset to center it (not yet used)
MapSize REAL4 0.0		; Map size multiplier to fit it into the parchment

Shop BYTE 1				; Shop state
ShopKoluplyk DWORD 78	; Koluplyk's list
ShopTimer REAL4 0.0		; Koluplyk's timer for animation
ShopWall REAL4 3.0		; For moving the shop wall after purchasing

Trench BYTE 0			; Trench state
TrenchTimer REAL4 0.0	; Trench timer, set in Control with movement
TrenchColor REAL4 1.0, 1.0, 1.0, 1.0	; To use as fog and clear color

IniReturn DB "........", 0	; Ini return dummy string
IniPathAbs DB 256 DUP (0)	; Absolute path to ini file

GetIniSettingsOnFirstFrame BYTE 0	; GetSettings on WM_CREATE had problems

; ----- UNINITIALIZED DATA -----
.DATA?
FPUMode WORD ?	; To load FPU control word

hInstance HINSTANCE ?	; Program instance
hwnd HWND ?		; Window handle
GDI HDC ?		; Graphics device context
GLC HANDLE ?	; OpenGL context
RandSeed DD ?	; Random seed for nrandom

Maze DWORD ?		; Maze memory
MazeBuffer DWORD ?	; Maze buffer pointer
MazeLevelStr DWORD ?; String, containing the layer number

TexBricks DWORD ?	; Textures
TexCompass DWORD ?
TexCompassWorld DWORD ?
TexCursor DWORD ?
TexDirt DWORD ?
TexDoor DWORD ?
TexDoorblur DWORD ?
TexFacade DWORD ?
TexFloor DWORD ?
TexGlyphs DWORD ?
TexHbd DWORD ?
TexKey DWORD ?
TexKoluplyk DWORD ?
TexLamp DWORD ?
TexMap DWORD ?
TexMetal DWORD ?
TexMetalFloor DWORD ?
TexMetalRoof DWORD ?
TexNoise DWORD ?
TexPipe DWORD ?
TexPlanks DWORD ?
TexRain DWORD ?
TexRoof DWORD ?
TexSigns1 DWORD ?
TexShadow DWORD ?
TexTaburetka DWORD ?
TexTilefloor DWORD ?
TexTree DWORD ?
TexVas DWORD ?
TexVignette DWORD ?
TexVignetteRed DWORD ?
TexWall DWORD ?
TexWBBK DWORD ?
TexWhitewall DWORD ?

TexGlyph DWORD 7 DUP(?)

TexWmblykHappy DWORD ?
TexWmblykNeutral DWORD ?
TexWmblykJumpscare DWORD ?
TexWmblykStr DWORD ?
TexWmblykL1 DWORD ?
TexWmblykL2 DWORD ?
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

SndAmb DWORD ?	; Sounds
SndAmbT DWORD ?
SndAmbW DWORD ?, ?, ?, ?
SndDeath DWORD ?
SndDig DWORD ?
SndDrip DWORD ?
SndExit DWORD ?
SndExplosion DWORD ?
SndHbd DWORD ?
SndHbdO DWORD ?
SndImpact DWORD ?
SndIntro DWORD ?
SndKey DWORD ?
SndKubale DWORD ?
SndKubaleAppear DWORD ?
SndKubaleV DWORD ?
SndMistake DWORD ?
SndMus2 DWORD ?
SndScribble DWORD ?
SndSiren DWORD ?
SndSlam DWORD ?
SndStep DWORD ?, ?, ?, ?
SndVirdya DWORD ?
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

ErrorOut PROTO :DWORD
FreeMaze PROTO
GenerateMaze PROTO
GetMazeCellPos PROTO :REAL4, :REAL4, :DWORD, :DWORD
GetOffset PROTO :DWORD, :DWORD
GetPosition PROTO :DWORD
GLE PROTO
Halt PROTO
InitContext PROTO :DWORD
MouseMove PROTO
MoveAndCollide PROTO :DWORD, :DWORD, :DWORD, :DWORD, :REAL4, :BYTE
Render PROTO
RenderUI PROTO
SetFullscreen PROTO :BYTE
SetMazeLevelStr PROTO :DWORD
Shake PROTO :REAL4
ShowHideCursor PROTO :BYTE
ShowSubtitles PROTO :DWORD
SpawnMazeElements PROTO

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
				invoke GetOffset, MazeX, MazeY
				add eax, MazeBuffer
				mov al, BYTE PTR [eax]
				and al, MZC_PASSTOP
				.IF !(al)
					inc Blocked
					.BREAK
				.ENDIF
				fld CheckY
				fsub flRaycast
				fstp CheckY
			CASE 1		;-X
				invoke GetOffset, MazeX, MazeY
				add eax, MazeBuffer
				mov al, BYTE PTR [eax]
				and al, MZC_PASSLEFT
				.IF !(al)
					inc Blocked
					.BREAK
				.ENDIF
				fld CheckX
				fsub flRaycast
				fstp CheckX
			CASE 2		;+Y
				inc MazeY
				invoke GetOffset, MazeX, MazeY
				add eax, MazeBuffer
				mov al, BYTE PTR [eax]
				and al, MZC_PASSTOP
				.IF !(al)
					inc Blocked
					.BREAK
				.ENDIF
				fld CheckY
				fadd flRaycast
				fstp CheckY
			CASE 3		;+X
				inc MazeX
				invoke GetOffset, MazeX, MazeY
				add eax, MazeBuffer
				mov al, BYTE PTR [eax]
				and al, MZC_PASSLEFT
				.IF !(al)
					inc Blocked
					.BREAK
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

; Control player, called if canControl != 0
Control PROC
	LOCAL curSpeed:REAL4
	mov curSpeed, 0
	fldz
	fst camCurSpeed
	fstp camCurSpeed[8]
	
	.IF (keyUp == 1) || (keyDown == 1)
		fld camForward		; X AXIS MOVEMENT
		fmul flCamSpeed
		.IF keyDown == 1
			fchs
		.ENDIF
		fadd camCurSpeed
		fstp camCurSpeed
		
		fld camForward[8]	; Y AXIS MOVEMENT
		fmul flCamSpeed
		.IF keyDown == 1
			fchs
		.ENDIF
		fadd camCurSpeed[8]
		fstp camCurSpeed[8]
		
		fld deltaTime
		fstp curSpeed
	.ENDIF
	.IF keyLeft == 1 || keyRight == 1
		fld camRight		; X AXIS MOVEMENT
		fmul flCamSpeed
		.IF keyLeft == 1
			fchs
		.ENDIF
		fadd camCurSpeed
		fstp camCurSpeed
		
		fld camRight[8]		; Y AXIS MOVEMENT
		fmul flCamSpeed
		.IF keyLeft == 1
			fchs
		.ENDIF
		fadd camCurSpeed[8]
		fstp camCurSpeed[8]
		
		fld camCurSpeed
		fmul camRight
		fstp curSpeed
		fld camCurSpeed[8]
		fmul camRight[8]
		fchs
		fadd curSpeed
		fstp curSpeed
		invoke Lerp, ADDR camTilt, curSpeed, delta2
		
		fld deltaTime
		fstp curSpeed
	.ENDIF
	
	fld camCurSpeed		; Deltatimize
	fmul deltaTime
	fstp camCurSpeed
	fld camCurSpeed[8]
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
	
	fld curSpeed	; Walk animation
	fmul flStep
	fadd camStep
	fstp camStep
	
	fld curSpeed
	fmul flStep
	fadd camStepSide
	fstp camStepSide
	
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
	.ENDIF
	fcmp camStepSide, PI2	; Loop camStep and play random step sound
	.IF !Sign? && !Zero?
		fld PI2
		fsubr camStepSide
		fstp camStepSide
	.ENDIF
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
	
	invoke LoadTexture, ADDR ImgBricks, IMG_GCT
	mov TexBricks, eax
	invoke LoadTexture, ADDR ImgCompass, IMG_GCT5A1
	mov TexCompass, eax
	invoke LoadTexture, ADDR ImgCompassWorld, IMG_GCT5A1
	mov TexCompassWorld, eax
	invoke LoadTexture, ADDR ImgCursor, IMG_GCT332
	mov TexCursor, eax
	invoke LoadTexture, ADDR ImgDirt, IMG_GCT
	mov TexDirt, eax
	invoke LoadTexture, ADDR ImgDoor, IMG_GCT
	mov TexDoor, eax
	invoke LoadTexture, ADDR ImgDoorblur, IMG_GCT
	mov TexDoorblur, eax
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
	invoke LoadTexture, ADDR ImgMap, IMG_GCT5A1
	mov TexMap, eax
	invoke LoadTexture, ADDR ImgMetal, IMG_GCT
	mov TexMetal, eax
	invoke LoadTexture, ADDR ImgMetalFloor, IMG_GCT
	mov TexMetalFloor, eax
	invoke LoadTexture, ADDR ImgMetalRoof, IMG_GCT
	mov TexMetalRoof, eax
	invoke LoadTexture, ADDR ImgNoise, IMG_GCT
	mov TexNoise, eax
	invoke LoadTexture, ADDR ImgPipe, IMG_GCT
	mov TexPipe, eax
	invoke LoadTexture, ADDR ImgPlanks, IMG_GCT
	mov TexPlanks, eax
	invoke LoadTexture, ADDR ImgRain, IMG_GCT
	mov TexRain, eax
	invoke LoadTexture, ADDR ImgRoof, IMG_GCT
	mov TexRoof, eax
	invoke LoadTexture, ADDR ImgSigns1, IMG_GCT
	mov TexSigns1, eax
	invoke LoadTexture, ADDR ImgShadow, IMG_GCT
	mov TexShadow, eax
	invoke LoadTexture, ADDR ImgTaburetka, IMG_GCT
	mov TexTaburetka, eax
	invoke LoadTexture, ADDR ImgTilefloor, IMG_GCT
	mov TexTilefloor, eax
	invoke LoadTexture, ADDR ImgTree, IMG_GCT5A1
	mov TexTree, eax
	invoke LoadTexture, ADDR ImgVas, IMG_GCT
	mov TexVas, eax
	invoke LoadTexture, ADDR ImgVignette, IMG_GCT or IMG_HALFY
	mov TexVignette, eax
	invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR
	invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR
	invoke LoadTexture, ADDR ImgVignetteRed, IMG_GCT or IMG_HALFY
	mov TexVignetteRed, eax
	invoke LoadTexture, ADDR ImgWall, IMG_GCT
	mov TexWall, eax
	invoke LoadTexture, ADDR ImgWBBK, IMG_GCT
	mov TexWBBK, eax
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
	invoke LoadIcon, NULL, IDI_APPLICATION
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
		invoke ShowHideCursor, 1
		
		invoke alGetSourcei, SndAmb, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndAmb
		.ENDIF
		invoke alGetSourcei, SndDrip, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndDrip
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
		invoke alGetSourcei, SndSiren, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndSiren
		.ENDIF
		invoke alGetSourcei, SndWhisper, AL_SOURCE_STATE, ADDR AudSt
		.IF (AudSt == AL_PLAYING)
			invoke alSourcePause, SndWhisper
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
		.IF (Menu == 0)
			.IF (playerState == 0)
				mov canControl, 1
			.ENDIF
			mov focused, 1
			invoke ShowHideCursor, 0
			
			invoke alGetSourcei, SndAmb, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndAmb
			.ENDIF
			invoke alGetSourcei, SndDrip, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndDrip
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
			invoke alGetSourcei, SndSiren, AL_SOURCE_STATE, ADDR AudSt
			.IF (AudSt == AL_PAUSED)
				invoke alSourcePlay, SndSiren
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
			mov canControl, 1
			mov playerState, 0
		.ENDIF
		ret
	.ELSEIF (playerState == 3)	; Exit continuous opendoor
		mov canControl, 0
		mov camCurSpeed, 0
		mov camCurSpeed[8], 0
		invoke Lerp, ADDR camRot, 1050253722, delta2
		invoke LerpAngle, ADDR camRot[4], 1078523331, delta2
		invoke Lerp, ADDR MazeDoor, 3267887104, delta2
		
		.IF (kubale < 29)
			mov kubale, 0
		.ENDIF
		
		invoke Lerp, ADDR camPos, MazeDoorPos, delta2
		invoke Lerp, ADDR camPos[8], MazeDoorPos[4], delta2
		
		fld PIHalfN
		fmul R2D
		fstp mtplr
		
		fcmp MazeDoor, mtplr
		.IF Sign? && !Zero?
			fld MazeDoorPos[4]
			fsub fl2
			fstp MazeDoorPos[4]
			mov fade, 0
			mov fadeState, 2
			mov playerState, 4
		.ENDIF
		ret
	.ELSEIF (playerState == 4)	; Exit continuous
		invoke Lerp, ADDR camRot, 1050253722, delta2
		invoke LerpAngle, ADDR camRot[4], 1078523331, delta2
		
		invoke Lerp, ADDR camPos, MazeDoorPos, delta2
		
		fld flHalf
		fadd flCamHeight
		fstp mtplr
		
		invoke Lerp, ADDR camPos[4], mtplr, deltaTime
		invoke Lerp, ADDR camPos[8], MazeDoorPos[4], delta2
		
		fcmp fade, fl1
		.IF !Sign? && Zero?
			invoke FreeMaze
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
			invoke GenerateMaze
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
		invoke ShowSubtitles, ADDR CCSpace
		
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
		.IF (playerState == 9)
			mov canControl, 0
			invoke Lerp, ADDR fade, fl1n2, deltaTime
			fcmp fade, fl1
			.IF !Sign?
				invoke alSourcePlay, SndDeath
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
		mov fade, 0
		m2m fogDensity, flTenth
		fcmp wmblykBlink
		.IF Sign?
			.IF (playerState == 17)
				invoke GenerateMaze
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
		fmul flFifth
		fst mtplr
		invoke LerpAngle, ADDR camRot[4], 1077936128, deltaTime
		fmul flHalf
		fstp mtplr
		invoke Lerp, ADDR camRot, 3206125978, mtplr
		
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
	LOCAL BndX1:REAL4, BndX2:REAL4, BndY1:REAL4, BndY2:REAL4, Dist:REAL4
	; Draw stuff
	invoke glCallList, List
	.IF (!canControl)
		ret
	.ENDIF
	
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
		invoke InRange, camPosNext, camPosNext[8], BndX1, BndX2, BndY1, BndY2
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
			invoke InRange, camPosNext, camPosNext[8], BndX1, BndX2, BndY1, BndY2
			
			.IF (al == 1)
				fld camCurSpeed
				fchs
				fstp camCurSpeed
				fld camCurSpeed[8]
				fchs
				fstp camCurSpeed[8]
			.ENDIF
		.ENDIF
	.ENDIF
	ret
DrawWall ENDP

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
		
		invoke glPushMatrix
		invoke glTranslatef, MazeX, 0, MazeY
		; Draw walls
		invoke glBindTexture, GL_TEXTURE_2D, CurrentWall
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
									lea eax, CCShop
									mov ccText, eax
									m2m ccTimer, flTenth
								.ENDIF
								mov Shop, 2
							.ELSE
								mov Shop, 1
							.ENDIF
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
					invoke DrawWall, CurrentWallMDL, MazeX, MazeY, 1
				.ENDIF
			.ENDIF
			invoke glRotatef, 1119092736, 0, fl1, 0
		.ENDIF
		
		invoke DrawFloorRoof, 2, MazeX, MazeY
		
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
				invoke DrawWall, 6, MazeX, MazeY, 0
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
				
				invoke DrawFloorRoofEnd, 2, MazeX, MazeY
				
				fld MazeX
				fadd fl2
				fstp MazeX1
				fld MazeY
				fsub fl2
				fstp MazeY1
				
				.IF (playerState == 0) && (MazeLocked != 1)
					invoke InRange, camPosN, camPosN[4], \
					MazeX, MazeX1, MazeY1, MazeY
					
					.IF (al == 1)
						invoke alSourcePlay, SndExit
						mov playerState, 3
					.ENDIF
				.ENDIF
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
				invoke glEnable, GL_BLEND
				invoke glBlendFunc, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
				invoke glTranslatef, camPosN, flHalf, camPosN[4]
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
	
		invoke glPushMatrix
			invoke glDisable, GL_LIGHTING
			invoke glEnable, GL_FOG
			invoke glDisable, GL_BLEND
			invoke glBindTexture, GL_TEXTURE_2D, 0
			invoke glTranslatef, MazeTeleportPos, 0, MazeTeleportPos[4]
			invoke glRotatef, MazeTeleportRot, 0, fl1, 0
			invoke glCallList, 47
			fld MazeTeleportRot
			fchs
			fstp rotVal
			invoke glRotatef, rotVal, 0, fl1, 0
			invoke glRotatef, rotVal, 0, fl1, 0
			invoke glCallList, 48
			
			invoke DistanceToSqr, camPosN, camPosN[4], MazeTeleportPos, MazeTeleportPos[4]
			mov rotVal, eax
			fcmp rotVal, flHalf
			.IF Sign?
				mov canControl, 0
				mov playerState, 18
				mov fadeState, 2
				invoke Lerp, ADDR camPosN, MazeTeleportPos, deltaTime
				fld camPosN
				fchs
				fstp camPos
				invoke Lerp, ADDR camPosN[4], MazeTeleportPos[4], deltaTime
				fld camPosN[4]
				fchs
				fstp camPos[8]
				mov camCurSpeed, 0
				mov camCurSpeed[8], 0
				
				fcmp fade, fl1
				.IF !Sign?
					invoke ShowSubtitles, ADDR CCTeleport
					invoke alSourcePlay, SndMistake
					print "Teleported player", 13, 10
					fld MazeTeleportPos[8]
					fchs
					fst camPos
					fst camPosNext
					fstp camPosL
					fld MazeTeleportPos[12]
					fchs
					fst camPos[8]
					fst camPosNext[8]
					fstp camPosL[8]
					mov fadeState, 1
					mov MazeTeleport, 0
					mov canControl, 1
					mov playerState, 0
				.ENDIF
			.ENDIF
		invoke glPopMatrix
		invoke glPushMatrix
			invoke glDisable, GL_LIGHTING
			invoke glEnable, GL_FOG
			invoke glDisable, GL_BLEND
			invoke glBindTexture, GL_TEXTURE_2D, 0
			invoke glTranslatef, MazeTeleportPos[8], 0, MazeTeleportPos[12]
			invoke glRotatef, MazeTeleportRot, 0, fl1, 0
			invoke glCallList, 47
			fld MazeTeleportRot
			fchs
			fstp rotVal
			invoke glRotatef, rotVal, 0, fl1, 0
			invoke glRotatef, rotVal, 0, fl1, 0
			invoke glCallList, 48
			
			invoke DistanceToSqr, camPosN, camPosN[4], MazeTeleportPos[8], MazeTeleportPos[12]
			mov rotVal, eax
			fcmp rotVal, flHalf
			.IF Sign?
				mov canControl, 0
				mov playerState, 18
				mov fadeState, 2
				invoke Lerp, ADDR camPosN, MazeTeleportPos[8], deltaTime
				fld camPosN
				fchs
				fstp camPos
				invoke Lerp, ADDR camPosN[4], MazeTeleportPos[12], deltaTime
				fld camPosN[4]
				fchs
				fstp camPos[8]
				mov camCurSpeed, 0
				mov camCurSpeed[8], 0
				
				fcmp fade, fl1
				.IF !Sign?
					invoke ShowSubtitles, ADDR CCTeleport
					invoke alSourcePlay, SndMistake
					print "Teleported player", 13, 10
					fld MazeTeleportPos
					fchs
					fst camPos
					fst camPosNext
					fstp camPosL
					fld MazeTeleportPos[4]
					fchs
					fst camPos[8]
					fst camPosNext[8]
					fstp camPosL[8]
					mov fadeState, 1
					mov MazeTeleport, 0
					mov canControl, 1
					mov playerState, 0
				.ENDIF
			.ENDIF
		invoke glPopMatrix
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
	LOCAL Char:BYTE, StrIdx:DWORD, StrLength:DWORD
	
	invoke glPushMatrix
	invoke glTranslatef, X, Y, 0
	invoke glScalef, mnFont, mnFont[4], fl1
	
	.IF (TextAlign != FNT_LEFT)
		invoke StrLen, TextString	; I guess MASM has StrLen
		mov StrLength, eax
		.IF (TextAlign == FNT_CENTERED)
			fld mnFontSpacing
			fimul StrLength
			fmul flHalf
			fchs
			fstp StrLength
		.ENDIF
		invoke glTranslatef, StrLength, 0, 0
	.ENDIF
	mov StrIdx, 0
	mov bl, 1
	
	.REPEAT
		mov eax, TextString
		mov ebx, StrIdx
		mov bl, BYTE PTR [eax+ebx]
		.IF (bl == 0)
			.BREAK
		.ENDIF
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
					invoke glBindTexture, GL_TEXTURE_2D, TexFont[152]
					invoke glCallList, 3
				CASE 33
					invoke glBindTexture, GL_TEXTURE_2D, TexFont[156]
					invoke glCallList, 3
				CASE 45
					invoke glBindTexture, GL_TEXTURE_2D, TexFont[160]
					invoke glCallList, 3
					
			ENDSW
		.ENDIF
		
		invoke glTranslatef, mnFontSpacing, 0, 0
		
		inc StrIdx
		mov bl, Char
	.UNTIL (bl == 0)
	
	invoke glPopMatrix
	ret
DrawBitmapText ENDP

; Draw placeable glyphs
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
	LOCAL PosXF:REAL4, PosYF:REAL4

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
			
			add eax, MazeBuffer
			mov al, BYTE PTR [eax]
			.IF (hbdRot == 0) || (hbdRot == 8)
				and al, MZC_PASSTOP
			.ELSE
				and al, MZC_PASSLEFT
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
		;invoke glMaterialf, GL_FRONT, GL_SHININESS, 1119879168
		invoke glCallList, kubale
	invoke glPopMatrix
	ret
DrawKubale ENDP

; Process Kubale AI
KubaleAI PROC
	LOCAL distance:REAL4, lookAt:REAL4, dotProduct:REAL4, dotX:REAL4, dotY:REAL4
	LOCAL nextPosX:REAL4, nextPosY:REAL4, mazePosX:SWORD, mazePosY:SWORD
	LOCAL cellCntX:REAL4, cellCntY:REAL4, blocked:BYTE, teleportAttempts:BYTE
	LOCAL PosX:DWORD, PosY:DWORD
	
	.IF (playerState != 0)
		invoke Lerp, ADDR kubaleRun, 0, delta10
		invoke Lerp, ADDR kubaleVision, 0, delta2
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
			mov eax, MazeWM1
			invoke nrandom, eax
			mov ebx, 2
			mul ebx
			inc eax
			mov PosX, eax
			
			mov eax, MazeHM1
			invoke nrandom, eax
			mul ebx
			inc eax
			mov PosY, eax
			
			fild PosX
			fstp kubalePos
			fild PosY
			fstp kubalePos[4]
			
			inc teleportAttempts
			
			invoke DistanceToSqr, kubalePos, kubalePos[4], \
			camPosNext, camPosNext[8]
			mov distance, eax
			fcmp distance, fl32
		.UNTIL (!Sign?) || (teleportAttempts > 8)
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
		
	mov blocked, 0
		
	fcmp dotProduct, flThird
	.IF (Sign?) && (!blocked)	; If not visible
		fld lookAt	; Rotate
		fmul R2D
		fstp kubaleDir
		
		mov blocked, 0
			
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
		.IF (Sign?) && (blocked == 0)
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
			invoke Lerp, ADDR vignetteRed, 0, deltaTime
			invoke Lerp, ADDR fade, 0, deltaTime
		.ENDIF
	.ELSE
		invoke Lerp, ADDR kubaleVision, 0, delta2
		invoke Lerp, ADDR vignetteRed, 0, deltaTime
		invoke Lerp, ADDR fade, 0, deltaTime
		invoke Lerp, ADDR kubaleRun, 0, delta10
	.ENDIF
	
	invoke alSourcef, SndKubaleV, AL_GAIN, kubaleVision
	invoke alSourcef, SndKubale, AL_GAIN, kubaleRun
	invoke alSource3f, SndKubale, AL_POSITION, kubalePos, 0, kubalePos[4]
	ret
KubaleAI ENDP

; Spawn Kubale into the layer with random position
MakeKubale PROC
	LOCAL PosX:DWORD, PosY:DWORD
	mov kubale, 29
	
	invoke alSourcePlay, SndKubale
	invoke alSourcePlay, SndKubaleV
	
	mov eax, MazeWM1
	dec eax
	invoke nrandom, eax
	inc eax
	mov ebx, 2
	mul ebx
	inc eax
	mov PosX, eax
	
	mov eax, MazeHM1
	dec eax
	invoke nrandom, eax
	inc eax
	mul ebx
	inc eax
	mov PosY, eax
	fild PosX
	fstp kubalePos
	fild PosY
	fstp kubalePos[4]
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


DrawWBBK PROC
	LOCAL rotDir:REAL4
	
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
	
	
	invoke GetDirection, WBBKPos, WBBKPos[4], camPosN, camPosN[4]	; Direction
	mov rotDir, eax
	fld rotDir
	fmul R2D
	fstp rotDir
	
	invoke glPushMatrix
		;invoke glDisable, GL_FOG
		invoke glDisable, GL_LIGHTING
		invoke glEnable, GL_BLEND
		invoke glBlendFunc, GL_ONE, GL_ONE
		invoke glTranslatef, WBBKPos, fl1, WBBKPos[4]
		invoke glRotatef, rotDir, 0, fl1, 0
		invoke glBindTexture, GL_TEXTURE_2D, TexWBBK
		invoke glCallList, 84
		;invoke glEnable, GL_FOG
		invoke glEnable, GL_LIGHTING
	invoke glPopMatrix
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
	LOCAL MazeX:DWORD, MazeY:DWORD, MazeI:DWORD, WalkX:REAL4, WalkY:REAL4, ChoosePath: DWORD, ChooseByte:BYTE
	LOCAL anim:DWORD, face:DWORD
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
		fld wmblykBlink
		fmul wmblykWalkAnim
		fistp anim
		
		add anim, 11	; Animate walking
		.IF (anim >= 15)
			mov anim, 14
		.ENDIF
		fcmp wmblykBlink
		.IF Sign?
			fld wmblykWalkAnim
			fadd fl1
			fdivr fl4
			fstp wmblykBlink
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
		.IF Sign? || Zero?
			inc ChoosePath
		.ENDIF
		invoke DistanceScalar, WalkY, flHalf
		mov WalkY, eax
		fcmp WalkY, flTenth
		.IF Sign? || Zero?
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
			.IF Sign? && !Zero?
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
		fistp anim
		
		mov eax, wmblykStrState	; Animate strangling
		add anim, eax
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
			mov anim, 24
			mov playerState, 8
			mov wmblyk, 13
			m2m face, TexWmblykL1
		.ELSEIF
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
		mov anim, 24
		invoke glColor3f, 0, 0, 0
		
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
		invoke glCallList, anim
		
		invoke glEnable, GL_BLEND
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

; Draw
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
	
	fld virdyaRotL
	fmul R2D
	fstp rotDeg

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
		invoke nrandom, 6
		mov rand, eax
		.IF (virdyaState == 0)
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
			.ENDIF
		.ELSEIF (virdyaState == 1)
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
		.ENDIF
	.ENDIF
	
	mov headHeight, 1068457001
	.IF (virdyaState == 0)	; Standing process
		mov virdyaSpeed, 0
		mov virdyaSpeed[4], 0
		invoke Lerp, ADDR virdyaSound, 0, delta2
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
		
		.IF (playerState == 0)
			mov close, 0
			;fcmp distance, fl12
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
				invoke Lerp, ADDR fade, 0, delta2
				invoke Lerp, ADDR vignetteRed, 0, delta2
				invoke Lerp, ADDR virdyaSound, 0, delta2
			.ENDIF
		.ELSE
			invoke Lerp, ADDR virdyaSound, 0, delta2
		.ENDIF
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
		fcmp distance, fl32
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
	.IF (wmblyk == 11) || (wmblyk == 12)
		invoke DistanceToSqr, virdyaPos, virdyaPos[4], wmblykPos, wmblykPos[4]
		mov distance, eax
		fcmp distance, fl2
		.IF (Sign?)
			mov virdyaState, 2
			m2m virdyaFace, TexVirdyaN
			invoke GetDirection, virdyaPos, virdyaPos[4], \
			wmblykPos, wmblykPos[4]
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
			inc close
		.ENDIF
	.ENDIF
	.IF (Glyphs == 7) && (virdyaState > 1) && (!close)
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
			.IF (virdyaState < 2)
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

; Free maze data from memory
FreeMaze PROC
	invoke GlobalUnlock, MazeBuffer
	invoke GlobalFree, Maze
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
	
	.IF (Menu == 0)
		fild diff
		fidiv perfFreq
	.ELSE
		fldz
	.ENDIF
	.IF (debugF)
		fmul fl3
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
	mov eax, PosX
	.IF (eax > 2147483647)
		mov PosX, 0
	.ELSEIF (eax > MazeWM1)
		mov eax, MazeWM1
		mov PosX, eax
	.ENDIF
	mov eax, PosY
	.IF (eax > 2147483647)
		mov PosY, 0
	.ELSEIF (eax > MazeHM1)
		mov eax, MazeHM1
		mov PosY, eax
	.ENDIF
	
	mov eax, MazeW
	mul PosY
	add eax, PosX
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
	; Get absolute path to settings.ini
	invoke GetFullPathNameA, ADDR IniPath, LENGTH IniPathAbs, ADDR IniPathAbs, 0
	; Width & height
	invoke GetPrivateProfileInt, ADDR IniGraphics, ADDR IniWidth, \
	800, ADDR IniPathAbs
	mov winW, ax
	invoke GetPrivateProfileInt, ADDR IniGraphics, ADDR IniHeight, \
	600, ADDR IniPathAbs
	mov winH, ax
	invoke SetWindowPos, hwnd, HWND_TOPMOST, 0, 0, winW, winH, \
	SWP_NOZORDER or SWP_FRAMECHANGED or SWP_SHOWWINDOW or SWP_NOMOVE
	
	; Fullscreen
	invoke GetPrivateProfileString, ADDR IniGraphics, ADDR IniFullscreen, \
	ADDR IniFalse, ADDR IniReturn, 9, ADDR IniPathAbs
	.IF (IniReturn == 116) || (IniReturn == 84) ;t or T
		mov fullscreen, -1
		invoke SetFullscreen, fullscreen
	.ENDIF
	
	; Brightness
	invoke GetPrivateProfileString, ADDR IniGraphics, ADDR IniBrightness, \
	ADDR Ini05, ADDR IniReturn, 9, ADDR IniPathAbs
	print ADDR IniReturn, 13, 10
	invoke ParseFloat, ADDR IniReturn
	mov Gamma, eax
	
	; Sensitivity
	invoke GetPrivateProfileString, ADDR IniControls, ADDR IniSensitivity, \
	ADDR Ini03, ADDR IniReturn, 9, ADDR IniPathAbs
	print ADDR IniReturn, 13, 10
	invoke ParseFloat, ADDR IniReturn
	mov camTurnSpeed, eax
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
	mov ebx, 2
	mul ebx		; *2 = to world coords
	inc eax		; center
	mov XPos, eax
	
	mov eax, MazeHM1
	sub eax, 2
	invoke nrandom, eax
	inc eax
	mul ebx		; *2 = to world coords
	inc eax		; center
	mov YPos, eax
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
		invoke nrandom, 4	; Random environment
		SWITCH eax
			CASE 0
				m2m CurrentWall, TexWall
			CASE 1
				m2m CurrentWall, TexMetal
			CASE 2
				m2m CurrentWall, TexWhitewall
			CASE 3
				m2m CurrentWall, TexBricks
		ENDSW
		invoke nrandom, 3
		SWITCH eax
			CASE 0
				m2m CurrentWallMDL, 1
			CASE 1
				m2m CurrentWallMDL, 25
			CASE 2
				m2m CurrentWallMDL, 26
		ENDSW
		invoke nrandom, 2
		SWITCH eax
			CASE 0
				m2m CurrentRoof, TexRoof
			CASE 1
				m2m CurrentRoof, TexMetalRoof
		ENDSW
		invoke nrandom, 3
		SWITCH eax
			CASE 0
				m2m CurrentFloor, TexFloor
			CASE 1
				m2m CurrentFloor, TexMetalFloor
			CASE 2
				m2m CurrentFloor, TexTilefloor
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
	
	.IF (MazeHostile == 1)
		invoke nrandom, 3	; Door slam event
		.IF !(eax)
			print "Will slam door.", 13, 10
			mov doorSlam, 1
		.ENDIF
	
		invoke nrandom, MazeLevel	; Key
		.IF (eax > 7)
			print "Locking maze.", 13, 10
			mov MazeLocked, 1
			invoke GetRandomMazePosition, ADDR MazeKeyPos, \
			ADDR MazeKeyPos[4]
		.ENDIF
		
		.IF (Glyphs < 5)
			invoke nrandom, 3	; Glyphs
			.IF (eax == 0) || (Glyphs == 0)
				print "Spawned glyphs.", 13, 10
				mov MazeGlyphs, 1
				invoke GetRandomMazePosition, \
				ADDR MazeGlyphsPos, ADDR MazeGlyphsPos[4]
			.ENDIF
		.ENDIF
		
		.IF (Compass != 2) && (MazeLevel > 11)	; Compass
			mov Compass, 0
			invoke nrandom, 2
			.IF (eax == 0)
				print "Spawned compass.", 13, 10
				mov Compass, 1
				invoke GetRandomMazePosition, \
				ADDR CompassPos, ADDR CompassPos[4]
			.ENDIF
		.ENDIF
		
		mov wmblyk, 0
		mov wmblykStealthy, 0
		mov wmblykBlink, 0
		.IF (MazeLevel > 6)
			invoke nrandom, 2
			.IF (eax == 0)
				invoke GetRandomMazePosition, \
				ADDR wmblykPos, ADDR wmblykPos[4]
				
				print "Spawned Wmblyk", 13, 10
				mov wmblyk, 8
				invoke nrandom, 2
				.IF (eax == 0)
					invoke MakeWmblykStealthy
				.ENDIF
				.IF (MazeLevel > 9)
					invoke nrandom, 2
					.IF (eax == 0)
						mov wmblykStealthy, 0
						mov wmblyk, 11
						mov wmblykTurn, 0
						invoke alSourcef, SndWmblykB, AL_GAIN, fl1
						invoke alSourcePlay, SndWmblykB
						print "Wmblyk is angry", 13, 10
					.ENDIF
				.ENDIF
			.ENDIF
		.ENDIF
		
		.IF (MazeLevel > 12)
			invoke nrandom, 3
			.IF (eax == 0)
				print "Spawned Kubale", 13, 10
				invoke nrandom, 10
				.IF (eax == 0) || (kubaleAppeared == 0)
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
		
		invoke nrandom, 3	; Virdya
		.IF (MazeLevel > 13) && (kubale == 0) && (eax == 0)
			print "Spawned Virdya", 13, 10
			mov virdya, 63
			mov virdyaState, 0
			m2m virdyaFace, TexVirdyaNeut
			mov virdyaSound, 0
			invoke alSourcePlay, SndVirdya
			invoke GetRandomMazePosition, \
			ADDR virdyaPos, ADDR virdyaPos[4]
		.ENDIF
		
		.IF (MazeLevel > 15) && (kubale == 0) && (virdya == 0)	; HBD
			print "Huenbergondel?", 9
			print str$(wmblyk), 9
			print sbyte$(wmblykStealthy), 13, 10
			.IF (wmblyk == 0) || (wmblykStealthy == 1)
				print "Huenbergondel", 13, 10
				mov hbd, 1
				
				m2m PosX, MazeWM1
				sub PosX, 1
				m2m PosY, MazeHM1
				sub PosY, 1
				
				invoke nrandom, PosX
				add eax, 1
				mov hbdPos, eax
				invoke nrandom, PosY
				add eax, 1
				mov hbdPos[4], eax
				
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
		
		.IF (MazeLevel > 10)
			invoke nrandom, 3
			.IF (eax == 0)
				print "Spawned teleporters", 13, 10
				mov MazeTeleport, 1
				invoke GetRandomMazePosition, \
				ADDR MazeTeleportPos, ADDR MazeTeleportPos[4]
				invoke GetRandomMazePosition, \
				ADDR MazeTeleportPos[8], ADDR MazeTeleportPos[12]
			.ENDIF
		.ENDIF
	
	
		print "Maze size is: "
		print str$(MazeW), 9
		print str$(MazeH), 9
		print str$(MazeSize), 13, 10
		.IF (MazeSize > 80)	; Shop
			.IF (Glyphs >= 5) || (MazeGlyphs)
				invoke SetupShopMap
			.ENDIF
		.ENDIF
	
		.IF (MazeLevel > 17) && (MazeSize < 100)	; WBBK
			invoke nrandom, 16
			.IF (eax == 0)
				mov hbd, 0
				mov kubale, 0
				mov MazeGlyphs, 0
				mov MazeLocked, 0
				mov Shop, 0
				mov wmblyk, 0
				mov virdya, 0
				
				mov WBBK, 1
				
				invoke glLightModelfv, GL_LIGHT_MODEL_AMBIENT, ADDR clBlack
				invoke glLightf, GL_LIGHT0, GL_CONSTANT_ATTENUATION, 0
				invoke glLightf, GL_LIGHT0, GL_QUADRATIC_ATTENUATION, fl2
				
				invoke alSourceStop, SndAmb
				invoke alSourcef, SndAmbT, AL_PITCH, flFifth
				invoke alSourcePlay, SndAmbT
				invoke alSourcef, SndStep, AL_PITCH, flThird
				invoke alSourcef, SndStep[4], AL_PITCH, flThird
				invoke alSourcef, SndStep[8], AL_PITCH, flThird
				invoke alSourcef, SndStep[12], AL_PITCH, flThird
			.ENDIF
		.ENDIF
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

; Generates the maze and spawns maze elements with the procedures above
GenerateMaze PROC
	LOCAL PosX: DWORD, PosY: DWORD, PoolI: BYTE, StackCntr: DWORD
	LOCAL PoolX: DWORD, PoolY: DWORD, ByteChosen: BYTE, MazePoolCopy: DWORD
	
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
	
	invoke nrandom, MazeWM1	; Position = Random(Width), Random(Height)
	mov PosX, eax
	invoke nrandom, MazeHM1
	mov PosY, eax
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
				.IF (cl == 0)				; if !CL.Visited
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
			
			print "Pos: "
			print str$(PosX), 32
			print str$(PosY)
			print ", MazePool is "
			print uhex$(MazePool), 13, 10
			
			.IF (MazePool == 0)	; No direction to draw from
				print "No direction, MazePool is "
				print str$(MazePool), 13, 10
				.IF (StackCntr == 0) ; This is the end, the bitter, bitter end
					print "Back to start", 13, 10
					
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
					
					mov doorSlam, 0
					mov GlyphsInLayer, 0
					mov hbd, 0
					mov kubale, 0
					mov MazeGlyphs, 0
					mov MazeLocked, 0
					mov MazeTeleport, 0
					mov Map, 0
					mov Shop, 0
					mov virdya, 0
					mov vignetteRed, 0
					mov wmblyk, 0
					mov wmblykStealthy, 0
					
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
					
					invoke alSourceStop, SndHbd
					invoke alSourceStop, SndKubale
					invoke alSourceStop, SndKubaleV
					invoke alSourceStop, SndVirdya
					
					mov al, Glyphs
					sub al, 7
					mov bl, -4
					mul bl
					mov GlyphOffset, al
					
					.IF (MazeLevel > 16)
						invoke nrandom, 10
						.IF (eax == 0)
							invoke SpawnTrench
						.ENDIF
					.ENDIF

					.IF !(Trench)
						invoke SpawnMazeElements
					.ENDIF
					ret
				.ENDIF
				
				pop PosY	; Continue our journey
				pop PosX
				dec StackCntr
			.ENDIF
		.UNTIL (MazePool != 0)
		
		print "Found way", 13, 10
		
		mov ByteChosen, 0	; Pool index = random(Pool.Length)
		.WHILE (ByteChosen == 0)
			invoke nrandom, 4
			mov ebx, 8
			mul ebx
			mov PoolI, al	; Random shift amount
			
			
			mov cl, PoolI
			mov ebx, MazePool
			shr ebx, cl
			mov ByteChosen, bl
			
			.IF (ByteChosen == 0)
				.CONTINUE
			.ENDIF
			
			invoke GetOffset, PosX, PosY	; Maze[x, y].Visited = true
			mov ebx, eax
			mov eax, MazeBuffer
			or BYTE PTR [eax+ebx], MZC_VISITED
			
			; Offset (Pool[Pool index])
			.IF (PoolI == 0)		; [0, -1]
				invoke GetOffset, PosX, PosY
				mov ebx, eax
				mov eax, MazeBuffer
				or BYTE PTR [eax+ebx], MZC_PASSTOP
				dec PosY
				print "Going up", 13, 10
			.ELSEIF (PoolI == 8)	; [-1, 0]
				invoke GetOffset, PosX, PosY
				mov ebx, eax
				mov eax, MazeBuffer
				or BYTE PTR [eax+ebx], MZC_PASSLEFT
				dec PosX
				print "Going left", 13, 10
			.ELSEIF (PoolI == 16)	; [0, 1]
				inc PosY
				invoke GetOffset, PosX, PosY
				mov ebx, eax
				mov eax, MazeBuffer
				or BYTE PTR [eax+ebx], MZC_PASSTOP
				print "Going down", 13, 10
			.ELSE					; [1, 0]
				inc PosX
				invoke GetOffset, PosX, PosY
				mov ebx, eax
				mov eax, MazeBuffer
				or BYTE PTR [eax+ebx], MZC_PASSLEFT
				print "Going right", 13, 10
			.ENDIF
			
			invoke GetOffset, PosX, PosY	; Maze[x, y].Visited = true
			mov ebx, eax
			mov eax, MazeBuffer
			or BYTE PTR [eax+ebx], MZC_VISITED
			
			invoke nrandom, 32	; Misc
			.IF (eax == 0)
				mov eax, MazeBuffer
				or BYTE PTR [eax+ebx], MZC_LAMP 
			.ENDIF
			invoke nrandom, 30
			.IF (eax == 0)
				mov eax, MazeBuffer
				or BYTE PTR [eax+ebx], MZC_PIPE 
			.ENDIF
			invoke nrandom, 29
			.IF (eax == 0)
				mov eax, MazeBuffer
				or BYTE PTR [eax+ebx], MZC_WIRES 
			.ENDIF
			
			invoke nrandom, 33
			.IF (MazeLevel == 0) && (PosX == 1) && (PosY == 0)
				xor eax, eax
			.ENDIF
			.IF (eax == 0)
				mov eax, MazeBuffer
				or BYTE PTR [eax+ebx], MZC_TABURETKA
			.ENDIF
			invoke nrandom, 2
			.IF (eax)
				mov eax, MazeBuffer
				or BYTE PTR [eax+ebx], MZC_ROTATED
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
	
	invoke LoadAudio, ADDR SndAmbPath, ADDR SndAmb
	invoke LoadAudio, ADDR SndAmbTPath, ADDR SndAmbT
	invoke LoadAudio, ADDR SndDeathPath, ADDR SndDeath
	invoke LoadAudio, ADDR SndDigPath, ADDR SndDig
	invoke LoadAudio, ADDR SndDripPath, ADDR SndDrip
	invoke LoadAudio, ADDR SndExitPath, ADDR SndExit
	invoke LoadAudio, ADDR SndExplosionPath, ADDR SndExplosion
	invoke LoadAudio, ADDR SndHbdPath, ADDR SndHbd
	invoke LoadAudio, ADDR SndHbdOPath, ADDR SndHbdO
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
	invoke LoadAudio, ADDR SndScribblePath, ADDR SndScribble
	invoke LoadAudio, ADDR SndSirenPath, ADDR SndSiren
	invoke LoadAudio, ADDR SndSlamPath, ADDR SndSlam
	invoke LoadAudio, ADDR SndVirdyaPath, ADDR SndVirdya
	invoke LoadAudio, ADDR SndWhisperPath, ADDR SndWhisper
	invoke LoadAudio, ADDR SndWmblykPath, ADDR SndWmblyk
	invoke LoadAudio, ADDR SndWmblykBPath, ADDR SndWmblykB
	invoke LoadAudio, ADDR SndWmblykStrPath, ADDR SndWmblykStr
	invoke LoadAudio, ADDR SndWmblykStrMPath, ADDR SndWmblykStrM
	
	invoke LoadAudio, ADDR SndAmbW1Path, ADDR SndAmbW
	invoke LoadAudio, ADDR SndAmbW2Path, ADDR SndAmbW[4]
	invoke LoadAudio, ADDR SndAmbW3Path, ADDR SndAmbW[8]
	invoke LoadAudio, ADDR SndAmbW4Path, ADDR SndAmbW[12]
	
	invoke LoadAudio, ADDR SndMus2Path, ADDR SndMus2
	invoke alSourcef, SndMus2, AL_GAIN, flHalf
	
	invoke alSourcei, SndAmb, AL_LOOPING, AL_TRUE
	invoke alSourcei, SndAmbT, AL_LOOPING, AL_TRUE
	invoke alSourcei, SndWmblykB, AL_LOOPING, AL_TRUE
	invoke alSourcef, SndWmblykB, AL_ROLLOFF_FACTOR, fl4
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
	invoke alSourcef, SndVirdya, AL_GAIN, 0
	invoke alSourcei, SndVirdya, AL_LOOPING, AL_TRUE
	invoke alSourcei, SndWhisper, AL_LOOPING, AL_TRUE
	invoke alSourcef, SndWhisper, AL_ROLLOFF_FACTOR, fl2
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
	;invoke glLightf, GL_LIGHT0, GL_QUADRATIC_ATTENUATION, flFifth
	;invoke glLightf, GL_LIGHT0, GL_QUADRATIC_ATTENUATION, flHalf
	
	;invoke glLightModelfv, GL_LIGHT_MODEL_AMBIENT, ADDR clBlack
	
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
	.ELSEIF Key == 13
		.IF (Shop == 2)
			.IF (Glyphs >= 5)
				sub Glyphs, 5
				mov Shop, 3
				invoke alSourcePlay, SndHbd
				invoke alSource3f, SndDig, AL_POSITION, fl1N, 0, fl1
				invoke alSourcePlay, SndDig
				invoke alSourcePlay, SndMistake
				mov al, Glyphs
				sub al, 7
				mov bl, -4
				mul bl
				mov GlyphOffset, al
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
		ret
	.ELSEIF Key == 27
		.IF (playerState >= 11) && (playerState <= 17)
			invoke alSourceStop, SndIntro
			invoke alSourcePlay, SndSiren
			invoke GenerateMaze
			mov MazeHostile, 0
			mov playerState, 1
			ret
		.ENDIF
		.IF (State == 1)
			invoke DoMenu
		.ENDIF
		ret
	.ELSEIF Key == 115
		.IF (State == 0)
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
			.IF (State == 1) && (playerState != 9) && (playerState != 10)
				fild MazeLevel
				fsqrt
				fdivr fl04
				fadd wmblykStr
				fstp wmblykStr
			.ENDIF
		.ENDIF
		ret
	.ELSEIF Key == 71
		.IF (State == 0) && (canControl)
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
				invoke alSourcef, SndAmb, AL_PITCH, fl3
				invoke alSourcef, SndExplosion, AL_PITCH, fl3
				invoke alSourcef, SndExit, AL_PITCH, fl3
				invoke alSourcef, SndImpact, AL_PITCH, fl3
				invoke alSourcef, SndIntro, AL_PITCH, fl3
				invoke alSourcef, SndKubaleAppear, AL_PITCH, fl3
				invoke alSourcef, SndSiren, AL_PITCH, fl3
			.ELSE
				invoke alSourcef, SndAmb, AL_PITCH, fl1
				invoke alSourcef, SndExplosion, AL_PITCH, fl1
				invoke alSourcef, SndExit, AL_PITCH, fl1
				invoke alSourcef, SndImpact, AL_PITCH, fl1
				invoke alSourcef, SndIntro, AL_PITCH, fl1
				invoke alSourcef, SndKubaleAppear, AL_PITCH, fl1
				invoke alSourcef, SndSiren, AL_PITCH, fl1
			.ENDIF
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
			mov wmblyk, 8
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
	.ELSEIF Key == 89
		.IF (State == 0)
			mov wmblyk, 11
			m2m wmblykPos, fl1
			m2m wmblykPos[4], fl1
			invoke alSourcePlay, SndWmblykB
		.ENDIF
		ret
	.ELSEIF Key == 66
		.IF (State == 0)
			mov Glyphs, 7
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
	.ELSEIF Key == 86
		.IF (State == 0)
			m2m virdyaPos, camPosN
			m2m virdyaPos[4], camPosN[4]
			mov virdya, 67
		.ENDIF
	.ENDIF
	
	ret
KeyPress ENDP

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
	
	invoke Clamp, camRot, PIHalfN, PIHalf	; Clamp pitch so you can't spindash
	mov camRot, eax
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

; Render frame
Render PROC
	LOCAL camRotDeg:REAL4
	LOCAL camSin:REAL4
	LOCAL camCos:REAL4
	
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
	
	.IF (canControl)
		invoke Control
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
			fst camRotDeg
			
			invoke alSourcef, SndImpact, AL_GAIN, camRotDeg
			invoke alSourcePlay, SndImpact
			
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
	
	invoke glLightfv, GL_LIGHT0, GL_POSITION, ADDR camLight	; Draw light
	
	.IF (Trench)
		fld delta2
		fmul fl4
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
	
	.IF (WBBK)
		invoke DrawWBBK
	.ENDIF
	
	.IF (kubale > 28)
		invoke KubaleAI
		invoke DrawKubale
	.ELSEIF (kubale > 0)
		invoke KubaleEvent
	.ENDIF
	
	.IF (wmblyk == 8) || (wmblyk == 10)
		invoke DrawWmblyk
	.ELSEIF (wmblyk > 10)
		invoke DrawWmblykAngry
	.ENDIF
	
	invoke glDisable, GL_BLEND
	invoke DrawMazeItems
	
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
		;fst fade
		
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
		;fst fade
		
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
	.ELSEIF (playerState == 15)	; GreatCorn presents
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
	.ELSEIF (playerState == 17)	; GreatCorn presents
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
	
	.IF (Menu != 0)	; Menu
		invoke glLoadIdentity	; BG
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
		
		.IF (Maze)
			invoke glLoadIdentity	; Maze layer
			invoke glBlendFunc, GL_ONE_MINUS_DST_COLOR, GL_ONE_MINUS_SRC_COLOR
			invoke glBindTexture, GL_TEXTURE_2D, 0
			invoke glTranslatef, 1090519040, 1090519040, 0
			invoke DrawBitmapText, ADDR CCLevel, 0,  0, FNT_LEFT
			invoke DrawBitmapText, MazeLevelStr, 1123024896,  0, FNT_LEFT
		.ENDIF
	.ENDIF
	.IF (Menu == 1)
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
			fld flHalf
			fadd flFifth
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
			fld flHalf
			fadd flFifth
			.IF (keyLMB == 1)
				inc Menu
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
			fld flHalf
			fadd flFifth
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
		invoke glColor4f, fl1, fl1, fl1, fl1
		
		invoke DrawBitmapText, ADDR MenuPaused, 0, 3267362816, FNT_CENTERED
		
		
		
		invoke glBlendFunc, GL_ZERO, GL_ONE_MINUS_SRC_COLOR
		; RESUME
		invoke DrawBitmapText, ADDR MenuResume, 0, 1090519040, FNT_CENTERED
		
		; GAMMA
		invoke DrawBitmapText, ADDR MenuSettings, 0, 1116209152, FNT_CENTERED
		
		; EXIT
		invoke DrawBitmapText, ADDR MenuExit, 0, 1124073472, FNT_CENTERED
	.ELSEIF (Menu == 2)
		fld screenWF
		fmul flHalf
		fstp btnOffX
		fld screenHF
		fmul flHalf
		fstp btnOffY
		
		invoke glLoadIdentity
		invoke glTranslatef, btnOffX, btnOffY, 0
		invoke DrawBitmapText, ADDR MenuSettingsWIP1, 0, 3258974208, FNT_CENTERED
		invoke DrawBitmapText, ADDR MenuSettingsWIP2, 0, 0, FNT_CENTERED
		invoke DrawBitmapText, ADDR MenuSettingsWIP3, 0, 1111490560, FNT_CENTERED
	.ENDIF
	
	invoke glBlendFunc, GL_DST_COLOR, GL_SRC_COLOR
	invoke DrawNoise, TexNoise
	
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

; Set fullscreen mode to _FS
SetFullscreen PROC _FS:BYTE
	LOCAL fullScreenX: DWORD, fullScreenY: DWORD
	LOCAL winRect: RECT
	
	print "Setting fullscreen: "
	print sbyte$(_FS), 13, 10
	.IF (_FS != 0)
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
		;invoke GenerateMaze
	.ELSEIF uMsg==WM_DESTROY
		invoke Halt
	.ELSEIF uMsg==WM_PAINT
		invoke Render
	.ELSEIF uMsg==WM_KEYDOWN
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
		invoke CreateThread, NULL, 0, OFFSET MouseMove, 0, 0, NULL
	.ELSEIF uMsg==WM_SETCURSOR
		invoke ShowHideCursor, 0
	.ELSEIF uMsg==WM_LBUTTONDOWN
		.IF (Menu == 0) && (focused == 0)
			mov focused, 1
			invoke ShowHideCursor, 0
		.ENDIF
		mov keyLMB, 1
	.ELSEIF uMsg==WM_LBUTTONUP
		mov keyLMB, 0
	.ELSEIF uMsg==WM_KILLFOCUS
		.IF (Menu == 0) && (focused == 1)
			mov focused, 0
			invoke ShowHideCursor, 1
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