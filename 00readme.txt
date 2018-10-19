Avery Cameron
October 2018

Question 2, 3:
These questions are found: 
Functions: Encrypt, Decrypt

Values for changing:
MOVT R3, #13 on line 34 in q2 and q3						AMOUNT TO SHIFT BY

string1 
	dcb "string to encrypt" 	line 52 in q2, line 60 in q3		STRING TO ENCRYPT

Memory buffer is stored in variable aux_buffer, currently 0x20000030		BUFFER LOCATION IN MEMORY
	aux_buffer
		dcd 0x20000030		line 57 in q2, 65 in q3

This function performs a Caesar Cipher encryption in the encrypt function by shifting to the right.
The shift value is stored R3 along with the size of the buffer

Copies a string to buffer
Encrypts string in buffer, ignores symbols and shifts of 0, shifts greater than 25 result in X's
Decrypts string in buffer, ignores symbols and shifts of 0, shifts greater than 25 are ignored
Note:
When encrypting, shifts that result in a letter going to a symbol ex Z -> [ is instead looped around to A
When decrypting, shifts that result in a letter going to a symbol ex A -> @ is instead looped around to Z
