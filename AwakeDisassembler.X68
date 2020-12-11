*-----------------------------------------------------------
* Title      : Final Project 422
* Written by : awaketeam
* Date       : November 13, 2020
* Description: Code for Disassembler
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program
    move.l  #31,d2
    MOVE.B  #0,D6
    MOVE.B  #13,D0
    LEA     startMsg,A1  ; prompt for start address 
    TRAP    #15

getStart
    MOVE.B  #2, D0  ; Store User input in A1
    TRAP    #15 
    JSR     validateAddrLen
    MOVE.W  D1,D0
    MOVE.L  #$00000000,D1
    
    JSR     AtoH
    jsr     checkOdd
    MOVE.L  D1,startAddr
    
getEnd
    move    #6,d6
    MOVE.B  #13,D0
    LEA     endMsg,A1  ; prompt for end address 
    TRAP    #15
    
    MOVE.B  #2, D0  ; Store User input in A1
    TRAP    #15 
    JSR     validateAddrLen
    MOVE.W  D1,D0
    MOVE.L  #$00000000,D1
    
    JSR     AtoH
    jsr     checkOdd
    CMP.L   (startAddr),D1
    BLT     invalidEnd
    MOVE.L  D1,endAddr
    
decompile
    move.l  startAddr,a3
    move.l  #0,d3
      
decode
    LEA     JMP_TABLE,A0
    LEA     printer,a5

    move.l  endAddr,a2
    cmp.l   a2,a3
    bge     endProgram
    
    jsr     PrintAddr
    
    move.w  (a3)+,d3
    move.w  d3,d4
    move.w  d3,code
    move.l  #12,d0
    lsr.w   d0,d3
    MULU    #6,d3
    jsr     0(a0,d3)
    
    move.b  #0,(a5)+
    lea     printer,a1
    move.b  #13,D0
    trap    #15
    move.l  #0,printer
    
    jsr     CLEAR_REG
    sub     #1,d2
    cmpi    #0,d2
    BEQ     WaitForEnter
    BRA     decode
    
printAddr
    move.w  a3,temp
    jsr     HtoA
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    lea     JMP_TABLE,a0
    rts
    
JMP_TABLE
    JMP     OP0000                           * - NR
    JMP     OP0001                           * - MOVE.B
    JMP     OP0010                           * - MOVE.W, MOVEA.W
    JMP     OP0011                           * - MOVE.L, MOVEA.L
    JMP     OP0100                           * - MOVEM, LEA, JSR, RTS, NOP, NOT
    JMP     OP0101                           * - NR
    JMP     OP0110                           * - BCC, BLE, BGT, BEQ, BRA
    JMP     OP0111                           * - MOVEQ
    JMP     OP1000                           * - OR, DIVU
    JMP     OP1001                           * - SUB
    JMP     OP1010                           * - NR
    JMP     OP1011                           * - NR
    JMP     OP1100                           * - AND, MULS
    JMP     OP1101                           * - ADDA, ADD
    JMP     OP1110                           * - ASR/ASL, LSR/LSL, ROL/ROR
    JMP     OP1111                           * - NR
    
AM_TABLE
    JMP     M000
    JMP     M001
    JMP     M010
    JMP     M011
    JMP     M100
    JMP     M101
    JMP     M110
    JMP     M111                             * - 
    
Reg_TABLE
    JMP     R000
    JMP     R001
    JMP     R010
    JMP     R011
    JMP     R100
    JMP     R101
    JMP     R110
    JMP     R111
    JMP     HEX8
    JMP     HEX9
    JMP     HEXA
    JMP     HEXB
    JMP     HEXC
    JMP     HEXD
    JMP     HEXE
    JMP     HEXF


M111_TABLE
    JMP     WORD
    JMP     LONG
    JMP     MYSTERY
    JMP     MYSTERY2
    JMP     IMMEDIATE

OP0000
    jsr     INVALID
    RTS

OP0001
    move.b  #'M',(a5)+    ; print MOVEB
    move.b  #'O',(a5)+
    move.b  #'V',(a5)+
    move.b  #'E',(a5)+
    move.b  #'.',(a5)+
    move.b  #'B',(a5)+
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    

