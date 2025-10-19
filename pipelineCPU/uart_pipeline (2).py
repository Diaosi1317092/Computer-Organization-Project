import serial, struct, threading, time
import tkinter as tk
from tkinter import ttk
from collections import deque

PORT = "COM6"
BAUD = 115200

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

def is_valid_bin(s: str) -> bool:
    return len(s) == 8 and all(c in "01" for c in s)

def byte_swap_32(x: int) -> int:
    return (
        ((x & 0xFF000000) >> 24) |
        ((x & 0x00FF0000) >> 8)  |
        ((x & 0x0000FF00) << 8)  |
        ((x & 0x000000FF) << 24)
    )
    
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

class UARTGui(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("UART Control Panel")
        self.geometry("1500x720")
        self.resizable(False, False)

        # ------- Style -------
        style = ttk.Style(self)
        style.theme_use('default')
        style.configure('TLabel', font=('Consolas', 12))
        style.configure('Header.TLabel', font=('Consolas', 14, 'bold'))
        style.configure('TButton', font=('Consolas', 12))

        # ------- Send Frame -------
        send_frame = ttk.Labelframe(self, text=" Send ", relief='groove', padding=10)
        send_frame.grid(row=0, column=0, padx=10, pady=10, sticky='ew')
        send_frame.columnconfigure(1, weight=1)

        ttk.Label(send_frame, text="8-bit binary:", style='Header.TLabel')\
            .grid(row=0, column=0, sticky='w')
        self.entry = ttk.Entry(send_frame, font=('Consolas', 14))
        self.entry.grid(row=0, column=1, padx=5, sticky='ew')
        self.entry.bind('<Return>', self.send_data)
        send_btn = ttk.Button(send_frame, text="Send", command=self.send_data)
        send_btn.grid(row=0, column=2, padx=(5,0))

        self.status = ttk.Label(self, text="Ready", foreground='blue')
        self.status.grid(row=1, column=0, sticky='w', padx=20)

        # ------- Latest Value Frame -------
        lv_frame = ttk.Labelframe(self, text=" Latest Value ", relief='groove', padding=10)
        lv_frame.grid(row=2, column=0, padx=10, pady=10, sticky='ew')
        for i,label in enumerate(("BIN:", "DEC:", "HEX:")):
            lbl = ttk.Label(lv_frame, text=label + " --------")
            lbl.grid(row=i, column=0, sticky='w', pady=2)
            setattr(self, f"{label.lower()[:3]}_label", lbl)

        # ------- Registers Frame -------
        regs_frame = ttk.Labelframe(self, text=" Registers [0..31] ", relief='groove', padding=10)
        regs_frame.grid(row=3, column=0, padx=10, pady=10, sticky='nsew')
        regs_frame.columnconfigure(0, weight=1)
        regs_frame.columnconfigure(1, weight=1)

        self.reg_labels = []
        for col in range(2):
            for row in range(16):
                idx = col*16 + row
                bg = '#f0f0ff' if row%2==0 else '#ffffff'
                lbl = tk.Label(regs_frame, text=f"regs{idx:02d}: 0x00000000",
                               font=('Consolas',11), bg=bg, anchor='w')
                lbl.grid(row=row, column=col, sticky='ew', padx=5, pady=1)
                self.reg_labels.append(lbl)

        # ------- PC Frame -------
        # pc_frame = ttk.Labelframe(self, text=" PC ", relief='groove', padding=10)
        # pc_frame.grid(row=2, column=1, padx=(5,10), pady=(10,5), sticky='nsew')
        # pc_frame.columnconfigure(0, weight=1)

        # # create a single label for PC
        # self.pc_label = tk.Label(
        #     pc_frame,
        #     text="PC : 0x00000000",
        #     font=('Consolas',11),
        #     bg='#f0f0ff',
        #     anchor='w'
        # )
        # self.pc_label.grid(row=0, column=0, sticky='ew', padx=5, pady=1)

        # ------- Debug Frame -------
        debug_frame = ttk.Labelframe(self, text=" Debug History ", relief='groove', padding=10)
        debug_frame.grid(row=3, column=1, padx=(5,10), pady=(5,10), sticky='nsew')

        dbg_signals = ["IF ", "ID ", "EXE", "MEM", "WB "]
        self.dbg_history = {}
        self.dbg_labels  = {}

        for c in range(len(dbg_signals)):
            debug_frame.columnconfigure(c, weight=1)

        for c, name in enumerate(dbg_signals):
            hdr = tk.Label(
                debug_frame,
                text=f"{name}:",
                font=('Consolas',11,'bold'),
                bg='#d0d0d0',
                anchor='center',
                padx=4
            )
            hdr.grid(row=0, column=c, sticky='ew', padx=2, pady=(0,4))

        for c, name in enumerate(dbg_signals):
            self.dbg_history[name] = deque(["U 0x00000000"]*5, maxlen=5)
            lbls = []
            for r in range(1, 6):
                bg = '#f0f0ff' if (r+c)%2==0 else '#ffffff'
                lbl = tk.Label(
                    debug_frame,
                    text=f"{self.dbg_history[name][r-1]}",
                    font=('Consolas',11),
                    width=22,
                    bg=bg,
                    anchor='w',
                    padx=4
                )
                lbl.grid(row=r, column=c, sticky='ew', padx=2, pady=1)
                lbls.append(lbl)
            self.dbg_labels[name] = lbls

        # ------- Start serial thread -------
        self.ser = serial.Serial(PORT, BAUD, timeout=0.1)
        self.running = True
        threading.Thread(target=self.read_serial, daemon=True).start()

        # Bind ESC to close
        self.bind('<Escape>', lambda e: self.close())

    def send_data(self, _=None):
        bits = self.entry.get().strip()
        if is_valid_bin(bits):
            v = int(bits, 2)
            self.ser.write(bytes([v]))
            self.status.config(text=f"Sent {bits} (0x{v:02X})", foreground='green')
        else:
            self.status.config(text="Invalid input!", foreground='red')
        self.entry.delete(0, tk.END)

    def read_serial(self):
        buf = bytearray()
        dbg_signals = ["WB ", "MEM", "EXE", "ID ", "IF "]
        while self.running:
            if self.ser.in_waiting:
                buf.extend(self.ser.read(self.ser.in_waiting))
                while len(buf) >= 156:
                    block = buf[:156]
                    del buf[:156]

                    # word0 at offset 44
                    w0, = struct.unpack_from('<I', block, 44)
                    # your byte-swap logic
                    w0 = byte_swap_32(w0)

                    # update BIN/DEC/HEX
                    self.bin_label.config(text=f"BIN: {w0&0xFF:08b}")
                    self.dec_label.config(text=f"DEC: {str(w0).zfill(8)[-8:]}")
                    self.hex_label.config(text=f"HEX: {w0:08X}")

                    # update regs
                    for i in range(32):
                        val, = struct.unpack_from('<I', block, 4+4*i)
                        val = byte_swap_32(val)
                        lbl = self.reg_labels[i]
                        # alternate highlight for changed value
                        lbl.config(text=f"regs{i:02d}: 0x{val:08X}",
                                   fg='blue' if val != int(lbl.cget('text')[-8:],16) else 'black')
                                        # update regs
                    
                    # update PC
                    # val, = struct.unpack_from('<I', block, 4+4*32)
                    # val = byte_swap_32(val)
                    # old_pc = int(self.pc_label.cget('text')[-10:], 16)
                    # self.pc_label.config(
                    #     text=f"PC : 0x{val:08X}",
                    #     fg='blue' if val != old_pc else 'black'
                    # )

                    # update pipeline (indices 33..37 → dbg_signals[0..4])
                    for i, name in enumerate(dbg_signals, start=33):
                        raw, = struct.unpack_from('<I', block, 4+4*i)
                        val = byte_swap_32(raw)
                        asm = decode_instruction(val) if i < 37 else f"0x{val:08X}"

                        hist = self.dbg_history[name]
                        hist.append(asm)

                        for row_offset, lbl in enumerate(self.dbg_labels[name]):
                            lbl.config(text=f"{hist[row_offset]}")

            time.sleep(0.005)

    def close(self):
        self.running = False
        try: self.ser.close()
        except: pass
        self.destroy()

if __name__ == '__main__':
    app = UARTGui()
    app.mainloop()