;ARM1.s 
;;Avery Cameron
;;October 18, 2018
; Directives
	PRESERVE8
	THUMB
		
; Vector Table Mapped to Address 0 at Reset, Linker requires __Vectors to be exported
	AREA RESET, DATA, READONLY
	EXPORT 	__Vectors


__Vectors DCD 0x20002000 ; stack pointer value when stack is empty
	DCD Reset_Handler ; reset vector
	
	ALIGN


;My program, Linker requires Reset_Handler and it must be exported
	AREA MYCODE, CODE, READONLY
	ENTRY

	EXPORT Reset_Handler
		
		
Reset_Handler	PROC

	LDR R0, =string1		;stores string1 in R0
	LDR R4, aux_buffer		;stores aux buffer in  R4 (0x20000030)
	LDR R2, =string1size	;stores string size in R2
	bl copy_string			;copies string to buffer
	
	;This is used to determine amount to shift by, change value in line below to change shift amount
	MOVT R3, #13			;Loads amount to shift by
	LSR R3, #1				;shifts R3 from bit 16 to bit 15 as required 
	AND R3, #0xF8000		;ands R3 together with 1's in bits 15 -19
	
	;loads buffer size into R5 and ensures it doesn't contain values past bit 14
	MOV R5, R2		
	LDR R6, =0x7FFF			
	AND R5, R6		
	
	ADD R3, R3, R5			;adds the values together of shift amount and buffer size into R3
	bl encrypt
deadEnd
	B deadEnd
	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;loads string, stringSize and sets buffer location
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
string1
	dcb 	"Hello, my boots are like onions."
string1size 	equ . - string1
	ALIGN
size1
	dcd string1size
aux_buffer
	dcd 0x20000030
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;copy_string function
;;used from lab 3 byte_copy function by Karim Naqvi
;;Loads values from string stored in R0 and stores in a buffer at R4
;;register values are left unchanged 
;;Requires: 
;;R0 to hold string to encrypt
;;R4 holds location of buffer 
;;R2 holds length of string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
copy_string PROC
	push {R0, R4, R2}
	MOV R1, #0
loopThroughString
	LDRB R1, [R0]	;loads byte in R0, to R1
	STRB R1, [R4]	;stores byte in R1 into R4
	ADD R0, #1		;increments memory locations in R0 and R4, and increments counter in R5
	ADD R4, #1
	ADD R5, #1
	CMP R2, R5		;checks if the counter is at string length, if not loops
	BNE loopThroughString
	pop {R0,R4,R2}	;pops original values
	BX LR			;branches to link register 
	ENDP
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Function: encrypt
;;Programmer: Avery Cameron
;;Date: October 18, 2018 
;;
;;Purpose: 
;;Encrypts a string in buffer, by using a Caesar shift to shift characters right by given value
;;If shift is 0, string is unchanged
;;If shift is >25 string becomes X
;;Symbols remain unchanged
;;capital Z loops to capital A, same with lowercase equivalent
;;
;;Requires: 
;;Buffer to be in R4
;;string size to be in bits 0-14 of R3, shift amount in bits 15-19 of R3
;;other registers should be clear
;;
;;Returns: Encrypted string stored in R4
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
encrypt PROC
	push {R4}			;PUSHES INITIAL BUFFER TO STACK
	push {LR}			;pushes link register for returning to main function
	
	MOV R5, R3			;copies R3 to R5
	LSR R5, #15			;shifts R5 right 15 bits to hold amount to shift by
	CMP R5, #0			;compares to 0
	BEQ goToEnd			;branches to goToEnd 
	CMP R5, #25			;compares to 25
	BGT shiftGreater25	;branches if result is greater than 25
	B encryptN			;branches encryptN
	
encryptN
	MOV R5, R3			;stores R3 in R5
	LSL R5, #17			;shifts R5 left 17, then right 17, gets size of string by itself
	LSR R5, #17
	LSR R3, #15			;shifts R3 right 15 to get shift amount
	
