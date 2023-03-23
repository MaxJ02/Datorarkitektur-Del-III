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
;* ISR_PCINT0: Avbrottsrutin för PCI-avbrott på I/O-port, som anropas vid
;             nedtryckning och uppsläppning av tryckknapparna. Vid nedtryckning
;             togglas Timer 1 eller timer 2. Om Timer 1 eller 2 stängs av släcks 
;             respektive lysdiod.
;********************************************************************************/
ISR_PCINT0:
   CLR R24
   STS PCICR, R24
   STS TIMSK0, R16
   ISR_PCINT_1:
   IN R24, PINB
   ANDI R24, (1 << BUTTON1)
   BREQ ISR_PCINT0_end
   CALL system_reset
ISR_PCINT0_end:
   RETI


;********************************************************************************
; main: Initierar systemet vid start. Programmet hålls sedan igång så länge
;       matningsspänning tillförs.
;********************************************************************************b
main:
   RCALL setup
main_loop:
   RJMP main_loop

