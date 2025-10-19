.data
	a:.word
	
.text
main:	
	li a7,5
	ecall
	andi a0,a0,7
	beq a0,x0,case0
	addi a0,a0,-1
	beq a0,x0,case1
	addi a0,a0,-1
	beq a0,x0,case2
	addi a0,a0,-1
	beq a0,x0,case3
	addi a0,a0,-1
	beq a0,x0,case4
	addi a0,a0,-1
	beq a0,x0,case5
	addi a0,a0,-1
	beq a0,x0,case6
	addi a0,a0,-1
	beq a0,x0,case7

output2:
	li a7,35
	ecall
	jr ra
output10:
	li a7,1
	ecall
	jr ra
output16:
	li a7,34
	ecall
	jr ra
inputlb:
	li a7,5
	ecall
	jr ra
inputlbu:
	li a7,5
	ecall
	andi a0,a0,255
	jr ra

case0: 
	jal inputlb
	jal output2
	jal inputlb
	jal output2
	j main
case1: 
	jal inputlb
	jal output16
	sw a0,0(t0)
	j main
case2: 
	jal inputlbu
	jal output16
	sw a0,4(t0)
	j main
case3: 
	lw t1,0(t0)
	lw t2,4(t0)
	beq t1,t2,label3_1
	addi a0,zero,0
	beq zero,zero,label3_2
	label3_1:addi a0,zero,255
	label3_2:
	jal output2
	j main
case4: 
	lw t1,0(t0)
	lw t2,4(t0)
	blt t1,t2,label4_1
	addi a0,zero,0
	beq zero,zero,label4_2
	label4_1:addi a0,zero,255
	label4_2:
	jal output2
	j main
case5: 
	lw t1,0(t0)
	lw t2,4(t0)
	bltu t1,t2,label5_1
	addi a0,zero,0
	beq zero,zero,label5_2
	label5_1:addi a0,zero,255
	label5_2:
	jal output2
	j main
case6: 
	lw t1,0(t0)
	lw t2,4(t0)
	slt a0,t1,t2
	jal output2
	j main
case7: 
	lw t1,0(t0)
	lw t2,4(t0)
	sltu a0,t1,t2
	jal output2
	j main
	