encryptLoop
	CMP R5,#0			;checks if string size is 0
	BEQ goToEnd			;branches to dead end if nothing in string
	LDRB R1, [R4]		;loads byte from R4 to R1
	CMP R1, #0x41		
	BLT isASymbol		;checks if it is below 0x41 (this would not be a letter)
	CMP R1, #0x5A
	BGT checkBetween	;checks if R1 is lower than 5A, it could be a symbol
	CMP R1, #0x7A		;checks if greater than 7A (z) would be a symbol
	BGT isASymbol
continue				;continue tag, if it isn't a symbol returns here
	BL checkValidSwitch	;branches with link
	
return					;return: this is a label although never branched to serves as a reference point
	STRB R1, [R4]		;stores value in R1 into memory at R4 (this is the shifted value)
	ADD R4, #1			;increments buffer position,  and string length by 1
	SUB R5, #1
	B encryptLoop		;loops to encrypt loop again 
	
checkValidSwitch		;checks if the switch needs to be looped around
	push {LR}			;pushes Link Register
	MOV R6, R3			;shift value to R6 (used as a counter)
	CMP R1, #0x5B		;checks if it is less than 5B (will be a upper case (can't be a symbol at this point))
	BLT upperCase
	CMP R1, #0x7B		;checks if it is less than 7B, will be a lowerCase
	BLT lowerCase

returnValidSwitch		;it is a valid switch, branch Link Register (will branch to return on line 144)
	BX LR
	
upperCase				;loops through uppercase specific info
	ADD R1, R1, R6		;adds amount to shift by to R1
	CMP R1, #0x5A		;if it is greater than 5A, it has looped past Z
	BGT loopUpper
	pop {LR}			;else, valid pop LR, branch back, to return
	BX LR
loopUpper				;loops value around, removes shited value
	SUB R1, R1, R6
LoopUpperInner
	CMP R1, #0x5A		;checks when it it Z, adds 1 to value in R1, removes 1 from shift amount in R6
	BEQ loopToA
	ADD R1, R1, #1
	SUB R6, R6, #1
	B LoopUpperInner
	
loopToA					;loops to 1 before A
	MOV R1, #0x40
addToA					;adds 1 and subtracts 1 from shift, when R6 is 0 shift is complete, pop LR and B 
	ADD R1, R1, #1
	SUB R6, R6, #1
	CMP R6, #0
	BNE addToA
	pop {LR}
	BX LR			;branches to return 
;;;;;;;;;;;;;;;;;;;;;Same system as upperCase section
lowerCase			;if it is lower case, add shift and looparound if it goes past z
	ADD R1, R1, R6
	CMP R1, #0x7A
	BGT loopLower
	pop {LR}
	BX LR
		
loopLower
	SUB R1, R1, R6	;remove shift
loopLowerInner
	CMP R1, #0x7A		;check if z, add 1 to R1 (value holding letter) sub from R6 to decrement shift
	BEQ loopToLowerA
	ADD R1, R1, #1
	SUB R6, R6, #1
	B loopLowerInner
	
loopToLowerA
	MOV R1, #0x60		;loops around to 1 before a
addToLowerA
	ADD R1, R1, #1		;adds 1 to value, reduces R6 loops while R6 isn't 0
	SUB R6, R6, #1
	CMP R6, #0
	BNE addToLowerA
	pop {LR}
	BX LR
;shen shift is greater than 25
shiftGreater25
	MOV R5, R3
	LSL R5, #16
	LSR R5, #16
makeStringX			;gets string size and stores in R5, loops through letters in R1 and makes 0x58 (X)
	MOV R1, #0x58
	CMP R5,#0
	BEQ goToEnd
	STRB R1, [R4]	;stores X in buffer at R4, increments R4 and decrements R5
	ADD R4, #1
	SUB R5, #1
	B makeStringX
		
isASymbol			;if it is a symbol, increment buffer location, reduce string size, value unchanged
	ADD R4, #1
	SUB R5, #1
	B encryptLoop

checkBetween		;checks if value is greater than 5A, Z, and less than a, 61, if it is it's a symbol
	CMP R1, #0x61
	BLT isASymbol
	B	continue
	ENDP

goToEnd PROC		;pops the link register to get out of function and into main program
	pop{LR}
	pop {R4}		;POPS START OF BUFFER BACK INTO R4
	BX LR
	ENDP
;end of file
	ALIGN
	END