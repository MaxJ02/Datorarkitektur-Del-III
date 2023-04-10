 ;********************************************************************************************************
; VG.asm: An assembler program containing serial transmission, where an LED 
;         connected to pin 8 (PORTB0) is pulled via pressing a push button connected 
;         to pin 13 (PORTB5). At startup, the following instructions should be printed in the terminal:
;       
;         Press the button connected to pin 13 to toggle the led connected to pin 8!
;
;          With each press, a message that the push button has been pressed and the new state of the LED 
;          must be printed as below:
;
;           1 - The button is pressed and the LED lights up: 
;           Button is pressed!
;           Led on!
;
;           2 - The button is pressed again and the LED turns off:
;           Button is pressed!
;           Led off!
;
;           3 - The button is pressed once more and the LED lights up again:
;           Button is pressed!
;           Led on!    
;                                          
;*************************************************************************************************************

.EQU LED1    = PORTB0         ; LED connected to pin 8 
.EQU BUTTON1 = PORTB5         ; Push button connected to pin 13
.EQU TIMER0_MAX_COUNT  = 18   ; Approximately 300ms delay.
.EQU RESET_vect        = 0x00 ; Reset vector. Starting point for the program.
.EQU PCINT0_vect       = 0x06 ; Interruptvector for PCI-interrupts on I/O-port B.
.EQU TIMER0_OVF_vect   = 0X20 ; Overflow vector for timer0.

;/********************************************************************************
;* .DSEG: Data memory, stores a static variable.
;/********************************************************************************
.DSEG
.ORG SRAM_START
counter0: .byte 1

;********************************************************************************
; .CSEG: Program memory - This is where the program code is stored.
;********************************************************************************
.CSEG

;********************************************************************************
; RESET_vect: Starting point of the program. Program jump to the main subroutine
;             to start the program.
;********************************************************************************
.ORG RESET_vect
   RJMP main

;/********************************************************************************
;* PCINT0_vect: Interrupt vector for PCI interrupts on I/O port B. When an interrupt 
;*              occurs, program execution jumps to the corresponding interrupt 
;*              service routine ISR_PCINT0
;********************************************************************************/
.ORG PCINT0_vect 
   RJMP ISR_PCINT0

