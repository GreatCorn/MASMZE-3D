; Floating point comparison macro and PROC by jj2007
fcmp MACRO cmp1:REQ, cmp2
	LOCAL oa
	ffree st(7)
	ifb <cmp2>
		fldz	; No second arg; compare against zero
	else
		oa = (opattr cmp2) and 127
		if (oa eq 36) or (oa eq 48)
			push cmp2
			fild DWORD PTR [esp]	; Integer or reg32 on stack, then on FPU
			pop eax
		else
			fld cmp2	; Real on FPU
		endif
	endif
	ffree st(7)
	fld cmp1
	call fcmpP
ENDM

.CODE
fcmpP PROC
	push edx
	xor edx, edx	; Clear the flag register
	fcompp			; Compare ST(0) with ST(1) and pop twice
	fstsw ax		; Move FPU flags C1 etc to ax
	test ah, 64		; C3 is set if ST=0 (bt eax, 14)
	jne @F			; Equal, edx=0
	test ah, 1		; C0 (bt eax, 8)
	je fcPos
	dec edx			; Negative (-2+1=-1)
	@@:		dec edx	; Zero (0-1+1=0)
	fcPos:	inc edx	; Positive
		pop edx
		ret
fcmpP ENDP

;
;	MASMZE-3D generic mathematical functions.
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



.CONST
R2D REAL4 57.29578	; Radians to degrees multiplier
PI REAL4 3.1415927
PIN REAL4 -3.1415927
PIHalf REAL4 1.5707
PIHalfN REAL4 -1.5707
PI2 REAL4 6.2831

.CODE

; Angleify takes a pointer to a float and loops it around like an angle
Angleify PROC Val: DWORD
	LOCAL ValF: REAL4
	mov eax, Val
	mov ecx, REAL4 PTR [eax]
	mov ValF, ecx
	
	fcmp ValF, PI
	.IF !Sign? && !Zero?	; direction > PI
		fld ValF
		fsub PI2
		fstp ValF
	.ENDIF
	fcmp ValF, PIN
	.IF Sign? && !Zero?		; direction < -PI
		fld ValF
		fadd PI2
		fstp ValF
	.ENDIF
	
	mov eax, Val
	mov ecx, ValF
	mov REAL4 PTR [eax], ecx
	ret
Angleify ENDP

; ATan2 returns the arc tangent of Y and X in radians. This was made before I
; realized fpatan does pretty much what I needed
ATan2 PROC Y: REAL4, X: REAL4
	LOCAL Val:REAL4
	
	fcmp X
	.IF !Zero?	; X != 0
		fld Y
		fld X
		fpatan
		fwait
		fstp Val
		mov eax, Val
		ret
	.ENDIF
	; X == 0
	fcmp Y
	.IF !Sign? && !Zero?	; Y > 0
		mov eax, PIHalf
	.ELSE					; Y < 0
		mov eax, PIHalfN
	.ENDIF
	ret
ATan2 ENDP

; Clamp clamps Val between MinVal and MaxVal, returns the result in EAX
Clamp PROC Val: REAL4, MinVal: REAL4, MaxVal: REAL4
	fcmp Val, MaxVal
	.IF !Sign? && !Zero?		; X > X1
		fld MaxVal
		fstp Val
	.ELSE
		fcmp Val, MinVal
		.IF Sign? && !Zero?		; X < X1
			fld MinVal
			fstp Val
		.ENDIF
	.ENDIF
	
	mov eax, Val
	ret
Clamp ENDP

; DistanceScalar returns distance from SFrom to STo in EAX
DistanceScalar PROC SFrom: REAL4, STo:REAL4
	LOCAL Val: REAL4
	fld SFrom
	fsub STo
	fabs
	fstp Val
	mov eax, Val
	ret
DistanceScalar ENDP

; DistanceToSqr returns squared distance from 2D vector (XFrom, YFrom) to
; (XTo, YTo) in EAX. Distance is used only for comparisons in MASMZE-3D, so
; there is no need to find the square root, without it the function is faster
DistanceToSqr PROC XFrom: REAL4, YFrom: REAL4, XTo: REAL4, YTo: REAL4
	LOCAL Val: REAL4
	fld XFrom
	fsub XTo
	fmul st, st
	fstp Val
	fld YFrom
	fsub YTo
	fmul st, st
	fadd Val
	fstp Val
	mov eax, Val
	ret
DistanceToSqr ENDP

; GetDirection gets direction angle from 2D position vector (XFrom, YFrom) to
; 2D position vector (XTo, YTo) and returns it in EAX
GetDirection PROC XFrom:REAL4, YFrom:REAL4, XTo:REAL4, YTo:REAL4
	LOCAL tX: REAL4, tY: REAL4

	fld XFrom
	fsub XTo
	fstp tX
	fld YFrom
	fsub YTo
	fstp tY
	
	invoke ATan2, tX, tY
	ret
GetDirection ENDP

