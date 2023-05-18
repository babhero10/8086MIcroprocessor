name "Project#9: Mononumeric substitution encryption"
; Name:    Abdullah Elsayed Ahmed
; ID:      7459
; Group;   3
; Section: 2
include 'emu8086.inc'
org     100h

JMP MAIN_CODE
     
;-------------------- CONSTANTS -------------------;            
ENCODE_TABLE DB 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26
DECODE_TABLE DB 'abcdefghijklmnopqrstuvwxyz'
len          DB 26    
buffer_size  DW 100                                  

;-------------------- VARIABLES -------------------;  
generalInputText DB 100 dup(0)

;-------------------- MAIN CODE -------------------;  
MAIN_CODE:
    CALL ShowMenu 
    JMP MAIN_CODE


;----------------------- MENU ---------------------; 
;---- Show Menu 
ShowMenu PROC   
    CALL CLEAR_SCREEN 
    GOTOXY 0, 0
    PRINTN '-- Project#9: Mononumeric substitution encryption --'   
    PRINTN '1- Encode text'
    PRINTN '2- Decode text'
    PRINTN '3- Exit'
    PRINT 'Select: '  
    
    ShowMenuSelect:
        CALL SCAN_NUM 
        
        MOV BL, 1
        CMP CL, BL
        JE  EncodeMessageMenu  
        
        MOV BL, 2
        CMP CL, BL
        JE  DecodeMessageMenu
        
        MOV BL, 3
        CMP CL, BL   
        JE  PROGRAM_END
    
        ;-- Niether
        GOTOXY 8, 4 
        PRINT '        '
        GOTOXY 8, 4   
        JMP ShowMenuSelect
    
    RET    
ShowMenu ENDP

;---- Encode Message Menu                             
EncodeMessageMenu PROC   
    RepeatEncoding:
        CALL CLEAR_SCREEN 
        GOTOXY 0, 0
        
        PRINT 'Enter the text message: '  
        LEA     DI, generalInputText      ; buffer offset.
        MOV     DX, buffer_size           ; buffer size.
        CALL GET_STRING                 
        NOP
        NOP
        NOP                   
        GOTOXY 0, 1
        PRINT 'Encoded text message: '
        EncodeString generalInputText, 00h 
        GOTOXY 0, 2
        PRINTN 'WANT TO ENTER ANOTHER TEXT (Y>...'
        MOV AH, 0   
        INT 16h
        CMP AL, 'y'
        JE RepeatEncoding  
        CMP AL, 'Y'
        JE RepeatEncoding 
    
    RET
EncodeMessageMenu ENDP  

;---- Decode Message Menu  
DecodeMessageMenu PROC  
    RepeatDecoding:
        CALL CLEAR_SCREEN 
        GOTOXY 0, 0   
        PRINT 'Enter the Encoded message: '  
        LEA     DI, generalInputText      ; buffer offset.
        MOV     DX, buffer_size           ; buffer size.
        CALL GET_STRING                 
        NOP
        NOP
        NOP                   
        GOTOXY 0, 1
        PRINT 'text message: '
        DecodeString generalInputText  
        
        GOTOXY 0, 2
        PRINTN 'WANT TO ENTER ANOTHER TEXT (Y>...'
        MOV AH, 0   
        INT 16h
        CMP AL, 'y'
        JE RepeatDecoding  
        CMP AL, 'Y'
        JE RepeatDecoding 
    
    RET
DecodeMessageMenu ENDP     

