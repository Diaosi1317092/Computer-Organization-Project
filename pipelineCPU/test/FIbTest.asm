.data
.text
main: 
	li t1,10000000
	li a1,1
	li a2,1
	li t0,2
	jal count
	li a7,34
	ecall
	li a7,5
	ecall
count:
	mv a3,a2
	add a2,a2,a1
	mv a1,a3
	addi t0,t0,1
	
	ble t0,t1,count
	
	mv a0,a2
	jr ra
	
	