;/********************************************************************************
;* TIMER0_OVF_vect: Timer0 interruptvector with overflow. Jump to the subroutine
;*					ISR_TIMER0_OVF.
;/********************************************************************************
.ORG TIMER0_OVF_vect
	RJMP ISR_TIMER0_OVF

;/********************************************************************************
;* ISR_PCINT0: Interrupt service routine that is activated when an interrupt occurs
;*             on I/O port B. Debouncing for 300ms is enabled at the beginning of 
;*             the ISR to prevent bouncing contacts. Then, the LED on pin 8/PORTB0 
;*             is toggled if the button is pressed. The status of the LED and the 
;*             button press is also transmitted to the terminal via serial communication.
;/********************************************************************************
ISR_PCINT0:
ISR_PCINT0_debounce:
	LDS R24, PCICR
	ANDI R24, ~(1<<PCIE0)
	STS PCICR, R24
	LDI R24, (1<<TOIE0)
	STS TIMSK0, R24
ISR_PCINT0_led_toggle:
	IN R24, PINB
	ANDI R24, (1<<BUTTON1)
	BREQ ISR_PCINT0_end
	OUT PINB, R16
	RCALL serial_print_button_pressed
	RCALL serial_print_led_status
ISR_PCINT0_end:
	RETI

;/********************************************************************************
;* ISR_TIMER0_OVF: Interrupt routine responsible for the debounce function.
;*				   Creates a debounce of 300ms.
;/********************************************************************************
ISR_TIMER0_OVF:
	LDS R24, counter0
	INC R24
	CPI R24, TIMER0_MAX_COUNT
	BRLO ISR_TIMER0_OVF_end
timer0_off:
	LDS R25, PCICR
	ORI R25, (1<<PCIE0)
	STS PCICR, R25
	CLR R24
	STS TIMSK0, R24
ISR_TIMER0_OVF_end:
	STS counter0, R24
	RETI

;/********************************************************************************
;* serial_print_button_pressed: Outputs to the terminal via serial communication 
;*                              that the button has been pressed
;/********************************************************************************
serial_print_button_pressed:
	LDI ZL, low(2*button_is_pressed)
	LDI ZH, high(2*button_is_pressed)
	RCALL write
	RET

;/********************************************************************************
;* serial_print_led_status: Outputs the state of the LED to the terminal
;*                          via serial communication
;/********************************************************************************
serial_print_led_status:
	IN R18, PINB
	AND R18, R16
	BREQ serial_print_led_status_off
serial_print_led_status_on:
	LDI ZL, low(2*led_on)
	LDI ZH, high(2*led_on)
	RCALL write
	RET
serial_print_led_status_off:
	LDI ZL, low(2*led_off)
	LDI ZH, high(2*led_off)
	RCALL write
	RET

;/********************************************************************************
;* write: Outputs to the terminal via serial communication. Reads the content of 
;*        an array, one element at a time, using a pointer, and outputs it to the 
;*        terminal. If the character it reads is the null character (\0),
;*        the reading is terminated.
;/********************************************************************************
write:
	LPM R24, Z+
	CPI R24, 0 
	BREQ write_end
output_loop:
	LDS R20, UCSR0A
	ANDI R20, (1<<UDRE0)
	BREQ output_loop
	MOV R20, R24 
	STS UDR0, R20
	RJMP write
write_end:
	RET

;********************************************************************************
; main: Initializes the system at startup. The program then runs continuously 
;*      as long as power is supplied.
;********************************************************************************
main:
   RCALL setup
main_loop:
   RJMP main_loop

;/********************************************************************************
;* setup: Initializes I/O ports for LED on pin 8/PORTB0 as output and button on 
;*        pin 13/PORTB5 as input. Also initializes timer circuit 0 with an interrupt
;*        every 16.384 ms. Additionally, initializes serial communication with a 
;*        speed of 9600 baud. Finally, outputs a message to the terminal with instructions.
;*        0x0D is the 8-bit ASCII code for the carriage return character (\r).
;/********************************************************************************
setup:
	LDI R16, (1 << LED1)
	OUT DDRB, R16
	LDI R17, (1<<BUTTON1)
	OUT PORTB, R17
	SEI
	STS PCICR, R16
	STS PCMSK0, R17
init_serial:
	LDI R24, (1<<TXEN0)
	STS UCSR0B, R24
	LDI R24, (1<<UCSZ00) | (1<<UCSZ01)
	STS UCSR0C, R24
	LDI R24, LOW(103)
	STS UBRR0L, R24
	LDI R24, HIGH(103)
	STS UBRR0H, R24
	LDI R24, 0X0D 
	STS UDR0, R24
init_timer0:
	LDI R24, (1<<CS02) | (1<<CS00)
	OUT TCCR0B, R24
serial_prompt:
	LDI ZL, low(2*prompt)
	LDI ZH, high(2*prompt)
	RCALL write
	RET

;/********************************************************************************
;* Arrays in program memory: Strings that are output are stored with .db as bytes, 
;* with one byte per character. Data is stored as words, and if you have an odd 
;* number of bytes, you will get an error message, but it does not affect the
;* program since the remaining byte is filled with zeroes. Alternatively, you can 
;* add a zero at the end to fill out the word
;/********************************************************************************
prompt: .db "Press the button connected to pin 13 to toggle the led connected to pin 8!", '\n', '\0', 0
button_is_pressed: .db "Button is pressed!", '\n', '\0'. 
led_on: .db "Led on!", '\n', '\0', 0
led_off: .db "Led off!", '\n', '\0'
