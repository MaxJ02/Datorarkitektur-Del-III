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