sourceMOVE
    jsr     printSource
    move.b  #',',(a5)+

destMOVE
    jsr     printDest

    RTS

OP0010
    move.b  #'M',(a5)+    ; print MOVEB
    move.b  #'O',(a5)+
    move.b  #'V',(a5)+
    move.b  #'E',(a5)+
    move    code,d5
    jsr     getDestMode
    CMPI    #1,d5
    BEQ     MOVEA
    
OP0010_NEXT
    move.b  #'.',(a5)+
    jsr     getSize
    jsr     printSize
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    JMP     sourceMove

MOVEA
    move.b  #'A',(a5)+
    BRA     OP0010_NEXT

OP0011
    jmp     OP0010

OP0100
    move.w  code,d5
    cmp.w   #$4E75,d5
    BEQ     printRTS
    cmp.w   #$4E71,d5
    BEQ     printNOP
    move    code,d5
    jsr     getDestMode
    move    code,d5
    jsr     getDestReg
    cmpi    #7,d7
    beq     checkJSR
    
checkLea
    cmpi    #7,d6
    beq     printLea
    cmpi    #3,d7
    beq     printNot
    bra     printMOVEM

printLEA
    move.b  #'L',(a5)+    ; print MOVEB
    move.b  #'E',(a5)+
    move.b  #'A',(a5)+
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+

    jsr     printSource
    move.b  #',',(a5)+
    move.b  #'A',(a5)+
    jsr     getDestReg
    mulu    #6,d7
    jsr     printNum
    rts
    
    
printNOT
    move.b  #'N',(a5)+    ; print MOVEB
    move.b  #'O',(a5)+
    move.b  #'T',(a5)+
    move.b  #'.',(a5)+
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    move    code,d5
    ANDI.W  #$00FF,d5
    lsr     #6,d5
    move    d5,size
    jsr     printSize2
    jsr     printSource
    RTS
    
printRTS
    move.b  #'R',(a5)+    ; print MOVEB
    move.b  #'T',(a5)+
    move.b  #'S',(a5)+
    rts

printNOP
    move.b  #'N',(a5)+    ; print MOVEB
    move.b  #'O',(a5)+
    move.b  #'P',(a5)+
    rts

checkJSR
    cmpi    #2,d6
    beq     printJSR
    BRA     checkLEA
    
printJSR
    move.b  #'J',(a5)+    ; print 
    move.b  #'S',(a5)+
    move.b  #'R',(a5)+
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    jsr     printSource
    rts

printMOVEM
    move.b  #'M',(a5)+    ; print MOVEB
    move.b  #'O',(a5)+
    move.b  #'V',(a5)+
    move.b  #'E',(a5)+
    move.b  #'M',(a5)+
    move.b  #'.',(a5)+
    
movemSize
    move.w  code,d5
    lsr     #6,d5
    ANDI.W  #$0001,d5
    move.W  d5,size
    
    cmp.w   #0,size
    BEQ     movemWord
    Bra     movemLong
    
movemWord
    move.b  #'W',(a5)+
    move    #$11,size
    Bra     movemDr
    

movemLong
    move.b  #'L',(a5)+
    move    #$111,size
    
movemDr
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    move.w  code,d5
    move    #10,d0
    lsr     d0,d5
    ANDI.W  #$0001,d5
    move    d5,d1
    cmp     #0,d1
    BEQ     Reg2Mem
    BRA     Mem2Reg
    
Reg2Mem
    move.w  code,d5
    jsr     getSourceMode
    cmp     #4,d6
    BEQ     PreMask
    Bra     PostMask
    
PreMask
    jsr     PreRegisterMask
    move.b  #',',(a5)+
    jsr     printSource
    rts

PostMask
    jsr     RegisterMask
    move.b  #',',(a5)+
    jsr     printSource
    rts

