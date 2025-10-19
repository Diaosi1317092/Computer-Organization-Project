import os
import re
import random
from typing import List
from typing import Tuple
from typing import Dict
from typing import Any
from collections import defaultdict, Counter

R_TYPE   = 0b0110011
I_TYPE1  = 0b0010011  # addi
I_TYPE2  = 0b0000011  # lw
I_TYPE3  = 0b1100111  # jalr
I_TYPE4  = 0b1110011  # ecall
S_TYPE   = 0b0100011
B_TYPE   = 0b1100011
U_TYPE1  = 0b0110111  # lui
U_TYPE2  = 0b0010111  # auipc
J_TYPE   = 0b1101111  # jal

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def sign_extend(value: int, bits: int) -> int:
    sign_bit = 1 << (bits - 1)
    return (value & (sign_bit - 1)) - (value & sign_bit)

def to_signed32(x):
    return x if x < 0x80000000 else x - 0x100000000

def decode_fields(inst: int) -> dict:
    opcode = inst & 0x7F
    rd     = (inst >> 7) & 0x1F
    func3  = (inst >> 12) & 0x7
    rs1    = (inst >> 15) & 0x1F
    rs2    = (inst >> 20) & 0x1F
    func7  = (inst >> 25) & 0x7F

    # Default imm = 0
    imm = 0

    if opcode in (I_TYPE1, I_TYPE2, I_TYPE3, I_TYPE4):
        # I Type inst[31:20]
        imm_12 = (inst >> 20) & 0xFFF
        imm    = sign_extend(imm_12, 12)

    elif opcode == S_TYPE:
        # S Type inst[31:25] | inst[11:7]
        imm_11_5 = (inst >> 25) & 0x7F
        imm_4_0  = (inst >> 7)  & 0x1F
        imm_12   = (imm_11_5 << 5) | imm_4_0
        imm      = sign_extend(imm_12, 12)

    elif opcode == B_TYPE:
        # B Type inst[31],inst[7],inst[30:25],inst[11:8],0
        b11   = (inst >> 31) & 0x1
        b1    = (inst >> 7)  & 0x1
        b10_5 = (inst >> 25) & 0x3F
        b4_1  = (inst >> 8)  & 0xF
        imm_13 = (b11 << 12) | (b1 << 11) | (b10_5 << 5) | (b4_1 << 1)
        imm    = sign_extend(imm_13, 13)

    elif opcode == J_TYPE:
        # J Type inst[31],inst[19:12],inst[20],inst[30:21],0
        j20   = (inst >> 31) & 0x1
        j10_1 = (inst >> 21) & 0x3FF
        j11   = (inst >> 20) & 0x1
        j19_12= (inst >> 12) & 0xFF
        imm_21 = (j20 << 20) | (j19_12 << 12) | (j11 << 11) | (j10_1 << 1)
        imm     = sign_extend(imm_21, 21)

    elif opcode in (U_TYPE1, U_TYPE2):
        # U Type inst[31:12] << 12
        imm_31_12 = (inst >> 12) & 0xFFFFF
        imm        = imm_31_12 << 12

    # R Type imm=0

    return {
        'opcode': opcode,
        'func3':  func3,
        'func7':  func7,
        'rd':     rd,
        'rs1':    rs1,
        'rs2':    rs2,
        'imm':    imm
    }

