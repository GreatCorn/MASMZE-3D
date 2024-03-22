@echo off
choice /c CW /n /m "Build for subsystem [C]onsole or [W]indows?"
set targetSystem=CONSOLE
if errorlevel==2 set targetSystem=WINDOWS
set /p masmDir=Input your MASM32 directory (e.g. "C:\masm32"):
ml /c /coff /I %masmDir% masmze.asm
link /subsystem:%targetSystem% masmze.obj /libpath:%masmDir%"\lib" /release /out:"MASMZE-3D.exe"