PreRegisterMask
    jsr     getNextWord
    cmp.w   #$7F00,temp
    BEQ     DataMask
    cmp.w   #$FE00,temp
    BEQ     DataMask
    cmp.w   #$00FE,temp
    BEQ     AddrMask
    cmp.w   #$007F,temp
    BEQ     AddrMask
    cmp.w   #$0280,temp
    BEQ     MixMask
    cmp.W   #$0140,temp
    BEQ     MixMask
    BRA     DataMask
    rts
    
RegisterMask
    jsr     getNextWord
    cmp.w   #$7F00,temp
    BEQ     AddrMask
    cmp.w   #$FE00,temp
    BEQ     AddrMask
    cmp.w   #$00FE,temp
    BEQ     DataMask
    cmp.w   #$007F,temp
    BEQ     DataMask
    cmp.w   #$0280,temp
    BEQ     MixMask
    cmp.W   #$0140,temp
    BEQ     MixMask
    BRA     DataMask
    rts 

AddrMask
    move.b  #'A',(a5)+
    move.b  #'1',(a5)+
    move.b  #'-',(a5)+
    move.b  #'A',(a5)+
    move.b  #'7',(a5)+
    rts

DataMask
    move.b  #'D',(a5)+
    move.b  #'1',(a5)+
    move.b  #'-',(a5)+
    move.b  #'D',(a5)+
    move.b  #'7',(a5)+
    rts

MixMask
    move.b  #'A',(a5)+
    move.b  #'1',(a5)+
    move.b  #'/',(a5)+
    move.b  #'D',(a5)+
    move.b  #'7',(a5)+
    rts

Mem2Reg
    jsr     getSourceMode
    cmp     #7,d6
    BEQ     rawMem2Reg
    jsr     printSource
    jsr     getNextWord  
    
continueMem2Reg
    move.b  #',',(a5)+
    cmp.w   #$FE00,temp
    BEQ     AddrMask
    cmp.w   #$00FE,temp
    BEQ     DataMask
    cmp.w   #$0280,temp
    BEQ     MixMask
    cmp.w   #$0140,temp
    BEQ     MixMask
    jsr     INVALID
    rts
    
rawMem2Reg
    jsr     getNextWord
    move.w  temp,temp2
    jsr     printSource
    move.w  temp2,temp
    BRA     continueMem2Reg

OP0101
    jsr     INVALID
    RTS

OP0110
    move.b  #'B',(a5)+
    jsr     getSecondNibble
    cmp.w   #$4,d5
    BEQ     printCC
    cmp.w   #$7,d5
    BEQ     printEQ
    cmp.w   #$C,d5
    BEQ     printGE
    cmp.w   #$E,d5
    BEQ     printGT
    cmp.w   #$F,d5
    BEQ     printLE
    jsr     INVALID
    RTS

printCC
    move.b  #'C',(a5)+
    move.b  #'C',(a5)+
    BRA     getBranchSize

printEQ
    move.b  #'E',(a5)+
    move.b  #'Q',(a5)+
    BRA     getBranchSize

printGE
    move.b  #'G',(a5)+
    move.b  #'E',(a5)+
    BRA     getBranchSize

printGT
    move.b  #'G',(a5)+
    move.b  #'T',(a5)+
    BRA     getBranchSize
    
printLE
    move.b  #'L',(a5)+
    move.b  #'E',(a5)+
    BRA     getBranchSize
    
getBranchSize
    move.b  #'.',(a5)+
    move.w  code,d5
    ANDI.W  #$00FF,d5
    cmp     #$00,d5
    BEQ     branchWord
    BRA     branchByte
    
branchWord
    move.b  #'W',(a5)+
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    jsr     getNextWord
    jsr     HtoA
    rts
    
branchByte
    move.b  #'B',(a5)+
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    move.w  d5,temp
    jsr     HtoA
    rts
    