def alu_execute(
    read_data1: int,
    read_data2: int,
    imm32: int,
    alu_src: int,
    alu_op: int,
    funct3: int,
    funct7: int,
    is_lui: bool,
    is_auipc: bool,
    pc: int
) -> Tuple[int, bool]:

    MASK32 = 0xFFFFFFFF

    operand2 = (imm32 & MASK32) if alu_src else (read_data2 & MASK32)
    shamt    = operand2 & 0x1F

    def to_signed(x):
        return x if x < 0x80000000 else x - 0x100000000

    rd1_s = to_signed(read_data1 & MASK32)
    op2_s = to_signed(operand2)

    zero = False
    if   alu_op == 0:
        # Load/Store: ADD
        alu_result = (read_data1 + operand2) & MASK32

    elif alu_op == 1:
        diff = (read_data1 - operand2) & MASK32
        alu_result = diff
        if   funct3 == 0 and diff == 0:
            zero = True   # BEQ
        elif funct3 == 1 and diff != 0:
            zero = True   # BNE
        elif funct3 == 4 and rd1_s <  op2_s:
            zero = True   # BLT (signed)
        elif funct3 == 5 and rd1_s >= op2_s:
            zero = True   # BGE (signed)
        elif funct3 == 6 and (read_data1 & MASK32) < (operand2 & MASK32):
            zero = True   # BLTU (unsigned)
        elif funct3 == 7 and (read_data1 & MASK32) >= (operand2 & MASK32):
            zero = True   # BGEU (unsigned)

    elif alu_op == 2:
        # R-type
        if   funct3 == 0:
            # ADD / SUB
            if (funct7 >> 5) & 1:
                alu_result = (read_data1 - operand2) & MASK32
            else:
                alu_result = (read_data1 + operand2) & MASK32

        elif funct3 == 4:
            alu_result = (read_data1 ^ operand2) & MASK32
        elif funct3 == 6:
            alu_result = (read_data1 | operand2) & MASK32
        elif funct3 == 7:
            alu_result = (read_data1 & operand2) & MASK32
        elif funct3 == 1:
            alu_result = ((read_data1 & MASK32) << shamt) & MASK32
        elif funct3 == 5:
            if (funct7 >> 5) & 1:
                alu_result = (rd1_s >> shamt) & MASK32
            else:
                alu_result = ((read_data1 & MASK32) >> shamt) & MASK32
        elif funct3 == 2:
            alu_result = (1 if rd1_s <  op2_s else 0) & MASK32
        elif funct3 == 3:
            alu_result = (1 if (read_data1 & MASK32) < (operand2 & MASK32) else 0) & MASK32
        else:
            alu_result = 0

    elif alu_op == 3:
        # I-type & U-type
        if is_lui:
            alu_result = operand2 & MASK32
        elif is_auipc:
            alu_result = (pc + (operand2 & MASK32)) & MASK32
        else:
            if   funct3 == 0:
                # ADDI
                alu_result = (read_data1 + operand2) & MASK32
            elif funct3 == 4:
                # XORI
                alu_result = (read_data1 ^ operand2) & MASK32
            elif funct3 == 6:
                # ORI
                alu_result = (read_data1 | operand2) & MASK32
            elif funct3 == 7:
                # ANDI
                alu_result = (read_data1 & operand2) & MASK32
            elif funct3 == 1:
                # SLLI
                alu_result = ((read_data1 & MASK32) << shamt) & MASK32
            elif funct3 == 5:
                # SRLI / SRAI
                if (funct7 >> 5) & 1:
                    alu_result = (rd1_s >> shamt) & MASK32
                else:
                    alu_result = ((read_data1 & MASK32) >> shamt) & MASK32
            elif funct3 == 2:
                alu_result = (1 if rd1_s <  op2_s else 0) & MASK32
            elif funct3 == 3:
                alu_result = (1 if (read_data1 & MASK32) < (operand2 & MASK32) else 0) & MASK32
            else:
                alu_result = 0
    else:
        alu_result = 0

    return alu_result, zero

