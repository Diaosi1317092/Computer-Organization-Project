import serial, struct, threading, time
import tkinter as tk
from tkinter import ttk

def is_valid_bin(s: str) -> bool:
    return len(s) == 8 and all(c in "01" for c in s)

def byte_swap_32(x: int) -> int:
    return (
        ((x & 0xFF000000) >> 24) |
        ((x & 0x00FF0000) >> 8)  |
        ((x & 0x0000FF00) << 8)  |
        ((x & 0x000000FF) << 24)
    )

def to_signed32(x):
    return x if x < 0x80000000 else x - 0x100000000

class UARTGui(tk.Tk):
    def __init__(self, PORT: str, BAUD: int = 115200):
        super().__init__()
        self.title("UART Control Panel")
        self.geometry("490x250")
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
                while len(buf) >= 4:
                    block = buf[:4]
                    del buf[:4]

                    w0, = struct.unpack_from('<I', block, 0)
                    print(f"{w0:08X}")
                    w0 = byte_swap_32(w0)

                    # update BIN/DEC/HEX
                    self.bin_label.config(text=f"BIN: {w0&0xFF:08b}")
                    self.dec_label.config(text=f"DEC: {to_signed32(w0)}")
                    self.hex_label.config(text=f"HEX: {w0:08X}")

            # time.sleep(0.005)

    def close(self):
        self.running = False
        try: self.ser.close()
        except: pass
        self.destroy()

if __name__ == '__main__':
    raw = input("Enter COM port number [6]: ").strip()
    num = raw or "6"
    if num.lower().startswith("com"):
        num = num[3:]
    PORT = f"COM{num}"
    print(f"Opening serial port {PORT}")
    app = UARTGui(PORT)
    app.mainloop()