OP0111
    move.b  #'M',(a5)+    ; print MOVEQ
    move.b  #'O',(a5)+
    move.b  #'V',(a5)+
    move.b  #'E',(a5)+
    move.b  #'Q',(a5)+
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    move.b  #'#',(a5)+
    move.b  #'$',(a5)+
    move.w  code,d5
    ANDI.W  #$00FF,d5
    lsr     #4,d5
    mulu    #6,d5
    lea     REG_TABLE,a0
    jsr     0(a0,d5)
    move.w  code,d5
    ANDI.W  #$000F,d5
    mulu    #6,d5
    lea     REG_TABLE,a0
    jsr     0(a0,d5)
    move.b  #',',(a5)+
    move.b  #'D',(a5)+
    move.w  code,d5
    jsr     getDestReg
    mulu    #6,d7
    lea     REG_TABLE,a0
    jsr     0(a0,d7)
    RTS

OP1000
    move.w  code,d5
    lsr     #6,d5
    ANDI.W  #$0003,d5
    cmpi    #3,d5
    BNE     printOR
    move.b  #'D',(a5)+    ; print MOVEB
    move.b  #'I',(a5)+
    move.b  #'V',(a5)+    ; print MOVEB
    move.b  #'U',(a5)+    ; print MOVEB
    move.b  #'.',(a5)+
    move.b  #'W',(a5)+    ; print MOVEB
    move.b  #' ',(a5)+    ; print MOVEB
    move.b  #' ',(a5)+    ; print MOVEB
    jsr     MULDIVHELPER
    rts

printOR
    move.b  #'O',(a5)+    ; 
    move.b  #'R',(a5)+
    move.b  #'.',(a5)+ 
    jsr     ADDHELPER
    RTS

OP1001
    move.b  #'S',(a5)+    ;
    move.b  #'U',(a5)+
    move.b  #'B',(a5)+
    move.b  #'.',(a5)+ 
    jsr     SUBHELPER
    rts
    
SUBHELPER
    move.w  code,d5
    jsr     getDestMode
    move.w  code,d5
    cmpi    #0,d6
    beq     ADD_B_DN
    cmpi    #1,d6
    beq     ADD_W_DN
    cmpi    #2,d6
    beq     ADD_L_DN
    cmpi    #4,d6
    beq     ADD_B_EA
    cmpi    #5,d6
    beq     ADD_W_EA
    bra     ADD_L_EA

OP1010
    jsr     INVALID
    RTS

OP1011
    jsr     INVALID
    RTS

OP1100
    move.w  code,d5
    lsr     #6,d5
    ANDI.W  #$0007,d5
    cmpi    #7,d5
    BNE     printAND
    move.b  #'M',(a5)+    ; print MOVEB
    move.b  #'U',(a5)+
    move.b  #'L',(a5)+    ; print MOVEB
    move.b  #'S',(a5)+    ; print MOVEB
    move.b  #'.',(a5)+
    move.b  #'W',(a5)+    ; print MOVEB
    move.b  #' ',(a5)+    ; print MOVEB
    move.b  #' ',(a5)+    ; print MOVEB
    jsr     MULDIVHELPER
    rts
    
printAND
    move.b  #'A',(a5)+    ; 
    move.b  #'N',(a5)+
    move.b  #'D',(a5)+
    move.b  #'.',(a5)+ 
    jsr     ADDHELPER
    RTS

MULDIVHELPER
    move.w  code,d5
    move.l  #0,size
    move.l  #$11,size
    jsr     printSource
    move.b  #',',(a5)+
    move.b  #'D',(a5)+
    move.w  code,d5
    ANDI.W  #$0E00,d5
    lsr     #8,d5
    lsr     #1,d5
    move.b  d5,d7
    mulu    #6,d7
    jsr     printNum
    rts

OP1101
    move.b  #'A',(a5)+   
    move.b  #'D',(a5)+
    move.b  #'D',(a5)+    
    jsr     checkADDA
    cmp.l   #$F,d1
    BEQ     rtsWrapper
    move.b  #'.',(a5)+
    jsr     ADDHELPER
    RTS
    
rtsWrapper
    rts

checkADDA
    move.w  code,d5
    jsr     getDestMode
    cmpi    #3,d6
    BEQ     addaWord
    cmpi    #7,d6
    BEQ     addaLong
    rts
    
