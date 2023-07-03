@echo off
choice /c CW /n /m "Build for subsystem [C]onsole or [W]indows?"
set targetSystem=CONSOLE
if errorlevel==2 set targetSystem=WINDOWS
ml /c /coff masmze.asm
link /subsystem:%targetSystem% masmze.obj /out:"MASMZE-3D.exe"