;------------------ INPUT PROCESS -----------------;          
; get a null terminated string from keyboard,
; write it to buffer at ds:di, maximum buffer size is set in dx.
; 'enter' stops the input.
GET_STRING      PROC  
    PUSH    AX
    PUSH    CX
    PUSH    DI
    PUSH    DX
    
    MOV     CX, 0                   ; char counter.
    
    CMP     DX, 1                   ; buffer too small?
    JBE     empty_buffer            ;
    
    DEC     DX                      ; reserve space for last zero (null char>.
    
    
    ;============================
    ; eternal loop to get
    ; and processes key presses:
    
    wait_for_key:
    
        MOV     AH, 0                   ; get pressed key.
        INT     16h
        
        CMP     AL, 0Dh                 ; 'enter' pressed?
        JZ      exit
        
        
        CMP     AL, 8                   ; 'backspace' pressed?
        JNE     add_to_buffer
        JCXZ    wait_for_key            ; nothing to remove!
        DEC     CX
        DEC     DI
        PUTC    8                       ; backspace.
        PUTC    ' '                     ; clear position.
        PUTC    8                       ; backspace again.
        JMP     wait_for_key
            
    add_to_buffer:
    
        CMP     CX, DX          ; buffer is full?
        JAE     wait_for_key    ; if so wait for 'backspace' or 'return'...
    
        MOV     [DI], AL
        INC     DI
        INC     CX
        
        ; print the key:
        MOV     AH, 0Eh
        INT     10h
    
        JMP     wait_for_key
    
    exit:
    
        ; terminate by null:
        MOV     [DI], 32
        MOV     [DI + 1], 0
    
    empty_buffer:
    
        POP     DX
        POP     DI                     
        POP     CX
        POP     AX
        RET         
        
GET_STRING      ENDP    

;---------------- ENCODING PROCESS ----------------;          
; Encode only one char and store it in AL register
EncodeSingle MACRO char    
    ;--- DELAY  
    NOP  
    NOP
    NOP
    ;---- Check if Lowercas, Uppercase or Nither     
    MOV AL, char     ; Store the argument in AL
    
    ; if char >= 'a' && char <= 'z'
    MOV BL, 'a'
    MOV CL, 'z'
    CMP AL, BL
    JB  Uppercase
    CMP AL, CL
    JA  Uppercase
    Lowercase:      
        SUB AL, 'a'
        AND AL, 00FFh    
        JMP EncodeSingleGet
    Uppercase:      
        ; if char >= 'A' && char <= 'Z'
        MOV BL, 'A'
        MOV CL, 'Z'
        CMP AL, BL
        JB  Nethier
        CMP AL, CL
        JA  Nethier  
        MOV AL, char
        SUB AL, 'A' 
        JMP EncodeSingleGet
    Nethier:         
        AND AX, 00FFh 
        MOV CL, 01h
        JMP EncodeSingle_EXIT
    EncodeSingleGet:
        ; Get the value from the Table
        AND AX, 00FFh
        MOV BX, OFFSET ENCODE_TABLE
        ADD BX, AX   
        MOV AL, [BX] 
        MOV CL, 00h   
    EncodeSingle_EXIT: 
     
ENDM             
                       

; Encode text and print it
EncodeString MACRO text, textEnd      
    
    LEA SI, text
    LoopOnTextToEecode:   
        MOV AL, [SI]  
        MOV BL, 32  ; Check if there is space
        CMP AL, BL
        JE  Encode_nex_char  
          
        EncodeSingle AL 
        MOV BL, 01h
        CMP CL, BL
        JE EncodePrintChar ; Print normal char as it is
        
        CALL PRINT_NUM ; Print the number on the screen    
        PRINT ' ' ; Print space on the screen                               
        JMP Encode_nex_char
        
        EncodePrintChar:
            PUTC AL
            
        Encode_nex_char:
            INC SI
            MOV BL, [SI]
            CMP BL, textEnd
            JNE LoopOnTextToEecode     
        
ENDM       
        
;---------------- DECODING PROCESS ----------------;          
; Decode only one number and store it in AL register
DecodeSingle MACRO number    
    ;--- DELAY  
    NOP  
    NOP
    NOP
    ;---- Check if Valid number   
    MOV AL, number     ; Store the argument in AL
    
    ; if number >= '1' && number <= '26'
    MOV BL, 1
    MOV CL, 26
    CMP AL, BL
    JB  NotCode  ; If Smaller then 1
    CMP AL, CL
    JA  NotCode  ; If Bigger then 26
    DecodeSingleGet:
        ; Get the value from the Table
        AND AX, 00FFh               ; Avoid any unwanted data
        MOV BX, OFFSET DECODE_TABLE ; Get the start address of the table
        SUB AX, 1                   ; Strat from 0 index
        ADD BX, AX                  ; Get the address of the given index
        MOV AL, [BX]                ; Get the value
        JMP DecodeSingle_EXIT
    NotCode:         
        MOV AX, 00h          ; Print zero if not valid code
        JMP DecodeSingle_EXIT
    
    DecodeSingle_EXIT:  
ENDM             
                       

; Encode text and print it
DecodeString MACRO numberList
              
    MOV DX, 0000h
    LEA SI, numberList 
    MOV CL, 01h ; Decmial Number Power        
    LoopOnTextToDecode:   
        MOV AL, [SI]  
        MOV BL, 32  ; Get the number from the digits
        CMP AL, BL   
        JE DecodeNumber
        
        MOV BL, 0 ; END of numbers 
        CMP AL, BL
        JE EXITDecodeString   
        
        ; DL = DL <the number> * CL <power> + AL (current digit)
        SUB AL, 48  ; Get the value not the ascii code
        MOV BL, AL
        MOV AL, CL
        MUL DL
        MOV DL, AL
        ADD DL, BL
        MOV AL, 0010
        MUL CL    
        MOV CX, AX              
        INC SI
        JMP LoopOnTextToDecode 
        
        DecodeNumber:
            INC SI
            MOV AL, 01h 
            CMP CL, AL             
            JE LoopOnTextToDecode  ; Remove Extra spaces
            
            DecodeSingle DL 
            PUTC AL ; Print the number on the screen      
            MOV DL, 00h
            MOV CL, 01h            
            JMP LoopOnTextToDecode                            
   
    EXITDecodeString:
     
        
ENDM        
          
PROGRAM_END:         
    CALL CLEAR_SCREEN 
    GOTOXY 8, 4  
    PRINTN '------ THANK YOU! ------' 
    PRINTN 'PRESS ANY KEY TO EXIT...'   
    MOV AH, 0
    INT 16h
    
    DEFINE_CLEAR_SCREEN
    DEFINE_PRINT_STRING
    DEFINE_PRINT_NUM
    DEFINE_PRINT_NUM_UNS  ; required for print_num.
    DEFINE_PTHIS
    DEFINE_SCAN_NUM
    END