addaWord
    move.b  #'A',(a5)+
    move.b  #'.',(a5)+
    move.b  #'W',(a5)+
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    move.l  #$F,d1
    move.l  #0,size
    move.l  #$11,size
    jsr     printSource
    move.b  #',',(a5)+
    jsr     addaRegPrint
    rts

addaLong
    move.b  #'A',(a5)+
    move.b  #'.',(a5)+
    move.b  #'L',(a5)+
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    move.l  #$F,d1
    move.l  #0,size
    move.l  #$111,size
    jsr     printSource
    move.b  #',',(a5)+
    jsr     addaRegPrint
    rts

addaRegPrint
    move.b  #'A',(a5)+
    move.w  code,d5
    jsr     getDestReg
    mulu    #6,d7
    jsr     printNum
    move.l  #$F,d1
    rts

ADDHELPER
    move.w  code,d5
    jsr     getDestMode
    move.w  code,d5
    cmpi    #0,d6
    beq     ADD_B_DN
    cmpi    #1,d6
    beq     ADD_W_DN
    cmpi    #2,d6
    beq     ADD_L_DN
    cmpi    #4,d6
    beq     ADD_B_EA
    cmpi    #5,d6
    beq     ADD_W_EA
    bra     ADD_L_EA
    
ADD_B_EA
    move.b  #'B',(a5)+
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    move.w  code,d5
    move.l  #$11,size
    jsr     getDestReg
    mulu    #6,d7
    jsr     M000
    move.b  #',',(a5)+
    jsr     printSource
    RTS
    

ADD_W_EA
    move.b  #'W',(a5)+
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    move.w  code,d5
    move    #$11,size
    jsr     getDestReg
    mulu    #6,d7
    jsr     M000
    move.b  #',',(a5)+
    jsr     printSource
    rts


ADD_L_EA
    move.b  #'L',(a5)+
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    move.w  code,d5
    move    #$111,size
    jsr     getDestReg
    mulu    #6,d7
    jsr     M000
    move.b  #',',(a5)+
    jsr     printSource
    rts

ADD_B_DN
    move.b  #'B',(a5)+
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    move.l  #$11,size
    jsr     printSource
    move.b  #',',(a5)+
    jsr     getDestReg
    mulu    #6,d7
    jsr     M000
    rts

ADD_W_DN
    move.b  #'W',(a5)+
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    move.l  #$11,size
    jsr     printSource
    move.b  #',',(a5)+
    jsr     getDestReg
    mulu    #6,d7
    jsr     M000
    rts

ADD_L_DN
    move.b  #'L',(a5)+
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    move.l  #$111,size
    jsr     printSource
    move.b  #',',(a5)+
    jsr     getDestReg
    mulu    #6,d7
    jsr     M000
    rts

OP1110
    move.w  code,d5
    lsr     #6,d5
    ANDI.W  #$0003,d5
    cmpi    #3,d5
    BEQ     MEMSHIFT
    
    move.w  code,d5
    lsr     #3,d5
    ANDI.W  #$0003,d5
    cmpi.b  #0,d5
    BEQ     printASL
    cmpi.b  #1,d5
    BEQ     printLSL
    BEQ     printLSL
    cmpi.b  #3,d5
    BEQ     printROL
    jsr     INVALID
    rts
    
MEMSHIFT
    move.w  code,d5
    move    #9,d0
    lsr     d0,d5
    ANDI.W  #$0003,d5
    cmpi.b  #0,d5
    BEQ     ASLMEM
    cmpi.b  #1,d5
    BEQ     LSLMEM
    cmpi.b  #3,d5
    BEQ     ROLMEM
    jsr     INVALID
    rts
    
ASLMEM
    move.b  #'A',(a5)+
    move.b  #'S',(a5)+
    jsr     getDR
    cmpi    #1,D5
    BEQ     leftMemShift
    move.b  #'R',(a5)+
    BRA     continueMemShift
    
LSLMEM
    move.b  #'L',(a5)+
    move.b  #'S',(a5)+
    jsr     getDR
    cmpi    #1,D5
    BEQ     leftMemShift
    move.b  #'R',(a5)+
    BRA     continueMemShift

