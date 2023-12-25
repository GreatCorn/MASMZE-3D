;
;	MASMZE-3D basic heap-based relocatable DWORD stack implementation.
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

UseHeap = TRUE

.DATA?
Heap DWORD ?

.CODE

HSClear PROC hStack:DWORD
	mov eax, hStack
	mov DWORD PTR [eax], 4
	ret
HSClear ENDP

; Create HeapStack object
HSCreate PROC dwSize:DWORD
	LOCAL LockHandle:DWORD
	
	mov eax, dwSize
	add eax, 1
	mov ecx, 4
	mul ecx
	IFDEF UseHeap
		invoke HeapAlloc, Heap, 0, eax
		mov DWORD PTR [eax], 4
	ELSE
		invoke GlobalAlloc, GMEM_MOVEABLE or GMEM_ZEROINIT, eax
		mov LockHandle, eax
		invoke GlobalLock, LockHandle
		mov DWORD PTR [eax], 4
		mov ecx, LockHandle
	ENDIF
	ret
HSCreate ENDP

; Free HeapStack object
HSFree PROC hStack:DWORD, hLock:DWORD
	IFDEF UseHeap
		invoke HeapFree, Heap, 0, hStack
	ELSE
		invoke GlobalUnlock, hStack
		invoke GlobalFree, hLock
	ENDIF
	ret
HSFree ENDP

; Pop from HeapStack object into lpReturn
HSPop PROC hStack:DWORD, lpReturn:DWORD
	mov eax, hStack
	mov ecx, DWORD PTR [eax]
	sub DWORD PTR [eax], 4
	add eax, ecx
	mov eax, DWORD PTR [eax]
	mov ecx, lpReturn
	mov DWORD PTR [ecx], eax
	ret
HSPop ENDP

; Push dwValue to HeapStack
HSPush PROC hStack:DWORD, dwValue:DWORD
	mov eax, hStack
	add DWORD PTR [eax], 4
	mov ecx, DWORD PTR [eax]
	add eax, ecx
	mov ecx, dwValue
	mov DWORD PTR [eax], ecx
	ret
HSPush ENDP

; Get default heap
HSInit PROC
	IFDEF UseHeap
		invoke HeapCreate, 0, 0, 0
		mov Heap, eax
		.IF (Heap == 0)
			invoke GetProcessHeap
			mov Heap, eax
			print "Couldn't create heap, got process heap.", 13, 10
		.ELSE
			invoke HeapLock, Heap
		.ENDIF
	ENDIF
	ret
HSInit ENDP