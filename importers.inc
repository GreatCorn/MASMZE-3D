;
;	MASMZE-3D file importers. Does not include audio importing.
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


; -----	INTERFACE -----

; ----- CONSTANTS -----
IMG_BMP EQU 1		; Obsolete, not using BMPs anymore
IMG_GCT EQU 2
IMG_GCT565 EQU 2
IMG_GCT332 EQU 4
IMG_GCT2 EQU 8
IMG_GCT5A1 EQU 16
; Due to bad decisions in format specification, only the width of the texture
; is stored at the beginning of a GCT file, as a DWORD. Thus, if the texture's
; width is half of its height, or the opposite, it has to be explicitly defined
; while importing. Same goes for the color format
IMG_HALFX EQU 64
IMG_HALFY EQU 128

; ---- INITIALIZED DATA -----
.DATA
xPic DD 0	; Used to store texture size when importing
yPic DD 0

; ----- UNINITIALIZED DATA -----
.DATA?
MemToFree DWORD ?	; Memory pointers to free after loading a texture
MemToUnlock DWORD ?


; ----- IMPLEMENTATION -----
.CODE

; LoadGCM loads a GCM model from FilePath into a compiled GL list at ListIndex
LoadGCM PROC FilePath:DWORD, ListIndex:DWORD
	LOCAL hFile:DWORD, dwFileSize:DWORD, dwBytesRead:DWORD, dwHighSize:DWORD
	LOCAL mem:DWORD, buffer:DWORD, bufferData:DWORD
	
	invoke CreateFile, FilePath, GENERIC_READ, FILE_SHARE_READ, 0, \
	OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, 0
    mov hFile, eax

    invoke GetFileSize, hFile, ADDR dwHighSize
    mov dwFileSize, eax
    invoke GlobalAlloc, GMEM_MOVEABLE or GMEM_ZEROINIT, dwFileSize
    mov mem, eax
    invoke GlobalLock, mem
    mov buffer, eax

    invoke ReadFile, hFile, buffer, dwFileSize, ADDR dwBytesRead, 0
    invoke CloseHandle, hFile
	
	invoke glNewList, ListIndex, GL_COMPILE_AND_EXECUTE
	invoke glBegin, GL_TRIANGLES
	
	push ebx	; Preserve ebx
	xor ebx, ebx
	.WHILE (ebx < dwFileSize)
		mov eax, buffer	; Get the UV data
		mov ecx, DWORD PTR [eax+ebx+4]
		mov eax, DWORD PTR [eax+ebx]
		invoke glTexCoord2f, eax, ecx
		add ebx, 8
		
		mov eax, buffer	; Get the normals
		mov edx, DWORD PTR [eax+ebx+8]
		mov ecx, DWORD PTR [eax+ebx+4]
		mov eax, DWORD PTR [eax+ebx]
		invoke glNormal3f, eax, ecx, edx
		add ebx, 12
		
		mov eax, buffer	; Get the vertices
		mov edx, DWORD PTR [eax+ebx+8]
		mov ecx, DWORD PTR [eax+ebx+4]
		mov eax, DWORD PTR [eax+ebx]
		invoke glVertex3f, eax, ecx, edx
		add ebx, 12
	.ENDW
	pop ebx
	
	invoke glEnd
	invoke glEndList
	
    invoke GlobalUnlock, buffer
    invoke GlobalFree, mem
	ret
LoadGCM ENDP

; LoadGCT loads a GCT image from FilePath and returns its data into EAX
LoadGCT PROC FilePath:DWORD
	LOCAL hFile:DWORD, dwFileSize:DWORD, dwBytesRead:DWORD, dwHighSize:DWORD, pBits:DWORD
	
	invoke CreateFile, FilePath, GENERIC_READ, FILE_SHARE_READ, 0, \
	OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, 0
    mov hFile, eax

    invoke GetFileSize, hFile, ADDR dwHighSize
    mov dwFileSize, eax
    invoke GlobalAlloc, GMEM_MOVEABLE or GMEM_ZEROINIT, dwFileSize
    mov MemToFree, eax
    invoke GlobalLock, MemToFree
    mov MemToUnlock, eax
	
    invoke ReadFile, hFile, MemToUnlock, dwFileSize, ADDR dwBytesRead, 0
    invoke CloseHandle, hFile
	
	mov eax, MemToUnlock	; Get width
	mov eax, DWORD PTR [eax]
	mov xPic, eax
	mov yPic, eax
	
	mov eax, 4
	add eax, MemToUnlock
	mov pBits, eax
	
	print FilePath, 32
	print str$(dwFileSize), 32
	print str$(xPic), 32
	print str$(yPic), 13, 10

	mov eax, pBits
	ret
LoadGCT ENDP

; LoadTexture loads an image from FilePath with specified ImageType, makes it a
; GL texture and returns in EAX
LoadTexture PROC FilePath:DWORD, ImageType:DWORD
	LOCAL hTxtr:DWORD
	LOCAL hPic:DWORD
	
	mov eax, ImageType
	and eax, IMG_BMP
	.IF (eax != 0)
		;invoke LoadBMP, FilePath
	.ELSE
		invoke LoadGCT, FilePath
	.ENDIF
	
	mov hPic, eax

	invoke glGenTextures, 1, ADDR hTxtr
	invoke glBindTexture, GL_TEXTURE_2D, hTxtr
	invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST
	invoke glTexParameteri, GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST

	mov eax, ImageType
	and eax, IMG_HALFX
	.IF (eax != 0)
		mov eax, yPic
		mov ecx, 2
		mul ecx
		mov yPic, eax
	.ENDIF
	
	mov eax, ImageType
	and eax, IMG_HALFY
	.IF (eax != 0)
		xor edx, edx
		mov eax, yPic
		mov ecx, 2
		div ecx
		mov yPic, eax
	.ENDIF
	
	mov eax, ImageType
	and eax, IMG_GCT565
	.IF (eax != 0)
		invoke glTexImage2D, GL_TEXTURE_2D, 0, GL_RGB, xPic, yPic, 0, GL_RGB, \
		8363h, hPic
	.ENDIF
	
	mov eax, ImageType
	and eax, IMG_GCT332
	.IF (eax != 0)
		invoke glTexImage2D, GL_TEXTURE_2D, 0, GL_RGB, xPic, yPic, 0, GL_RGB, \
		8032h, hPic
	.ENDIF
	
	mov eax, ImageType
	and eax, IMG_GCT2
	.IF (eax != 0)
		invoke glTexImage2D, GL_TEXTURE_2D, 0, GL_RGBA2, xPic, yPic, 0, \
		GL_RGBA, GL_UNSIGNED_BYTE, hPic
	.ENDIF
	
	mov eax, ImageType
	and eax, IMG_GCT5A1
	.IF (eax != 0)
		invoke glTexImage2D, GL_TEXTURE_2D, 0, GL_RGB5_A1, xPic, yPic, 0, \
		GL_RGBA, 8034h, hPic
	.ENDIF
	
	
	invoke GlobalUnlock, MemToUnlock
	invoke GlobalFree, MemToFree
	mov eax, hTxtr
	
	ret
LoadTexture	ENDP