ROLMEM    
    move.b  #'R',(a5)+
    move.b  #'O',(a5)+
    jsr     getDR
    cmpi    #1,D5
    BEQ     leftMemShift
    move.b  #'R',(a5)+
    BRA     continueMemShift
    
leftMemShift
    move.b  #'L',(a5)+
    BRA     continueMemShift
    
continueMemShift
    move.b  #'.',(a5)+
    move.b  #'W',(a5)+
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    jsr     printSource
    rts
    
printROL
    move.b  #'R',(a5)+
    move.b  #'O',(a5)+
    jsr     getDR
    cmpi    #1,D5
    BEQ     leftShift
    move.b  #'R',(a5)+
    BRA     continueShift
    
printLSL
    move.b  #'L',(a5)+
    move.b  #'S',(a5)+
    jsr     getDR
    cmpi    #1,D5
    BEQ     leftShift
    move.b  #'R',(a5)+
    BRA     continueShift
    
printASL
    move.b  #'A',(a5)+
    move.b  #'S',(a5)+
    jsr     getDR
    cmpi    #1,D5
    BEQ     leftShift
    move.b  #'R',(a5)+

continueShift
    jsr     getShiftSize
    move.b  #'.',(a5)+
    jsr     printSize2
    move.b  #' ',(a5)+
    move.b  #' ',(a5)+
    jsr     getIR
    cmpi.b  #1,d5
    BEQ     printRegShift
    move.b  #'#',(a5)+
    move.b  #'$',(a5)+
    
continueShift2
    move.w  code,d5
    ANDI.W  #$0E00,d5
    lsr     #8,d5
    lsr     #1,d5
    move    d5,d7
    mulu    #6,d7
    jsr     printNum
    move.b  #',',(a5)+
    
    move.b  #'D',(a5)+
    move.w  code,d5
    ANDI.W  #$0003,d5
    move    d5,d7
    mulu    #6,d7
    jsr     printNum
    rts
    
    
printRegShift
    move.b  #'D',(a5)+
    BRA     continueShift2


getIR
    move.w  code,d5
    ANDI.W  #$0020,d5
    lsr     #5,d5
    rts

getShiftSize
    move.w  code,d5
    ANDI.W  #$00FF,d5
    lsr     #6,d5
    move.w  d5,size
    rts    
    
getDR
    move.w  code,d5
    ANDI.W  #$0100,d5
    lsr     #8,d5
    rts

leftShift
    move.b  #'L',(a5)+
    BRA     continueShift
    

OP1111
    jsr     INVALID
    RTS
    
    
M000
    move.b  #'D',(a5)+    ; print
    jsr     printNum
    RTS
    
M001
    move.b  #'A',(a5)+    ; print
    jsr     printNum
    RTS
    
M010
    move.b  #'(',(a5)+    ; print
    move.b  #'A',(a5)+ 
    jsr     printNum
    move.b  #')',(a5)+ 
    RTS

M011
    move.b  #'(',(a5)+    ; print
    move.b  #'A',(a5)+ 
    jsr     printNum
    move.b  #')',(a5)+ 
    move.b  #'+',(a5)+ 
    RTS
    
M100
    move.b  #'-',(a5)+
    move.b  #'(',(a5)+    ; print
    move.b  #'A',(a5)+ 
    jsr     printNum
    move.b  #')',(a5)+ 
    RTS
    
M101
    jsr     INVALID
    RTS
    
M110
    jsr     INVALID
    RTS
    
M111
    lea     M111_TABLE,a0
    jsr     0(a0,d7)
    RTS
    

R000
    move.b  #'0',(a5)+    ; print
    RTS

R001
    move.b  #'1',(a5)+    ; print
    RTS
    
R010
    move.b  #'2',(a5)+    ; print
    RTS

R011
    move.b  #'3',(a5)+    ; print
    RTS
    
R100
    move.b  #'4',(a5)+    ; print
    RTS
    
