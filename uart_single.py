import serial, struct, threading, time
import tkinter as tk
from tkinter import ttk

PORT = "COM6"
BAUD = 115200

def is_valid_bin(s: str) -> bool:
    return len(s) == 8 and all(c in "01" for c in s)

class UARTGui(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("UART Control Panel")
        self.geometry("620x800")
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
        while self.running:
            if self.ser.in_waiting:
                buf.extend(self.ser.read(self.ser.in_waiting))
                while len(buf) >= 132:
                    block = buf[:132]
                    del buf[:132]

                    # word0 at offset 44
                    w0, = struct.unpack_from('<I', block, 44)
                    # your byte-swap logic
                    ww0 = (w0 & 0xFF000000)>>24
                    ww1 = (w0 & 0x00FF0000)>>8
                    ww2 = (w0 & 0x0000FF00)<<8
                    ww3 = (w0 & 0x000000FF)<<24
                    w0 = ww0|ww1|ww2|ww3

                    # update BIN/DEC/HEX
                    self.bin_label.config(text=f"BIN: {w0&0xFF:08b}")
                    self.dec_label.config(text=f"DEC: {str(w0).zfill(8)[-8:]}")
                    self.hex_label.config(text=f"HEX: {w0:08X}")

                    # update regs
                    for i in range(32):
                        val, = struct.unpack_from('<I', block, 4+4*i)
                        v0 = (val & 0xFF000000)>>24
                        v1 = (val & 0x00FF0000)>>8
                        v2 = (val & 0x0000FF00)<<8
                        v3 = (val & 0x000000FF)<<24
                        val = v0|v1|v2|v3
                        lbl = self.reg_labels[i]
                        # alternate highlight for changed value
                        lbl.config(text=f"regs{i:02d}: 0x{val:08X}",
                                   fg='blue' if val != int(lbl.cget('text')[-8:],16) else 'black')
            time.sleep(0.005)

    def close(self):
        self.running = False
        try: self.ser.close()
        except: pass
        self.destroy()

if __name__ == '__main__':
    app = UARTGui()
    app.mainloop()