# MASMZE-3D
MASMZE-3D is a horror maze-runner game made almost entirely on x86 Assembly and native WinAPI procedures with the help of the Microsoft Macro Assembler (MASM32).
This is the **source code** repository, to play the game, download it from https://itch.io/game/edit/2143353

## Building
To build the game, you can use the **makeit.bat** file included in the folder. Before building, make sure to check the include paths in **masmze.asm**.
The repository does not include the libraries **stb_vorbis** and **OpenAL Soft**, you can download (and build) them from: https://github.com/nothings/stb and https://openal-soft.org/ . You can also use the installable OpenAL library by changing **OpenALPath** in **audio.inc** to a valid path to OpenAL.dll.
The repository also does not include any game assets, the use of which, together with the game logic, are hard-coded. To get the resources, you can download the game.

## Resource specification
Most of the custom resources are simply raw data, the reading (and parsing) of which is easy to understand from **audio.inc** and **importers.inc**.