def get_control_signals(inst: int,
                        reg_a7: int,
                        done_input: bool) -> Dict[str, Any]:
    opcode = inst & 0x7F

    signals = {
        'branch'    : False,
        'alu_op'    : 0,     # 2'b11
        'alu_src'   : 0,
        'mem_read'  : False,
        'mem_write' : False,
        'mem_to_reg': False,
        'reg_write' : False,
        'is_jal'    : False,
        'is_jalr'   : False,
        'is_lui'    : False,
        'is_auipc'  : False,
        'is_ecall'  : False,
        'en_pc'     : True,
        'en_input'  : False,
        'en_output' : False
    }

    if opcode == R_TYPE:
        signals.update({
            'alu_op'   : 2,   # 2'b10
            'alu_src'  : 0,
            'reg_write': True
        })

    elif opcode == I_TYPE1:
        signals.update({
            'alu_op'   : 3,   # 2'b11
            'alu_src'  : 1,
            'reg_write': True
        })

    elif opcode == I_TYPE2:  # lw
        signals.update({
            'alu_op'    : 0,  # 2'b00
            'alu_src'   : 1,
            'mem_read'  : True,
            'mem_to_reg': True,
            'reg_write' : True
        })

    elif opcode == I_TYPE3:  # jalr
        signals.update({
            'alu_op'   : 3,
            'alu_src'  : 1,
            'reg_write': True,
            'is_jalr'  : True
        })

    elif opcode == I_TYPE4:  # ecall
        signals['is_ecall'] = True
        if reg_a7 in (1, 34, 35):
            signals['en_output'] = True
        elif reg_a7 == 5:
            signals['reg_write'] = True
            signals['en_input']  = True
            signals['en_pc']     = done_input

    elif opcode == S_TYPE:  # sw
        signals.update({
            'alu_op'   : 0,
            'alu_src'  : 1,
            'mem_write': True
        })

    elif opcode == B_TYPE:  # beq/bne/...
        signals.update({
            'alu_op' : 1,  # 2'b01
            'branch' : True
        })

    elif opcode == U_TYPE1:  # lui
        signals.update({
            'alu_op'   : 3,
            'alu_src'  : 1,
            'reg_write': True,
            'is_lui'   : True
        })

    elif opcode == U_TYPE2:  # auipc
        signals.update({
            'alu_op'   : 3,
            'alu_src'  : 1,
            'reg_write': True,
            'is_auipc' : True
        })

    elif opcode == J_TYPE:  # jal
        signals.update({
            'alu_op'   : 3,  # don't care
            'alu_src'  : 1,  # don't care
            'reg_write': True,
            'is_jal'   : True
        })

    else:
        # default: en_pc = 0
        signals['en_pc'] = False

    return signals

def memory_store(addr: int, funct3: int, value: int, memory: bytearray) -> None:
    b0 = (value >>   0) & 0xFF
    b1 = (value >>   8) & 0xFF
    b2 = (value >>  16) & 0xFF
    b3 = (value >>  24) & 0xFF

    if funct3 == 0b010:  # SW
        memory[addr  ] = b0
        memory[addr+1] = b1
        memory[addr+2] = b2
        memory[addr+3] = b3

    elif funct3 == 0b001:  # SH
        memory[addr  ] = b0
        memory[addr+1] = b1

    elif funct3 == 0b000:  # SB
        memory[addr] = b0

    else:
        pass

def memory_load(addr: int, funct3: int, memory: bytearray) -> int:
    # Helper: 8/16-bit sign‐extension
    def sign8(x: int) -> int:
        return x - 0x100 if x & 0x80 else x
    def sign16(x: int) -> int:
        return x - 0x10000 if x & 0x8000 else x

    if funct3 == 0:        # LB
        byte = memory[addr]
        return sign8(byte) & 0xFFFFFFFF

    elif funct3 == 1:      # LH
        # align half‐word
        base = addr & ~0x1
        lo = memory[base]
        hi = memory[base+1]
        half = lo | (hi << 8)
        return sign16(half) & 0xFFFFFFFF

    elif funct3 == 2:      # LW
        # align word
        base = addr & ~0x3
        b0 = memory[base]
        b1 = memory[base+1]
        b2 = memory[base+2]
        b3 = memory[base+3]
        word = b0 | (b1<<8) | (b2<<16) | (b3<<24)
        return word  # already 32-bit

    elif funct3 == 4:      # LBU
        return memory[addr] & 0xFF

    elif funct3 == 5:      # LHU
        base = addr & ~0x1
        lo = memory[base]
        hi = memory[base+1]
        half = lo | (hi << 8)
        return half & 0xFFFF

    else:
        return 0

