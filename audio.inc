;
;	MASMZE-3D-specific OpenAL Soft (and stb_vorbis) headers.
;	OpenAL Soft v1.15 by kcat & Co.
;	Additional credits and links to OpenAL: <https://openal-soft.org/>
;	stb_vorbis from stb by Sean Barrett: <https://github.com/nothings/stb>
;	This file does not include all of the OpenAL Soft or stb_vorbis definitions.
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
AL_BUFFER EQU 1009h
AL_DATA EQU 2005h
AL_FALSE EQU 0
AL_FORMAT_MONO16 EQU 1101h
AL_FORMAT_STEREO16 EQU 1103h
AL_GAIN EQU 100Ah
AL_LOOPING EQU 1007h
AL_MAX_DISTANCE EQU 1023h
AL_NONE EQU 0
AL_ORIENTATION EQU 100Fh
AL_POSITION EQU 1004h
AL_ROLLOFF_FACTOR EQU 1021h
AL_TRUE EQU 1
ALC_DEFAULT_DEVICE_SPECIFIER EQU 1004h

.CONST
stb_vorbisPath DB "stb_vorbis.dll", 0
Astb_vorbis_decode_filename DB "stb_vorbis_decode_filename", 0

OpenALPath DB "soft_oal.dll", 0
AalcCloseDevice DB "alcCloseDevice", 0
AalcCreateContext DB "alcCreateContext", 0
AalcDestroyContext DB "alcDestroyContext", 0
AalcGetContextsDevice DB "alcGetContextsDevice", 0
AalcGetCurrentContext DB "alcGetCurrentContext", 0
AalcGetString DB "alcGetString", 0
AalcMakeContextCurrent DB "alcMakeContextCurrent", 0
AalcOpenDevice DB "alcOpenDevice", 0
AalBufferData DB "alBufferData", 0
AalDeleteBuffers DB "alDeleteBuffers", 0
AalDeleteSources DB "alDeleteSources", 0
AalGenBuffers DB "alGenBuffers", 0
AalGenSources DB "alGenSources", 0
AalGetError DB "alGetError", 0
AalGetSourcef DB "alGetSourcef", 0
AalGetSourcei DB "alGetSourcei", 0
AalListener3f DB "alListener3f", 0
AalListenerf DB "alListenerf", 0
AalListenerfv DB "alListenerfv", 0
AalListeneri DB "alListeneri", 0
AalSource3f DB "alSource3f", 0
AalSourcef DB "alSourcef", 0
AalSourcefv DB "alSourcefv", 0
AalSourcei DB "alSourcei", 0
AalSourcePlay DB "alSourcePlay", 0
AalSourceStop DB "alSourceStop", 0

ErrorDLL DB "Can't load library.", 0
ErrorPROC DB "Can't load process.", 0
ErrorOALDEV DB "Can't open OpenAL device.", 0

; ----- UNINITIALIZED DATA -----
.DATA?
stb_vorbis HINSTANCE ?
Pstb_vorbis_decode_filename DWORD ?

OpenAL HINSTANCE ?
PalcCloseDevice DWORD ?
PalcCreateContext DWORD ?
PalcDestroyContext DWORD ?
PalcGetContextsDevice DWORD ?
PalcGetCurrentContext DWORD ?
PalcMakeContextCurrent DWORD ?
PalcOpenDevice DWORD ?
PalBufferData DWORD ?
PalDeleteBuffers DWORD ?
PalDeleteSources DWORD ?
PalGenBuffers DWORD ?
PalGenSources DWORD ?
PalcGetString DWORD ?
PalGetError DWORD ?
PalGetSourcef DWORD ?
PalGetSourcei DWORD ?
PalListener3f DWORD ?
PalListenerf DWORD ?
PalListenerfv DWORD ?
PalListeneri DWORD ?
PalSource3f DWORD ?
PalSourcef DWORD ?
PalSourcefv DWORD ?
PalSourcei DWORD ?
PalSourcePlay DWORD ?
PalSourceStop DWORD ?

