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

R_TYPE_MAP = {
    # (func3, funct7): mnemonic
    (0x0, 0x00): "add",
    (0x0, 0x20): "sub",
    (0x4, 0x00): "xor",
    (0x6, 0x00): "or",
    (0x7, 0x00): "and",
    (0x1, 0x00): "sll",
    (0x5, 0x00): "srl",
    (0x5, 0x20): "sra",
    (0x2, 0x00): "slt",
    (0x3, 0x00): "sltu",
}

I_TYPE1_MAP = {
    0x0: "addi",
    0x4: "xori",
    0x6: "ori",
    0x7: "andi",
    0x2: "slti",
    0x3: "sltiu",
}

I_TYPE2_MAP = {
    0x0: ("lb",  True),   # Load Byte (signed)
    0x1: ("lh",  True),   # Load Half (signed)
    0x2: ("lw",  True),   # Load Word
    0x4: ("lbu", False),  # Load Byte unsigned
    0x5: ("lhu", False),  # Load Half unsigned
}

S_TYPE_MAP = {
    0x0: "sb",
    0x1: "sh",
    0x2: "sw",
}

B_TYPE_MAP = {
    0x0: "beq",
    0x1: "bne",
    0x4: "blt",
    0x5: "bge",
    0x6: "bltu",
    0x7: "bgeu",
}
    
def sign_extend(value: int, bits: int) -> int:
    sign_bit = 1 << (bits - 1)
    return (value & (sign_bit - 1)) - (value & sign_bit)

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

def decode_instruction(word: int) -> str:
    inst = word
    if inst == 0x13 :
        return "nop"
    fields = decode_fields(inst)
    opc = fields['opcode']
    func3 = fields['func3']
    func7 = fields['func7']
    rd  = fields['rd']
    rs1 = fields['rs1']
    rs2 = fields['rs2']
    imm = fields['imm']
    if opc == R_TYPE:
        key = (func3, func7)
        if key in R_TYPE_MAP:
            mnem = R_TYPE_MAP[key]
            return f"{mnem} x{rd}, x{rs1}, x{rs2}"
        return f"U_R (f3=0x{func3:X},f7=0x{func7:X})"
    if opc == I_TYPE1:
        if func3 == 0x1 and func7 == 0x00:
            shamt = imm & 0x1F
            return f"slli x{rd}, x{rs1}, {shamt}"
        if func3 == 0x5 and func7 == 0x00:
            shamt = imm & 0x1F
            return f"srli x{rd}, x{rs1}, {shamt}"
        if func3 == 0x5 and func7 == 0x20:
            shamt = imm & 0x1F
            return f"srai x{rd}, x{rs1}, {shamt}"
        if func3 in I_TYPE1_MAP:
            mnem = I_TYPE1_MAP[func3]
            return f"{mnem} x{rd}, x{rs1}, {imm}"
        return f"U_I1 (f3=0x{func3:X})"
    if opc == I_TYPE2:
        if func3 in I_TYPE2_MAP:
            mnem, _signed = I_TYPE2_MAP[func3]
            return f"{mnem} x{rd}, {imm}(x{rs1})"
        return f"U_load (f3=0x{func3:X})"
    if opc == S_TYPE:
        if func3 in S_TYPE_MAP:
            mnem = S_TYPE_MAP[func3]
            return f"{mnem} x{rs2}, {imm}(x{rs1})"
        return f"U_store (f3=0x{func3:X})"
    if opc == B_TYPE:
        if func3 in B_TYPE_MAP:
            mnem = B_TYPE_MAP[func3]
            return f"{mnem} x{rs1}, x{rs2}, {imm}"
        return f"U_branch (f3=0x{func3:X})"
    if opc == J_TYPE:
        return f"jal x{rd}, {imm}"
    if opc == U_TYPE1:
        return f"lui   x{rd}, {imm}"
    if opc == U_TYPE2:
        return f"auipc x{rd}, {imm}"
    if opc == I_TYPE3 and func3 == 0x0:
        return f"jalr x{rd}, {imm}(x{rs1})"
    if opc == I_TYPE4:
        return "ecall"
    return f"U 0x{inst:08X}"

if __name__ == '__main__':
    