def handle_ecall(regs: List[int],
                 signals: Dict[str, Any],
                 pc: int = 0x00003000) -> bool:
    a0 = regs[10]
    a7 = regs[17]

    if signals['en_output']:
        if a7 == 34:
            print(f"0x{a0:08X}")
        elif a7 == 35:
            print(f"0b{a0:032b}")
        else:
            print(to_signed32(a0))
        return True

    if signals['en_input']:
        rand_val = random.randint(0, 255)
        print(f"ECALL input at PC=0x{pc:08X}, assigned random {rand_val}")
        regs[10] = rand_val
        return True

    # if signals['en_input']:
    #     try:
    #         print(f"PC = 0x{pc:08X}")
    #         line = input()
    #         val = int(line, 0)
    #     except (EOFError, ValueError):
    #         val = 0
    #     regs[10] = val
    #     return True

    return True

def load_instructions(
    filename: str = "inst.txt",
    start_addr: int = 0x00003000
) -> Dict[int, int]:
    INST_PATH = os.path.join(BASE_DIR, filename)

    instr_mem: Dict[int, int] = {}
    pc = start_addr

    HEX8_RE = re.compile(r'^[0-9a-f]{8}$')

    with open(INST_PATH, 'r', encoding='utf-8') as f:
        for lineno, line in enumerate(f, start=1):
            s = line.strip()
            if not s or s.startswith('#'):
                continue
            if not HEX8_RE.fullmatch(s):
                raise ValueError(
                    f"Error in {filename} on line {lineno}: "
                    f"expected 8 lowercase hex digits, got '{s}'"
                )
            instr = int(s, 16)
            instr_mem[pc] = instr
            pc += 4

    return instr_mem

if __name__ == '__main__':
    T = int(input())
    pc: int = 0x00003000
    cycle: int = 0
    regs: List[int] = [0] * 32
    regs[2] = 0x00002FFC  # stack pointer
    regs[3] = 0x00001800  # global pointer
    instr_mem = load_instructions()
    memory = bytearray(1024 * 1024)
    done_input = False
    next_counts: Dict[int, Counter[int]] = defaultdict(Counter)
    default_target: Dict[int, int] = {}
    
    for pc_addr in instr_mem:
        next_counts[pc_addr] 

    for i in range(T):
        inst = instr_mem.get(pc)
        if inst is None:
            break

        fields  = decode_fields(inst)
        reg_a7  = regs[17]
        signals = get_control_signals(inst, reg_a7, done_input)
        
        if signals['is_ecall'] and not done_input:
            done_input = handle_ecall(regs, signals, pc)

        alu_res, zero = alu_execute(
            regs[fields['rs1']],
            regs[fields['rs2']],
            fields['imm'],
            signals['alu_src'],
            signals['alu_op'],
            fields['func3'],
            fields['func7'],
            signals['is_lui'],
            signals['is_auipc'],
            pc
        )

        if signals['mem_read']:
            mem_data = memory_load(addr=alu_res, funct3=fields['func3'], memory=memory)
        if signals['mem_write']:
            memory_store(addr=alu_res, funct3=fields['func3'], value=regs[fields['rs2']], memory=memory)

        if signals['reg_write'] and fields['rd'] != 0:
            if signals['is_jal'] or signals['is_jalr']:
                write_val = pc + 4
            elif signals['mem_to_reg']:
                write_val = mem_data
            else:
                write_val = alu_res
            regs[fields['rd']] = write_val

        if signals['is_jal']:
            next_pc = pc + fields['imm']
        elif signals['is_jalr']:
            next_pc = (regs[fields['rs1']] + fields['imm']) & ~1
        elif signals['branch'] and zero:
            next_pc = pc + fields['imm']
        else:
            next_pc = pc + 4
                
        if fields['opcode'] == B_TYPE:
            next_counts[pc][next_pc] += 1
        
        if signals['en_pc']:
            pc = next_pc
            done_input = False
        cycle += 1

    for pc_addr, counter in next_counts.items():
        if counter:
            tgt, _ = counter.most_common(1)[0]
        else:
            tgt = pc_addr + 4
        default_target[pc_addr] = tgt
    
    LOG_PATH = os.path.join(BASE_DIR, "log.coe")
    
    with open(LOG_PATH, "w", encoding="utf-8") as fout:
        fout.write("memory_initialization_radix = 16;\n")
        fout.write("memory_initialization_vector =\n")
        for pc_addr in sorted(default_target):
            tgt = default_target[pc_addr]
            fout.write(f"{tgt:08x}\n") # Only NEXT_PC