*-----------------------------------------------------------
* Title      :
* Written by :  Awake Team
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

    MOVE.B  #2,D0       ; get string input from keyboard
    TRAP    #15
    MOVE.W  D1,D0
    MOVE.L  #$00000000,D1
    
; convert ASCII to Hexidecimal
AtoH    ASL.L   #4,D1   ; shift output left 1 hex digit (4 bits)
        MOVE.B  (A1),D4 ; move char from string to data reg 4
        ADDA    #1,A1   ; increment string index
        CMP.B   #$30,D4 ; cannot be less than 30
        BLT     INV_CHAR
        CMP.B   #$46,D4 ; cannot be greater than 46
        BGT     INV_CHAR
        CMP.B   #$39,D4
        BGT.B   LETTER  ; if char bigger than #39, branch letter
        SUBI.B  #$30,D4 ; otherwise subtract $30 to get number
        ADD.L   D4,D1   ; add to output
        SUB.W   #1,D0   ; decrement counter
        BNE     AtoH    ; if counter not zero, loop
        BRA     DONE    ; done
       
INV_CHAR
        LEA     INVCHAR,A1
        MOVE.B  #14,D0 
        TRAP    #15
        BRA     DONE
; convert ASCII to hex letter 
LETTER  SUBI.B  #$37,D4 ; subtract $37 to get letter
        ADD.L   D4,D1   ; add to output
        SUB.W   #1,D0   ; decrement counter
        BNE     AtoH    ; loop if counter not 0
DONE
        SIMHALT

* Put variables and constants here
INVCHAR DC.B    'ERROR: INVALID HEX CHARACTER',0
    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
