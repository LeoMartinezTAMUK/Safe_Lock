; Written by Leo Martinez in HCS12 Assembly using AsmIDE 3.40 (in Spring 2023), assisted by Dr. Leung of TAMUK in Microprocessors.
; Program was tested using a Dragon12 JR Development Board

; this program requires to input the Master 4-Digit PIN
; With entering the 4-digit Master PIN, a yellow LED will turn on for 1 sec.
; then input the user-inputed 4-Digit PIN.
; Verify the User PIN with the Master PIN by pulling the MASTER-PIN from the stack

#include "REG9S12.H" ; Directory needs to be updated based on the location of the file

keyboard        equ     PTA
UserTimerCh5    equ     $3E64
hi_freq         equ     1500        ; delay count for 1000 Hz
lo_freq         equ     7500         ; delay count for 200 Hz
toggle          equ     $04        ; value to toggle the TC5 pin, $04=%0000 0100

                org     $1500
count           rmb     1
delay           ds.w    1
                fill    0,14            ; fill with zeros $1502~150F

                org     $1600
                lds     #$1600          ; initialize the stack

;first set of Master PIN saved onto the stack

                ldy    #4
loop_0          jsr     get_char
                psha
                jsr     delay250ms
                dbne    y,loop_0

; turn on yellow LED to indicate 4 digit PIN has been entered
                movb    #$04,DDRK       ; set PK2 for YELLOW LED output
                movb    #$04,PTK        ; turn on YELLOW LED
                ldy     #04             ; load y with constant 4
                jsr     delayy250ms     ; execute 250ms four times
                movb    #$00,DDRK       ; reset all DDRK for all inputs only

;second set of User's PIN and store in $1502-1505
	        jsr     get_char
                staa    $1502           ; store character 1 in $1502
                jsr     delay250ms

                jsr     get_char
                staa    $1503           ; store character 2 in $1503
                jsr     delay250ms

                jsr     get_char
                staa    $1504           ; store character 3 in $1504
                jsr     delay250ms

                jsr     get_char
                staa    $1505          ; store character 4 in $1505
                jsr     delay250ms

; compare the 2nd set of PIN with the saved PIN in the stack
loop            clr     count           ; clear count1
                pula                     ; pull 4 from the stack and save it in Acc. A
                cmpa    $1505            ; compare the top of the stack with [$1505]
                bne     next1            ; if not equal, move to the next input
                inc     count           ; increment count1

next1           pula                    ; pull 3 from the stack and save it to Acc. A
                cmpa    $1504           ; compare the top of the stack with [$1504]
                bne     next2
                inc     count           ; increment count1

next2           pula                    ; pull 2 from the stack and save it to Acc. A
                cmpa    $1503           ; compare the top of the stack with [$1503]
                bne     next3
                inc     count           ; increment count1

next3           pula                    ; pull 1 from the stack and save it to Acc. A
                cmpa    $1502           ; compare the top of the stack with [$1502]
                bne     next4
                inc     count           ; increment count1

next4           ldab    count           ; load count1 to Acc. B
                cmpb    #4              ; compare count1 with 4
                beq     match
                bls     wrong
                bra     loop

; the mis-match PIN routine

wrong           movb    #$02,DDRK       ; set PK1 for RED LED output
                movb    #$02,PTK        ; turn on RED LED
                ldy     #04             ; load y with constant 4
                jsr     delayy250ms     ; execute 250ms four times
                movb    #$00,DDRK       ; reset all DDRK for all inputs only
                bra     endd

; verify the PIN

match           movb    #$01,DDRK       ; set PK0 for GREEN LED output
                movb    #$01,PTK        ; turn on GREEN LED
                ldy     #04              ; load y with constant 4
                jsr     delayy250ms     ; execute 250ms four times
                movb    #$00,DDRK       ; reset all DDRK for all inputs only
                
;***********************************************
; Siren sound
                movw       #OC5_isr,UserTimerCh5 ; initialize the interrupt vector entry
                movb       #$90,TSCR1 ; enable TCNT, fast timer flag clear
                movb       #$03,TSCR2 ; set main timer prescaler to 8
                bset       TIOS,$20 ; enable OC5
                movb       #toggle,TCTL1 ; select toggle for OC5 pin action, OM5:OL5 = 0 1
                ldd        #hi_freq ; use high frequency delay count first
                ldd        TCNT ; start the high frequency sound
                addd       delay ; "
                std        TC5 ; copy Reg D to TC register for channel 5
                bset       TIE,#$20 ; enable OC5 in Timer Interrupt Enable Register
                cli        ; "
                
                ldy        #100
                jsr        delayy10ms
                movw       #lo_freq,delay
                ldy        #100
                jsr        delayy10ms
                movw       #hi_freq,delay
                rts
                
                