R101
    move.b  #'5',(a5)+    ; print
    RTS
    
R110
    move.b  #'6',(a5)+    ; print
    RTS
    
R111
    move.b  #'7',(a5)+    ; print
    RTS

HEX8
    move.b  #'8',(a5)+
    RTS
    
HEX9
    move.b  #'9',(a5)+
    RTS
    
HEXA
    move.b  #'A',(a5)+
    RTS
    
HEXB
    move.b  #'B',(a5)+
    RTS 
    
HEXC
    move.b  #'C',(a5)+
    RTS
    
HEXD
    move.b  #'D',(a5)+
    RTS
    
HEXE
    move.b  #'E',(a5)+
    RTS
    
HEXF
    move.b  #'F',(a5)+
    RTS

validateAddrLen
    CMPI.B  #1,D1
    BLT     invalidAddr
    CMPI.B  #8,D1
    BGT     invalidAddr
    rts
    
invalidAddr
    MOVE.B  #13, D0
    LEA     invAddrMsg, A1
    TRAP    #15
    CMPI    #0,D6
    BEQ     START
    JMP     getEnd
    
invalidEnd
    MOVE.B  #13, D0
    LEA     invEndMsg, A1
    TRAP    #15
    JMP     getEnd
    
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
        RTS             ; done
       
INV_CHAR
        LEA     INVCHAR,A1
        MOVE.B  #14,D0 
        TRAP    #15
        BRA     START
; convert ASCII to hex letter 
LETTER  SUBI.B  #$37,D4 ; subtract $37 to get letter
        ADD.L   D4,D1   ; add to output
        SUB.W   #1,D0   ; decrement counter
        BNE     AtoH    ; loop if counter not 0
        RTS


HtoA
    move.w  temp,d1
    move    #12,d0
    lsr     d0,d1
    mulu    #6,d1
    lea     REG_TABLE,a0
    jsr     0(a0,d1)
    
    move.w  temp,d1
    lsl     #4,d1
    move    #12,d0
    lsr     d0,d1
    mulu    #6,d1
    lea     REG_TABLE,a0
    jsr     0(a0,d1)

    move.w  temp,d1
    lsr     #4,d1
    ANDI.W  #$000F,d1
    mulu    #6,d1
    lea     REG_TABLE,a0
    jsr     0(a0,d1)
    
    move.w  temp,d1
    ANDI.W  #$000F,d1
    mulu    #6,d1
    lea     REG_TABLE,a0
    jsr     0(a0,d1)
    
    RTS


getSourceMode
    move.w  code,d5
    lsr     #3,d5
    ANDI.W  #$0007,d5
    move    d5,d6
    RTS

getDestMode
    move.w  code,d5
    lsr     #6,d5
    ANDI    #$0007,d5
    move    d5,d6
    RTS
    
    
getSourceReg
    move.w  code,d5
    ANDI.W  #$0007,d5
    move    d5,d7
    RTS
    
getDestReg
    move.w  code,d5    
    move    #9,d0
    lsr     d0,d5
    ANDI.W  #$0007,d5
    move    d5,d7
    RTS
    
    
WORD
    move.b  #'$',(a5)+
    jsr     getNextWord
    jsr     HtoA
    ;move.b  #'.',(a5)+
    ;move.b  #'W',(a5)+
    RTS

LONG
    move.b  #'$',(a5)+
    jsr     getNextWord
    jsr     HtoA
    jsr     getNextWord
    jsr     HtoA
    ;move.b  #'.',(a5)+
    ;move.b  #'L',(a5)+
    RTS

MYSTERY
    RTS
    
MYSTERY2
    RTS
    
IMMEDIATE
    move.b  #'#',(a5)+
    move.b  #'$',(a5)+  
    move.l  size,d1
    cmp.l   #$11,d1
    BEQ     IMM_WORD
    cmp.l   #$111,d1
    BEQ     IMM_LONG
    jsr     INVALID
    RTS
    
IMM_WORD
    jsr     getNextWord
    jsr     HtoA
    rts
    