AudioContext DWORD ?
AudioDevice DWORD ?
ErrorProcedure DWORD ?


; ----- IMPLEMENTATION -----
.CODE

; I'm sure there is a better way to import DLL functions in MASM32, but I
; couldn't find anything and went with what I knew, creating this abomination
stb_vorbis_decode_filename PROC filename:DWORD, channels:DWORD, sample_rate:DWORD, output:DWORD
	push output
	push sample_rate
	push channels
	push filename
	call Pstb_vorbis_decode_filename
	ret
stb_vorbis_decode_filename ENDP

alcCloseDevice PROC device:DWORD
	push device
	call PalcCloseDevice
	ret
alcCloseDevice ENDP
alcCreateContext PROC device:DWORD, attrlist:DWORD
	push attrlist
	push device
	call PalcCreateContext
	ret
alcCreateContext ENDP
alcDestroyContext PROC context:DWORD
	push context
	call PalcDestroyContext
	ret
alcDestroyContext ENDP
alcGetContextsDevice PROC context:DWORD
	push context
	call PalcGetContextsDevice
	ret
alcGetContextsDevice ENDP
alcGetCurrentContext PROC
	call PalcGetCurrentContext
	ret
alcGetCurrentContext ENDP
alcGetString PROC device:DWORD, param: SDWORD
	push param
	push device
	call PalcGetString
	ret
alcGetString ENDP
alcMakeContextCurrent PROC context:DWORD
	push context
	call PalcMakeContextCurrent
	ret
alcMakeContextCurrent ENDP
alcOpenDevice PROC devicename:DWORD
	push devicename
	call PalcOpenDevice
	ret
alcOpenDevice ENDP
alBufferData PROC bid:DWORD, format:SDWORD, data:DWORD, _size:SDWORD, freq:SDWORD
	push freq
	push _size
	push data
	push format
	push bid
	call PalBufferData
	ret
alBufferData ENDP
alDeleteBuffers PROC n:SDWORD, buffers:DWORD
	push buffers
	push n
	call PalDeleteBuffers
	ret
alDeleteBuffers ENDP
alDeleteSources PROC n:SDWORD, sources:DWORD
	push sources
	push n
	call PalDeleteSources
	ret
alDeleteSources ENDP
alGenBuffers PROC n:SDWORD, buffers:DWORD
	push buffers
	push n
	call PalGenBuffers
	ret
alGenBuffers ENDP
alGenSources PROC n:SDWORD, sources:DWORD
	push sources
	push n
	call PalGenSources
	ret
alGenSources ENDP
alGetError PROC
	call PalGetError
	ret
alGetError ENDP
alGetSourcef PROC sid:DWORD, param:SDWORD, value:DWORD
	push value
	push param
	push sid
	call PalGetSourcef
	ret
alGetSourcef ENDP
alGetSourcei PROC sid:DWORD, param:SDWORD, value:DWORD
	push value
	push param
	push sid
	call PalGetSourcei
	ret
alGetSourcei ENDP
alListener3f PROC param:SDWORD, value1:REAL4, value2:REAL4, value3:REAL4
	push value3
	push value2
	push value1
	push param
	call PalListener3f
	ret
alListener3f ENDP
alListenerf PROC param:SDWORD, value:REAL4
	push value
	push param
	call PalListenerf
	ret
alListenerf ENDP
alListenerfv PROC param:SDWORD, values:DWORD
	push values
	push param
	call PalListenerfv
	ret
alListenerfv ENDP
alListeneri PROC param:SDWORD, value:SDWORD
	push value
	push param
	call PalListeneri
	ret
alListeneri ENDP
alSource3f PROC sid:DWORD, param:SDWORD, value1:REAL4, value2:REAL4, value3:REAL4
	push value3
	push value2
	push value1
	push param
	push sid
	call PalSource3f
	ret
