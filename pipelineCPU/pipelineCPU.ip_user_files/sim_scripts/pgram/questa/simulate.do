onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib pgram_opt

do {wave.do}

view wave
view structure
view signals

do {pgram.udo}

run -all

quit -force