OC5_isr         ldd        TC5
                addd       delay
                std        TC5
                rti
endd            swi
                end
				
;********************************************************************
;get_char subroutine for user input

;revised assembly program for the given keypad

get_char        movb       #$01,PUCR            ;pull up enable for Port A & Port K
                movb       #$F0,DDRA            ;set pins PA7~4 for outputs
scan_r0         movb       #$EF,keyboard        ;row 0 containing keys 123A
scan_k1         brclr      keyboard,$01,key1    ;is key 1 pressed?
scan_k2         brclr      keyboard,$02,key2    ;is key 2 pressed?
scan_k3         brclr      keyboard,$04,key3    ;is key 3 pressed?
scan_kA         brclr      keyboard,$08,keyA    ;is key A pressed?
                bra        scan_r1

key1            jmp        db_key1              ;debounce key 1
key2            jmp        db_key2              ;debounce key 2
key3            jmp        db_key3              ;debounce key 3
keyA            jmp        db_keyA              ;debounce key A

scan_r1         movb       #$DF,keyboard        ;row 2 containing keys 456B
scan_k4         brclr      keyboard,$01,key4    ;is key 4 pressed?
scan_k5         brclr      keyboard,$02,key5    ;is key 5 pressed?
scan_k6         brclr      keyboard,$04,key6    ;is key 6 pressed?
scan_kB         brclr      keyboard,$08,keyB    ;is key B pressed?
                bra        scan_r2

key4            jmp        db_key4              ;debounce key 4
key5            jmp        db_key5              ;debounce key 5
key6            jmp        db_key6              ;debounce key 6
keyB            jmp        db_keyB              ;debounce key B

scan_r2         movb       #$BF,keyboard        ;row 2 containing keys 789C
scan_k7         brclr      keyboard,$01,key7    ;is key 7 pressed?
scan_k8         brclr      keyboard,$02,key8    ;is key 8 pressed?
scan_k9         brclr      keyboard,$04,key9    ;is key 9 pressed?
scan_kC         brclr      keyboard,$08,keyC    ;is key C pressed?
                bra        scan_r3

key7            jmp        db_key7              ;debounce key 7
key8            jmp        db_key8              ;debounce key 8
key9            jmp        db_key9              ;debounce key 9
keyC            jmp        db_keyC              ;debounce key C

scan_r3         movb       #$7F,keyboard        ;row 0 containing keys *0#A
scan_kstar      brclr      keyboard,$01,keystar ;is key * pressed?
scan_k0         brclr      keyboard,$02,key0    ;is key 0 pressed?
scan_klb        brclr      keyboard,$04,keylb   ;is key # pressed?
scan_kD         brclr      keyboard,$08,keyD    ;is key D pressed?
                jmp        scan_r0

keystar         jmp        db_keystar           ;debounce key *
key0            jmp        db_key0              ;debounce key 0
keylb           jmp        db_keylb             ;debounce key #
keyD            jmp        db_keyD              ;debounce key D
;************************************************************************
db_key1         jsr        delay10ms            ;debounce key 1
                brclr      keyboard,$01,getc1
                jmp        scan_k2
getc1           ldaa       #$31                 ;get the ASCII code of 1 = $31
                rts

db_key2         jsr        delay10ms            ;debounce key 2
                brclr      keyboard,$02,getc2
                jmp        scan_k3
getc2           ldaa       #$32                 ;get the ASCII code of 2 = $32
                rts

db_key3         jsr        delay10ms            ;debounce key 3
                brclr      keyboard,$04,getc3
                jmp        scan_kA
getc3           ldaa       #$33                 ;get the ASCII code of 3 = $33
                rts

db_keyA         jsr        delay10ms            ;debounce key A
                brclr      keyboard,$08,getcA
                jmp        scan_r1
getcA           ldaa       #$41                 ;get the ASCII code of A = $41
                rts
;************************************************************************
db_key4         jsr        delay10ms            ;debounce key 4
                brclr      keyboard,$01,getc4
                jmp        scan_k5
getc4           ldaa       #$34                 ;get the ASCII code of 4 = $34
                rts

