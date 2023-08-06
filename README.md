# MASMZE-3D
MASMZE-3D is a horror maze-runner game made almost entirely on x86 Assembly and native WinAPI procedures with the help of the Microsoft Macro Assembler (MASM32).
This is the **source code** repository, to play the game, download it from https://greatcorn.itch.io/masmze-3d or https://gamejolt.com/games/masmze-3D/829109

## Building
To build the game, you can use the **makeit.bat** file included in the folder. Before building, make sure to check the include paths in **masmze.asm**.
The repository does not include the libraries **stb_vorbis** and **OpenAL Soft**, you can download (and build) them from: https://github.com/nothings/stb and https://openal-soft.org/ . You can also use the installable OpenAL library by changing **OpenALPath** in **audio.inc** to a valid path to OpenAL.dll.
The repository also does not include any game assets, the use of which, together with the game logic, are hard-coded. To get the resources, you can download the game.

## Resource specification
Most of the custom resources are simply raw data, the reading (and parsing) of which is easy to understand from **audio.inc** and **importers.inc**.
GCT is a raw image data format that has a 4-byte header, containing its width, in pixels. Then, the data is placed in one of OpenGL's supported color formats in RGB(A) order.
GCM is a model format, similar to obj, however, it doesn't support multiple materials and indexing. It stores model data in UV2-Normal3-Vertex3 order, meaning, 2 4-byte float UV values (U, V), 3 4-byte float normal values (X, Y, Z), and 3 4-byte float vertex values (X, Y, Z).
GCS is simply a renamed OGG Vorbis file for obfuscation purposes without exclusively packing them.
The in-game bitmap font uses a GCF file that contains null-terminated string paths to all the characters, having a fixed length of 15 characters, including NUL. For the reason of punctuation characters, some font symbols are renamed as GCG, instead of GCT.

***

The game's code, not including the external libraries, is licensed under the GNU General Public License v3.0. The game's assets are licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.

© Yevhenii Ionenko (aka GreatCorn), 2023

https://greatcorn.github.io/me/
