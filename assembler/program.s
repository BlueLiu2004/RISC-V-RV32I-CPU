# 4-digit seven-seg MMIO map (from soc.sv)
#   0(x0): digit0 (ones)
#   4(x0): digit1 (tens)
#   8(x0): digit2 (hundreds)
#  12(x0): digit3 (thousands)
#
# Behavior:
#   show 0000 first, then countdown as 9999, 9998, ... , 0000, 9999, ...

addi x10, x0, 0   # d0
addi x11, x0, 0   # d1
addi x12, x0, 0   # d2
addi x13, x0, 0   # d3

main_loop:
sw   x10, 0(x0)
sw   x11, 4(x0)
sw   x12, 8(x0)
sw   x13, 12(x0)

# simple delay for visible refresh
addi x14, x0, 2000
delay_loop:
addi x14, x14, -1
beq  x14, x0, dec_step
jal  x0, delay_loop

dec_step:
beq  x10, x0, borrow1
addi x10, x10, -1
jal  x0, main_loop

borrow1:
addi x10, x0, 9
beq  x11, x0, borrow2
addi x11, x11, -1
jal  x0, main_loop

borrow2:
addi x11, x0, 9
beq  x12, x0, borrow3
addi x12, x12, -1
jal  x0, main_loop

borrow3:
addi x12, x0, 9
beq  x13, x0, wrap9999
addi x13, x13, -1
jal  x0, main_loop

wrap9999:
addi x13, x0, 9
jal  x0, main_loop
