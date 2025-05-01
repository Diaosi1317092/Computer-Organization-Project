onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib prgram_opt

do {wave.do}

view wave
view structure
view signals

do {prgram.udo}

run -all

quit -force
