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
	LDR R4, aux_buffer		;stores aux buffer in  R4 (0x20000000)
	LDR R2, =string1size	;stores string size in R2
	bl copy_string
	
	;This is used to determine amount to shift by, change value in line below to change shift amount
	MOVT R3, #0x3			;Loads amount to shift by
	LSR R3, #1				;shifts R3 from bit 16 to bit 15 as required 
	AND R3, #0xF8000		;ands R3 together with 1's in bits 15 -19
	
	;loads buffer size into R5 and ensures it doesn't contain values past bit 14
	MOV R5, R2		
	LDR R6, =0x7FFF			
	AND R5, R6		
	
	ADD R3, R3, R5			;adds the values together of shift amount and buffer size into R3
	
	push {R3}		;pushes R3, value to shift and asize of string to stack
	bl encrypt
	pop {R3}
	bl decrypt
deadEnd
	B deadEnd
	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;loads string, stringSize and sets buffer location
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
string1
	dcb 	"!azY"
string1size 	equ . - string1
	ALIGN
size1
	dcd string1size
		
RAM_START equ 0x20000000
aux_buffer equ RAM_START + 0
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
	push {R4}
	push {LR}			;pushes link register for returning to main function
	
	MOV R5, R3			;copies R3 to R5
	LSR R5, #15			;shifts R5 right 15 bits to hold amount to shift by
	CMP R5, #0			
	BEQ goToEnd			;branches to goToEnd, no shift
	CMP R5, #25			
	BGT shiftGreater25	;branches if result is greater than 25
	B encryptN			;branches encryptN
	
encryptN
	MOV R5, R3			;stores R3 in R5
	LSL R5, #17			;shifts R5 left 17, then right 17, gets size of string by itself
	LSR R5, #17
	LSR R3, #15			;shifts R3 right 15 to get shift amount
	
encryptLoop
	CMP R5,#0			
	BEQ goToEnd			;branches out if nothing in string
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
	MOV R6, R3			;shift value to R6 (used as a shift counter)
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
	CMP R1, #0x5A		;checks when it it Z, loop to A
	BEQ loopToA
	ADD R1, R1, #1		;increment hex caharacter
	SUB R6, R6, #1		;decrement shift 
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
	ADD R1, R1, #1		;adds 1 to character value, reduces R6 loops while R6 isn't 0
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
	pop {R4}
	BX LR
	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Function: decrypt
;;Programmer: Avery Cameron
;;Date: October 18, 2018 
;;
;;Purpose: 
;;Decrypts a string in buffer, by using a Caesar shift to shift characters left by given value
;;If shift is 0, string is unchanged
;;leave as is (string will be all X's
;;Symbols remain unchanged
;;capital A loops to capital Z, same with lowercase equivalent
;;
;;Requires: 
;;Buffer to be in R4
;;string size to be in bits 0-14 of R3, shift amount in bits 15-19 of R3
;;other registers should be clear
;;Encrypt should be used before Decrypt is called
;;
;;Returns: Encrypted string stored in R4
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
decrypt PROC
	push {R4}
	push {LR}		;pushes link register to allow for exit out
	MOV R5, R3
	LSR R5, #15
	CMP R5, #0
	BEQ goToEnd		;branches to end if shift is 0, or 25
	CMP R5, #25
	BGT goToEnd
	B decryptN
;puts string length in R5, and shift amount in R3 (by logical shifts)
decryptN 
	MOV R5, R3
	LSL R5, #17
	LSR R5, #17
	LSR R3, #15
;checks if 5 is 0, checks for symbols
decryptLoop		
	CMP R5, #0
	BEQ goToEnd
	LDRB R1, [R4]
	CMP R1, #0x41
	BLT isSymbolDecrypt
	CMP R1, #0x5A
	BGT checkBetweenDecrypt
	CMP R1,#0x7A
	BGT isSymbolDecrypt
;value is a letter, decrypt
continueDecrypt
	BL checkValidDecrypt
;returns decrypted value, stores in buffer, R4, increments Buffer and decrements size
ReturnDecrypt
	STRB R1, [R4]
	ADD R4, #1
	SUB R5, #1
	B decryptLoop	;loops back to decryptLoop, above
;branches based on upper or lower case
checkValidDecrypt
	MOV R6, R3		;shifts R3 to R6 (used as shift counter)
	CMP R1, #0x5B
	BLT upperCaseDecrypt
	CMP R1, #0x7B
	BLT LowerCaseDecrypt
returnValidDecrypt
	BX LR
;decrypts uppercase (subtracts shift from value in R1) 
upperCaseDecrypt 
	SUB R1, R1, R6
	CMP R1, #0x41
	BLT	loopUpperDecrypt	;if value is less than a, needs to be looped around
	B ReturnDecrypt			;branches to returnDecrypt (value is decrypted and 
	
loopUpperDecrypt			;loops through and decrements byte in R1 one at a time
	ADD R1, R1, R6
LoopUpperInnerDecrypt
	CMP R1, #0x41			;when it hits a, looparound to Z
	BEQ LoopToZ
	SUB R1, R1, #1			;else reduce R1 and reduce shift amount
	SUB R6, R6, #1
	B LoopUpperInnerDecrypt
;brings byte value back to Z, shifts proper amount
LoopToZ
	MOV R1, #0x5B
SubFromZ
	SUB R1, R1, #1
	SUB R6, R6, #1
	CMP R6, #0
	BNE SubFromZ
	B ReturnDecrypt
;lowerCaseDecrypt version of upperCase, checks if it needs to go to z and branches
LowerCaseDecrypt
	SUB R1, R1, R6
	CMP R1, #0x61
	BLT	loopLowerDecrypt
	B ReturnDecrypt		;valid decrypt and can return
;invalid decrypt, went below 'a'
loopLowerDecrypt
	ADD R1, R1, R6		;add value back
;loops until it hits 'a' at 0x61
LoopLowerInnerDecrypt
	CMP R1, #0x61
	BEQ LoopToLowerZ
	SUB R1, R1, #1
	SUB R6, R6, #1
	B LoopLowerInnerDecrypt	;loops while not 'a' 
;loops around to z
LoopToLowerZ
	MOV R1, #0x7B
;decrypts, decrements R1 and R6 until proper position is found (R6 is 0)
SubFromLowerZ	
	SUB R1, R1, #1
	SUB R6, R6, #1
	CMP R6, #0
	BNE SubFromLowerZ
	B ReturnDecrypt
;if it is a symbol, increment memory buffer and subtract size to reverse
isSymbolDecrypt
	ADD R4, #1
	SUB R5, #1
	B decryptLoop
;checks if value is less than 'a', if so, it's a symbol
checkBetweenDecrypt
	CMP R1, #0x61
	BLT isSymbolDecrypt	;branches to symbolDecrypt
	B continueDecrypt	;branches to continueDecrypt for valid value
	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;end of file
	ALIGN
	END