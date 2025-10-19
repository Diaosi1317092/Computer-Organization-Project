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
calc_pal:
	li a2, 0 
    	li a3, 0        
	
	reverse_loop:
	li a4, 1              
    	sll a4, a4, a3  
    	and a5, a1, a4 
    	beq a5, zero, skip_set   
    	li a6, 1                 
    	li a7, 7                 
    	sub a7, a7, a3
    	sll a6, a6, a7
    	or a2, a2, a6

	skip_set:
    	addi a3, a3, 1           # i++
    	li t0, 8
    	blt a3, t0, reverse_loop 
	jr ra

input_float:
    # 1. ???????
    li a7, 5          # ecall: read_int
    ecall             # a0 = ??????8¦Ë

    # 2. ??????????12-bit????: high 8 bits in a0, low 4 bits = 0
    slli a0, a0, 4    # a0 = encoded_12bit (in low 12 bits)

    # 3. ???????¦Ë S (bit 11)
    mv t3, a0
    srli t3, t3, 11   # t3 = sign bit (0 positive, 1 negative)
    andi t3, t3, 0x1

    # 4. ???????? E_raw (bits 10..8)
    srli t1, a0, 8    # t1 = a0 >> 8
    andi t1, t1, 0x7  # t1 = E_raw (0..7)

    # 5. ???¦Â?? M (bits 7..4)????????????1??? 1.M in fixed-point (5-bit integer)
    srli t2, a0, 4    # t2 = a0 >> 4
    andi t2, t2, 0xF  # t2 = M_raw (4 bits)
    ori t2, t2, 0x10  # t2 = 1.M => (1<<4) | M_raw

    # 6. ?????? E_raw ??????¦Ë: magnitude = (1.M) << E_raw
    sll t2, t2, t1   # t2 = magnitude

    # 7. ???????¦Ë??? (t3==1), ?????????????
    beq t3, zero, store_result
    neg t2, t2       # t2 = -magnitude

store_result:
    mv a0, t2        # a0 = ???????????
    ret
    
calc_int:
    # 1. ??????
    mv   t0, a0          # t0 = value
    li a7,35
    ecall
    bltz t0, make_pos
    j    abs_ready
make_pos:
    neg  t0, t0          # t0 = -t0
abs_ready:
    # 2. ?????????: ????§³??????4¦Ë?????????? = t0 >> 4
    srai t1, t0, 7       # ?????????t1 = integer part (abs)

	bltz a0, make_pos2
    j    abs_ready2
make_pos2:
    neg  t1, t1          # t0 = -t0
abs_ready2:

    mv   a0, t1
    li   a7, 1           # ecall: print_int
    ecall

    ret

case0: 
	jal inputlbu
	addi a1,a0,0         
    	jal calc_pal
	addi a0,a2,0
	
	jal output2
	j main
case1: 
	jal inputlbu
	addi a1,a0,0         
    	jal calc_pal
    	xor a0,a1,a2
    	seqz a0,a0
	jal output2
	j main
case2: 
	jal input_float
	la t1, a
    	sw a0, 0(t1)
    	jal calc_int
	jal input_float
	la t1, a
    	sw a0, 4(t1)
    	jal calc_int
	j main
case3: 
	la t0,a
	lw t1,0(t0)
	lw t2,4(t0)
	add a0,t1,t2
	jal calc_int
	j main
case4:
 	jal inputlbu
 	li s2,0
 case4_calculate:
 	slli a0,a0,4
 	mv t1,a0
 	li t2,152
 	li a1,0x0080

 	mv t3,t1
 	add t0, zero, zero   # t0: loop cnt
 	li s1,4  #s1: loop times
 loopb:
 # t1: dividend,   t2: divisor,    t3: remainder,   
 # a1: 0x0080,  s1: 4
 	xor t3, t3, t2 
 	and s0, t3, a1 # get the highest bit of remainder to check if rem<0
 	beq s0, zero, SdrUq # if  rem>=0, shift Divright
 	xor t3, t3, t2 # if rem<0, rem=rem+div
 SdrUq:
 	srli t2, t2, 1
 	srli a1,a1,1
 loope:
 	addi t0, t0, 1
 	bne t0, s1, loopb 

 	add a0,a0,t3
 	beq s2,x0,exit_4
 	jr ra
 exit_4:
 	jal output2
 	j main

case5: 
	jal inputlbu
 	addi sp,sp,-8
 	sw a0,0(sp)
 	sw ra,4(sp)
 	srli a0,a0,4
 	li s2,1
 	jal case4_calculate
 	lw ra,4(sp)
 	lw a1,0(sp)
 	addi sp,sp,4
 	sub s0,a1,a0
 	seqz a0,s0
 	jal output2
 	j main 
case6: 
	lui a0,0x12345
	jal output16
	j main
case7: 
	li a7, 5
	 ecall #get n, and set in register a0
	 jal fact #call the fact function
	 li a7, 1
	 ecall
	 j main
 fact:
 	addi sp, sp,-8 #adjust stack for 2 items
 	sw ra, 4(sp) #save the return address
 	sw a0, 0(sp) #save the argument n
 	slti t0, a0, 1  #test for n<1
 	beq t0, zero, L1 #if n>=1,go to L1
 	addi a0, zero, 1 #else return 1
 	addi a1,zero,0
 	addi sp, sp, 8 #pop 2 items off stack
 	jr ra #return to caller
 	L1:  
 	
 	addi a0, a0, -1 #n>=1; argument gets(n-1)
 	jal fact              #call fact with(n-1)
 	addi t0, a0, 0 #
 	addi t1, a1, 0 #
 	
 	lw a0, 0(sp) #return from jal: restore argument
 	lw ra, 4(sp) #restore the return address
 	addi sp, sp, 8 #adjust stack pointer to pop 2 items
 	add a0,t0,t1
 	add a1,t0,zero
 	jr ra #return to the caller
