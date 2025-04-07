;TITLE String Primitives and Macros 

; Description: This program will read temperature measurements from a file and prin them out in the reverse order.
;              

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; gets File name from user
;
; Preconditions: pass address of a byte sized array
;
; Receives:
; user_file address
; 
;
; returns: file name
; ---------------------------------------------------------------------------------
mGetString MACRO file

	MOV		EDX, file
	CALL	ReadString
	MOV		bytesRead, EAX 



ENDM


; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Macro displays all strings printed in program
;
; Preconditions: none.
;
; Receives:
;		Strings
;
; returns: none
; ---------------------------------------------------------------------------------
mDisplayString MACRO string
	PUSH	EDX
	MOV		EDX, string
	CALL	WriteString
	POP		EDX


ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayChar
;
; Macro displays all charactyers in program
;
; Preconditions: none.
;
; Receives:
;		characters
;
; returns: none
; ---------------------------------------------------------------------------------
mDisplayChar MACRO   char 
	PUSH	EAX
	MOV		AL, char
	CALL	WriteChar
	POP EAX


ENDM
;------------------------------

TEMPS_PER_DAY = 24
DELIMITER  = ","
MAX_SIZE TEXTEQU %(TEMPS_PER_DAY * 4)


.data
intro1				BYTE		"Welcome to the intern error-corrector!",13,10,0
intro2				BYTE		"I'll read a ','-delimited file storing a series of temperature values.",13,10,13,10,0
intro3				BYTE		"The file must be ASCII-formatted. I'll then reverse the ordering and provide",13,10,0
intro4				BYTE		"the corrected temperature ordering as a printout!",13,10,13,10,0
prompt1				BYTE		"Enter the name of the file to be read: ",0

rightTempsString	BYTE		"Here's the corrected temperature order!",13,10,0

user_file			BYTE		MAX_SIZE DUP(?)									

bytesRead			DWORD		?							
convertedTemp		SDWORD		TEMPS_PER_DAY DUP(?)
arr_size			SDWORD		LENGTHOF convertedTemp
count				DWORD       MAX_SIZE
tempArray			SDWORD		TEMPS_PER_DAY DUP(?)
fileBuffer			BYTE		MAX_SIZE DUP(?) 
fileHandle			DWORD		?
curr_total			DWORD		0
check_neg			DWORD		0

goodbye				BYTE		" Thank you for using the intern error-corrector, goodbye!",0

notValid			BYTE		"There was an error reading the file.",13,10,0
notValid2			BYTE		"Please verify that the file is in the same directory as the intern error-corrector program. ",0

.code
main PROC

; introduce program and instructions
_intro:
	mDisplayString OFFSET intro1
	mDisplayString OFFSET intro2
	mDisplayString OFFSET intro3
	mDisplayString OFFSET intro4

; gets file from user calling macros to get the name of it
_promptUser:
	mDisplayString	OFFSET prompt1
	MOV				ECX, SIZEOF user_file - 1
	MOV				ECX, MAX_SIZE
	mGetString		OFFSET user_file
	
; ; open file
_openAndReadFile:
	mov		EDX, OFFSET user_file					
	call	OpenInputFile									; open file
	mov		fileHandle, EAX

	; read file
	mov		EAX, fileHandle
	MOV		EDX, OFFSET fileBuffer
	mov		ECX, MAX_SIZE - 1
	call	ReadFromFile
	MOV     bytesRead, EAX


	MOV		EAX, fileHandle						; Put OS File Handle into EAX
	CALL	CloseFile

	; verifies that the file is valid
_validFile:
	cmp		fileHandle, -1
	JE		_invalid
	jmp		_valid

_invalid:
	CALL CrLf
	mDisplayString OFFSET notValid
	mDisplayString OFFSET notValid2
	CALL	CrLf
	exit

_valid:
; ParseTempsFromString
	PUSH check_neg
	PUSH curr_total
	PUSH BYTESREAD
	PUSH OFFSET convertedTemp
	PUSH OFFSET fileBuffer
	CALL ParseTempsFromString

; displays string for temperature correction
_correctedTemperatures:
	CALL	CrLf
	mDisplayString OFFSET rightTempsString


; WriteTempsReverse
	PUSH arr_size
	PUSH OFFSET tempArray
	PUSH count
	PUSH OFFSET convertedTemp
	CALL WriteTempsReverse


; concludes program by thanking the user and saying goodbye
_goodbye:
	CALL	CrLf
	CALL	CrLf
	mDisplayString OFFSET goodbye
	CALL	CrLf



	Invoke ExitProcess,0	; exit to operating system
