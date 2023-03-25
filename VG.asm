 ;********************************************************************************************************
; VG.asm: An assembler program containing serial transmission, where an LED 
;         connected to pin 8 (PORTB0) is pulled via pressing a push button connected 
;         to pin 13 (PORTB5). At startup, the following instructions should be printed in the terminal:
;       
;         Press the button connected to pin 13 to toggle the led connected to pin 8!
;
;          With each press, a message that the push button has been pressed and the new state of the LED 
;          must be printed as below:
;           1 - The button is pressed and the LED lights up: 
;           Button is pressed!
;           Led on!
;           2 - The button is pressed again and the LED turns off:
;           Button is pressed!
;           Led off!
;           3 - The button is pressed once more and the LED lights up again:
;           Button is pressed!
;           Led on!    
;                                          
;*************************************************************************************************************


.EQU LED1 = PORTB0 ; LED ansluten till pin 8. 
.EQU BUTTON1 = PORTB5 ; Tryckknapp ansluten till pin 13.

.EQU RESET_vect        = 0x00 ; Reset-vektor, programmets startpunkt.
.EQU PCINT0_vect       = 0x06 ; Avbrottsvektor för PCI-avbrott på I/O-port B.

;********************************************************************************
; .CSEG: Programminnet - Här lagrar programkoden.
;********************************************************************************
.CSEG

;********************************************************************************
; RESET_vect: Programmets startpunkt. Programhopp sker till subrutinen main
;             för att starta programmet.
;********************************************************************************
.ORG RESET_vect
   RJMP main

;/********************************************************************************
;* PCINT0_vect: Avbrottsvektor för PCI-avbrott på I/O-port B. Vid avbrott sker
;*              programhopp till motsvarande avbrottsrutin ISR_PCINT0.
;********************************************************************************/
.ORG PCINT0_vect 
   RJMP ISR_PCINT0 ; Hoppar till motsvarande avbrottsrutin ISR_PCINT0.

;/********************************************************************************
;* ISR_PCINT0: Avbrottsrutin för PCI-avbrott på I/O-port B, som äger rum vid
;*             nedtryckning och uppsläppning av tryckknappen. Vid nedtryckning 
;*             togglas lysdioden, annars görs ingenting.
;********************************************************************************/
ISR_PCINT0:
   IN R17, PINB             ; Läser insignaler från PINB, sparar en kopia i R17.
   ANDI R17, (1 << BUTTON1) ; Multiplicerar bitvis med 0010 0000.
   BREQ ISR_PCINT0_end      ; Om kvarvarande värde är lika med 0x00 görs ingenting.x
   OUT PINB, R16            ; Annars togglas lysdioden (0000 0001 ligger kvar i R16).
ISR_PCINT0_end:
   RETI                     ; Avslutar avbrottet och återställer systemet.

;/********************************************************************************
;* setup: Initierar I/O-portar (lysdioden sätts till utport och den interna 
;*        pullup-resistorn på tryckknappens pin aktiveras) samt aktiverar 
;*        PCI-avbrott på tryckknappens pin. Denna subrutin placeras inline i
;*        i main för att effektivisera programmet (vi slipper programhopp samt
;*        återhopp).
;********************************************************************************/
setup:                    
   LDI R16, (1 << LED1)    ; Läser in värdet 0000 0001 i CPU-register R16.
   OUT DDRB, R16           ; Sätter lysdioden till utport.
   LDI R17, (1 << BUTTON1) ; Läser in värdet 0010 0000 i CPU-register R17.
   OUT PORTB, R17          ; Aktiverar den interna pullup-resistorn på tryckknappens pin.
   SEI                     ; Aktiverar avbrott globalt.
   STS PCICR, R16          ; Aktiverar PCI-avbrott på I/O-port B.
   STS PCMSK0, R17         ; Aktiverar PCI-avbrott på tryckknappens pin 13 (PORTB5).

;********************************************************************************
; main: Initierar systemet vid start. Programmet hålls sedan igång så länge
;       matningsspänning tillförs.
;********************************************************************************
main:
   RCALL setup
main_loop:
   RJMP main_loop
                      
