	.data

	.global dma_control
	.global dma
dma_control:
	.align 1024
	.space 1024

LED_DATA:
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F

	.text
li .macro reg, data
    mov  reg, #(data & 0x0000FFFF)
    movt reg, #((data & 0xFFFF0000) >> 16)
    .endm

	.global gpio_btn_and_LED_init
	.global timer_interrupt_init
	.global read_tiva_pushbutton
	.global illuminate_RGB_LED
	.global dma_init

ptr_to_dma_control:		.word dma_control
ptr_to_led_data:		.word LED_DATA
dma_init:
	PUSH {r4-r12,lr}

	MOV r4, #0xE000
	MOVT r4, #0x400F

	LDR r0, [r4, #0x60C] ; RAGCDMA
	ORR r0, r0, #1
	STR r0, [r4, #0x60C]

	li r4, 0x400FF000

	LDR r0, [r4, #0x004]
	ORR r0, r0, #1
	STR r0, [r4, #0x004]

	LDR r5, ptr_to_dma_control ;R5 is DMA CTRL
	STR r5, [r4, #0x008]
	ADD r5, r5, #0x120

	LDR r6, ptr_to_led_data
	ADD r6, r6, #15
	STR r6, [r5, #0x000]

	li r0, 0x400053FC
	STR r0, [r5, #0x004]

	LDR r0, [r4, #0x024]
	BIC r0, r0, #(0x1 << 18)
	STR r0, [r4, #0x024]

	li r0, 0xC00000F1
	STR r0, [r5, #0x008]

	LDR r0, [r4, #0x028]
	ORR r0, r0, #(0x1 << 18)
	STR r0, [r4, #0x028]

	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr


gpio_btn_and_LED_init:
	;---------------------------------------------------------------------------
	; Initializes the four push buttons on the Alice EduBase board, the four
	; LEDs on the AliceEduBase board, the momentary push button on the Tiva board (SW1)
	; , and the RGB LED on the Tiva board.
	;___________________________________________________________________________
	PUSH {r4-r12,lr}	; Spill registers to stack


	;---------------------------------------------------------------------------
	;PORT B IS THE ALICE EDUBASE BOARD LEDS!!!
	;PORT D IS THE ALICE EDUBASE BOARD BUTTONS!!!
	;PORT F IS THE TIVA BOARD BUTTONS AND RGB LEDS!!!
	;___________________________________________________________________________



	;-------------------------------------------------
	;PORT B IS THE ALICE EDUBASE BOARD LEDS!!!
	;_________________________________________________
	;-----------------------------
	;ENABLE THE CLOCK IN PORT B
	;_____________________________
	MOV r5, #0xE000
    MOVT r5, #0x400F
	;Enable the clock for port B
	LDRB r6, [r5, #0x608]
	ORR r6, #2
	STRB r6, [r5, #0x608]

	;-----------------------------
	;ENABLE THE PINS FOR IO IN PORT B
	;_____________________________
	MOV r5, #0x5000
	MOVT r5, #0x4000
	;Enabling the pins
	LDRB r6, [r5, #0x400]
	ORR r6, #0xF ; we set bits 0, 1, 2, and 3 to 1 so that we set the LED pins for output
	STRB r6, [r5, #0x400]

	;-----------------------------------------------
	;SETTING THE PINS FOR IO IN PORT B TO BE DIGITAL
	;_______________________________________________
	;r5 ALREADY has Port B's address in it!!!
	LDRB r6, [r5, #0x51C]
	ORR r6, #0xF ;Setting all the bits to be 1 so they can be in digital mode
	STRB r6, [r5, #0x51C]


	;-------------------------------------------------
	;PORT D IS THE ALICE EDUBASE BOARD BUTTONS!!!
	;_________________________________________________
	;-----------------------------
	;ENABLE THE CLOCK IN PORT D
	;_____________________________
	MOV r5, #0xE000
    MOVT r5, #0x400F
	;Enable the clock for port D
	LDRB r6, [r5, #0x608]
	ORR r6, #8
	STRB r6, [r5, #0x608]

	;-----------------------------
	;ENABLE THE PINS FOR IO IN PORT D
	;_____________________________
	MOV r5, #0x7000
	MOVT r5, #0x4000
	;Enabling the pins
	LDRB r6, [r5, #0x400]
	BIC r6, #0xF ; we set bits 0, 1, 2, and 3 to 0 so that we set the button pins for input
	STRB r6, [r5, #0x400]

	;-----------------------------------------------
	;SETTING THE PINS FOR IO IN PORT D TO BE DIGITAL
	;_______________________________________________
	;r5 ALREADY has Port D's address in it!!!
	LDRB r6, [r5, #0x51C]
	ORR r6, #0xF ;Setting all the bits to be 1 so they can be in digital mode
	STRB r6, [r5, #0x51C]


	;-------------------------------------------------
	;PORT F IS THE TIVA BOARD BUTTONS AND RGB LEDS!!!
	;_________________________________________________
	BL tiva_init

	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr

tiva_init:
	;-----------------------------------------------
	;HELPER FUNCTION FOR gpio_btn_and_LED_init
	;_______________________________________________

	PUSH {r4-r12,lr}	; Spill registers to stack

	;-----------------------------
	;ENABLE THE CLOCK IN PORT F
	;_____________________________
	MOV r5, #0xE000
    MOVT r5, #0x400F
	;Enable the clock for port F
	LDRB r6, [r5, #0x608]
	ORR r6, #32
	STRB r6, [r5, #0x608]



	;-----------------------------
	;ENABLE THE PINS FOR IO IN PORT F
	;_____________________________
	MOV r5, #0x5000
	MOVT r5, #0x4002
	;Enabling the pins
	LDRB r6, [r5, #0x400]
	ORR r6, #14	;we set bits 1, 2, and 3 to 1 so that we set the rgb pins for output
	BIC r6, #0x10 ;we bitclear the 4th bit(starting from 0) so that it is 0 for input
	STRB r6, [r5, #0x400]

	;-----------------------------------------------
	;SETTING THE PINS FOR IO IN PORT F TO BE DIGITAL
	;_______________________________________________
	;r5 ALREADY has Port F's address in it!!!
	LDRB r6, [r5, #0x51C]
	ORR r6, #30 ;Setting all the bits to be 1 so they can be in digital mode
	STRB r6, [r5, #0x51C]

	; Enabling the Pull Up Resistor for the button.
	LDRB r6, [r5, #0x510]
	ORR r6, r6, #0x10
	STRB r6, [r5, #0x510]

	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr


timer_interrupt_init:
	PUSH {r4-r12, lr}
	MOV r0, #0xE000
	MOVT r0, #0x400F

	LDRB r1, [r0, #0x604]
	ORR r1, r1, #0x3
	STRB r1, [r0, #0x604]

	MOV r0, #0x0000
	MOVT r0, #0x4003

	LDRB r1, [r0, #0x00C]
	BIC r1, r1, #0x1
	STRB r1, [r0, #0x00C]

	LDRH r1, [r0, #0x000]
	MOV r5, #0x111
	BIC r1, r1, r5
	STRH r1, [r0, #0x000]

	LDRB r1, [r0, #0x004]
	ORR r1, r1, #0x2
	STRB r1, [r0, #0x004]

	LDRB r1, [r0, #0x004]
	ORR r1, r1, #0x2
	STRB r1, [r0, #0x004]

	MOV r1, #0x2400
	MOVT r1, #0x00F4
	STR r1, [r0, #0x028]

	LDRB r1, [r0, #0x018]
	ORR r1, r1, #0x1
	STRB r1, [r0, #0x018]

	MOV r0, #0xE000
	MOVT r0, #0xE000

	LDR r1, [r0, #0x100]
	MOV r2, #0x0000
	MOVT r2, #0x0008
	ORR r1, r1, r2
	STR r1, [r0, #0x100]

	MOV r0, #0x0000
	MOVT r0, #0x4003

	LDRB r1, [r0, #0x00C]
	ORR r1, r1, #0x1
	STRB r1, [r0, #0x00C]

	POP {r4-r12, lr}
	MOV pc, lr

read_tiva_pushbutton:
	;---------------------------------------------------------------------------
	;Reads from the momentary push button (SW1) on the Tiva board, and
	;returns a one (1) in r0 if the button is currently being pressed
	;, and a zero (0) if it is not.
	;___________________________________________________________________________

	PUSH {r4-r12,lr}	; Spill registers to stack

	;Port F's address
	MOV r5, #0x5000
	MOVT r5, #0x4002


	;READ from data register to see when button is pushed
	LDRB r6, [r5, #0x3FC]
	AND r6, r6, #0x10
	EOR r0, r6, #0x10 ; When this bit is 0, the button is being pressed
	CMP r0, #0x10
	BEQ set_to_one

set_to_zero:
	MOV r0, #0
	B end_of_tiva

set_to_one:
	MOV r0, #1
						;when this bit is 1, the button is not being pressed
end_of_tiva:			;we will return a 1 into r0 if the button is being pressed
						;and we will return a 0 into r0 if the button is not being pressed
	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr


illuminate_RGB_LED:
	;---------------------------------------------------------------------------
	;Illuminates the RBG LED on the TIVA board. The color to be displayed is
	;passed into the routine in r0 as such:
	;	0 -> OFF
	;	1 -> Red
	;	2 -> Green
	;	3 -> Blue
	;	4 -> Purple
	;	5 -> Yellow
	;	6 -> White
	; Port F, Pin 1 - Red, Pin 2 - Blue, Pin 3 - Green
	; Port F address: 0x40025000
	;___________________________________________________________________________

	PUSH {r4-r12,lr}	; Spill registers to stack

	;r10 is where we will put the color choice
	MOV r10, #0

	;OFF
	CMP r0, #0
	BEQ TURN_ON_LIGHTS

	;RED
	CMP r0, #1
	BEQ SET_RED

	;GREEN
	CMP r0, #2
	BEQ SET_GREEN

	;BLUE
	CMP r0, #3
	BEQ SET_BLUE

	;PURPLE
	CMP r0, #4
	BEQ SET_PURPLE

	;YELLOW
	CMP r0, #5
	BEQ SET_YELLOW

	;WHITE
	CMP r0, #6
	BEQ SET_WHITE

	;IF NO COLOR IS CHOSEN,
	;WE WILL DEFAULT TO WHITE
	B SET_WHITE

SET_RED:
	;Turning on RED pin to make RED
	MOV r10, #0x2
	B TURN_ON_LIGHTS

SET_GREEN:
	;Turning on GREEN pin to make GREEN
	MOV r10, #0x8
	B TURN_ON_LIGHTS

SET_BLUE:
	;Turning on BLUE pin to make BLUE
	MOV r10, #0x4
	B TURN_ON_LIGHTS

SET_PURPLE:
	;Turning on RED and BLUE pin to make PURPLE
	MOV r10, #0x6
	B TURN_ON_LIGHTS

SET_YELLOW:
	;Turning on RED and GREEN pin to make YELLOW
	MOV r10, #0xA
	B TURN_ON_LIGHTS

SET_WHITE:
	;Turning on RED and GREEN and BLUE pin to make WHITE
	MOV r10, #0xE
	B TURN_ON_LIGHTS



TURN_ON_LIGHTS:
	;Port F's address
	MOV r5, #0x5000
	MOVT r5, #0x4002

    LDRB r6, [r5, #0x3FC]
	BIC r6, #0xE ;I BIT CLEAR HERE IN CASE A BIT THAT NEEDS
				;TO BE 0 HAS BEEN PREVIOUSLY SET TO 1

	ORR r6, r6, r10 ; SETTING THE PINS FOR GPIO DATA REGISTER USE
	STRB r6, [r5, #0x3FC]

	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr

	.end