main ENDP

; ---------------------------------------------------------------------------------
; Name: ParseTempsFromString
;
; Changes a string byte sized array into a SDWORD sized array turning string to their corresponding numerical values.
;
; Preconditions: program opens and read a file copying values into a FileBuffer byte size array
;
; Postconditions: to convert all strings to integers from filebuffer convertedTemps array
;
; Receives:
;  [EBP+24] = check_neg
	; [EBP+20] = curr_total
	; [EBP+16] = bytesRead
	; [EBP+12] = OFFSET convertedTemp
	; [EBP+8] = OFFSET fileBuffer
	; [EBP+4] = return address
	; [EBP] = OLD EBP
;	DELIMITER  [CONSTANT]
; returns:  SDWORD sized array with signed values
; ---------------------------------------------------------------------------------

ParseTempsFromString PROC
	PUSH	EBP
	MOV		EBP, ESP
	
	mov		ECX, [EBP+16]					; Moves bytesRead to ECX to count
	mov		ESI, [EBP+8]					; Moves fileBuffer address to ESI pointing at the first value
	mov		EDI, [EBP+12]					; moves convertedTemp array address to EDI
	
_checkVal:
	LODSB					; puts byte in AL
	cmp		AL, 45
	JE		_checkNeg
	cmp		AL, 48
	JGE		_checkVal2
	cmp		AL, DELIMITER
	JE		_calculateInt
	
	POP EBP
	RET	20

; checks that it doesn't go past numeric characters
_checkVal2:
	cmp		AL, 57
	JG		_checkVal

_convert:
	PUSH	EAX
	mov		EAX, [EBP+20]				; current total 
	mov		EBX, 10
	mul		EBX							; multiply current total by 10
	mov		EBX, EAX					; store in ebx
	
	POP		EAX
	mov		EDX, EAX					; save character value in register
	sub		EAX, 48						; subtract number the value represents, with 48


	add		EAX, EBX

	mov		[EBP+20], EAX				; keep track of currrent total
	jmp		_checkVal


_addToArray:
	STOSD
	mov		EAX, 0
	mov		[EBP+20], EAX				; change curr_value back to 0
	mov		[EBP+24], EAX				; change check_neg back to 0
	jmp		_checkVal


; calculate whole integer
_calculateInt:
	
	mov		EAX, edx				; move last character value to EAX

	sub		EAX, 48						; subtract number the value represents, with 48


	add		EAX, EBX
	
	push	EAX
	mov		EAX, [EBP+24]
	cmp		EAX, 1
	JE		_convertNeg
	
	pop		EAX
	

	jmp		_addToArray

_convertNeg:
	pop		EAX
	neg		AL
	
	movsx	EAX, AL						; move signed value to the bigger size register

	jmp		_addToArray
	
; if negative sign, change check_neg to 1
_checkNeg:
	mov		EAX, 1
	mov		[EBP+24], EAX
	jmp		_checkVal


ParseTempsFromString ENDP


; ---------------------------------------------------------------------------------
; Name: WriteTempsReverse
; Reverses and prints array and it's DELIMITER by calling macro to print character
;
; Preconditions:  completed converteTemp array with signed values
;
; Postconditions: none.
;
; Receives:
	; [EBP+20] = arr_size
	; [EBP+16] = OFFSET tempArray
	; [EBP+12] = count
	; [EBP+8] = OFFSET convertedTemp
	; [EBP+4] = return address
	; [EBP] = OLD EBP
;	DELIMITER  [CONSTANT]
; returns:  A reversed tempArray with correct temperature readings.
; ---------------------------------------------------------------------------------
WriteTempsReverse PROC
	PUSH	EBP
	MOV		EBP, ESP

	MOV		ECX, [EBP+20]				; move length of array to register to keep count 
	MOV		ESI, [EBP+8]				; move converted array address to ESI
	add		ESI, [EBP+12]					
	SUB		ESI, 4							; start from the last value of array
	mov		EDI, [EBP+16]
	
_PrintArr:
	STD										; go backwards setting flag to Set
	LODSD									; copy value from convertedTemp array
	CLD										; set flag to clear to go forward
	STOSD									; place value in new array
	CALL	WriteInt
	mDisplayChar OFFSET DELIMITER			; print Delimiter by calling Macro
	LOOP _PrintArr

	POP		EBP
	RET		16

WriteTempsReverse ENDP



END main