db_key5         jsr        delay10ms            ;debounce key 5
                brclr      keyboard,$02,getc5
                jmp        scan_k6
getc5           ldaa       #$35                 ;get the ASCII code of 5 = $35
                rts

db_key6         jsr        delay10ms            ;debounce key 6
                brclr      keyboard,$04,getc6
                jmp        scan_kB
getc6           ldaa       #$36                 ;get the ASCII code of 6 = $36
                rts

db_keyB         jsr        delay10ms            ;debounce key B
                brclr      keyboard,$08,getcB
                jmp        scan_r2
getcB           ldaa       #$42                 ;get the ASCII code of B = $42
                rts
;************************************************************************
db_key7         jsr        delay10ms            ;debounce key 7
                brclr      keyboard,$01,getc7
                jmp        scan_k8
getc7           ldaa       #$37                 ;get the ASCII code of 7 = $37
                rts

db_key8         jsr        delay10ms            ;debounce key 8
                brclr      keyboard,$02,getc8
                jmp        scan_k9
getc8           ldaa       #$38                 ;get the ASCII code of 8 = $38
                rts

db_key9         jsr        delay10ms            ;debounce key 9
                brclr      keyboard,$04,getc9
                jmp        scan_kC
getc9           ldaa       #$39                 ;get the ASCII code of 9 = $39
                rts

db_keyC         jsr        delay10ms            ;debounce key C
                brclr      keyboard,$08,getcC
                jmp        scan_r3
getcC           ldaa       #$43                 ;get the ASCII code of C = $43
                rts
;***********************************************************************
db_keystar      jsr        delay10ms            ;debounce key *
                brclr      keyboard,$01,getcstar
                jmp        scan_k0
getcstar        ldaa       #$2a                 ;get the ASCII code of * = $2a
                rts

db_key0         jsr        delay10ms            ;debounce key 0
                brclr      keyboard,$02,getc0
                jmp        scan_klb
getc0           ldaa       #$30                 ;get the ASCII code of 0 = $30
                rts

db_keylb        jsr        delay10ms            ;debounce key #
                brclr      keyboard,$04,getclb
                jmp        scan_klb
getclb          ldaa       #$23                 ;get the ASCII code of # = $23
                rts

db_keyD         jsr        delay10ms            ;debounce key D
                brclr      keyboard,$08,getcD
                jmp        scan_r0
getcD           ldaa       #$44                 ;get the ASCII code of D = $44
                rts
;************************************************************************
;the following subroutine creates a l0 ms delay

delay10ms       movb       #$90,TSCR1           ;enable TCNT and fast flags clear
                movb       #$06,TSCR2           ;configure prescale factor to 64
                movb       #$01,TIOS            ;enable OC0
                ldd        TCNT
                addd       #3750                ;start an output compare operation
                std        TC0                  ;with 10 ms time delay
                brclr      TFLG1,$01,*          ;if equal, C0F in TFLG1 is set to 1
                rts

;*********************************************************************
;the following subroutine creates a 250 ms delay
delay250ms      movb       #$90,TSCR1           ;enable TCNT and fast flags clear
                movb       #$07,TSCR2           ;configure prescale factor to 128
                movb       #$01,TIOS            ;enable OC0
                ldd        TCNT
                addd       #46875               ;start an output compare operation
                std        TC0                  ;with 250 ms time delay
                brclr      TFLG1,$01,*          ;if equal, C0F in TFLG1 is set to 1
                rts
;*********************************************************************
;the following subroutine creates a 250 ms x y time delay
delayy250ms     movb       #$90,TSCR1           ;enable TCNT and fast flags clear
                movb       #$07,TSCR2           ;configure prescale factor to 128
                movb       #$01,TIOS            ;enable OC0
                ldd        TCNT
again           addd       #46875               ;start an output compare operation
                std        TC0                  ;with 250 ms time delay
                brclr      TFLG1,$01,*          ;if equal, C0F in TFLG1 is set to 1
                ldd        TC0
                dbne       y,again
                rts
;********************************************************************* l
; The following subroutine creates a time delay that is equal to [Y] times 10 ms.
delayy10ms      pshd                ; save accumulator D onto the stack
                bset       TIOS,#$01 ; enable OC0
                ldd        TCNT
again1          addd       #30000 ; start an output-compare operation
                std        TC0
                brclr      TFLG1,#$01,*
                ldd        TC0
                dbne       y,again1
                bclr       TIOS,#$01 ; disable OC0
                puld        ; restore accumulator D
                rts