alSource3f ENDP
alSourcef PROC sid:DWORD, param:SDWORD, value:REAL4
	push value
	push param
	push sid
	call PalSourcef
	ret
alSourcef ENDP
alSourcefv PROC sid:DWORD, param:SDWORD, values:DWORD
	push values
	push param
	push sid
	call PalSourcefv
	ret
alSourcefv ENDP
alSourcei PROC sid:DWORD, param:SDWORD, value:SDWORD
	push value
	push param
	push sid
	call PalSourcei
	ret
alSourcei ENDP
alSourcePlay PROC sid:DWORD
	push sid
	call PalSourcePlay
	ret
alSourcePlay ENDP
alSourceStop PROC sid:DWORD
	push sid
	call PalSourceStop
	ret
alSourceStop ENDP

; InitOpenAL opens a device and creates a context
InitOpenAL PROC
	;invoke alcGetString, NULL, ALC_DEFAULT_DEVICE_SPECIFIER
	invoke alcOpenDevice, NULL
	mov AudioDevice, eax
	.IF AudioDevice == NULL
		lea eax, ErrorOALDEV
		push eax
		call ErrorProcedure
	.ENDIF
	invoke alcCreateContext, AudioDevice, NULL
	mov AudioContext, eax
	invoke alcMakeContextCurrent, AudioContext
	ret
InitOpenAL ENDP

; LoadAudio loads an OGG Vorbis audio at FilePath into AudioPTR
LoadAudio PROC FilePath: DWORD, AudioPTR: DWORD
	LOCAL channels:DWORD, sample:DWORD, decoded:DWORD, fileLen:DWORD
	LOCAL buffer:DWORD, format:SDWORD, bufferSize:DWORD
	
	print "Loading audio: "
	print FilePath
	print " into "
	print str$(AudioPTR), 13, 10
	
	invoke stb_vorbis_decode_filename, FilePath, ADDR channels, ADDR sample, \
	ADDR decoded
	mov fileLen, eax
	mov ebx, 2
	mul ebx
	mov ebx, channels
	mul ebx
	mov bufferSize, eax
	
	invoke alGenBuffers, 1, ADDR buffer
	.IF channels == 2
		mov format, AL_FORMAT_STEREO16
	.ELSE
		mov format, AL_FORMAT_MONO16
	.ENDIF
	invoke alBufferData, buffer, format, decoded, bufferSize, sample
	invoke alGenSources, 1, AudioPTR
	mov eax, AudioPTR
	invoke alSourcei, [eax], AL_BUFFER, buffer
	
	;invoke GetProcessHeap
	;mov buffer, eax
	;invoke HeapSize, buffer, 0, decoded
	;print str$(eax), 32
	;print str$(bufferSize), 13, 10
	;invoke HeapFree, buffer, HEAP_NO_SERIALIZE, decoded 
	;print str$(eax), 13, 10
	;invoke GlobalFree, decoded
	;invoke alGetError
	;print str$(eax), 13, 10
	ret
LoadAudio ENDP

; FreeAudio frees loaded audio data from memory
FreeAudio PROC AudioSource:DWORD
	LOCAL bufSID:SDWORD
	mov ebx, AudioSource
	invoke alGetSourcei, [ebx], AL_BUFFER, ADDR bufSID
	invoke alDeleteSources, 1, AudioSource
	invoke alDeleteBuffers, 1, ADDR bufSID
	ret
FreeAudio ENDP

; LoadProc loads a procedure at ProcAdress from Library into OutPtr
LoadProc PROC Library:DWORD, ProcAdress:DWORD, OutPtr:DWORD
	invoke GetProcAddress, Library, ProcAdress
	mov ecx, OutPtr
	mov DWORD PTR [ecx], eax
	.IF eax == NULL
		lea eax, ErrorPROC 
		push eax
		call ErrorProcedure
	.ENDIF
	ret
LoadProc ENDP

