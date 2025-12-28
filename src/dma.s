	.text
	.global Timer_Handler
	.global gpio_btn_and_LED_init
	.global timer_interrupt_init
	.global read_tiva_pushbutton
	.global illuminate_RGB_LED
	.global dma_init
	.global dma
	.global dma_control

ptr_to_dma_control: .word dma_control

li .macro reg, data
    mov  reg, #(data & 0x0000FFFF)
    movt reg, #((data & 0xFFFF0000) >> 16)
    .endm

dma:
	PUSH {r4-r12,lr}

	BL gpio_btn_and_LED_init
	BL timer_interrupt_init
	BL dma_init

LOOP:
	BL read_tiva_pushbutton
	CMP r0, #1
	BNE LOOP

	POP {r4-r12,lr}  	; Restore registers from stack
	MOV pc, lr

Timer_Handler:
	PUSH {r4-r12,lr}
	MOV r0, #0x0000
	MOVT r0, #0x4003

	LDRB r1, [r0, #0x024]
	ORR r1, r1, #0x1
	STRB r1, [r0, #0x024]

	li r0, 0x400FF504
	LDR r1, [r0]
	BIC r1, r1, #(0x1 << 18)
	STR r1, [r0]

	LDR r5, ptr_to_dma_control
	ADD r5, r5, #0x120

	LDR r0, [r5, #0x008]
	ORR r0, r0, #0xF1
	STR r0, [r5, #0x008]

	li r4, 0x400FF000
	LDR r0, [r4, #0x028]
	ORR r0, r0, #(0x1 << 18)
	STR r0, [r4, #0x028]

end_interrupt:
	POP {r4-r12,lr}  	; Restore registers from stack
	BX lr
	.end