IMM_LONG
    jsr     getNextWord
    jsr     HtoA
    jsr     getNextWord
    jsr     HtoA
    rts
    
printNum
    lea     REG_TABLE,a0
    jsr     0(a0,d7)
    RTS
 
getSize
    move    code,d5
    lsl     #2,d5
    move    #14,d0
    lsr     d0,d5
    move    d5,size
    rts
       
printSize
    move    size,d0
    cmpi    #1,d0
    BEQ     printByte
    cmpi    #3,d0
    BEQ     printWord
    move.b  #'L',(a5)+
    RTS
    
printSize2
    move    size,d0
    cmpi    #0,d0
    BEQ     printByte
    cmpi    #1,d0
    BEQ     printWord
    move.b  #'L',(a5)+
    RTS

    
printByte
    move.b  #'B',(a5)+
    rts
    
printWord
    move.b  #'W',(a5)+
    rts

getNextWord
    move.w  (a3)+,d4
    move.w  d4,temp
    Rts

printDest
    move.w  code,d5
    jsr     getDestMode
    move.w  code,d5
    jsr     getDestReg
    mulu    #6,d6
    mulu    #6,d7
    lea     AM_TABLE,a0
    jsr     0(a0,d6)
    rts
    
printSource
    move.w  code,d5
    jsr     getSourceMode
    move.w  code,d5
    jsr     getSourceReg
    mulu    #6,d6
    mulu    #6,d7
    lea     AM_TABLE,a0
    jsr     0(a0,d6)
    rts

getSecondNibble
    move.w  code,d5
    lsr     #8,d5
    ANDI.W  #$000F,d5
    rts
    
INVALID
    move.b  #'I',(a5)+
    move.b  #'N',(a5)+
    move.b  #'V',(a5)+
    rts
    
CLEAR_REG
    rts

checkOdd
    move    d1,d4
    andi    #1,d4
    bne     invalidAddr
    rts

PrintNewLine
    lea     emptyLine,a1
    move.b  #13,d0
    trap    #15
    rts

WaitForEnter
    LEA     pauseMsg,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    LEA     $0,A1
    MOVE.B  #2,D0
    TRAP    #15
    
    move.b  #31,d2
    BRA     decode
    
restart
    BRA     START

epErrorRoutine
    LEA     epError,A1
    move.b  #13,d0
    trap    #15
    BRA     endProgram

CLEAREVERYTHING
    CLR     (a0)
    CLR     (a1)
    CLR     (a2)
    CLR     (a3)
    CLR     (a4)
    CLR     (a5)
    move.l  #0,d0
    move.l  #0,d1
    move.l  #0,d2
    move.l  #0,d3
    move.l  #0,d4
    move.l  #0,d5
    move.l  #0,d6
    move.l  #0,d7
    rts

endProgram
    jsr     CLEAREVERYTHING
    LEA     endProgramMsg,A1
    move.b  #13,d0
    trap    #15
    
    move.b  #5,d0
    trap    #15
    
    cmp     #'y',d1
    BEQ     restart
    cmp     #'n',d1
    BEQ     EXIT
    BNE     epErrorRoutine

EXIT  
    SIMHALT             ; halt simulator

* Put variables and constants here
startMsg   DC.B     'Please enter a start address: ',0
endMsg     DC.B     'Please enter a end address: ',0
INVCHAR     DC.B    'ERROR: INVALID HEX CHARACTER',0
invAddrMsg  DC.B    'Address is not valid',0
invEndMsg   DC.B    'End address must be greater than start',0
emptyLine   DC.B    ' ',0
pauseMsg    DC.B    'Please hit enter to see the next page',0
spacing     DC.B    '           ',0
endProgramMsg   DC.B    '100% complete. Would you like to disassemble again (y/n)?',0
epError     DC.B    'Invalid input',0

startAddr   DS.L    1
endAddr     DS.L    1
code        DS.W    1
temp        DS.W    1
temp2       DS.W    1
size        DS.L    1
opmode      DS.L    1
dr          DS.L    1
printer     DC.L    16
    END    START        ; last line of source










*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