; LoadLibraries loads the stb_vorbis_decode_filename function from stb_vorbis
; and all of the defined OpenAL Soft procedures
LoadLibraries PROC ErrorProc:DWORD
	m2m ErrorProcedure, ErrorProc
	
	; stb_vorbis
	invoke LoadLibrary, ADDR stb_vorbisPath
	mov stb_vorbis, eax
	.IF eax == NULL
		lea eax, ErrorDLL
		push eax
		call ErrorProcedure
	.ENDIF
	invoke LoadProc, stb_vorbis, ADDR Astb_vorbis_decode_filename, \
	ADDR Pstb_vorbis_decode_filename
	
	; OpenAL
	invoke LoadLibrary, ADDR OpenALPath
	mov OpenAL, eax
	.IF eax == NULL
		lea eax, ErrorDLL
		push eax
		call ErrorProcedure
	.ENDIF
	invoke LoadProc, OpenAL, ADDR AalcCloseDevice,			ADDR PalcCloseDevice
	invoke LoadProc, OpenAL, ADDR AalcCreateContext,		ADDR PalcCreateContext
	invoke LoadProc, OpenAL, ADDR AalcDestroyContext,		ADDR PalcDestroyContext
	invoke LoadProc, OpenAL, ADDR AalcGetContextsDevice,	ADDR PalcGetContextsDevice
	invoke LoadProc, OpenAL, ADDR AalcGetCurrentContext,	ADDR PalcGetCurrentContext
	invoke LoadProc, OpenAL, ADDR AalcGetString,			ADDR PalcGetString
	invoke LoadProc, OpenAL, ADDR AalcMakeContextCurrent,	ADDR PalcMakeContextCurrent
	invoke LoadProc, OpenAL, ADDR AalcOpenDevice,			ADDR PalcOpenDevice
	invoke LoadProc, OpenAL, ADDR AalBufferData,			ADDR PalBufferData
	invoke LoadProc, OpenAL, ADDR AalDeleteBuffers,			ADDR PalDeleteBuffers
	invoke LoadProc, OpenAL, ADDR AalDeleteSources,			ADDR PalDeleteSources
	invoke LoadProc, OpenAL, ADDR AalGenBuffers,			ADDR PalGenBuffers
	invoke LoadProc, OpenAL, ADDR AalGenSources,			ADDR PalGenSources
	invoke LoadProc, OpenAL, ADDR AalGetError,				ADDR PalGetError
	invoke LoadProc, OpenAL, ADDR AalGetSourcef,			ADDR PalGetSourcef
	invoke LoadProc, OpenAL, ADDR AalGetSourcei,			ADDR PalGetSourcei
	invoke LoadProc, OpenAL, ADDR AalListener3f,			ADDR PalListener3f
	invoke LoadProc, OpenAL, ADDR AalListenerf,				ADDR PalListenerf
	invoke LoadProc, OpenAL, ADDR AalListenerfv,			ADDR PalListenerfv
	invoke LoadProc, OpenAL, ADDR AalListeneri,				ADDR PalListeneri
	invoke LoadProc, OpenAL, ADDR AalSource3f,				ADDR PalSource3f
	invoke LoadProc, OpenAL, ADDR AalSourcef,				ADDR PalSourcef
	invoke LoadProc, OpenAL, ADDR AalSourcefv,				ADDR PalSourcefv
	invoke LoadProc, OpenAL, ADDR AalSourcei,				ADDR PalSourcei
	invoke LoadProc, OpenAL, ADDR AalSourcePlay,			ADDR PalSourcePlay
	invoke LoadProc, OpenAL, ADDR AalSourceStop,			ADDR PalSourceStop
	ret
LoadLibraries ENDP

; FreeLibraries frees loaded libraries from memory
FreeLibraries PROC
	invoke FreeLibrary, stb_vorbis
	invoke FreeLibrary, OpenAL
	print "Freed libraries", 13, 10
	ret
FreeLibraries ENDP