; InRange checks if 2D vector (PosX, PosY) is in range (X1, Y1) --
; (X2, Y2) and returns result in EAX
InRange PROC PosX: REAL4,PosY: REAL4, X1: REAL4,X2: REAL4, Y1: REAL4,Y2: REAL4
	LOCAL Flag:BYTE

	mov Flag, 0
	
	fcmp PosX, X1
	.IF !Sign? && !Zero?		; X > X1
		fcmp PosX, X2
		.IF Sign? && !Zero?		; X < X2
			fcmp PosY, Y1
			.IF !Sign? && !Zero?		; Y > Y1
				fcmp PosY, Y2
				.IF Sign? && !Zero?		; Y < Y2
					; I shalt repent for the sins of mine,
					; may the Lord and jj2007 forgive me
					mov Flag, 1
				.ENDIF
			.ENDIF
		.ENDIF
	.ENDIF
	mov al, Flag
	ret
InRange ENDP

; Lerp takes a pointer to a float and interpolates it to LerpB by LerpT
Lerp PROC LerpA: DWORD, LerpB: REAL4, LerpT: REAL4
	LOCAL LerpAV: REAL4
	mov eax, LerpA
	mov ecx, REAL4 PTR [eax]
	mov LerpAV, ecx
	
	fld LerpB
	fsub LerpAV
	fmul LerpT
	fadd LerpAV
	fstp LerpAV
	
	mov ecx, LerpAV
	mov REAL4 PTR [eax], ecx
	ret
Lerp ENDP

; LerpAngle takes a pointer to a float and interpolates it to LerpB by LerpT,
; while also 'angleifying' it. Useful for lopped angle values
LerpAngle PROC LerpA: DWORD, LerpB: REAL4, LerpT: REAL4
	LOCAL LerpAV: REAL4, LerpBV: REAL4
	mov eax, LerpA
	mov ecx, REAL4 PTR [eax]
	mov LerpAV, ecx
	
	fld LerpB
	fsub LerpAV
	fstp LerpBV
	
	invoke Angleify, ADDR LerpBV
	
	fld LerpBV
	fmul LerpT
	fadd LerpAV
	fstp LerpAV
	
	mov eax, LerpA
	mov ecx, LerpAV
	mov REAL4 PTR [eax], ecx
	ret
LerpAngle ENDP

; Normalize takes two pointers to floats as a 2D vector and scales it to unit
; length (normalizes it)
Normalize PROC X: DWORD, Y: DWORD
	LOCAL XV: REAL4, YV: REAL4
	LOCAL LengthSQ: REAL4
	mov eax, X
	mov ecx, REAL4 PTR [eax]
	mov XV, ecx
	mov eax, Y
	mov ecx, REAL4 PTR [eax]
	mov YV, ecx
	
	fld XV
	fmul XV
	fstp LengthSQ
	fld YV
	fmul YV
	fadd LengthSQ
	fstp LengthSQ
	
	fcmp LengthSQ
	.IF Zero?
		mov eax, X
		mov ecx, 0
		mov REAL4 PTR [eax], ecx
		mov eax, Y
		mov REAL4 PTR [eax], ecx
		ret
	.ENDIF
	fld LengthSQ
	fsqrt
	fstp LengthSQ
	
	fld XV
	fdiv LengthSQ
	fstp XV
	fld YV
	fdiv LengthSQ
	fstp YV
	
	mov eax, X
	mov ecx, XV
	mov REAL4 PTR [eax], ecx
	mov eax, Y
	mov ecx, YV
	mov REAL4 PTR [eax], ecx
	ret
Normalize ENDP

; ParseFloat takes pointer to string that contains a representation of a float
; (e.g. "1.0") parses it into a REAL4 value and returns in EAX. Not really a
; math function, but I decided to put it here nonetheless
ParseFloat PROC String:DWORD
	LOCAL floatFact:REAL4, intFact:REAL4, point:BYTE, dml:DWORD
	fld1
	fstp floatFact
	mov intFact, 0
	
	xor ebx, ebx
	mov eax, String
	mov cl, BYTE PTR [eax]
	.IF (cl == 45)
		inc ebx
		fld1
		fchs
		fstp floatFact
	.ENDIF
	
	mov point, 0
	.WHILE (cl != 0)
		mov cl, BYTE PTR [eax+ebx]
		.IF (cl == 46)
			mov point, 1
			inc ebx
			.CONTINUE
		.ENDIF
		xor edx, edx
		mov dl, cl
		sub dl, 48
		mov dml, edx
		.IF (dml >= 0) && (dml <= 9)
			.IF (point == 1)
				fld floatFact
				fdiv fl10
				fstp floatFact
			.ENDIF
			fld intFact
			fmul fl10
			fiadd dml
			fstp intFact
		.ENDIF
		inc ebx
	.ENDW
	
	fld intFact
	fmul floatFact
	fstp intFact
	
	mov eax, intFact
	ret
ParseFloat ENDP